import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'app_icon_badge.dart';
import 'app_text.dart';

/// List row used across Profile / Settings: leading icon badge, title, optional
/// subtitle, and a trailing value/chevron.
///
/// ```dart
/// AppListTile(icon: Icons.person_outline, title: 'My Profile', onTap: ...)
/// AppListTile(icon: Icons.language, title: 'Language', trailingText: 'English')
/// ```
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailingText,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = iconColor ?? context.colors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              AppIconBadge(icon: icon!, color: color),
              const HGap(AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.title(title, maxLines: 1),
                  if (subtitle != null) ...[
                    const VGap(AppSpacing.xxs),
                    AppText.caption(subtitle!, maxLines: 1),
                  ],
                ],
              ),
            ),
            if (trailingText != null) ...[
              const HGap(AppSpacing.xs),
              AppText.caption(trailingText!),
            ],
            if (trailing != null) ...[
              const HGap(AppSpacing.xs),
              trailing!,
            ] else if (showChevron && onTap != null) ...[
              const HGap(AppSpacing.xs),
              Icon(Icons.chevron_right,
                  color: tokens.textSecondary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
