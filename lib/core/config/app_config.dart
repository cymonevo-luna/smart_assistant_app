import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment / build configuration loaded from the `.env` file.
///
/// Call [AppConfig.load] once at startup (before reading any values). Use
/// different `.env` contents per environment (dev/staging/prod).
abstract final class AppConfig {
  /// Loads the `.env` asset. Safe to call once at startup.
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get apiBaseUrl =>
      dotenv.maybeGet('API_BASE_URL') ?? 'https://api.example.com';

  static String get sentryDsn => dotenv.maybeGet('SENTRY_DSN') ?? '';

  /// AccessKey from https://console.picovoice.ai/ used to run the on-device
  /// Porcupine wake-word engine. Empty disables wake-word detection.
  ///
  /// Guards on [DotEnv.isInitialized] (unlike the other getters here) because
  /// this is read from a background isolate (see
  /// ActiveListeningTaskHandler) as well as from widget tests that never
  /// call [load].
  static String get picovoiceAccessKey => dotenv.isInitialized
      ? (dotenv.maybeGet('PICOVOICE_ACCESS_KEY') ?? '')
      : '';

  /// Which on-device wake-word engine to run. Unknown/blank values fall back
  /// to [WakeWordEngineKind.picovoice]. Build-time choice (not a user-facing
  /// setting) — neither engine works without its own vendor credentials.
  static WakeWordEngineKind get wakeWordEngine {
    final value = dotenv.isInitialized ? dotenv.maybeGet('WAKE_WORD_ENGINE') : null;
    return switch (value) {
      'davoice' => WakeWordEngineKind.davoice,
      _ => WakeWordEngineKind.picovoice,
    };
  }

  /// License key from DaVoice (https://davoice.io/) for the flutter_wake_word
  /// engine. Empty disables it even if selected via [wakeWordEngine].
  static String get daVoiceLicenseKey => dotenv.isInitialized
      ? (dotenv.maybeGet('DAVOICE_LICENSE_KEY') ?? '')
      : '';

  /// Detection confidence threshold (0-1) passed to flutter_wake_word.
  static double get daVoiceWakeWordThreshold {
    final raw = dotenv.isInitialized ? dotenv.maybeGet('DAVOICE_WAKE_WORD_THRESHOLD') : null;
    return double.tryParse(raw ?? '') ?? 0.7;
  }

  /// Whether the currently selected [wakeWordEngine] has the config it needs
  /// to actually start (vendor credentials present).
  static bool get wakeWordEngineConfigured => switch (wakeWordEngine) {
        WakeWordEngineKind.picovoice => picovoiceAccessKey.isNotEmpty,
        WakeWordEngineKind.davoice => daVoiceLicenseKey.isNotEmpty,
      };

  static AppEnv get environment {
    return switch (dotenv.maybeGet('APP_ENV')) {
      'prod' => AppEnv.prod,
      'staging' => AppEnv.staging,
      _ => AppEnv.dev,
    };
  }

  /// Whether crash/error reporting should be active.
  static bool get sentryEnabled => sentryDsn.isNotEmpty;
}

enum AppEnv { dev, staging, prod }

enum WakeWordEngineKind { picovoice, davoice }
