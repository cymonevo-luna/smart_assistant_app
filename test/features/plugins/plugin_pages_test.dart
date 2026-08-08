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
import 'package:smart_assistant_app/features/plugins/pages/plugin_store_page.dart';
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
      ..registerSingleton<PluginRepository>(PluginRepository(mocked.client));
  });

  ProviderScope scope(Widget child) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _AuthenticatedAuthController()),
      ],
      child: child,
    );
  }

  void mockCatalog() {
    adapter.onGet(
      PluginRepository.catalogPath,
      (server) => server.reply(200, {
        'success': true,
        'data': catalogPlugins,
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
    adapter.onGet(
      PluginRepository.catalogPath,
      (server) => server.reply(200, {
        'success': true,
        'data': [catalogGoogleCalendarMeet],
      }),
    );
    mockInstalledEmpty();

    await tester.pumpWidget(
      scope(_materialApp(const PluginStorePage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Google Meet Scheduler'), findsOneWidget);
    expect(find.text('Install'), findsOneWidget);
  });

  testWidgets('install plugin success', (WidgetTester tester) async {
    mockCatalog();
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
        'data': installedWeather,
      }),
      data: {'plugin_slug': 'weather'},
    );

    await tester.pumpWidget(
      scope(_materialApp(const PluginStorePage())),
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
      scope(_materialApp(const MyPluginsPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weather'), findsOneWidget);
    expect(find.text('Get weather forecasts'), findsOneWidget);
  });

  testWidgets('uninstall with confirmation', (WidgetTester tester) async {
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
      scope(_materialApp(const MyPluginsPage())),
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

  testWidgets('toggle enable calls PATCH', (WidgetTester tester) async {
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
      scope(_materialApp(const MyPluginsPage())),
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
