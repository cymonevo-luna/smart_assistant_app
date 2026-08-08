import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_text.dart';

/// Row with a section title and an optional trailing action (e.g. "View all"),
/// matching the "Recent Activity / View all" pattern in the mockup.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.title(title),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: AppText.label(actionLabel!, color: context.colors.primary),
          ),
      ],
    );
  }
}
