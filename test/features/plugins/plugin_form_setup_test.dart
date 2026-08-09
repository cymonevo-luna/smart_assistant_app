import 'package:flutter/material.dart';
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
import 'package:smart_assistant_app/features/plugins/pages/plugin_setup_page.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_auth_url_launcher.dart';
import 'package:smart_assistant_app/features/plugins/services/plugin_setup_deep_link_service.dart';
import '../../helpers/auth_harness.dart';
import '../../helpers/material_test_harness.dart';
import '../../helpers/plugin_test_data.dart';

void main() {
  late DioAdapter adapter;
  late FakeSecureStorage secureStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    secureStorage = FakeSecureStorage();
    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<SecureStorageService>(secureStorage)
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<PluginRepository>(PluginRepository(mocked.client))
      ..registerSingleton<PluginAuthUrlLauncher>(_NoopUrlLauncher())
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

  void mockStatus({
    required String installId,
    required String setupStatus,
    String? setupError,
    List<String> connectedToolkits = const [],
    int connectedAccountsCount = 0,
  }) {
    adapter.onGet(
      '${PluginRepository.setupPath(installId)}/status',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'setup_status': setupStatus,
          'setup_error': ?setupError,
          'connected_toolkits': connectedToolkits,
          'connected_accounts_count': connectedAccountsCount,
        },
      }),
    );
  }

  void mockCatalog() {
    adapter.onGet(
      PluginRepository.catalogPath,
      (server) => server.reply(200, {
        'success': true,
        'data': [catalogComposioAi],
        'meta': {'page': 1, 'per_page': 20, 'total': 1},
      }),
    );
  }

  void mockInstalled(List<Map<String, dynamic>> plugins) {
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.reply(200, {
        'success': true,
        'data': plugins,
      }),
    );
  }

  void mockInstalledNotStarted(String installId) {
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.reply(200, (_) => {
            'success': true,
            'data': [nestedInstalledComposioAi(id: installId)],
          }),
    );
  }

  void mockInstalledCompleted(String installId) {
    adapter.onGet(
      PluginRepository.installedPath,
      (server) => server.reply(200, (_) => {
            'success': true,
            'data': [
              nestedInstalledComposioAi(
                id: installId,
                setupStatus: 'completed',
              ),
            ],
          }),
    );
  }

  testWidgets('submit valid API key completes setup', (WidgetTester tester) async {
    const installId = 'install-composio-ai';
    const validKey = 'mock-valid-composio-key';
    mockCatalog();
    mockInstalledNotStarted(installId);
    mockStatus(installId: installId, setupStatus: 'not_started');
    adapter.onPost(
      PluginRepository.setupPath(installId),
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'setup_status': 'completed',
          'connected_toolkits': ['github', 'gmail'],
          'connected_accounts_count': 2,
        },
      }),
      data: {'api_key': validKey},
    );

    appRouter.goNamed(
      AppRoute.composioAiSetup.name,
      pathParameters: {'id': installId},
    );

    await tester.pumpWidget(scope(shaderSafeRouterApp(routerConfig: appRouter)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('composio_api_key_field')),
      validKey,
    );
    await tester.tap(find.byKey(const ValueKey('save_composio_api_key')));
    await tester.pumpAndSettle();

    final setupPosts = adapter.history.where(
      (h) =>
          h.request.method?.name == 'POST' &&
          h.request.route == PluginRepository.setupPath(installId),
    );
    expect(setupPosts, isNotEmpty);
    expect(setupPosts.last.request.data, {'api_key': validKey});

    expect(find.text('Setup complete! This plugin is ready to use.'), findsOneWidget);
    expect(find.text('github'), findsOneWidget);
    expect(find.text('gmail'), findsOneWidget);
    expect(find.byKey(const ValueKey('composio_connected_toolkits')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('composio_setup_done')));
    await tester.pumpAndSettle();

    expect(find.byType(PluginSetupPage), findsNothing);
    expect(find.text('Manage Plugins'), findsOneWidget);
  });

  testWidgets('invalid API key shows inline error', (WidgetTester tester) async {
    const installId = 'install-composio-ai';
    const invalidKey = 'invalid-key';

    mockCatalog();
    mockInstalled([
      nestedInstalledComposioAi(id: installId),
    ]);
    mockStatus(installId: installId, setupStatus: 'not_started');
    adapter.onPost(
      PluginRepository.setupPath(installId),
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'setup_status': 'failed',
          'setup_error': 'Invalid Composio API key',
        },
      }),
      data: {'api_key': invalidKey},
    );

    appRouter.goNamed(
      AppRoute.composioAiSetup.name,
      pathParameters: {'id': installId},
    );

    await tester.pumpWidget(scope(shaderSafeRouterApp(routerConfig: appRouter)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('composio_api_key_field')),
      invalidKey,
    );
    await tester.tap(find.byKey(const ValueKey('save_composio_api_key')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid Composio API key'), findsOneWidget);
    expect(find.byKey(const ValueKey('composio_api_key_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('save_composio_api_key')), findsOneWidget);
    expect(find.text('Setup needed'), findsNothing);
  });

  testWidgets('status endpoint on screen open shows completed state',
      (WidgetTester tester) async {
    const installId = 'install-composio-ai';

    mockCatalog();
    mockInstalledCompleted(installId);
    mockStatus(
      installId: installId,
      setupStatus: 'completed',
      connectedToolkits: ['github', 'slack'],
      connectedAccountsCount: 2,
    );

    appRouter.goNamed(
      AppRoute.composioAiSetup.name,
      pathParameters: {'id': installId},
    );

    await tester.pumpWidget(scope(shaderSafeRouterApp(routerConfig: appRouter)));
    await tester.pumpAndSettle();

    expect(find.text('Setup complete! This plugin is ready to use.'), findsOneWidget);
    expect(find.text('github'), findsOneWidget);
    expect(find.text('slack'), findsOneWidget);
    expect(find.byKey(const ValueKey('composio_api_key_field')), findsNothing);

    final statusGets = adapter.history.where(
      (h) =>
          h.request.method?.name == 'GET' &&
          h.request.route == '${PluginRepository.setupPath(installId)}/status',
    );
    expect(statusGets, isNotEmpty);
  });

  testWidgets('API key is not persisted locally after submit',
      (WidgetTester tester) async {
    const installId = 'install-composio-ai';
    const validKey = 'secret-composio-key-not-stored';

    mockCatalog();
    mockInstalled([
      nestedInstalledComposioAi(id: installId),
    ]);
    mockStatus(installId: installId, setupStatus: 'not_started');
    adapter.onPost(
      PluginRepository.setupPath(installId),
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'setup_status': 'completed',
          'connected_toolkits': ['github'],
          'connected_accounts_count': 1,
        },
      }),
      data: {'api_key': validKey},
    );

    appRouter.goNamed(
      AppRoute.composioAiSetup.name,
      pathParameters: {'id': installId},
    );

    await tester.pumpWidget(scope(shaderSafeRouterApp(routerConfig: appRouter)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('composio_api_key_field')),
      validKey,
    );
    await tester.tap(find.byKey(const ValueKey('save_composio_api_key')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final allPrefs = prefs.getKeys().map((key) => prefs.get(key)).join();
    final allSecure = secureStorage.store.values.join();

    expect(allPrefs.contains(validKey), isFalse);
    expect(allSecure.contains(validKey), isFalse);
    expect(secureStorage.store.keys.any((k) => k.contains('composio')), isFalse);
  });
}

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _NoopUrlLauncher implements PluginAuthUrlLauncher {
  @override
  Future<bool> launchAuthorizationUrl(String url) async => true;
}
