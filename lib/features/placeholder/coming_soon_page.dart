import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/widgets.dart';

/// Lightweight stand-in for tabs that don't have a real screen yet (Tasks,
/// Calendar, Messages). Swap with the real feature page when it's built.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(title: AppText.heading(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconBadge(icon: icon, color: context.colors.primary, size: 64,
                iconSize: 32, circular: true),
            const VGap(AppSpacing.md),
            AppText.title(title),
            const VGap(AppSpacing.xxs),
            AppText.caption('Coming soon', color: tokens.textSecondary),
          ],
        ),
      ),
    );
  }
}
