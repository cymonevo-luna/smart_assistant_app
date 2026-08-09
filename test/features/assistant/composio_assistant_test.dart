import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:smart_assistant_app/features/assistant/models/assistant_action_reason.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_settings.dart';
import 'package:smart_assistant_app/features/assistant/pages/assistant_page.dart';
import 'package:smart_assistant_app/features/assistant/services/speech_to_text_service.dart';
import 'package:smart_assistant_app/features/assistant/services/text_to_speech_service.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/plugins/data/plugin_repository.dart';
import 'package:smart_assistant_app/features/plugins/pages/plugin_setup_page.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_auth_url_launcher.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_setup_deep_link_service.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import '../../helpers/auth_harness.dart';
import '../../helpers/plugin_test_data.dart';

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

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
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

class _FakePluginAuthUrlLauncher implements PluginAuthUrlLauncher {
  @override
  Future<bool> launchAuthorizationUrl(String url) async => true;
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
      ..registerSingleton<SecureStorageService>(FakeSecureStorage())
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<AssistantRepository>(
        AssistantRepository(mocked.client),
      )
      ..registerSingleton<PluginRepository>(PluginRepository(mocked.client))
      ..registerSingleton<PluginAuthUrlLauncher>(_FakePluginAuthUrlLauncher())
      ..registerSingleton<PluginSetupDeepLinkService>(PluginSetupDeepLinkService());
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

  Future<ProviderContainer> pumpAssistantPage(
    WidgetTester tester, {
    GoRouter? router,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_AuthenticatedAuthController.new),
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
    );

    if (router != null) {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
    } else {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AssistantPage(),
          ),
        ),
      );
    }

    await tester.pumpAndSettle();
    return container;
  }

  Future<void> sendMicCommand(WidgetTester tester, String text) async {
    await tester.tap(find.byKey(const ValueKey('assistant_mic_button')));
    await tester.pump();
    recognizer.emitFinal(text);
    await tester.pumpAndSettle();
  }

  Map<String, dynamic> composioFollowUpReply(String prompt) => {
        'type': 'follow_up',
        'text': prompt,
        'action': {
          'plugin_slug': 'composio-ai',
        },
      };

  Map<String, dynamic> composioActionResultReply({
    required String text,
    String status = 'success',
    Map<String, dynamic>? payload,
  }) =>
      {
        'type': 'action_result',
        'text': text,
        'action': {
          'plugin_slug': 'composio-ai',
          'status': status,
          'payload': payload ?? {'plugin_name': 'Composio AI'},
        },
      };

  testWidgets('follow-up prompt displayed in chat', (tester) async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': composioFollowUpReply('Which Slack channel should I post in?'),
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'Post a Slack update',
        'source': 'button',
      },
    );

    final container = await pumpAssistantPage(tester);
    await sendMicCommand(tester, 'Post a Slack update');

    expect(find.text('Which Slack channel should I post in?'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);

    final mic = tester.widget<InkWell>(
      find.byKey(const ValueKey('assistant_mic_button')),
    );
    expect(mic.onTap, isNotNull);
    expect(
      container.read(assistantControllerProvider).expectsFollowUpInput,
      isTrue,
    );
  });

  testWidgets('follow-up answer completes task', (tester) async {
    adapter
      ..onPost(
        '/api/v1/assistant/sessions/sess-1/messages',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'reply': composioFollowUpReply('Which Slack channel should I post in?'),
            'session_status': 'active',
          },
        }),
        data: {
          'text': 'Post a Slack update',
          'source': 'button',
        },
      )
      ..onPost(
        '/api/v1/assistant/sessions/sess-1/messages',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'reply': composioActionResultReply(
              text: 'Posted your update to #general.',
            ),
            'session_status': 'active',
          },
        }),
        data: {
          'text': '#general',
          'source': 'button',
        },
      );

    await pumpAssistantPage(tester);
    await sendMicCommand(tester, 'Post a Slack update');

    for (var i = 0; i < 50; i++) {
      if (recognizer.listening) break;
      await Future<void>.delayed(Duration.zero);
      await tester.pump();
    }
    recognizer.emitFinal('#general');
    await tester.pumpAndSettle();

    expect(find.text('Posted your update to #general.'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant_plugin_badge')), findsOneWidget);
    expect(find.text('Composio AI'), findsOneWidget);
  });

  testWidgets('confirmation yes completes task', (tester) async {
    adapter
      ..onPost(
        '/api/v1/assistant/sessions/sess-1/messages',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'reply': {
              'type': 'confirmation',
              'text': 'Send this email to Janet?',
              'action': {'plugin_slug': 'composio-ai'},
            },
            'session_status': 'active',
          },
        }),
        data: {
          'text': 'Email Janet the report',
          'source': 'button',
        },
      )
      ..onPost(
        '/api/v1/assistant/sessions/sess-1/messages',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'reply': composioActionResultReply(text: 'Email sent to Janet.'),
            'session_status': 'active',
          },
        }),
        data: {
          'text': 'yes',
          'source': 'button',
        },
      );

    await pumpAssistantPage(tester);
    await sendMicCommand(tester, 'Email Janet the report');

    expect(find.text('Send this email to Janet?'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant_confirm_yes_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('assistant_confirm_yes_button')));
    await tester.pumpAndSettle();

    expect(find.text('Email sent to Janet.'), findsOneWidget);
  });

  testWidgets('confirmation no cancels', (tester) async {
    adapter
      ..onPost(
        '/api/v1/assistant/sessions/sess-1/messages',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'reply': {
              'type': 'confirmation',
              'text': 'Send this email to Janet?',
              'action': {'plugin_slug': 'composio-ai'},
            },
            'session_status': 'active',
          },
        }),
        data: {
          'text': 'Email Janet the report',
          'source': 'button',
        },
      )
      ..onPost(
        '/api/v1/assistant/sessions/sess-1/messages',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'reply': {
              'type': 'text',
              'text': 'Okay, I cancelled that action.',
            },
            'session_status': 'active',
          },
        }),
        data: {
          'text': 'no',
          'source': 'button',
        },
      );

    await pumpAssistantPage(tester);
    await sendMicCommand(tester, 'Email Janet the report');

    await tester.tap(find.byKey(const ValueKey('assistant_confirm_no_button')));
    await tester.pumpAndSettle();

    expect(find.text('Okay, I cancelled that action.'), findsOneWidget);
    expect(find.text('Email sent to Janet.'), findsNothing);
  });

  testWidgets('setup incomplete CTA navigates to composio form setup',
      (tester) async {
    const installId = 'install-composio-ai';

    adapter
      ..onPost(
        '/api/v1/assistant/sessions/sess-1/messages',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'reply': {
              'type': 'text',
              'text': 'Connect Composio before I can run that task.',
              'action': {
                'plugin_slug': 'composio-ai',
                'payload': {
                  'reason': AssistantActionReason.setupIncomplete,
                  'install_id': installId,
                  'plugin_slug': 'composio-ai',
                },
              },
            },
            'session_status': 'active',
          },
        }),
        data: {
          'text': 'Summarize my inbox',
          'source': 'button',
        },
      )
      ..onGet(
        PluginRepository.catalogPath,
        (server) => server.reply(200, {
          'success': true,
          'data': [catalogComposioAi],
          'meta': {'page': 1, 'per_page': 20, 'total': 1},
        }),
      )
      ..onGet(
        PluginRepository.installedPath,
        (server) => server.reply(200, {
          'success': true,
          'data': [nestedInstalledComposioAi(id: installId)],
        }),
      )
      ..onGet(
        '${PluginRepository.setupPath(installId)}/status',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'setup_status': 'not_started',
            'setup_error': null,
            'connected_toolkits': <String>[],
            'connected_accounts_count': 0,
          },
        }),
      );

    final router = GoRouter(
      initialLocation: AppRoute.assistant.path,
      routes: [
        GoRoute(
          path: AppRoute.assistant.path,
          name: AppRoute.assistant.name,
          builder: (context, state) => const AssistantPage(),
        ),
        GoRoute(
          path: AppRoute.composioAiSetup.path,
          name: AppRoute.composioAiSetup.name,
          builder: (context, state) => PluginSetupPage(
            pluginId: state.pathParameters['id']!,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await pumpAssistantPage(tester, router: router);
    await sendMicCommand(tester, 'Summarize my inbox');

    expect(find.text('Connect Composio before I can run that task.'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant_complete_setup_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('assistant_complete_setup_button')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/plugins/$installId/composio-setup');
    expect(find.byKey(const ValueKey('composio_api_key_field')), findsOneWidget);
  });

  testWidgets('reminder confirmation regression still works', (tester) async {
    adapter
      ..onPost(
        '/api/v1/assistant/sessions/sess-1/messages',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'reply': {
              'type': 'confirmation',
              'text': 'Set a reminder for groceries tomorrow at 9am?',
              'action': {'plugin_slug': 'reminder'},
            },
            'session_status': 'active',
          },
        }),
        data: {
          'text': 'Remind me about groceries',
          'source': 'button',
        },
      )
      ..onPost(
        '/api/v1/assistant/sessions/sess-1/messages',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'reply': {
              'type': 'action_result',
              'text': 'Reminder set for tomorrow at 9am.',
              'action': {
                'plugin_slug': 'reminder',
                'status': 'success',
                'payload': {
                  'reminder_id': 'rem-1',
                  'title': 'Groceries',
                  'scheduled_at': '2026-08-10T09:00:00Z',
                },
              },
            },
            'session_status': 'active',
          },
        }),
        data: {
          'text': 'yes',
          'source': 'button',
        },
      );

    await pumpAssistantPage(tester);
    await sendMicCommand(tester, 'Remind me about groceries');

    expect(
      find.text('Set a reminder for groceries tomorrow at 9am?'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('assistant_confirm_yes_button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('assistant_confirm_yes_button')));
    await tester.pumpAndSettle();

    expect(find.text('Reminder set for tomorrow at 9am.'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant_plugin_badge')), findsNothing);
  });

  test('action_result sanitizes raw composio JSON in reply text', () async {
    adapter.onPost(
      '/api/v1/assistant/sessions/sess-1/messages',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'reply': {
            'type': 'action_result',
            'text': '{"message":"Email sent to Janet."}',
            'action': {
              'plugin_slug': 'composio-ai',
              'status': 'success',
              'payload': {'message': 'Email sent to Janet.'},
            },
          },
          'session_status': 'active',
        },
      }),
      data: {
        'text': 'send it',
        'source': 'wake_word',
      },
    );

    final container = ProviderContainer(
      overrides: [
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
    );
    addTearDown(container.dispose);

    final controller = container.read(assistantControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await controller.sendWakeWordCommand('send it');
    await Future<void>.delayed(Duration.zero);

    final state = container.read(assistantControllerProvider);
    final assistantMessage =
        state.messages.lastWhere((message) => !message.isUser);
    expect(assistantMessage.text, 'Email sent to Janet.');
    expect(state.expectsFollowUpInput, isFalse);
  });
}
