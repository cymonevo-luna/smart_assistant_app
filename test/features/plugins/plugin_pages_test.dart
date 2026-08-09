import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/router/app_router.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/core/storage/secure_storage_service.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/plugins/data/plugin_repository.dart';
import 'package:smart_assistant_app/features/plugins/pages/manage_plugins_page.dart';
import 'package:smart_assistant_app/features/plugins/pages/plugin_setup_page.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_auth_url_launcher.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_setup_deep_link_service.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import '../../helpers/auth_harness.dart';
import '../../helpers/plugin_test_data.dart';

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

Widget _routerApp() {
  return MaterialApp.router(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: appRouter,
  );
}

class _RecordingUrlLauncher implements PluginAuthUrlLauncher {
  final List<String> urls = [];

  @override
  Future<bool> launchAuthorizationUrl(String url) async {
    urls.add(url);
    return true;
  }
}

void main() {
  late DioAdapter adapter;
  late _RecordingUrlLauncher urlLauncher;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    urlLauncher = _RecordingUrlLauncher();
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

  void mockCatalog({List<Map<String, dynamic>>? plugins}) {
    final data = plugins ?? catalogPlugins;
    adapter.onGet(
      PluginRepository.catalogPath,
      (server) => server.reply(200, {
        'success': true,
        'data': data,
        'meta': {'page': 1, 'per_page': 20, 'total': data.length},
      }),
    );
  }

  void mockInstalledEmpty() {
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.reply(200, {
        'success': true,
        'data': <Map<String, dynamic>>[],
      }),
    );
  }

  testWidgets('catalog page lists plugins', (WidgetTester tester) async {
    mockCatalog(plugins: [catalogGoogleCalendarMeet]);
    mockInstalledEmpty();

    await tester.pumpWidget(
      scope(
        _materialApp(
          const ManagePluginsPage(initialTab: ManagePluginsTab.available),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Google Calendar Meet'), findsOneWidget);
    expect(find.text('Install'), findsOneWidget);
  });

  testWidgets('install plugin success', (WidgetTester tester) async {
    mockCatalog(plugins: [
      {
        'id': 'catalog-weather',
        'slug': 'weather',
        'name': 'Weather',
        'description': 'Get weather forecasts',
        'version': '1.0.0',
        'required_setup': true,
        'setup_type': 'oauth_google',
      },
    ]);
    var installedFetchCount = 0;
    adapter.onGet(
      PluginRepository.installedPath,
      (server) {
        installedFetchCount++;
        if (installedFetchCount == 1) {
          return server.reply(200, {
            'success': true,
            'data': <Map<String, dynamic>>[],
          });
        }
        return server.reply(200, {
          'success': true,
          'data': [installedWeather],
        });
      },
    );
    adapter.onPost(
      PluginRepository.installedPath,
      (server) => server.reply(201, {
        'success': true,
        'data': {
          ...installedWeather,
          'setup_status': 'completed',
        },
      }),
      data: {'plugin_slug': 'weather'},
    );

    await tester.pumpWidget(
      scope(
        _materialApp(
          const ManagePluginsPage(initialTab: ManagePluginsTab.available),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Install').first);
    await tester.pumpAndSettle();

    final postMatchers = adapter.history.where(
      (h) => h.request.method?.name == 'POST',
    );
    expect(postMatchers, isNotEmpty);
    expect(postMatchers.last.request.data, {'plugin_slug': 'weather'});

    await tester.pumpWidget(
      scope(_materialApp(const ManagePluginsPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weather'), findsOneWidget);
    expect(find.text('Get weather forecasts'), findsOneWidget);
  });

  testWidgets('Composio AI appears in plugin catalog', (WidgetTester tester) async {
    mockCatalog(plugins: catalogPlugins);
    mockInstalledEmpty();

    await tester.pumpWidget(
      scope(
        _materialApp(
          const ManagePluginsPage(initialTab: ManagePluginsTab.available),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Composio AI'), findsOneWidget);
    expect(
      find.text(
        'Connect external apps and automate workflows with Composio integrations',
      ),
      findsOneWidget,
    );
    expect(find.text('API key required'), findsOneWidget);
    expect(find.text('Google Calendar Meet'), findsOneWidget);
    expect(find.text('Reminder'), findsOneWidget);
  });

  testWidgets('install composio-ai succeeds and opens form setup',
      (WidgetTester tester) async {
    const installId = 'install-composio-ai';
    mockCatalog(plugins: [catalogComposioAi]);
    mockInstalledEmpty();

    final installedComposio = nestedInstalledComposioAi(id: installId);
    adapter.onPost(
      PluginRepository.installedPath,
      (server) => server.reply(201, {
        'success': true,
        'data': installedComposio,
      }),
      data: {'plugin_slug': 'composio-ai'},
    );
    adapter.onGet(
      '${PluginRepository.setupPath(installId)}/status',
      (server) => server.reply(200, {
        'success': true,
        'data': {'setup_status': 'not_started'},
      }),
    );

    appRouter.go('${AppRoute.managePlugins.path}?tab=available');

    await tester.pumpWidget(scope(_routerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();

    final postMatchers = adapter.history.where(
      (h) => h.request.method?.name == 'POST',
    );
    expect(postMatchers.last.request.data, {'plugin_slug': 'composio-ai'});
    expect(find.byType(PluginSetupPage), findsOneWidget);
    expect(find.byKey(const ValueKey('composio_api_key_field')), findsOneWidget);
    expect(find.text('Save API key'), findsOneWidget);
  });

  testWidgets('setup required badge shown for composio-ai without setup',
      (WidgetTester tester) async {
    mockCatalog(plugins: [catalogComposioAi]);
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.reply(200, {
        'success': true,
        'data': [nestedInstalledComposioAi(id: 'install-composio-ai')],
      }),
    );

    await tester.pumpWidget(scope(_materialApp(const ManagePluginsPage())));
    await tester.pumpAndSettle();

    expect(find.text('Setup needed'), findsOneWidget);
    expect(find.text('Ready'), findsNothing);
    expect(find.text('API key required'), findsOneWidget);
  });

  testWidgets('install plugin with incomplete setup navigates to PluginSetupPage',
      (WidgetTester tester) async {
    mockCatalog(plugins: [catalogGoogleCalendarMeet]);
    mockInstalledEmpty();

    final installedMeet = nestedInstalledPlugin(
      id: 'install-google-calendar-meet',
      slug: 'google-calendar-meet',
      name: 'Google Calendar Meet',
      setupStatus: 'not_started',
    );
    adapter.onPost(
      PluginRepository.installedPath,
      (server) => server.reply(201, {
        'success': true,
        'data': installedMeet,
      }),
      data: {'plugin_slug': 'google-calendar-meet'},
    );

    appRouter.go('${AppRoute.managePlugins.path}?tab=available');

    await tester.pumpWidget(scope(_routerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();

    expect(find.text('Plugin Setup'), findsOneWidget);
    expect(find.byType(PluginSetupPage), findsOneWidget);
    expect(
      tester.widget<PluginSetupPage>(find.byType(PluginSetupPage)).pluginId,
      'install-google-calendar-meet',
    );
  });

  testWidgets(
      'install plugin with incomplete setup shows connect and launches OAuth',
      (WidgetTester tester) async {
    const installId = 'install-google-calendar-meet';
    const authorizationUrl =
        'https://accounts.google.com/o/oauth2/auth?client_id=handoff-test';

    mockCatalog(plugins: [catalogGoogleCalendarMeet]);
    mockInstalledEmpty();

    final installedMeet = nestedInstalledPlugin(
      id: installId,
      slug: 'google-calendar-meet',
      name: 'Google Calendar Meet',
      setupStatus: 'not_started',
    );
    adapter.onPost(
      PluginRepository.installedPath,
      (server) => server.reply(201, {
        'success': true,
        'data': installedMeet,
      }),
      data: {'plugin_slug': 'google-calendar-meet'},
    );
    adapter.onPost(
      PluginRepository.setupPath(installId),
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'authorization_url': authorizationUrl,
          'state': 'test-state',
        },
      }),
    );
    adapter.onGet(
      '${PluginRepository.setupPath(installId)}/status',
      (server) => server.reply(200, {
        'success': true,
        'data': {'setup_status': 'in_progress'},
      }),
    );

    appRouter.go('${AppRoute.managePlugins.path}?tab=available');

    await tester.pumpWidget(scope(_routerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();

    expect(find.byType(PluginSetupPage), findsOneWidget);
    expect(
      tester.widget<PluginSetupPage>(find.byType(PluginSetupPage)).pluginId,
      installId,
    );
    expect(find.byKey(const ValueKey('connect_google_account')), findsOneWidget);
    expect(find.text('Connect Google Account'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('connect_google_account')));
    await tester.pumpAndSettle();

    expect(urlLauncher.urls, [authorizationUrl]);

    final setupPostMatchers = adapter.history.where(
      (h) =>
          h.request.method?.name == 'POST' &&
          h.request.route == PluginRepository.setupPath(installId),
    );
    expect(setupPostMatchers, isNotEmpty);
  });

  testWidgets('install plugin with completed setup does not navigate to setup',
      (WidgetTester tester) async {
    mockCatalog(plugins: [catalogGoogleCalendarMeet]);
    mockInstalledEmpty();

    final installedMeet = nestedInstalledPlugin(
      id: 'install-google-calendar-meet',
      slug: 'google-calendar-meet',
      name: 'Google Calendar Meet',
      setupStatus: 'completed',
    );
    adapter.onPost(
      PluginRepository.installedPath,
      (server) => server.reply(201, {
        'success': true,
        'data': installedMeet,
      }),
      data: {'plugin_slug': 'google-calendar-meet'},
    );

    appRouter.go('${AppRoute.managePlugins.path}?tab=available');

    await tester.pumpWidget(scope(_routerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();

    expect(find.byType(PluginSetupPage), findsNothing);
    expect(find.text('Plugin Setup'), findsNothing);
    expect(find.text('Manage Plugins'), findsOneWidget);
  });

  testWidgets('uninstall with confirmation', (WidgetTester tester) async {
    mockCatalog();
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.reply(200, {
        'success': true,
        'data': [installedWeather],
      }),
    );
    adapter.onDelete(
      '${PluginRepository.installedPath}/plugin-1',
      (server) => server.reply(204, null),
    );

    await tester.pumpWidget(
      scope(_materialApp(const ManagePluginsPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weather'), findsOneWidget);

    await tester.tap(find.text('Uninstall'));
    await tester.pumpAndSettle();

    expect(find.text('Uninstall plugin?'), findsOneWidget);
    await tester.tap(find.text('Uninstall').last);
    await tester.pumpAndSettle();

    expect(find.text('Weather'), findsNothing);
    final deleteMatchers = adapter.history.where(
      (h) => h.request.method?.name == 'DELETE',
    );
    expect(deleteMatchers, isNotEmpty);
    expect(
      deleteMatchers.last.request.route,
      '${PluginRepository.installedPath}/plugin-1',
    );
  });

  testWidgets('setup badge navigates to PluginSetupPage', (WidgetTester tester) async {
    mockCatalog();
    final installed = nestedInstalledPlugin(
      id: 'plugin-calendar',
      slug: 'google-calendar',
      name: 'Google Calendar',
      setupStatus: 'not_started',
    );
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.reply(200, {
        'success': true,
        'data': [installed],
      }),
    );

    appRouter.go(AppRoute.managePlugins.path);

    await tester.pumpWidget(scope(_routerApp()));
    await tester.pumpAndSettle();

    expect(find.text('Setup needed'), findsOneWidget);
    expect(
      find.text('Some plugins need setup before they can be used.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Setup needed'));
    await tester.pumpAndSettle();

    expect(find.text('Plugin Setup'), findsOneWidget);
    expect(find.byKey(const ValueKey('connect_google_account')), findsOneWidget);
    expect(find.text('Connect Google Account'), findsOneWidget);
  });

  testWidgets('toggle enable calls PATCH', (WidgetTester tester) async {
    mockCatalog();
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.reply(200, {
        'success': true,
        'data': [installedWeather],
      }),
    );
    adapter.onPatch(
      '${PluginRepository.installedPath}/plugin-1',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          ...installedWeather,
          'enabled': false,
        },
      }),
      data: {'enabled': false},
    );

    await tester.pumpWidget(
      scope(_materialApp(const ManagePluginsPage())),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(const ValueKey('plugin_enabled_plugin-1'));
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final patchMatchers = adapter.history.where(
      (h) => h.request.method?.name == 'PATCH',
    );
    expect(patchMatchers, isNotEmpty);
    expect(
      patchMatchers.last.request.route,
      '${PluginRepository.installedPath}/plugin-1',
    );
    expect(patchMatchers.last.request.data, {'enabled': false});
    expect(tester.widget<Switch>(switchFinder).value, isFalse);
  });
}

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}
