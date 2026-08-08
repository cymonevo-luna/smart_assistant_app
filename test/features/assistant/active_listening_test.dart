import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/assistant/active_listening_controller.dart';
import 'package:smart_assistant_app/features/assistant/assistant_settings_provider.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_repository.dart';
import 'package:smart_assistant_app/features/assistant/models/assistant_settings.dart';
import 'package:smart_assistant_app/features/assistant/pages/assistant_page.dart';
import 'package:smart_assistant_app/features/assistant/services/foreground_listening_service.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

import '../../helpers/auth_harness.dart';

// Active listening now runs on Picovoice Porcupine (see
// wake_word_engine.dart) instead of a continuous speech-to-text transcript
// match. Porcupine is a real native plugin (and, on Android, runs inside a
// separate flutter_foreground_task isolate), so it can't be meaningfully
// faked from a widget test — these tests cover the controller's gating
// logic (enabled/disabled, missing configuration) rather than an actual
// wake-word-to-API round trip. Verify that end-to-end on a device once
// PICOVOICE_ACCESS_KEY is configured.

class FakeForegroundListeningService implements ForegroundListeningService {
  bool running = false;

  @override
  bool get isRunning => running;

  @override
  Future<bool> start({required String notificationText}) async {
    running = true;
    return true;
  }

  @override
  Future<void> stop() async {
    running = false;
  }
}

class _FakeAssistantSettingsNotifier extends AssistantSettingsNotifier {
  _FakeAssistantSettingsNotifier(this._settings);

  final AssistantSettings _settings;

  @override
  Future<AssistantSettings> build() async => _settings;
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

class _ActiveListeningHarness extends ConsumerWidget {
  const _ActiveListeningHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(activeListeningControllerProvider);
    return const AssistantPage();
  }
}

void main() {
  late DioAdapter adapter;
  late FakeForegroundListeningService foregroundService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    final prefs = await PreferencesService.create();
    final mocked = buildMockedApiClient();
    adapter = mocked.adapter;
    foregroundService = FakeForegroundListeningService();

    locator
      ..registerSingleton<PreferencesService>(prefs)
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<AssistantRepository>(
        AssistantRepository(mocked.client),
      );

    adapter.onPost(
      '/api/v1/assistant/sessions',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'session_id': 'sess-1',
          'session_status': 'active',
        },
      }),
    );
  });

  Future<void> pumpHarness(
    WidgetTester tester, {
    required AssistantSettings settings,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantSettingsProvider.overrideWith(
            () => _FakeAssistantSettingsNotifier(settings),
          ),
          foregroundListeningServiceProvider.overrideWithValue(
            foregroundService,
          ),
        ],
        child: _materialApp(const _ActiveListeningHarness()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('active listening off never starts the foreground service', (
    tester,
  ) async {
    await pumpHarness(
      tester,
      settings: const AssistantSettings(
        wakeWord: 'Jarvis',
        activeListeningEnabled: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(foregroundService.running, isFalse);
    expect(
      find.byKey(const ValueKey('assistant_active_listening_chip')),
      findsNothing,
    );
  });

  testWidgets(
    'active listening on without a Picovoice access key stays idle',
    (tester) async {
      // No PICOVOICE_ACCESS_KEY is loaded in the test environment, so the
      // controller should refuse to start the wake-word engine rather than
      // spin up a foreground service with nothing to run.
      await pumpHarness(
        tester,
        settings: const AssistantSettings(
          wakeWord: 'Jarvis',
          activeListeningEnabled: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(foregroundService.running, isFalse);
      expect(
        find.byKey(const ValueKey('assistant_active_listening_chip')),
        findsNothing,
      );
    },
  );
}
