import 'package:flutter/material.dart';

/// The selectable primary/accent color schemes shown at the bottom of the
/// mockup. Each app built on this template can pick a different default.
///
/// Add a new accent by adding an entry here and giving it a [seed] — the whole
/// theme regenerates from that single color.
enum AppAccent {
  blue('Blue', Color(0xFF2F6BED)),
  red('Red', Color(0xFFEF4444)),
  orange('Orange', Color(0xFFF59E0B)),
  green('Green', Color(0xFF22C55E)),
  purple('Purple', Color(0xFF8B5CF6)),
  teal('Teal', Color(0xFF14B8A6));

  const AppAccent(this.label, this.seed);

  /// Human readable name (useful for theme pickers).
  final String label;

  /// The seed color the entire [ColorScheme] is generated from.
  final Color seed;

  static AppAccent fromName(String? name) {
    return AppAccent.values.firstWhere(
      (a) => a.name == name,
      orElse: () => AppAccent.blue,
    );
  }
}

/// Fixed semantic colors that do NOT change with the accent (status colors,
/// neutral surfaces). Accent-driven colors live on [ColorScheme] instead.
abstract final class AppPalette {
  // Status colors.
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF2F6BED);

  // Light neutrals.
  static const Color lightScaffold = Color(0xFFF4F6F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E8EC);

  // Dark neutrals.
  static const Color darkScaffold = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF181B21);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF2A2E37);
}
