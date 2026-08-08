import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography for the app, built on a single Google Font so every app on this
/// template has a consistent, modern type scale.
///
/// Swap [fontFamily] in one place to rebrand the whole app's text.
abstract final class AppTypography {
  /// Change this to use a different Google Font across the app.
  static TextTheme textTheme(Color textColor, Color mutedColor) {
    final base = GoogleFonts.interTextTheme();
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w700),
          displayMedium:
              base.displayMedium?.copyWith(fontWeight: FontWeight.w700),
          headlineLarge:
              base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
          headlineMedium:
              base.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          headlineSmall:
              base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
          bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: textColor, displayColor: textColor);
  }
}
