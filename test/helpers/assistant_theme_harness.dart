import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_assistant_app/core/theme/app_palette.dart';
import 'package:smart_assistant_app/core/theme/app_theme.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

/// Jarvis HUD dark theme used in assistant widget/golden tests.
ThemeData get jarvisDarkTheme => AppTheme.dark(AppAccent.jarvis);

Widget jarvisThemedApp(Widget home) {
  return MaterialApp(
    theme: jarvisDarkTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}
