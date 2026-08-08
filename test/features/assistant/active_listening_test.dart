import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/assistant/active_listening_controller.dart';
import 'package:smart_assistant_app/features/assistant/assistant_settings_provider.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_repository.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_settings.dart';
import 'package:smart_assistant_app/features/assistant/pages/assistant_page.dart';
import 'package:smart_assistant_app/features/assistant/services/foreground_listening_service.dart';
import 'package:smart_assistant_app/features/assistant/services/speech_to_text_service.dart';
import 'package:smart_assistant_app/features/assistant/services/text_to_speech_service.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import '../../helpers/auth_harness.dart';

class FakeSpeechRecognizer implements SpeechRecognizer {
  FakeSpeechRecognizer({this.available = true});

  bool available;
  bool listening = false;
  void Function(SpeechRecognitionResult result)? onResult;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(Object error)? onError,
  }) async {
    return available;
  }

  @override
  bool get isAvailable => available;

  @override
  bool get isListening => listening;

  @override
  Future<void> listen({
    required void Function(SpeechRecognitionResult result) onResult,
    ListenMode listenMode = ListenMode.confirmation,
  }) async {
    this.onResult = onResult;
    listening = true;
  }

  @override
  Future<void> stop() async {
    listening = false;
  }

  void emitFinal(String words) {
    onResult?.call(_result(words, finalResult: true));
  }

  SpeechRecognitionResult _result(String words, {required bool finalResult}) {
    return SpeechRecognitionResult.init(
      [
        SpeechRecognitionWords(
          words,
          null,
          SpeechRecognitionWords.missingConfidence,
        ),
      ],
      finalResult ? ResultType.finalResult : ResultType.partial,
    );
  }
}

class FakeMicrophonePermissionClient implements MicrophonePermissionClient {
  @override
  Future<PermissionStatus> request() async => PermissionStatus.granted;
}

class FakeTextToSpeechEngine implements TextToSpeechEngine {
  final spokenTexts = <String>[];

  @override
  Future<void> speak(String text) async {
    spokenTexts.add(text);
    _handler?.call();
  }

  VoidCallback? _handler;

  @override
  Future<void> stop() async {}

  @override
  void setCompletionHandler(VoidCallback? handler) {
    _handler = handler;
  }
}

class FakeForegroundListeningService implements ForegroundListeningService {
  bool running = false;

  @override
  bool get isRunning => running;

  @override
  Future<void> start({required String notificationText}) async {
    running = true;
  }

  @override
  Future<void> stop() async {
    running = false;
  }
}

class _FakeAssistantSettingsNotifier extends AssistantSettingsNotifier {
  _FakeAssistantSettingsNotifier(this._settings);

  final AssistantSettings _settings;

  @override
  Future<AssistantSettings> build() async => _settings;
}

Widget _materialApp(Widget home) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

class _ActiveListeningHarness extends ConsumerWidget {
  const _ActiveListeningHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activeListeningControllerProvider);
    return const AssistantPage();
  }
}

void main() {
  late DioAdapter adapter;
  late FakeSpeechRecognizer recognizer;
  late FakeTextToSpeechEngine ttsEngine;
  late FakeForegroundListeningService foregroundService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    recognizer = FakeSpeechRecognizer();
    ttsEngine = FakeTextToSpeechEngine();
    foregroundService = FakeForegroundListeningService();

    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<AssistantRepository>(
        AssistantRepository(mocked.client),
      );

    adapter.onPost(
      '/api/v1/assistant/sessions',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'session_id': 'sess-1',
          'session_status': 'active',
        },
      }),
    );
  });

  Future<void> pumpHarness(
    WidgetTester tester, {
    required AssistantSettings settings,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantSettingsProvider.overrideWith(
            () => _FakeAssistantSettingsNotifier(settings),
          ),
          speechToTextServiceProvider.overrideWithValue(
            SpeechToTextService(
              recognizer: recognizer,
              permissionClient: FakeMicrophonePermissionClient(),
            ),
          ),
          textToSpeechServiceProvider.overrideWithValue(
            TextToSpeechService(engine: ttsEngine),
          ),
          foregroundListeningServiceProvider.overrideWithValue(
            foregroundService,
          ),
        ],
        child: _materialApp(const _ActiveListeningHarness()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('active listening off ignores wake word transcript', (
    tester,
  ) async {
    await pumpHarness(
      tester,
      settings: const AssistantSettings(
        wakeWord: 'Jarvis',
        activeListeningEnabled: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    final historyBefore = adapter.history.length;

    recognizer.emitFinal('Jarvis hello');
    await tester.pumpAndSettle();

    final messagePosts = adapter.history
        .skip(historyBefore)
        .where(
          (h) =>
              h.request.method?.name == 'POST' &&
              h.request.route == '/api/v1/assistant/sessions/sess-1/messages',
        );
    expect(messagePosts, isEmpty);
    expect(foregroundService.running, isFalse);
  });

  testWidgets('active listening on triggers wake word API call', (
    tester,
  ) async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'text',
            'text': 'Scheduled',
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'schedule meeting',
        'source': 'wake_word',
      },
    );

    await pumpHarness(
      tester,
      settings: const AssistantSettings(
        wakeWord: 'Jarvis',
        activeListeningEnabled: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(foregroundService.running, isTrue);
    expect(
      find.byKey(const ValueKey('assistant_active_listening_chip')),
      findsOneWidget,
    );

    recognizer.emitFinal('Jarvis schedule meeting');
    await tester.pumpAndSettle();

    final postMatchers = adapter.history.where(
      (h) =>
          h.request.method?.name == 'POST' &&
          h.request.route == '/api/v1/assistant/sessions/sess-1/messages',
    );
    expect(postMatchers, isNotEmpty);
    expect(postMatchers.last.request.data, {
      'text': 'schedule meeting',
      'source': 'wake_word',
    });
    expect(find.text('Scheduled'), findsOneWidget);
  });
}
