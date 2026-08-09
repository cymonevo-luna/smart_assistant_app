import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/router/app_router.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/core/storage/secure_storage_service.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/plugins/data/plugin_repository.dart';
import 'package:smart_assistant_app/features/plugins/pages/plugin_setup_page.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_auth_url_launcher.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_setup_deep_link_service.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_action_reason.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_reply.dart';
import 'package:smart_assistant_app/features/assistant/widgets/assistant_message_bubble.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import '../../helpers/assistant_theme_harness.dart';
import '../../helpers/auth_harness.dart';
import '../../helpers/plugin_test_data.dart';

class _FakePluginAuthUrlLauncher implements PluginAuthUrlLauncher {
  @override
  Future<bool> launchAuthorizationUrl(String url) async => true;
}

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

Widget _materialApp(Widget home) => jarvisThemedApp(home);

AssistantAction _setupIncompleteAction({String installId = 'test-id'}) {
  return AssistantAction(
    pluginSlug: 'google-calendar',
    payload: {
      'reason': AssistantActionReason.setupIncomplete,
      'install_id': installId,
      'plugin_slug': 'google-calendar',
    },
  );
}

BoxDecoration _bubbleDecoration(WidgetTester tester, String keySuffix) {
  final container = tester.widget<Container>(
    find.byKey(ValueKey('assistant_bubble_$keySuffix')),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  late DioAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<SecureStorageService>(FakeSecureStorage())
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<PluginRepository>(PluginRepository(mocked.client))
      ..registerSingleton<PluginAuthUrlLauncher>(_FakePluginAuthUrlLauncher())
      ..registerSingleton<PluginSetupDeepLinkService>(PluginSetupDeepLinkService());
  });

  ProviderScope scope(Widget child) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(_AuthenticatedAuthController.new),
      ],
      child: child,
    );
  }

  void mockInstalledForTestId() {
    adapter.onGet(
      PluginRepository.catalogPath,
      (server) => server.reply(200, {
        'success': true,
        'data': <Map<String, dynamic>>[],
        'meta': {'page': 1, 'per_page': 20, 'total': 0},
      }),
    );
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.reply(200, {
        'success': true,
        'data': [
          nestedInstalledPlugin(
            id: 'test-id',
            slug: 'google-calendar',
            name: 'Google Calendar',
          ),
        ],
      }),
    );
  }

  testWidgets('assistant bubble has gold HUD border and readable text',
      (tester) async {
    const message = 'Systems online.';
    await tester.pumpWidget(
      scope(
        _materialApp(
          const AssistantMessageBubble(
            text: message,
            isUser: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final decoration = _bubbleDecoration(tester, 'assistant_$message');
    final border = decoration.border as Border?;
    expect(border, isNotNull);
    expect(
      border!.top.color,
      jarvisDarkTheme.colorScheme.secondary.withValues(alpha: 0.4),
    );

    final text = tester.widget<Text>(find.text(message));
    expect(text.style?.color, jarvisDarkTheme.colorScheme.onSurface);
  });

  testWidgets('user bubble uses primary red background', (tester) async {
    const message = 'Hello Jarvis';
    await tester.pumpWidget(
      scope(
        _materialApp(
          const AssistantMessageBubble(
            text: message,
            isUser: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final decoration = _bubbleDecoration(tester, 'user_$message');
    expect(decoration.color, jarvisDarkTheme.colorScheme.primary);
    expect(decoration.border, isNull);
  });

  testWidgets('shows Complete setup button for setup_incomplete payload',
      (tester) async {
    await tester.pumpWidget(
      scope(
        _materialApp(
          AssistantMessageBubble(
            text: 'Please connect your calendar.',
            isUser: false,
            action: _setupIncompleteAction(),
            showActionCta: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete setup'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assistant_complete_setup_button')),
      findsOneWidget,
    );
  });

  testWidgets('hides setup CTA without action payload', (tester) async {
    await tester.pumpWidget(
      scope(
        _materialApp(
          const AssistantMessageBubble(
            text: 'All set.',
            isUser: false,
            showActionCta: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete setup'), findsNothing);
    expect(
      find.byKey(const ValueKey('assistant_complete_setup_button')),
      findsNothing,
    );
  });

  testWidgets('Complete setup navigates to plugin setup page', (tester) async {
    mockInstalledForTestId();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: AssistantMessageBubble(
              text: 'Please connect your calendar.',
              isUser: false,
              action: _setupIncompleteAction(),
              showActionCta: true,
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.pluginSetup.path,
          name: AppRoute.pluginSetup.name,
          builder: (context, state) => PluginSetupPage(
            pluginId: state.pathParameters['id']!,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      scope(
        MaterialApp.router(
          theme: jarvisDarkTheme,
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
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('assistant_complete_setup_button')),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/plugins/test-id/setup');
    expect(find.byType(PluginSetupPage), findsOneWidget);
  });
}
