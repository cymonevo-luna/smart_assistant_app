import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';

enum AppButtonVariant { primary, secondary, text }
enum AppButtonSize { small, medium, large }

/// The app's standard button. Filled primary by default, full-width to match
/// the mockup's CTA style. Supports loading state and leading icon.
///
/// ```dart
/// AppButton('Login', onPressed: _login)
/// AppButton('Cancel', variant: AppButtonVariant.secondary, onPressed: ...)
/// AppButton('Saving', loading: true, onPressed: null)
/// ```
class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;

  /// When true the button stretches to fill the available width.
  final bool expand;

  double get _height => switch (size) {
        AppButtonSize.small => 40,
        AppButtonSize.medium => 48,
        AppButtonSize.large => 52,
      };

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;
    final child = _Content(
      label: label,
      icon: icon,
      loading: loading,
      variant: variant,
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size(0, _height),
            shape:
                const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, _height),
            shape:
                const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(minimumSize: Size(0, _height)),
          child: child,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.label,
    required this.icon,
    required this.loading,
    required this.variant,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      final color = variant == AppButtonVariant.primary
          ? context.colors.onPrimary
          : context.colors.primary;
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const HGap(AppSpacing.xs),
        Text(label),
      ],
    );
  }
}

/// Social sign-in button (Google / Apple style) seen on the login screen.
class AppSocialButton extends StatelessWidget {
  const AppSocialButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.expand = true,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: BorderSide(color: context.tokens.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20, width: 20, child: icon),
          const HGap(AppSpacing.sm),
          Text(label),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
