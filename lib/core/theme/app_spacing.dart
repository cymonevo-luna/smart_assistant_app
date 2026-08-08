import 'package:flutter/widgets.dart';

/// Consistent spacing scale used across the app.
///
/// Use these instead of hardcoding numbers so spacing stays uniform between
/// screens and easy to tune in one place.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Common ready-made gap widgets to keep layouts terse.
  static const SizedBox gapXxs = SizedBox(height: xxs, width: xxs);
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);

  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
}

/// Vertical gap helper. Usage: `VGap(AppSpacing.md)`.
class VGap extends StatelessWidget {
  const VGap(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

/// Horizontal gap helper. Usage: `HGap(AppSpacing.md)`.
class HGap extends StatelessWidget {
  const HGap(this.size, {super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size);
}
