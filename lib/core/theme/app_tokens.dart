import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Design tokens that aren't covered by Material's [ColorScheme].
///
/// Access from widgets via `context.tokens` (see extension below) so semantic
/// colors stay theme-aware (light/dark) without hardcoding.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.cardShadow,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color cardShadow;

  static const AppTokens light = AppTokens(
    success: AppPalette.success,
    warning: AppPalette.warning,
    danger: AppPalette.danger,
    info: AppPalette.info,
    textPrimary: AppPalette.lightTextPrimary,
    textSecondary: AppPalette.lightTextSecondary,
    border: AppPalette.lightBorder,
    cardShadow: Color(0x14101828),
  );

  static const AppTokens dark = AppTokens(
    success: AppPalette.success,
    warning: AppPalette.warning,
    danger: AppPalette.danger,
    info: AppPalette.info,
    textPrimary: AppPalette.darkTextPrimary,
    textSecondary: AppPalette.darkTextSecondary,
    border: AppPalette.darkBorder,
    cardShadow: Color(0x33000000),
  );

  @override
  AppTokens copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? cardShadow,
  }) {
    return AppTokens(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
    );
  }
}

/// Convenient access: `context.tokens.success`, `context.colors.primary`, etc.
extension AppThemeContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
}
