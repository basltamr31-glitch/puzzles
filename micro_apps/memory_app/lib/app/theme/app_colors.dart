import 'package:flutter/material.dart';

/// Memory Match's visual identity: a card table — deep rose as the
/// primary (the colour of every face-down card back), warm gold as the
/// single accent that marks the motif on those backs and the reward
/// moments, and a barely-warm off-white ground so a white card face reads
/// as a card sitting *on* something rather than a hole in the page.
///
/// Deliberately a different palette from its three siblings — crossword
/// (indigo + amber on cream), sudoku (teal + orange on cool white), word
/// search (violet + lime on tinted white). They ship as separate products
/// and must not look like reskins of one another. The *shape* of this
/// file — this exact set of tokens — is what the portfolio reuses.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFBE123C);
  static const Color primaryDark = Color(0xFF9F1239);
  static const Color primaryLight = Color(0xFFFFE4E6);
  static const Color accent = Color(0xFFEAB308);
  static const Color accentLight = Color(0xFFFEF3C7);

  /// Per-tier accent hues. Deliberately *not* rose: these are semantic
  /// (green reads as easy, red-orange as hard) rather than brand, so they
  /// are shared verbatim with the three sibling apps. Four identical
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

  /// Soft shadow for light mode, tinted with this app's own plum ink
  /// rather than neutral grey — a grey shadow over a warm background
  /// reads as dirt. Dark mode gets none; shadows do nothing there.
  static const Color shadowLight = Color(0x142A1018);

  /// Vertical wash behind the welcome screen. Stays inside the existing
  /// warm off-white family so the brand palette is unchanged — this adds
  /// depth, it does not recolour the app.
  static const Color backdropTopLight = Color(0xFFFFFCFC);
  static const Color backdropBottomLight = Color(0xFFF7E1E5);

  // Feedback
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Light surface
  static const Color backgroundLight = Color(0xFFF9F4F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF2A1018);
  static const Color textSecondaryLight = Color(0xFF7A5C65);
  static const Color borderLight = Color(0xFFE9DBDE);

  // Dark surface
  static const Color backgroundDark = Color(0xFF161011);
  static const Color surfaceDark = Color(0xFF241A1D);
  static const Color textPrimaryDark = Color(0xFFF4ECEE);
  static const Color textSecondaryDark = Color(0xFFB3A1A6);
  static const Color borderDark = Color(0xFF3A2A2E);

  // Cards (light)
  //
  // A memory board has exactly four card states, and unlike a Sudoku grid
  // they are not a ramp of tints away from one neutral cell — a card is
  // either hiding something or showing it, and that difference has to be
  // unmistakable across a room. The distances asserted in
  // color_contrast_test.dart are measured against the *face*, since a
  // revealed card is the reference state a player compares against:
  //
  //   back      497   the card table itself: nothing revealed
  //   matched    70   claimed, and settled into the background
  //   mismatch   84   the one state the player must catch before it flips
  //
  /// A face-down card. The brand rose, used at full strength: most of the
  /// board is face down for most of the game, so this *is* the app's
  /// colour to anyone glancing at a screenshot.
  static const Color cardBackLight = Color(0xFFBE123C);

  /// The motif drawn on a face-down card. Gold on rose is the one place
  /// the accent appears at size, and it is what stops the board from
  /// reading as a grid of flat red squares.
  static const Color cardBackPatternLight = Color(0xFFF6CE55);
  static const Color cardBackBorderLight = Color(0xFF8E0E2D);

  /// A revealed, unmatched card — plain white, so the symbol on it is the
  /// only thing with any colour.
  static const Color cardFaceLight = Color(0xFFFFFFFF);
  static const Color cardFaceBorderLight = Color(0xFFE4D3D7);

  /// A matched pair. Deliberately *quiet*: a matched card is finished
  /// business, and a board that gets louder as you solve it fights the
  /// cards you still have to find. The mint tint plus its border carry
  /// "correct" without competing.
  static const Color cardMatchedLight = Color(0xFFDCF5E6);
  static const Color cardMatchedBorderLight = Color(0xFF15803D);

  /// The pair that just failed to match, during the moment before they
  /// flip back. Loud on purpose — it is the only feedback the player gets
  /// that a life was spent, and it is on screen for under a second.
  static const Color cardMismatchLight = Color(0xFFFFD5D5);
  static const Color cardMismatchBorderLight = Color(0xFFDC2626);

  /// Text drawn on a card face (the fallback glyph, and the pair counter
  /// on a matched card). Split out from the generic text tokens because
  /// it has to clear AA on both the white face and the mint matched tint.
  static const Color cardLabelLight = Color(0xFF4A1B24);

  /// The felt the cards sit on — a hair darker than the page so the board
  /// reads as a surface with edges.
  static const Color boardBackgroundLight = Color(0xFFF1E7E9);

  // Cards (dark)
  //
  // Same three distances, measured the same way: 153 / 66 / 96. Dark mode
  // cannot lean on the same brightness gap — a face-down card can't be
  // brighter than the face it hides — so the back stays saturated while
  // the face drops to a near-surface tone.
  static const Color cardBackDark = Color(0xFF9F1239);
  static const Color cardBackPatternDark = Color(0xFFF2C744);
  static const Color cardBackBorderDark = Color(0xFF6B0B26);

  static const Color cardFaceDark = Color(0xFF291D21);
  static const Color cardFaceBorderDark = Color(0xFF433237);

  static const Color cardMatchedDark = Color(0xFF16402D);
  static const Color cardMatchedBorderDark = Color(0xFF34D399);

  static const Color cardMismatchDark = Color(0xFF7A2429);
  static const Color cardMismatchBorderDark = Color(0xFFFCA5A5);

  static const Color cardLabelDark = Color(0xFFF6E4E8);

  static const Color boardBackgroundDark = Color(0xFF1D1416);
}
