import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'app_card.dart';
import 'app_icon_badge.dart';
import 'app_text.dart';

/// A compact metric card (the "Overview" tiles: Total Tasks, Completed,
/// In Progress) with an icon badge, value, label and optional trend.
///
/// ```dart
/// AppStatCard(icon: Icons.list_alt, color: context.colors.primary,
///   value: '24', label: 'Total Tasks', trend: '+12%')
/// ```
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.trend,
    this.trendPositive = true,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? trend;
  final bool trendPositive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconBadge(icon: icon, color: color),
          const VGap(AppSpacing.sm),
          AppText(value, variant: AppTextVariant.headlineSmall),
          const VGap(AppSpacing.xxs),
          AppText.caption(label, maxLines: 1),
          if (trend != null) ...[
            const VGap(AppSpacing.xs),
            AppText(
              trend!,
              variant: AppTextVariant.labelMedium,
              color: trendPositive ? tokens.success : tokens.danger,
            ),
          ],
        ],
      ),
    );
  }
}
