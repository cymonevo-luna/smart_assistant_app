import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'app_text.dart';

/// Labeled text input matching the mockup's rounded, filled fields. Handles the
/// common password show/hide toggle when [obscure] is true.
///
/// ```dart
/// AppTextField(label: 'Email', hint: 'example@email.com', prefixIcon: Icons.mail_outline)
/// AppTextField(label: 'Password', obscure: true)
/// ```
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          AppText.label(widget.label!),
          const VGap(AppSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: tokens.textSecondary, size: 20)
                : null,
            suffixIcon: _buildSuffix(tokens),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffix(AppTokens tokens) {
    if (widget.obscure) {
      return IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: tokens.textSecondary,
          size: 20,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }
    return widget.suffixIcon;
  }
}
