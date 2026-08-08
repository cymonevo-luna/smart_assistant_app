import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/core/storage/secure_storage_service.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/plugins/data/plugin_repository.dart';
import 'package:smart_assistant_app/features/plugins/pages/my_plugins_page.dart';
import 'package:smart_assistant_app/features/plugins/pages/plugin_setup_page.dart';
import 'package:smart_assistant_app/features/plugins/plugin_setup_provider.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_auth_url_launcher.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_setup_deep_link_service.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import '../../helpers/auth_harness.dart';

const _installedCalendar = {
  'id': 'plugin-calendar',
  'enabled': true,
  'setup_status': 'not_started',
  'plugin': {
    'id': 'catalog-calendar',
    'slug': 'google-calendar',
    'name': 'Google Calendar',
    'required_setup': true,
    'setup_type': 'oauth_google',
  },
};

const _authorizationUrl = 'https://accounts.google.com/o/oauth2/auth?test=1';

class _FakePluginAuthUrlLauncher implements PluginAuthUrlLauncher {
  final launchedUrls = <String>[];

  @override
  Future<bool> launchAuthorizationUrl(String url) async {
    launchedUrls.add(url);
    return true;
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
  late _FakePluginAuthUrlLauncher urlLauncher;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    urlLauncher = _FakePluginAuthUrlLauncher();
    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<SecureStorageService>(FakeSecureStorage())
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<PluginRepository>(PluginRepository(mocked.client))
      ..registerSingleton<PluginAuthUrlLauncher>(urlLauncher)
      ..registerSingleton<PluginSetupDeepLinkService>(PluginSetupDeepLinkService());
  });

  ProviderScope scope(Widget child) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _AuthenticatedAuthController()),
      ],
      child: child,
    );
  }

  void mockInstalled({Map<String, dynamic> plugin = _installedCalendar}) {
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.reply(200, {
        'success': true,
        'data': [plugin],
      }),
    );
  }

  test('start setup opens authorization URL', () async {
    adapter.onPost(
      PluginRepository.setupPath('plugin-calendar'),
      (server) => server.reply(200, {
        'success': true,
        'data': {'authorization_url': _authorizationUrl},
      }),
    );
    adapter.onGet(
      '${PluginRepository.setupPath('plugin-calendar')}/status',
      (server) => server.reply(200, {
        'success': true,
        'data': {'setup_status': 'in_progress'},
      }),
    );

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _AuthenticatedAuthController()),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(pluginSetupControllerProvider.notifier)
      ..bind('plugin-calendar');

    await notifier.connectGoogleAccount();

    expect(urlLauncher.launchedUrls, [_authorizationUrl]);
    notifier.retry();
  });

  testWidgets('setup page shows connect action', (tester) async {
    mockInstalled();

    await tester.pumpWidget(
      scope(
        _materialApp(const PluginSetupPage(pluginId: 'plugin-calendar')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('connect_google_account')), findsOneWidget);
    expect(find.text('Connect Google Account'), findsOneWidget);
  });

  test('polling shows completed status', () async {
    adapter.onPost(
      PluginRepository.setupPath('plugin-calendar'),
      (server) => server.reply(200, {
        'success': true,
        'data': {'authorization_url': _authorizationUrl},
      }),
    );
    var statusPollCount = 0;
    adapter.onGet(
      '${PluginRepository.setupPath('plugin-calendar')}/status',
      (server) => server.replyCallback(200, (request) {
        statusPollCount++;
        return {
          'success': true,
          'data': {
            'setup_status':
                statusPollCount < 2 ? 'in_progress' : 'completed',
          },
        };
      }),
    );

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _AuthenticatedAuthController()),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(pluginSetupControllerProvider.notifier)
      ..bind('plugin-calendar');

    await notifier.connectGoogleAccount();
    expect(statusPollCount, 1);
    await notifier.handleDeepLink(
      const PluginSetupDeepLinkEvent(status: PluginSetupDeepLinkStatus.success),
    );

    expect(statusPollCount, greaterThanOrEqualTo(2));
    expect(
      container.read(pluginSetupControllerProvider).phase,
      PluginSetupPhase.completed,
    );
    notifier.retry();
  });

  testWidgets('polling shows completed status in UI', (tester) async {
    mockInstalled(plugin: {
      ..._installedCalendar,
      'setup_status': 'completed',
    });

    await tester.pumpWidget(
      scope(
        _materialApp(const PluginSetupPage(pluginId: 'plugin-calendar')),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Setup complete! This plugin is ready to use.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('completed plugin list shows ready badge', (tester) async {
    mockInstalled(plugin: {
      ..._installedCalendar,
      'setup_status': 'completed',
    });

    await tester.pumpWidget(
      scope(_materialApp(const MyPluginsPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ready'), findsOneWidget);
  });

  test('failed setup shows setup_error and allows retry', () async {
    adapter.onPost(
      PluginRepository.setupPath('plugin-calendar'),
      (server) => server.reply(200, {
        'success': true,
        'data': {'authorization_url': _authorizationUrl},
      }),
    );
    adapter.onGet(
      '${PluginRepository.setupPath('plugin-calendar')}/status',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'setup_status': 'failed',
          'setup_error': 'Google account denied access',
        },
      }),
    );

    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => _AuthenticatedAuthController()),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(pluginSetupControllerProvider.notifier)
      ..bind('plugin-calendar');

    await notifier.connectGoogleAccount();
    expect(
      container.read(pluginSetupControllerProvider).setupError,
      'Google account denied access',
    );

    notifier.retry();
    expect(
      container.read(pluginSetupControllerProvider).phase,
      PluginSetupPhase.idle,
    );
  });
}

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}
