import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';

/// The "Google / Apple" social sign-in row shared by Login and Register.
class SocialAuthRow extends StatelessWidget {
  const SocialAuthRow({super.key, this.onGoogle, this.onApple});

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: AppSocialButton(
            label: l10n.google,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
            onPressed: onGoogle,
          ),
        ),
        const HGap(AppSpacing.md),
        Expanded(
          child: AppSocialButton(
            label: l10n.apple,
            icon: const Icon(Icons.apple, size: 20),
            onPressed: onApple,
          ),
        ),
      ],
    );
  }
}

/// Centered "or continue with" divider used between the primary CTA and the
/// social sign-in row.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: AppText.caption(label),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
