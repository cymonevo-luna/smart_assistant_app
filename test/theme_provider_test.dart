import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_assistant_app/core/di/locator.dart';
import 'package:smart_assistant_app/core/storage/preferences_service.dart';
import 'package:smart_assistant_app/core/theme/app_palette.dart';
import 'package:smart_assistant_app/core/theme/app_theme.dart';
import 'package:smart_assistant_app/core/theme/theme_provider.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    locator.registerSingleton<PreferencesService>(
      await PreferencesService.create(),
    );
  });

  test('fresh install defaults to Jarvis accent and dark mode', () {
    final container = ProviderContainer();
    final state = container.read(themeProvider);

    expect(state.accent, AppAccent.jarvis);
    expect(state.mode, ThemeMode.dark);
    container.dispose();
  });

  test('Jarvis dark theme uses red primary and gold secondary', () {
    final scheme = AppTheme.colorScheme(AppAccent.jarvis, Brightness.dark);

    expect(scheme.brightness, Brightness.dark);
    expect(scheme.primary, AppAccent.jarvis.seed);
    expect(scheme.secondary, AppPalette.jarvisGold);
    expect(scheme.tertiary, AppPalette.jarvisGold);
    expect(scheme.surface, AppPalette.darkSurface);
  });

  test('theme mode toggle persists across notifier rebuild', () async {
    final container = ProviderContainer();
    final notifier = container.read(themeProvider.notifier);

    notifier.setThemeMode(ThemeMode.light);
    expect(container.read(themeProvider).mode, ThemeMode.light);

    final prefs = locator<PreferencesService>();
    expect(prefs.getString(PrefKeys.themeMode), ThemeMode.light.name);

    await locator.reset();
    locator.registerSingleton<PreferencesService>(
      await PreferencesService.create(),
    );

    final restored = ProviderContainer().read(themeProvider);
    expect(restored.mode, ThemeMode.light);
  });

  test('accent selection persists across notifier rebuild', () async {
    final container = ProviderContainer();
    final notifier = container.read(themeProvider.notifier);

    notifier.setAccent(AppAccent.teal);
    expect(container.read(themeProvider).accent, AppAccent.teal);

    final prefs = locator<PreferencesService>();
    expect(prefs.getString(PrefKeys.themeAccent), AppAccent.teal.name);

    await locator.reset();
    locator.registerSingleton<PreferencesService>(
      await PreferencesService.create(),
    );

    final restored = ProviderContainer().read(themeProvider);
    expect(restored.accent, AppAccent.teal);
  });

  test('theme mode changes update color scheme brightness immediately', () {
    final container = ProviderContainer();
    final notifier = container.read(themeProvider.notifier);

    notifier.setThemeMode(ThemeMode.light);
    final lightAccent = container.read(themeProvider).accent;
    expect(
      AppTheme.colorScheme(lightAccent, Brightness.light).brightness,
      Brightness.light,
    );

    notifier.setThemeMode(ThemeMode.dark);
    final darkAccent = container.read(themeProvider).accent;
    expect(
      AppTheme.colorScheme(darkAccent, Brightness.dark).brightness,
      Brightness.dark,
    );
    container.dispose();
  });
}
