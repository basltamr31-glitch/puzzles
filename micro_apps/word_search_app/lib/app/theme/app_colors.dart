import 'package:flutter/material.dart';

/// Word Search's visual identity: confident violet as the primary, fresh
/// lime as the single accent that marks an active selection, and a
/// violet-tinted off-white instead of clinical white for backgrounds.
///
/// Deliberately a different palette from the crossword app (indigo +
/// amber on cream) and the sudoku app (teal + orange on cool white): the
/// three ship as separate products and should not look like reskins of
/// each other. The *shape* of this file — this exact set of tokens — is
/// what the portfolio reuses.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryLight = Color(0xFFEDE9FE);
  static const Color accent = Color(0xFF84CC16);
  static const Color accentLight = Color(0xFFECFCCB);

  /// Per-tier accent hues. Deliberately *not* violet: these are semantic
  /// (green reads as easy, red-orange as hard) rather than brand, so they
  /// are shared verbatim with the crossword and sudoku apps. Four
  /// identical brand-coloured icons gave every difficulty the same
  /// weight, which is what made the tier surfaces read as flat.
  static const Color difficultyEasy = Color(0xFF16A34A);
  static const Color difficultyMedium = Color(0xFF2563EB);
  static const Color difficultyHard = Color(0xFFEA580C);
  static const Color difficultyExpert = Color(0xFF7C3AED);

  /// Pale washes of the above, for badges and light-mode gradients.
  static const Color difficultyEasyTint = Color(0xFFDCFCE7);
  static const Color difficultyMediumTint = Color(0xFFDBEAFE);
  static const Color difficultyHardTint = Color(0xFFFFEDD5);
  static const Color difficultyExpertTint = Color(0xFFEDE9FE);

  /// Soft shadow for light mode, tinted with this app's own deep violet
  /// ink rather than neutral grey — a grey shadow over a tinted
  /// background reads as dirt. Dark mode gets none; shadows do nothing
  /// there.
  static const Color shadowLight = Color(0x142E1065);

  /// Vertical wash behind the welcome screen. Stays inside the existing
  /// tinted off-white family so the brand palette is unchanged — this
  /// adds depth, it does not recolour the app.
  static const Color backdropTopLight = Color(0xFFFCFBFE);
  static const Color backdropBottomLight = Color(0xFFECE6FA);

  // Feedback
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Light surface
  static const Color backgroundLight = Color(0xFFFAF9FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF241344);
  static const Color textSecondaryLight = Color(0xFF6B6478);
  static const Color borderLight = Color(0xFFE4E0EC);

  // Dark surface
  static const Color backgroundDark = Color(0xFF14101F);
  static const Color surfaceDark = Color(0xFF201A33);
  static const Color textPrimaryDark = Color(0xFFF2EEFA);
  static const Color textSecondaryDark = Color(0xFFA79FBD);
  static const Color borderDark = Color(0xFF362B52);

  // Word search grid (light)
  static const Color cellBackgroundLight = Color(0xFFFFFFFF);

  /// Cells under the player's finger while dragging out a selection —
  /// bright and unmistakably "live", distinct from the calmer tone a
  /// confirmed word settles into.
  static const Color cellSelectedLight = Color(0xFFBEF264);

  /// Background for cells belonging to an already-found word.
  static const Color cellFoundLight = Color(0xFFDDD6FE);
  static const Color cellBorderLight = Color(0xFFE4E0EC);
  static const Color foundLetterLight = Color(0xFF5B21B6);
  static const Color selectionLineLight = Color(0xFF65A30D);
  static const Color foundLineLight = Color(0xFF7C3AED);
  static const Color wrongSelectionLight = Color(0xFFEF4444);

  // Word search grid (dark)
  static const Color cellBackgroundDark = Color(0xFF241C38);
  static const Color cellSelectedDark = Color(0xFF365314);
  static const Color cellFoundDark = Color(0xFF3B2E5C);
  static const Color cellBorderDark = Color(0xFF362B52);
  static const Color foundLetterDark = Color(0xFFEDE9FE);
  static const Color selectionLineDark = Color(0xFFA3E635);
  static const Color foundLineDark = Color(0xFFC4B5FD);
  static const Color wrongSelectionDark = Color(0xFFF87171);
}
