import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/locator.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment config (.env) and register services.
  await AppConfig.load();
  await setupLocator();

  // Each app sets its brand color here; users can still change it at runtime.
  final app = ProviderScope(
    overrides: [
      defaultAccentProvider.overrideWithValue(AppAccent.blue),
    ],
    child: const App(),
  );

  // Wrap with Sentry only when a DSN is configured.
  if (AppConfig.sentryEnabled) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.environment.name;
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(SentryWidget(child: app)),
    );
  } else {
    runApp(app);
  }
}
