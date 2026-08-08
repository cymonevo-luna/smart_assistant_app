import '../../l10n/app_localizations.dart';

/// Shared field validators for the auth forms. Returns a localized error
/// message, or `null` when the value is valid.
class AuthValidators {
  AuthValidators(this.l10n);

  final AppLocalizations l10n;

  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  String? required(String? value) {
    if (value == null || value.trim().isEmpty) return l10n.fieldRequired;
    return null;
  }

  String? email(String? value) {
    final base = required(value);
    if (base != null) return base;
    if (!_emailRegex.hasMatch(value!.trim())) return l10n.invalidEmail;
    return null;
  }

  String? password(String? value) {
    final base = required(value);
    if (base != null) return base;
    if (value!.length < 6) return l10n.passwordTooShort;
    return null;
  }

  String? Function(String?) confirmPassword(String? Function() original) {
    return (value) {
      final base = required(value);
      if (base != null) return base;
      if (value != original()) return l10n.passwordsDoNotMatch;
      return null;
    };
  }
}
