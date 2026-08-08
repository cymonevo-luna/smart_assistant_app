import 'package:flutter/material.dart';

/// Circular/rounded icon chip with a tinted background — the colored icon
/// badges seen on the Overview stats and list rows in the mockup.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize = 20,
    this.circular = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius:
            circular ? null : BorderRadius.circular(size * 0.3),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
