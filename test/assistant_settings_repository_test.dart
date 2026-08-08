import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/network/api_client.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/features/assistant/data/assistant_settings_repository.dart';

import 'helpers/auth_harness.dart';

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
      ..registerSingleton<ApiClient>(mocked.client)
      ..registerSingleton<AssistantSettingsRepository>(
        AssistantSettingsRepository(mocked.client, prefs),
      );
  });

  test('cached settings persist across repository reads', () async {
    adapter.onPut(
      '/api/v1/assistant/settings',
      (server) => server.reply(200, {
        'success': true,
        'data': {
          'wake_word': 'Friday',
          'active_listening_enabled': true,
        },
      }),
      data: {
        'wake_word': 'Friday',
        'active_listening_enabled': true,
      },
    );

    final repo = locator<AssistantSettingsRepository>();
    await repo.updateSettings(
      wakeWord: 'Friday',
      activeListeningEnabled: true,
    );

    final cached = repo.readCachedOrDefaults();
    expect(cached.wakeWord, 'Friday');
    expect(cached.activeListeningEnabled, isTrue);

    final relaunched = AssistantSettingsRepository(
      locator<ApiClient>(),
      locator<PreferencesService>(),
    );
    final afterRelaunch = relaunched.readCachedOrDefaults();
    expect(afterRelaunch.wakeWord, 'Friday');
    expect(afterRelaunch.activeListeningEnabled, isTrue);
  });

  test('readCachedOrDefaults uses Jarvis defaults when cache is empty', () {
    final repo = locator<AssistantSettingsRepository>();
    final defaults = repo.readCachedOrDefaults();
    expect(defaults.wakeWord, AssistantSettingsRepository.defaultWakeWord);
    expect(defaults.activeListeningEnabled, isFalse);
  });
}
