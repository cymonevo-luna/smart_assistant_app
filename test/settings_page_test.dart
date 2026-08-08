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
import 'package:smart_assistant_app/features/assistant/assistant_settings_provider.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_settings_repository.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_settings.dart';
import 'package:smart_assistant_app/features/auth/auth_controller.dart';
import 'package:smart_assistant_app/features/plugins/data/plugin_repository.dart';
import 'package:smart_assistant_app/features/settings/settings_page.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import 'helpers/auth_harness.dart';
import 'helpers/plugin_test_data.dart';

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

class _AuthenticatedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
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
      ..registerSingleton<AssistantSettingsRepository>(
        AssistantSettingsRepository(mocked.client, prefs),
      );
  });

  testWidgets('settings section renders controls', (WidgetTester tester) async {
    const defaults = AssistantSettings(
      wakeWord: 'Jarvis',
      activeListeningEnabled: false,
      locationReminderThresholdMeters: 100,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantSettingsProvider.overrideWith(
            () => _FakeAssistantSettingsNotifier(defaults),
          ),
        ],
        child: _materialApp(const SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jarvis'), findsOneWidget);
    final switchFinder = find.byKey(const ValueKey('assistant_active_listening'));
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(find.text('100 m'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('location_reminder_threshold_slider')),
      findsOneWidget,
    );
  });

  testWidgets('settings page renders threshold control', (WidgetTester tester) async {
    const defaults = AssistantSettings(
      wakeWord: 'Jarvis',
      activeListeningEnabled: false,
      locationReminderThresholdMeters: 100,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantSettingsProvider.overrideWith(
            () => _FakeAssistantSettingsNotifier(defaults),
          ),
        ],
        child: _materialApp(const SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('100 m'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('location_reminder_threshold_slider')),
      findsOneWidget,
    );
  });

  testWidgets('threshold change calls API', (WidgetTester tester) async {
    adapter
      ..onGet(
        '/api/v1/assistant/settings',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'wake_word': 'Jarvis',
            'active_listening_enabled': false,
            'location_reminder_threshold_meters': 100,
          },
        }),
      )
      ..onPut(
        '/api/v1/assistant/settings',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'wake_word': 'Jarvis',
            'active_listening_enabled': false,
            'location_reminder_threshold_meters': 200,
          },
        }),
        data: {
          'wake_word': 'Jarvis',
          'active_listening_enabled': false,
          'location_reminder_threshold_meters': 200,
        },
      );

    await tester.pumpWidget(
      ProviderScope(child: _materialApp(const SettingsPage())),
    );
    await tester.pumpAndSettle();

    final sliderFinder =
        find.byKey(const ValueKey('location_reminder_threshold_slider'));
    await tester.scrollUntilVisible(
      sliderFinder,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final sliderBox = tester.getRect(sliderFinder);
    final start = Offset(
      sliderBox.left + sliderBox.width * 0.18,
      sliderBox.center.dy,
    );
    final end = Offset(
      sliderBox.left + sliderBox.width * 0.39,
      sliderBox.center.dy,
    );
    await tester.dragFrom(start, end - start);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    final putMatchers = adapter.history.where(
      (h) => h.request.method?.name == 'PUT',
    );
    expect(putMatchers, isNotEmpty);
    final putRequest = putMatchers.last.request;
    expect(putRequest.route, '/api/v1/assistant/settings');
    expect(putRequest.data, {
      'wake_word': 'Jarvis',
      'active_listening_enabled': false,
      'location_reminder_threshold_meters': 200,
    });
  });

  testWidgets('update settings calls API', (WidgetTester tester) async {
    adapter
      ..onGet(
        '/api/v1/assistant/settings',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'wake_word': 'Jarvis',
            'active_listening_enabled': false,
            'location_reminder_threshold_meters': 100,
          },
        }),
      )
      ..onPut(
        '/api/v1/assistant/settings',
        (server) => server.reply(200, {
          'success': true,
          'data': {
            'wake_word': 'Jarvis',
            'active_listening_enabled': true,
            'location_reminder_threshold_meters': 100,
          },
        }),
        data: {
          'wake_word': 'Jarvis',
          'active_listening_enabled': true,
          'location_reminder_threshold_meters': 100,
        },
      );

    await tester.pumpWidget(
      ProviderScope(child: _materialApp(const SettingsPage())),
    );
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(const ValueKey('assistant_active_listening'));
    await tester.scrollUntilVisible(
      switchFinder,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final putMatchers = adapter.history.where(
      (h) => h.request.method?.name == 'PUT',
    );
    expect(putMatchers, isNotEmpty);
    final putRequest = putMatchers.last.request;
    expect(putRequest.route, '/api/v1/assistant/settings');
    expect(putRequest.data, {
      'wake_word': 'Jarvis',
      'active_listening_enabled': true,
      'location_reminder_threshold_meters': 100,
    });
  });

  testWidgets('wake word field is fixed to Jarvis (not yet editable)', (
    WidgetTester tester,
  ) async {
    // Local wake-word detection (Porcupine) only supports its built-in
    // "Jarvis" keyword right now — see wake_word_engine.dart. The field is
    // disabled rather than removed so it's ready once custom wake words
    // (per-phrase trained models) are supported.
    adapter.onGet(
      '/api/v1/assistant/settings',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'wake_word': 'Jarvis',
          'active_listening_enabled': false,
          'location_reminder_threshold_meters': 100,
        },
      }),
    );

    await tester.pumpWidget(
      ProviderScope(child: _materialApp(const SettingsPage())),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.enabled, isFalse);
  });

  testWidgets('settings navigates to Manage Plugins', (WidgetTester tester) async {
    const defaults = AssistantSettings(
      wakeWord: 'Jarvis',
      activeListeningEnabled: false,
      locationReminderThresholdMeters: 100,
    );

    adapter
      ..onGet(
        PluginRepository.catalogPath,
        (server) => server.reply(200, {
          'success': true,
          'data': [catalogGoogleCalendarMeet],
          'meta': {'page': 1, 'per_page': 20, 'total': 1},
        }),
      )
      ..onGet(
        PluginRepository.installedPath,
        (server) => server.reply(200, {
          'success': true,
          'data': <Map<String, dynamic>>[],
        }),
      );

    locator.registerSingleton<PluginRepository>(
      PluginRepository(locator<ApiClient>()),
    );

    appRouter.go(AppRoute.settings.path);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_AuthenticatedAuthController.new),
          assistantSettingsProvider.overrideWith(
            () => _FakeAssistantSettingsNotifier(defaults),
          ),
        ],
        child: _routerApp(),
      ),
    );
    await tester.pumpAndSettle();

    final pluginsTile = find.text('Plugins');
    await tester.scrollUntilVisible(
      pluginsTile,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(pluginsTile);
    await tester.pumpAndSettle();

    expect(find.text('Manage Plugins'), findsOneWidget);
  });
}

class _FakeAssistantSettingsNotifier extends AssistantSettingsNotifier {
  _FakeAssistantSettingsNotifier(this._settings);

  final AssistantSettings _settings;

  @override
  Future<AssistantSettings> build() async => _settings;
}
