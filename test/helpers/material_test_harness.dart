import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_assistant_app/core/theme/app_palette.dart';
import 'package:smart_assistant_app/core/theme/app_theme.dart';
import 'package:smart_assistant_app/l10n/app_localizations.dart';

const _localizationDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

/// Production-like [AppTheme] with ink effects disabled for widget tests.
///
/// Material 3 defaults to [InkSparkle] when no [splashFactory] is set, which
/// loads `ink_sparkle.frag` at tap time and can crash the test binding.
ThemeData get shaderSafeTestTheme => AppTheme.light(AppAccent.jarvis).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );

/// [MaterialApp] wrapper for widget tests that tap primary buttons.
Widget shaderSafeMaterialApp({required Widget home}) {
  return MaterialApp(
    theme: shaderSafeTestTheme,
    localizationsDelegates: _localizationDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

/// [MaterialApp.router] wrapper for widget tests that tap primary buttons.
Widget shaderSafeRouterApp({required GoRouter routerConfig}) {
  return MaterialApp.router(
    theme: shaderSafeTestTheme,
    localizationsDelegates: _localizationDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: routerConfig,
  );
}
