import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Builds the full [ThemeData] from a single [AppAccent] seed.
///
/// Everything (colors, components, typography) is derived here, so changing the
/// accent regenerates a complete, consistent theme — the key to making each app
/// on this template feel distinct while sharing one design system.
abstract final class AppTheme {
  static ThemeData light(AppAccent accent) =>
      _build(accent, Brightness.light, AppTokens.light);

  static ThemeData dark(AppAccent accent) =>
      _build(accent, Brightness.dark, AppTokens.dark);

  static ThemeData _build(
    AppAccent accent,
    Brightness brightness,
    AppTokens tokens,
  ) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent.seed,
      brightness: brightness,
    ).copyWith(
      surface: isLight ? AppPalette.lightSurface : AppPalette.darkSurface,
    );

    final scaffoldBg =
        isLight ? AppPalette.lightScaffold : AppPalette.darkScaffold;
    final textTheme =
        AppTypography.textTheme(tokens.textPrimary, tokens.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      extensions: [tokens],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg,
        foregroundColor: tokens.textPrimary,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: tokens.border),
          foregroundColor: tokens.textPrimary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFF1F3F6) : AppPalette.darkScaffold,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: tokens.danger, width: 1.5),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: tokens.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primary.withValues(alpha: 0.1),
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.primary),
        side: BorderSide.none,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
    );
  }
}
