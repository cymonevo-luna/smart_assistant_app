import '../../../core/network/api_client.dart';
import '../../../core/storage/preferences_service.dart';
import '../models/assistant_settings.dart';

class AssistantSettingsRepository {
  AssistantSettingsRepository(this._api, this._prefs);

  final ApiClient _api;
  final PreferencesService _prefs;

  static const defaultWakeWord = 'Jarvis';

  Future<AssistantSettings> fetchSettings() async {
    final settings = await _api.get<AssistantSettings>(
      '/api/v1/assistant/settings',
      decoder: (raw) => AssistantSettings.fromJson(_unwrap(raw)),
    );
    await _cache(settings);
    return settings;
  }

  Future<AssistantSettings> updateSettings({
    required String wakeWord,
    required bool activeListeningEnabled,
  }) async {
    final settings = await _api.put<AssistantSettings>(
      '/api/v1/assistant/settings',
      body: {
        'wake_word': wakeWord,
        'active_listening_enabled': activeListeningEnabled,
      },
      decoder: (raw) => AssistantSettings.fromJson(_unwrap(raw)),
    );
    await _cache(settings);
    return settings;
  }

  AssistantSettings readCachedOrDefaults() {
    final wakeWord = _prefs.getString(PrefKeys.assistantWakeWord) ??
        defaultWakeWord;
    final activeListening = _prefs.getBool(PrefKeys.assistantActiveListening) ??
        false;
    return AssistantSettings(
      wakeWord: wakeWord,
      activeListeningEnabled: activeListening,
    );
  }

  Future<void> _cache(AssistantSettings settings) async {
    await _prefs.setString(PrefKeys.assistantWakeWord, settings.wakeWord);
    await _prefs.setBool(
      PrefKeys.assistantActiveListening,
      settings.activeListeningEnabled,
    );
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = (raw as Map).cast<String, dynamic>();
    return (map['data'] as Map).cast<String, dynamic>();
  }
}
