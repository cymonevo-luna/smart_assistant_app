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
import 'package:smart_assistant_app/core/router/app_router.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/core/storage/secure_storage_service.dart';
import 'package:smart_assistant_app/features/assistant/active_listening_controller.dart';
import 'package:smart_assistant_app/features/assistant/assistant_controller.dart';
import 'package:smart_assistant_app/features/assistant/assistant_settings_provider.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_repository.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_settings.dart';
import 'package:smart_assistant_app/features/assistant/services/speech_to_text_service.dart';
import 'package:smart_assistant_app/features/assistant/services/text_to_speech_service.dart';
import 'package:smart_assistant_app/features/assistant/services/widget_launch_service.dart';
import 'package:smart_assistant_app/features/assistant/services/widget_launch_uri.dart';
import 'package:smart_assistant_app/features/assistant/widget_launch_controller.dart';
import 'package:smart_assistant_app/features/assistant/widgets/assistant_listening_overlay_host.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/auth/login_page.dart';
import 'package:smart_assistant_app/features/user/models/user.dart';
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
  int stopCallCount = 0;
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
    stopCallCount++;
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

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(
      status: AuthStatus.authenticated,
      user: User(
        id: 'u1',
        name: 'Alex Johnson',
        email: 'alex@example.com',
      ),
    );
  }
}

class _UnauthenticatedAuthController extends AuthController {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter adapter;
  late FakeSpeechRecognizer recognizer;
  late FakeTextToSpeechEngine ttsEngine;
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
      ..registerSingleton<SecureStorageService>(FakeSecureStorage())
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<AssistantRepository>(
        AssistantRepository(mocked.client),
      )
      ..registerSingleton<WidgetLaunchService>(WidgetLaunchService());
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

    appRouter.go(AppRoute.profile.path);
  });

  tearDown(() {
    appRouter.go(AppRoute.splash.path);
  });

  baseOverrides({AuthController Function()? authOverride}) {
    return [
      authProvider.overrideWith(
        authOverride ?? () => _AuthenticatedAuthController(),
      ),
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
    ];
  }

  Widget buildRouterApp({
    ProviderContainer? container,
  }) {
    final app = AssistantListeningOverlayHost(
      child: MaterialApp.router(
        scaffoldMessengerKey: scaffoldMessengerKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter,
      ),
    );

    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: app,
      );
    }

    return ProviderScope(
      overrides: baseOverrides(),
      child: app,
    );
  }

  Future<ProviderContainer> pumpHarness(
    WidgetTester tester, {
    AuthController Function()? authOverride,
  }) async {
    final container = ProviderContainer(
      overrides: baseOverrides(authOverride: authOverride),
    );
    container.read(widgetLaunchControllerProvider);

    await tester.pumpWidget(
      buildRouterApp(container: container),
    );
    await tester.pumpAndSettle();

    return container;
  }

  void fireWidgetLaunch() {
    locator<WidgetLaunchService>().handleUri(widgetListenUri);
  }

  testWidgets('widget flow starts listening and sends message', (tester) async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'text',
            'text': 'Meeting scheduled.',
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'schedule meeting tomorrow',
        'source': 'button',
      },
    );

    final container = await pumpHarness(tester);

    fireWidgetLaunch();
    await tester.pump();

    expect(
      container.read(assistantListeningOverlayControllerProvider),
      isTrue,
    );
    expect(find.byKey(const ValueKey('assistant_listening_overlay')),
        findsOneWidget);
    expect(recognizer.listening, isTrue);

    recognizer.emitFinal('schedule meeting tomorrow');
    await tester.pump();

    expect(find.text('Thinking...'), findsOneWidget);

    await tester.pumpAndSettle();

    final postMatchers = adapter.history.where(
      (h) =>
          h.request.method?.name == 'POST' &&
          h.request.route == '/api/v1/assistant/sessions/sess-1/messages',
    );
    expect(postMatchers, isNotEmpty);
    expect(postMatchers.last.request.data, {
      'text': 'schedule meeting tomorrow',
      'source': 'button',
    });

    expect(
      container.read(assistantControllerProvider).interactionState,
      AssistantInteractionState.idle,
    );
    expect(
      container.read(assistantListeningOverlayControllerProvider),
      isFalse,
    );
  });

  testWidgets('unauthenticated widget launch redirects to login', (tester) async {
    await pumpHarness(
      tester,
      authOverride: () => _UnauthenticatedAuthController(),
    );

    fireWidgetLaunch();
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      find.text('Sign in to use the assistant widget'),
      findsOneWidget,
    );
    expect(recognizer.listening, isFalse);
    expect(find.byKey(const ValueKey('assistant_listening_overlay')),
        findsNothing);
  });

  testWidgets('cancel aborts without API call', (tester) async {
    final container = await pumpHarness(tester);

    fireWidgetLaunch();
    await tester.pump();

    expect(recognizer.listening, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('assistant_listening_overlay_cancel')),
    );
    await tester.pumpAndSettle();

    expect(recognizer.stopCallCount, greaterThanOrEqualTo(1));
    expect(recognizer.listening, isFalse);
    expect(
      container.read(assistantListeningOverlayControllerProvider),
      isFalse,
    );

    final postMatchers = adapter.history.where(
      (h) =>
          h.request.method?.name == 'POST' &&
          '${h.request.route}'.contains('/messages'),
    );
    expect(postMatchers, isEmpty);
  });
}
