import 'package:flutter/material.dart';

/// Warm parchment + olive palette inspired by classical Mushaf typography.
/// Shared between the reading screen and the home screen so the whole app
/// feels intentionally designed in one visual language.
class ReadingPalette {
  final Color background;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color accentSoft;

  const ReadingPalette({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.accentSoft,
  });

  static ReadingPalette of(ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return const ReadingPalette(
        background: Color(0xFF14130F),
        surface: Color(0xFF1C1B16),
        ink: Color(0xFFE8E2D2),
        muted: Color(0xFF8E8773),
        accent: Color(0xFF8FB07D),
        accentSoft: Color(0x208FB07D),
      );
    }
    return const ReadingPalette(
      background: Color(0xFFF7EFDC),
      surface: Color(0xFFFBF6E8),
      ink: Color(0xFF1C1A14),
      muted: Color(0xFF7B6F55),
      accent: Color(0xFF4B6043),
      accentSoft: Color(0x204B6043),
    );
  }
}
