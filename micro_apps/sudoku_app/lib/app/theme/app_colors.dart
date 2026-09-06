import 'package:flutter/material.dart';

/// Sudoku's visual identity: cool "graph paper" — deep teal as the calm,
/// focused primary, warm orange as the single accent that marks the
/// player's own moves, and a slightly cool off-white instead of pure
/// white so the grid's own white cells read as raised.
///
/// Deliberately a different palette from the crossword app (indigo +
/// amber on cream): the two ship as separate products and should not
/// look like reskins of each other. The *shape* of this file — this exact
/// set of tokens — is what the portfolio reuses.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color accent = Color(0xFFF97316);
  static const Color accentLight = Color(0xFFFFEDD5);

  /// Per-tier accent hues. Deliberately *not* teal: these are semantic
  /// (green reads as easy, red-orange as hard) rather than brand, so they
  /// are shared verbatim with the crossword app. Four identical
  /// brand-coloured icons gave every difficulty the same weight, which is
  /// what made the tier surfaces read as flat.
  static const Color difficultyEasy = Color(0xFF16A34A);
  static const Color difficultyMedium = Color(0xFF2563EB);
  static const Color difficultyHard = Color(0xFFEA580C);
  static const Color difficultyExpert = Color(0xFF7C3AED);

  /// Pale washes of the above, for badges and light-mode gradients.
  static const Color difficultyEasyTint = Color(0xFFDCFCE7);
  static const Color difficultyMediumTint = Color(0xFFDBEAFE);
  static const Color difficultyHardTint = Color(0xFFFFEDD5);
  static const Color difficultyExpertTint = Color(0xFFEDE9FE);

  /// Soft shadow for light mode, tinted with this app's own deep teal-ink
  /// rather than neutral grey — a grey shadow over a cool background reads
  /// as dirt. Dark mode gets none; shadows do nothing there.
  static const Color shadowLight = Color(0x14102A28);

  /// Vertical wash behind the welcome screen. Stays inside the existing
  /// cool off-white family so the brand palette is unchanged — this adds
  /// depth, it does not recolour the app.
  static const Color backdropTopLight = Color(0xFFFBFDFD);
  static const Color backdropBottomLight = Color(0xFFDFEDEB);

  // Feedback
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Light surface
  static const Color backgroundLight = Color(0xFFF4F7F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF102A28);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFDCE5E4);

  // Dark surface
  static const Color backgroundDark = Color(0xFF0E1717);
  static const Color surfaceDark = Color(0xFF172424);
  static const Color textPrimaryDark = Color(0xFFECF3F2);
  static const Color textSecondaryDark = Color(0xFF9AAAA8);
  static const Color borderDark = Color(0xFF263837);

  // Sudoku grid (light)
  static const Color cellBackgroundLight = Color(0xFFFFFFFF);

  /// Background for the puzzle's pre-filled clues. Slightly recessed
  /// rather than tinted with the brand color: givens are the *quiet*
  /// part of the grid, the player's own entries are what should pop.
  static const Color cellGivenLight = Color(0xFFEDF2F2);
  static const Color cellSelectedLight = Color(0xFF99F6E4);
  static const Color cellPeerLight = Color(0xFFE4F1F0);
  static const Color cellSameValueLight = Color(0xFFC7EDE8);
  static const Color cellBorderLight = Color(0xFFD3DEDD);

  /// The heavy lines separating the nine 3x3 boxes.
  static const Color gridBorderLight = Color(0xFF456B68);

  // Sudoku grid (dark)
  static const Color cellBackgroundDark = Color(0xFF1B2B2A);
  static const Color cellGivenDark = Color(0xFF121D1D);
  static const Color cellSelectedDark = Color(0xFF0F766E);
  static const Color cellPeerDark = Color(0xFF223635);
  static const Color cellSameValueDark = Color(0xFF2C4B48);
  static const Color cellBorderDark = Color(0xFF2C4241);
  static const Color gridBorderDark = Color(0xFF69908C);
}
