import 'package:flutter/material.dart';

/// Crossword's visual identity: a warm "paper meets modern app" palette —
/// deep indigo-violet as the confident primary, warm amber as the playful
/// accent, cream instead of clinical white for backgrounds. Each future
/// portfolio app defines its own version of this file with different
/// values; the *shape* (this set of tokens) is what's reused.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFFE0E7FF);
  static const Color accent = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFDECC8);

  // Difficulty accents — one hue per tier so a level reads at a glance
  // instead of four identical monochrome icons. Each has a soft tint for
  // chip/badge backgrounds that stays readable under dark text.
  static const Color difficultyEasy = Color(0xFF16A34A);
  static const Color difficultyMedium = Color(0xFF2563EB);
  static const Color difficultyHard = Color(0xFFEA580C);
  static const Color difficultyExpert = Color(0xFF7C3AED);

  static const Color difficultyEasyTint = Color(0xFFDCFCE7);
  static const Color difficultyMediumTint = Color(0xFFDBEAFE);
  static const Color difficultyHardTint = Color(0xFFFFEDD5);
  static const Color difficultyExpertTint = Color(0xFFEDE9FE);

  /// Soft, warm-tinted shadow for light mode. Neutral grey shadows read as
  /// dirty against the cream background; this keeps depth without grime.
  static const Color shadowLight = Color(0x141E1B2E);

  /// Light-mode puzzle backdrop. A flat cream field behind a white grid is
  /// what made the play screen read as unfinished; a barely-there wash from
  /// warm cream into soft lavender gives the page depth without competing
  /// with the grid for attention. Dark mode keeps its flat background.
  static const Color puzzleBackdropTopLight = Color(0xFFFDFBF7);
  static const Color puzzleBackdropBottomLight = Color(0xFFEDE9F9);

  /// Tinted fills for the two in-puzzle actions, so Hint and Check read as
  /// real controls rather than two identical grey outlines.
  static const Color hintFillLight = Color(0xFFFDF0D5);
  static const Color hintForegroundLight = Color(0xFF9A6412);
  static const Color checkFillLight = Color(0xFFE4E9FF);
  static const Color checkForegroundLight = Color(0xFF3730A3);

  // Feedback
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Light surface
  static const Color backgroundLight = Color(0xFFFAF7F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1E1B2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E1D8);

  // Dark surface
  static const Color backgroundDark = Color(0xFF15131F);
  static const Color surfaceDark = Color(0xFF201D2E);
  static const Color textPrimaryDark = Color(0xFFF3F1FA);
  static const Color textSecondaryDark = Color(0xFFA5A1B5);
  static const Color borderDark = Color(0xFF322D45);

  // Crossword grid (light)
  static const Color cellBackgroundLight = Color(0xFFFFFFFF);
  static const Color cellBlockedLight = Color(0xFFE5E1D8);
  // Deepened from near-white tints: the old values were so pale that the
  // active word barely registered, which is a large part of why light mode
  // felt flat. Still light enough for dark cell text to stay high-contrast.
  static const Color cellActiveWordLight = Color(0xFFFCDFA0);
  static const Color cellActiveCellLight = Color(0xFFB9C6FE);
  static const Color cellBorderLight = Color(0xFFD9D4C7);

  // Crossword grid (dark)
  static const Color cellBackgroundDark = Color(0xFF272337);
  static const Color cellBlockedDark = Color(0xFF15131F);
  static const Color cellActiveWordDark = Color(0xFF4A3F22);
  static const Color cellActiveCellDark = Color(0xFF3730A3);
  static const Color cellBorderDark = Color(0xFF3A3550);
}
