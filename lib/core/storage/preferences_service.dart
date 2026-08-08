import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper around [SharedPreferences] for simple, non-sensitive
/// key/value storage (settings, flags, cached primitives).
///
/// Resolve it from the service locator: `locator<PreferencesService>()`.
/// Created asynchronously at startup via [PreferencesService.create].
///
/// Note: do NOT store secrets here (tokens, passwords) — use
/// [SecureStorageService] for those.
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  /// Builds the service with an initialized [SharedPreferences].
  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // --- Readers -------------------------------------------------------------
  String? getString(String key) => _prefs.getString(key);
  int? getInt(String key) => _prefs.getInt(key);
  double? getDouble(String key) => _prefs.getDouble(key);
  bool? getBool(String key) => _prefs.getBool(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  // --- Writers -------------------------------------------------------------
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // --- Utilities -----------------------------------------------------------
  bool containsKey(String key) => _prefs.containsKey(key);
  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();
}

/// Central registry of preference keys to avoid typos and collisions.
abstract final class PrefKeys {
  static const String themeAccent = 'theme_accent';
  static const String themeMode = 'theme_mode';
  static const String onboardingDone = 'onboarding_done';
  static const String locale = 'locale';
}
