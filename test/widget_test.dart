import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:smart_assistant_app/app.dart';
import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/router/app_router.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/core/storage/secure_storage_service.dart';
import 'package:smart_assistant_app/features/assistant/active_listening_controller.dart';
import 'package:smart_assistant_app/features/assistant/assistant_settings_provider.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_repository.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_settings.dart';
import 'package:smart_assistant_app/features/assistant/pages/assistant_page.dart';
import 'package:smart_assistant_app/features/assistant/services/speech_to_text_service.dart';
import 'package:smart_assistant_app/features/assistant/services/text_to_speech_service.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/auth/login_page.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_auth_url_launcher.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_setup_deep_link_service.dart';
import 'package:smart_assistant_app/features/profile/profile_page.dart';
import 'package:smart_assistant_app/features/user/models/user.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import 'helpers/auth_harness.dart';

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

class _FakeSpeechRecognizer implements SpeechRecognizer {
  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(Object error)? onError,
  }) async =>
      true;

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => false;

  @override
  Future<void> listen({
    required void Function(SpeechRecognitionResult result) onResult,
    ListenMode listenMode = ListenMode.confirmation,
  }) async {}

  @override
  Future<void> stop() async {}
}

class _FakeMicrophonePermissionClient implements MicrophonePermissionClient {
  @override
  Future<PermissionStatus> request() async => PermissionStatus.granted;
}

class _FakeTextToSpeechEngine implements TextToSpeechEngine {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  void setCompletionHandler(VoidCallback? handler) {}
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

Widget _profileTestApp() {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_AuthenticatedAuthController.new),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ProfilePage(),
    ),
  );
}

void main() {
  late FakeSecureStorage secure;
  late DioAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    secure = FakeSecureStorage();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<SecureStorageService>(secure)
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<PluginAuthUrlLauncher>(DefaultPluginAuthUrlLauncher())
      ..registerSingleton<PluginSetupDeepLinkService>(PluginSetupDeepLinkService())
      ..registerSingleton<AssistantRepository>(
        AssistantRepository(mocked.client),
      );

    adapter.onPost(
      '/api/v1/assistant/sessions',
      (server) => server.reply(200, {
        'success': true,
        'data': {'session_id': 'sess-1'},
      }),
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    appRouter.go(AppRoute.splash.path);
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
              recognizer: _FakeSpeechRecognizer(),
              permissionClient: _FakeMicrophonePermissionClient(),
            ),
          ),
          textToSpeechServiceProvider.overrideWithValue(
            TextToSpeechService(engine: _FakeTextToSpeechEngine()),
          ),
        ],
        child: const App(),
      ),
    );
  }

  Future<void> settlePastSplash(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('unauthenticated startup routes to the login screen',
      (WidgetTester tester) async {
    await pumpApp(tester);
    await settlePastSplash(tester);

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('bottom nav has two tabs only', (WidgetTester tester) async {
    secure.store[SecureKeys.authToken] = 'acc';
    secure.store[SecureKeys.userId] = 'u1';
    adapter.onGet(
      '/api/v1/users/u1',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'id': 'u1',
          'email': 'alex@example.com',
          'name': 'Alex Johnson',
          'role': 'user',
        },
      }),
    );

    await pumpApp(tester);
    await settlePastSplash(tester);

    expect(find.byType(AssistantPage), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(2));
  });

  testWidgets('login routes to Assistant', (WidgetTester tester) async {
    adapter.onPost(
      '/api/v1/auth/login',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'tokens': {
            'access_token': 'acc',
            'refresh_token': 'ref',
            'expires_in': 900,
          },
          'user': {
            'id': 'u1',
            'email': 'a@b.com',
            'name': 'Alex',
            'role': 'user',
          },
        },
      }),
      data: {'email': 'a@b.com', 'password': 'secret123'},
    );

    await pumpApp(tester);
    await settlePastSplash(tester);

    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.byType(AssistantPage), findsOneWidget);
    expect(find.text('Have a great day!'), findsNothing);
    expect(appRouter.routeInformationProvider.value.uri.path, '/assistant');
  });

  testWidgets('removed routes are not reachable', (WidgetTester tester) async {
    secure.store[SecureKeys.authToken] = 'acc';
    secure.store[SecureKeys.userId] = 'u1';
    adapter.onGet(
      '/api/v1/users/u1',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'id': 'u1',
          'email': 'alex@example.com',
          'name': 'Alex Johnson',
          'role': 'user',
        },
      }),
    );

    await pumpApp(tester);
    await settlePastSplash(tester);

    appRouter.go('/home');
    await tester.pumpAndSettle();
    expect(find.textContaining('Route not found: /home'), findsOneWidget);

    appRouter.go('/tasks');
    await tester.pumpAndSettle();
    expect(find.textContaining('Route not found: /tasks'), findsOneWidget);
  });

  testWidgets('profile has no fake stats or dead menu items',
      (WidgetTester tester) async {
    await tester.pumpWidget(_profileTestApp());
    await tester.pumpAndSettle();

    expect(find.text('12'), findsNothing);
    expect(find.text('48'), findsNothing);
    expect(find.text('85%'), findsNothing);
    expect(find.text('Achievements'), findsNothing);
    expect(find.text('Activity History'), findsNothing);
    expect(find.text('Saved Items'), findsNothing);
    expect(find.text('Alex Johnson'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
  });
}
