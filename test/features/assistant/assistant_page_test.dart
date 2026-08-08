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
import 'package:smart_assistant_app/features/assistant/services/speech_to_text_service.dart';
import 'package:smart_assistant_app/features/assistant/services/text_to_speech_service.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import '../../helpers/auth_harness.dart';

class _IdleActiveListeningController extends ActiveListeningController {
  @override
  ActiveListeningState build() {
    return const ActiveListeningState(activeListeningEnabled: false);
  }
}

class _FakeAssistantSettingsNotifier extends AssistantSettingsNotifier {
  _FakeAssistantSettingsNotifier(this._settings);

  final AssistantSettings _settings;

  @override
  Future<AssistantSettings> build() async => _settings;
}

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

void main() {
  late DioAdapter adapter;
  late FakeSpeechRecognizer recognizer;
  late FakeTextToSpeechEngine ttsEngine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    recognizer = FakeSpeechRecognizer();
    ttsEngine = FakeTextToSpeechEngine();

    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<AssistantRepository>(
        AssistantRepository(mocked.client),
      );
    registerReminderTestServices(
      locator,
      prefs: prefs,
      apiClient: mocked.client,
    );

    adapter.onPost(
      '/api/v1/assistant/sessions',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'session_id': 'sess-1',
        },
      }),
    );
  });

  Future<void> pumpAssistantPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantSettingsProvider.overrideWith(
            () => _FakeAssistantSettingsNotifier(
              const AssistantSettings(
                wakeWord: 'Jarvis',
                activeListeningEnabled: false,
              ),
            ),
          ),
          activeListeningControllerProvider.overrideWith(
            _IdleActiveListeningController.new,
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
        ],
        child: _materialApp(const AssistantPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mic press triggers STT and API call', (tester) async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'text',
            'text': 'Hi there',
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'Hello',
        'source': 'button',
      },
    );

    await pumpAssistantPage(tester);

    await tester.tap(find.byKey(const ValueKey('assistant_mic_button')));
    await tester.pump();
    recognizer.emitFinal('Hello');
    await tester.pumpAndSettle();

    final postMatchers = adapter.history.where(
      (h) =>
          h.request.method?.name == 'POST' &&
          h.request.route == '/api/v1/assistant/sessions/sess-1/messages',
    );
    expect(postMatchers, isNotEmpty);
    expect(postMatchers.last.request.data, {
      'text': 'Hello',
      'source': 'button',
    });
  });

  testWidgets('assistant reply rendered and spoken', (tester) async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'text',
            'text': 'Done',
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'Hello',
        'source': 'button',
      },
    );

    await pumpAssistantPage(tester);

    await tester.tap(find.byKey(const ValueKey('assistant_mic_button')));
    await tester.pump();
    recognizer.emitFinal('Hello');
    await tester.pumpAndSettle();

    expect(find.text('Done'), findsOneWidget);
    expect(ttsEngine.spokenTexts, ['Done']);
  });

  testWidgets('follow-up question displayed with mic enabled', (tester) async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'follow_up',
            'text': 'Which room?',
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'Turn on the lights',
        'source': 'button',
      },
    );

    await pumpAssistantPage(tester);

    await tester.tap(find.byKey(const ValueKey('assistant_mic_button')));
    await tester.pump();
    recognizer.emitFinal('Turn on the lights');
    await tester.pumpAndSettle();

    expect(find.text('Which room?'), findsOneWidget);

    final mic = tester.widget<InkWell>(
      find.byKey(const ValueKey('assistant_mic_button')),
    );
    expect(mic.onTap, isNotNull);
  });

  testWidgets('assistant reply with setup_incomplete shows Complete setup CTA',
      (tester) async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'text',
            'text': 'Please connect your calendar.',
            'action': {
              'plugin_slug': 'google-calendar',
              'payload': {
                'reason': 'setup_incomplete',
                'install_id': 'test-id',
              },
            },
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'Schedule a meeting',
        'source': 'button',
      },
    );

    await pumpAssistantPage(tester);

    await tester.tap(find.byKey(const ValueKey('assistant_mic_button')));
    await tester.pump();
    recognizer.emitFinal('Schedule a meeting');
    await tester.pumpAndSettle();

    expect(find.text('Please connect your calendar.'), findsOneWidget);
    expect(find.text('Complete setup'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assistant_complete_setup_button')),
      findsOneWidget,
    );
    expect(ttsEngine.spokenTexts, ['Please connect your calendar.']);
  });

  testWidgets('assistant reply without action payload has no setup CTA',
      (tester) async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'text',
            'text': 'Done',
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'Hello',
        'source': 'button',
      },
    );

    await pumpAssistantPage(tester);

    await tester.tap(find.byKey(const ValueKey('assistant_mic_button')));
    await tester.pump();
    recognizer.emitFinal('Hello');
    await tester.pumpAndSettle();

    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Complete setup'), findsNothing);
    expect(
      find.byKey(const ValueKey('assistant_complete_setup_button')),
      findsNothing,
    );
  });
}
