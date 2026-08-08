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
