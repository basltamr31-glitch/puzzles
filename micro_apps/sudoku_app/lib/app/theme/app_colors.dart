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
  //
  // The four cell tints form a deliberate ramp away from a plain cell,
  // measured as summed channel distance (0-765) and asserted in
  // color_contrast_test.dart:
  //
  //   given  53   a whisper — givens are the quiet part of the grid
  //   peer  120   the row/column/box you are reasoning inside
  //   same  197   every other cell holding the selected digit
  //   sel   280   the one cell you tapped
  //
  // The previous ramp was 44 / 56 / 97 / 138, which put a peer cell just
  // 12 steps from a given cell — the two were indistinguishable, so the
  // row/column highlight effectively did not exist for the player.
  static const Color cellBackgroundLight = Color(0xFFFFFFFF);

  /// Background for the puzzle's pre-filled clues. Slightly recessed
  /// rather than tinted with the brand color: givens are the *quiet*
  /// part of the grid, the player's own entries are what should pop.
  static const Color cellGivenLight = Color(0xFFE9F0EF);
  static const Color cellSelectedLight = Color(0xFF5FCCBA);
  static const Color cellPeerLight = Color(0xFFC2E4DF);
  static const Color cellSameValueLight = Color(0xFF93D9CC);

  /// A cell whose digit breaks the rules, or that Check found wrong.
  /// A full red wash rather than red text alone: a duplicate digit is the
  /// one thing in the grid a player must not be able to miss.
  static const Color cellConflictLight = Color(0xFFFFC9C9);

  /// Ring drawn around the selected cell. Selection is carried by an
  /// outline as well as a fill because an outline costs no text contrast
  /// — which is what previously forced the selected fill to stay so pale
  /// that it barely read as selected.
  static const Color cellSelectedBorderLight = Color(0xFF07443E);

  static const Color cellBorderLight = Color(0xFFD3DEDD);

  /// The heavy lines separating the nine 3x3 boxes.
  static const Color gridBorderLight = Color(0xFF456B68);

  // Sudoku grid (dark)
  //
  // Same ramp, measured the same way: 39 / 96 / 174 / 368. The old dark
  // peer tint sat 29 steps from a plain cell, which on a phone screen in
  // a lit room is no tint at all.
  static const Color cellBackgroundDark = Color(0xFF1B2B2A);
  static const Color cellGivenDark = Color(0xFF111C1C);
  static const Color cellSelectedDark = Color(0xFF6FBFB2);
  static const Color cellPeerDark = Color(0xFF31514E);
  static const Color cellSameValueDark = Color(0xFF43706B);
  static const Color cellConflictDark = Color(0xFF6E2B2B);

  /// Dark ring on dark mode's bright selected cell — the inverse of the
  /// light theme, because there the selected fill is the light one.
  static const Color cellSelectedBorderDark = Color(0xFF06302B);

  static const Color cellBorderDark = Color(0xFF2C4241);
  static const Color gridBorderDark = Color(0xFF69908C);

  // Grid digits.
  //
  // Split out from the generic text tokens because a Sudoku digit has to
  // stay readable on five different cell fills, which no general-purpose
  // body-text colour is chosen for.

  /// The player's own entries, light theme. Darker than [primary] so it
  /// clears AA on the peer and same-value tints, which [primary] did not.
  static const Color digitEnteredLight = Color(0xFF0A5049);
  static const Color digitEnteredDark = Color(0xFFB8F5E8);

  /// A rule-breaking or wrong digit, on top of the red cell wash.
  static const Color digitIncorrectLight = Color(0xFFA81616);
  static const Color digitIncorrectDark = Color(0xFFFFC2C2);

  /// Digits and pencil marks sitting on the strongly filled selected
  /// cell, which inverts: dark ink in light mode, dark ink again in dark
  /// mode, because dark mode's selected cell is the bright one.
  static const Color digitOnSelectedLight = Color(0xFF05302B);
  static const Color digitOnSelectedDark = Color(0xFF062522);

  /// Pencil marks. Darker/lighter than the generic secondary text so they
  /// clear AA on the peer tint they most often sit on.
  static const Color noteTextLight = Color(0xFF2F4E4B);
  static const Color noteTextDark = Color(0xFFD3E4E1);
}
