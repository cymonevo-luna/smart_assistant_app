import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/locator.dart';
import '../storage/preferences_service.dart';
import 'app_palette.dart';

/// Immutable theme selection (accent color + light/dark mode).
@immutable
class ThemeState {
  const ThemeState({required this.accent, required this.mode});

  final AppAccent accent;
  final ThemeMode mode;

  ThemeState copyWith({AppAccent? accent, ThemeMode? mode}) =>
      ThemeState(accent: accent ?? this.accent, mode: mode ?? this.mode);
}

/// The fallback accent used when the user hasn't picked one yet. Override this
/// per app to set its brand color:
/// `ProviderScope(overrides: [defaultAccentProvider.overrideWithValue(AppAccent.purple)])`.
final defaultAccentProvider = Provider<AppAccent>((ref) => AppAccent.blue);

/// Owns the active theme. Restores from [PreferencesService] on creation and
/// persists every change, so selections survive restarts. Changes are applied
/// app-wide instantly via Riverpod.
class ThemeNotifier extends Notifier<ThemeState> {
  PreferencesService get _prefs => locator<PreferencesService>();

  @override
  ThemeState build() {
    final accent = _prefs.containsKey(PrefKeys.themeAccent)
        ? AppAccent.fromName(_prefs.getString(PrefKeys.themeAccent))
        : ref.read(defaultAccentProvider);
    return ThemeState(
      accent: accent,
      mode: _modeFromName(_prefs.getString(PrefKeys.themeMode)),
    );
  }

  void setAccent(AppAccent accent) {
    if (state.accent == accent) return;
    state = state.copyWith(accent: accent);
    _prefs.setString(PrefKeys.themeAccent, accent.name);
  }

  void setThemeMode(ThemeMode mode) {
    if (state.mode == mode) return;
    state = state.copyWith(mode: mode);
    _prefs.setString(PrefKeys.themeMode, mode.name);
  }

  void toggleBrightness() {
    setThemeMode(
      state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  static ThemeMode _modeFromName(String? name) => ThemeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => ThemeMode.system,
      );
}

/// Watch with `ref.watch(themeProvider)`; mutate with
/// `ref.read(themeProvider.notifier)`.
final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
