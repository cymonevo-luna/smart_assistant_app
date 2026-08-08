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
import 'package:smart_assistant_app/features/plugins/plugin_setup_deep_link_provider.dart';
import 'package:smart_assistant_app/features/plugins/plugin_setup_provider.dart';
import 'package:smart_assistant_app/features/plugins/plugins_provider.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_auth_url_launcher.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_setup_deep_link_service.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import '../../helpers/auth_harness.dart';
import '../../helpers/plugin_test_data.dart';

const _oauthSuccessUri =
    'smartassistant://plugin-setup/complete?status=success';
const _oauthFailedUri = 'smartassistant://plugin-setup/complete?status=failed';

final _installedCalendar = nestedInstalledPlugin(
  id: 'plugin-calendar',
  slug: 'google-calendar',
  name: 'Google Calendar',
  setupStatus: 'in_progress',
);

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _FakePluginAuthUrlLauncher implements PluginAuthUrlLauncher {
  @override
  Future<bool> launchAuthorizationUrl(String url) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioAdapter adapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    locator
      ..registerSingleton<PreferencesService>(
        await PreferencesService.create(),
      )
      ..registerSingleton<SecureStorageService>(FakeSecureStorage())
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<PluginRepository>(PluginRepository(mocked.client))
      ..registerSingleton<PluginAuthUrlLauncher>(_FakePluginAuthUrlLauncher())
      ..registerSingleton<PluginSetupDeepLinkService>(
        PluginSetupDeepLinkService(),
      );
    appRouter.go(AppRoute.managePlugins.path);
  });

  tearDown(() {
    appRouter.go(AppRoute.splash.path);
  });

  void mockPlugins({String setupStatus = 'in_progress'}) {
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
          {
            ...Map<String, dynamic>.from(_installedCalendar),
            'setup_status': setupStatus,
          },
        ],
      }),
    );
  }

  Widget routerApp({ProviderContainer? container}) {
    final app = MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );

    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: app,
      );
    }

    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _AuthenticatedAuthController()),
      ],
      child: app,
    );
  }

  testWidgets('GoRouter OAuth success URI does not show route error',
      (tester) async {
    mockPlugins();

    await tester.pumpWidget(routerApp());
    await tester.pumpAndSettle();

    appRouter.go(_oauthSuccessUri);
    await tester.pumpAndSettle();

    expect(find.textContaining('Route not found'), findsNothing);
    expect(find.byType(ManagePluginsPage), findsOneWidget);
    expect(find.text('Manage Plugins'), findsOneWidget);
    expect(appRouter.routeInformationProvider.value.uri.path, '/plugins');
  });

  testWidgets('GoRouter OAuth failed URI does not show route error',
      (tester) async {
    mockPlugins(setupStatus: 'failed');

    await tester.pumpWidget(routerApp());
    await tester.pumpAndSettle();

    appRouter.go(_oauthFailedUri);
    await tester.pumpAndSettle();

    expect(find.textContaining('Route not found'), findsNothing);
    expect(find.byType(ManagePluginsPage), findsOneWidget);
    expect(appRouter.routeInformationProvider.value.uri.path, '/plugins');
  });

  testWidgets('GoRouter OAuth success URI triggers setup completion',
      (tester) async {
    mockPlugins();
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
    container.read(pluginSetupDeepLinkNotifierProvider);

    await tester.pumpWidget(routerApp(container: container));
    await tester.pumpAndSettle();

    appRouter.go(_oauthSuccessUri);
    await tester.pumpAndSettle();

    expect(find.textContaining('Route not found'), findsNothing);
    expect(
      container.read(pluginSetupControllerProvider).phase,
      PluginSetupPhase.completed,
    );
    expect(statusPollCount, greaterThanOrEqualTo(1));
  });

  test('GoRouter OAuth success URI triggers setup completion in controller',
      () async {
    mockPlugins();
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
    container.read(pluginSetupDeepLinkNotifierProvider);
    await container.read(installedPluginsProvider.future);

    locator<PluginSetupDeepLinkService>().handleUri(
      Uri.parse(_oauthSuccessUri),
    );

    for (var attempt = 0; attempt < 40; attempt++) {
      final phase = container.read(pluginSetupControllerProvider).phase;
      if (phase == PluginSetupPhase.completed) break;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }

    expect(
      container.read(pluginSetupControllerProvider).phase,
      PluginSetupPhase.completed,
    );
    expect(statusPollCount, greaterThanOrEqualTo(1));
  });
}
