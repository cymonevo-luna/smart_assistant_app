import 'package:flutter/material.dart';

/// The selectable primary/accent color schemes shown in Settings. Jarvis red is
/// the default brand; other accents remain for user choice and persisted prefs.
///
/// Add a new accent by adding an entry here and giving it a [seed] — the whole
/// theme regenerates from that single color.
enum AppAccent {
  jarvis('Jarvis', Color(0xFFC8102E)),
  gold('Gold', Color(0xFFF5C518)),
  red('Red', Color(0xFFEF4444)),
  orange('Orange', Color(0xFFF59E0B)),
  green('Green', Color(0xFF22C55E)),
  purple('Purple', Color(0xFF8B5CF6)),
  teal('Teal', Color(0xFF14B8A6)),
  blue('Blue', Color(0xFF2F6BED));

  const AppAccent(this.label, this.seed);

  /// Human readable name (useful for theme pickers).
  final String label;

  /// The seed color the entire [ColorScheme] is generated from.
  final Color seed;

  static AppAccent fromName(String? name) {
    return AppAccent.values.firstWhere(
      (a) => a.name == name,
      orElse: () => AppAccent.jarvis,
    );
  }
}

/// Fixed semantic colors that do NOT change with the accent (status colors,
/// neutral surfaces). Accent-driven colors live on [ColorScheme] instead.
abstract final class AppPalette {
  /// Companion gold for Jarvis red primary (chips, nav indicators, highlights).
  static const Color jarvisGold = Color(0xFFF5C518);

  // Status colors — tuned for readability on dark HUD backgrounds.
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF5C518);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF38BDF8);

  // Light neutrals.
  static const Color lightScaffold = Color(0xFFF4F6F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E8EC);

  // Dark neutrals — tech HUD palette.
  static const Color darkScaffold = Color(0xFF0A0E14);
  static const Color darkSurface = Color(0xFF141820);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF252A33);
}
