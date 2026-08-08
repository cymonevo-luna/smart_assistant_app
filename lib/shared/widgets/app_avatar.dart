import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_text.dart';

/// Circular user avatar. Renders [imageUrl] when provided and falls back to the
/// user's initials over an accent gradient (works offline).
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 48,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      height: radius * 2,
      width: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, Colors.black, 0.25)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              errorBuilder: (_, _, _) => _initialsLabel(colors),
            )
          : _initialsLabel(colors),
    );
  }

  Widget _initialsLabel(ColorScheme colors) {
    return AppText(
      _initials,
      variant: AppTextVariant.headlineSmall,
      color: colors.onPrimary,
      weight: FontWeight.w700,
    );
  }
}
