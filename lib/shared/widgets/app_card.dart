import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';

/// The base surface used everywhere in the mockup: white, rounded, soft shadow,
/// no hard border. Tap support is optional via [onTap].
///
/// ```dart
/// AppCard(child: ...)
/// AppCard(onTap: () {}, padding: EdgeInsets.all(20), child: ...)
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.color,
    this.borderRadius = AppRadius.brLg,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius borderRadius;

  /// Whether to render the soft drop shadow.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? context.colors.surface,
        borderRadius: borderRadius,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: tokens.cardShadow,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
