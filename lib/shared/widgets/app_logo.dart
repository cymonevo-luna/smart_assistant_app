import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// The Jarvis brand mark: a rounded, accent-tinted square with arc-reactor
/// rings (outer gold, inner red glow), used on splash and auth screens.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final darkPrimary = Color.lerp(colors.primary, Colors.black, 0.35)!;

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, darkPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withValues(alpha: 0.35),
            blurRadius: size * 0.28,
            spreadRadius: size * 0.02,
          ),
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.18),
        child: CustomPaint(
          painter: _ArcReactorPainter(
            primary: colors.primary,
            secondary: colors.secondary,
            onPrimary: colors.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _ArcReactorPainter extends CustomPainter {
  const _ArcReactorPainter({
    required this.primary,
    required this.secondary,
    required this.onPrimary,
  });

  final Color primary;
  final Color secondary;
  final Color onPrimary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    _drawCoreGlow(canvas, center, maxRadius * 0.22);
    _drawRing(canvas, center, maxRadius * 0.34, primary, maxRadius * 0.045);
    _drawSegmentedRing(
      canvas,
      center,
      maxRadius * 0.58,
      secondary,
      maxRadius * 0.04,
      segments: 8,
      gapRadians: 0.28,
    );
    _drawSegmentedRing(
      canvas,
      center,
      maxRadius * 0.82,
      secondary,
      maxRadius * 0.035,
      segments: 12,
      gapRadians: 0.22,
    );
    _drawRadialTicks(canvas, center, maxRadius * 0.72, secondary, maxRadius * 0.06);
  }

  void _drawCoreGlow(Canvas canvas, Offset center, double radius) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          onPrimary.withValues(alpha: 0.95),
          primary.withValues(alpha: 0.85),
          primary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, glow);

    final core = Paint()..color = onPrimary.withValues(alpha: 0.9);
    canvas.drawCircle(center, radius * 0.45, core);
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  void _drawSegmentedRing(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double strokeWidth, {
    required int segments,
    required double gapRadians,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = (2 * math.pi / segments) - gapRadians;
    if (sweep <= 0) return;

    for (var i = 0; i < segments; i++) {
      final start = (i * 2 * math.pi / segments) - math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  void _drawRadialTicks(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double tickLength,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = tickLength * 0.18
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - tickLength),
        center.dy + math.sin(angle) * (radius - tickLength),
      );
      final outer = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcReactorPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.onPrimary != onPrimary;
  }
}
