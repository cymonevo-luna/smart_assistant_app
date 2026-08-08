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
import 'package:smart_assistant_app/features/assistant/assistant_settings_provider.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_settings_repository.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_settings.dart';
import 'package:smart_assistant_app/features/settings/settings_page.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import 'helpers/auth_harness.dart';

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
      ..registerSingleton<AssistantSettingsRepository>(
        AssistantSettingsRepository(mocked.client, prefs),
      );
  });

  testWidgets('settings section renders controls', (WidgetTester tester) async {
    const defaults = AssistantSettings(
      wakeWord: 'Jarvis',
      activeListeningEnabled: false,
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
          },
        }),
        data: {
          'wake_word': 'Jarvis',
          'active_listening_enabled': true,
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
}

class _FakeAssistantSettingsNotifier extends AssistantSettingsNotifier {
  _FakeAssistantSettingsNotifier(this._settings);

  final AssistantSettings _settings;

  @override
  Future<AssistantSettings> build() async => _settings;
}
