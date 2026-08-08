import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Text style variants mapped to the app's type scale.
enum AppTextVariant {
  displayLarge,
  displayMedium,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

/// A single, theme-aware text widget. Prefer this over raw [Text] so typography
/// stays consistent and colors come from the theme.
///
/// ```dart
/// AppText.title('Overview')
/// AppText.body('Have a great day!', muted: true)
/// AppText('Custom', variant: AppTextVariant.labelLarge, color: ...)
/// ```
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.muted = false,
    this.weight,
    this.align,
    this.maxLines,
    this.overflow,
  });

  const AppText.display(this.data,
      {super.key,
      this.color,
      this.muted = false,
      this.weight,
      this.align,
      this.maxLines,
      this.overflow})
      : variant = AppTextVariant.displayMedium;

  const AppText.heading(this.data,
      {super.key,
      this.color,
      this.muted = false,
      this.weight,
      this.align,
      this.maxLines,
      this.overflow})
      : variant = AppTextVariant.headlineSmall;

  const AppText.title(this.data,
      {super.key,
      this.color,
      this.muted = false,
      this.weight,
      this.align,
      this.maxLines,
      this.overflow})
      : variant = AppTextVariant.titleMedium;

  const AppText.body(this.data,
      {super.key,
      this.color,
      this.muted = false,
      this.weight,
      this.align,
      this.maxLines,
      this.overflow})
      : variant = AppTextVariant.bodyMedium;

  const AppText.label(this.data,
      {super.key,
      this.color,
      this.muted = false,
      this.weight,
      this.align,
      this.maxLines,
      this.overflow})
      : variant = AppTextVariant.labelLarge;

  const AppText.caption(this.data,
      {super.key,
      this.color,
      this.muted = true,
      this.weight,
      this.align,
      this.maxLines,
      this.overflow})
      : variant = AppTextVariant.bodySmall;

  final String data;
  final AppTextVariant variant;
  final Color? color;

  /// Uses the secondary/muted text color from the theme.
  final bool muted;
  final FontWeight? weight;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  TextStyle? _styleFor(TextTheme t) {
    switch (variant) {
      case AppTextVariant.displayLarge:
        return t.displayLarge;
      case AppTextVariant.displayMedium:
        return t.displayMedium;
      case AppTextVariant.headlineLarge:
        return t.headlineLarge;
      case AppTextVariant.headlineMedium:
        return t.headlineMedium;
      case AppTextVariant.headlineSmall:
        return t.headlineSmall;
      case AppTextVariant.titleLarge:
        return t.titleLarge;
      case AppTextVariant.titleMedium:
        return t.titleMedium;
      case AppTextVariant.titleSmall:
        return t.titleSmall;
      case AppTextVariant.bodyLarge:
        return t.bodyLarge;
      case AppTextVariant.bodyMedium:
        return t.bodyMedium;
      case AppTextVariant.bodySmall:
        return t.bodySmall;
      case AppTextVariant.labelLarge:
        return t.labelLarge;
      case AppTextVariant.labelMedium:
        return t.labelMedium;
      case AppTextVariant.labelSmall:
        return t.labelSmall;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _styleFor(context.textStyles)?.copyWith(
      color: color ?? (muted ? context.tokens.textSecondary : null),
      fontWeight: weight,
    );
    return Text(
      data,
      style: resolved,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }
}
