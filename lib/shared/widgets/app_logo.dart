import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// The brand mark: a rounded, accent-tinted square with a stacked-layers glyph,
/// matching the logo used across the splash and auth screens in the mockup.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, Colors.black, 0.2)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(
        Icons.layers_rounded,
        color: colors.onPrimary,
        size: size * 0.5,
      ),
    );
  }
}
