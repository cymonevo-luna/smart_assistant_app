import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/locator.dart';
import '../storage/preferences_service.dart';

/// Languages the app ships translations for. Add a locale here and a matching
/// `lib/l10n/app_<code>.arb` file to support a new language.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('id'),
];

/// Holds the user's selected locale. `null` means "follow the system locale".
/// Persisted via [PreferencesService].
class LocaleNotifier extends Notifier<Locale?> {
  PreferencesService get _prefs => locator<PreferencesService>();

  @override
  Locale? build() {
    final code = _prefs.getString(PrefKeys.locale);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  void setLocale(Locale? locale) {
    state = locale;
    if (locale == null) {
      _prefs.remove(PrefKeys.locale);
    } else {
      _prefs.setString(PrefKeys.locale, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
