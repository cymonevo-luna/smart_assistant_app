import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../auth/auth_controller.dart';
import 'data/assistant_settings_repository.dart';
import 'models/assistant_settings.dart';

class AssistantSettingsNotifier extends AsyncNotifier<AssistantSettings> {
  AssistantSettingsRepository get _repo =>
      locator<AssistantSettingsRepository>();

  @override
  Future<AssistantSettings> build() async {
    final auth = ref.watch(authProvider);
    if (auth.isAuthenticated) {
      try {
        return await _repo.fetchSettings();
      } catch (_) {
        return _repo.readCachedOrDefaults();
      }
    }
    return _repo.readCachedOrDefaults();
  }

  Future<bool> updateSettings({
    required String wakeWord,
    required bool activeListeningEnabled,
  }) async {
    final trimmed = wakeWord.trim();
    if (trimmed.isEmpty) return false;

    try {
      final updated = await _repo.updateSettings(
        wakeWord: trimmed,
        activeListeningEnabled: activeListeningEnabled,
      );
      state = AsyncData(updated);
      return true;
    } catch (_) {
      final cached = state.asData?.value ?? _repo.readCachedOrDefaults();
      state = AsyncData(cached);
      return false;
    }
  }

  Future<bool> setWakeWord(String wakeWord) {
    final current = state.requireValue;
    return updateSettings(
      wakeWord: wakeWord,
      activeListeningEnabled: current.activeListeningEnabled,
    );
  }

  Future<bool> setActiveListening(bool enabled) {
    final current = state.requireValue;
    return updateSettings(
      wakeWord: current.wakeWord,
      activeListeningEnabled: enabled,
    );
  }
}

final assistantSettingsProvider =
    AsyncNotifierProvider<AssistantSettingsNotifier, AssistantSettings>(
  AssistantSettingsNotifier.new,
);
