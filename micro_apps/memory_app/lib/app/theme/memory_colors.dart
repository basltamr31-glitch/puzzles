import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Card-specific colors that don't map cleanly onto Material's
/// [ColorScheme], exposed via [ThemeExtension] so widgets read them the
/// same way they read any other theme value (`Theme.of(context)...`) and
/// they animate correctly with `AnimatedTheme`/theme transitions.
@immutable
class MemoryColors extends ThemeExtension<MemoryColors> {
  const MemoryColors({
    required this.cardBack,
    required this.cardBackPattern,
    required this.cardBackBorder,
    required this.cardFace,
    required this.cardFaceBorder,
    required this.cardMatched,
    required this.cardMatchedBorder,
    required this.cardMismatch,
    required this.cardMismatchBorder,
    required this.cardLabel,
    required this.boardBackground,
  });

  /// A face-down card. Most of the board wears this for most of the game.
  final Color cardBack;

  /// The motif drawn on a face-down card — the one place the gold accent
  /// appears at size.
  final Color cardBackPattern;

  final Color cardBackBorder;

  /// A revealed card the player is still deciding about.
  final Color cardFace;

  final Color cardFaceBorder;

  /// A card whose pair has been found. Quiet on purpose: matched cards
  /// are finished business and must not compete with the ones still in
  /// play.
  final Color cardMatched;

  /// Border of a matched card. Carries the "correct" signal that the
  /// deliberately-pale [cardMatched] fill gives up — which is why it is
  /// a saturated green rather than a tint of one.
  final Color cardMatchedBorder;

  /// The two cards that just failed to match, for the moment before they
  /// turn back over. The only feedback that a life was spent, and on
  /// screen for well under a second — so it is the loudest state here.
  final Color cardMismatch;

  final Color cardMismatchBorder;

  /// Text on a card face. Symbols themselves are colour emoji and need no
  /// tint; this is for the fallback glyph and any label drawn over a face.
  final Color cardLabel;

  /// The felt the cards sit on.
  final Color boardBackground;

  static const light = MemoryColors(
    cardBack: AppColors.cardBackLight,
    cardBackPattern: AppColors.cardBackPatternLight,
    cardBackBorder: AppColors.cardBackBorderLight,
    cardFace: AppColors.cardFaceLight,
    cardFaceBorder: AppColors.cardFaceBorderLight,
    cardMatched: AppColors.cardMatchedLight,
    cardMatchedBorder: AppColors.cardMatchedBorderLight,
    cardMismatch: AppColors.cardMismatchLight,
    cardMismatchBorder: AppColors.cardMismatchBorderLight,
    cardLabel: AppColors.cardLabelLight,
    boardBackground: AppColors.boardBackgroundLight,
  );

  static const dark = MemoryColors(
    cardBack: AppColors.cardBackDark,
    cardBackPattern: AppColors.cardBackPatternDark,
    cardBackBorder: AppColors.cardBackBorderDark,
    cardFace: AppColors.cardFaceDark,
    cardFaceBorder: AppColors.cardFaceBorderDark,
    cardMatched: AppColors.cardMatchedDark,
    cardMatchedBorder: AppColors.cardMatchedBorderDark,
    cardMismatch: AppColors.cardMismatchDark,
    cardMismatchBorder: AppColors.cardMismatchBorderDark,
    cardLabel: AppColors.cardLabelDark,
    boardBackground: AppColors.boardBackgroundDark,
  );

  @override
  MemoryColors copyWith({
    Color? cardBack,
    Color? cardBackPattern,
    Color? cardBackBorder,
    Color? cardFace,
    Color? cardFaceBorder,
    Color? cardMatched,
    Color? cardMatchedBorder,
    Color? cardMismatch,
    Color? cardMismatchBorder,
    Color? cardLabel,
    Color? boardBackground,
  }) {
    return MemoryColors(
      cardBack: cardBack ?? this.cardBack,
      cardBackPattern: cardBackPattern ?? this.cardBackPattern,
      cardBackBorder: cardBackBorder ?? this.cardBackBorder,
      cardFace: cardFace ?? this.cardFace,
      cardFaceBorder: cardFaceBorder ?? this.cardFaceBorder,
      cardMatched: cardMatched ?? this.cardMatched,
      cardMatchedBorder: cardMatchedBorder ?? this.cardMatchedBorder,
      cardMismatch: cardMismatch ?? this.cardMismatch,
      cardMismatchBorder: cardMismatchBorder ?? this.cardMismatchBorder,
      cardLabel: cardLabel ?? this.cardLabel,
      boardBackground: boardBackground ?? this.boardBackground,
    );
  }

  @override
  MemoryColors lerp(ThemeExtension<MemoryColors>? other, double t) {
    if (other is! MemoryColors) return this;
    return MemoryColors(
      cardBack: Color.lerp(cardBack, other.cardBack, t)!,
      cardBackPattern: Color.lerp(cardBackPattern, other.cardBackPattern, t)!,
      cardBackBorder: Color.lerp(cardBackBorder, other.cardBackBorder, t)!,
      cardFace: Color.lerp(cardFace, other.cardFace, t)!,
      cardFaceBorder: Color.lerp(cardFaceBorder, other.cardFaceBorder, t)!,
      cardMatched: Color.lerp(cardMatched, other.cardMatched, t)!,
      cardMatchedBorder:
          Color.lerp(cardMatchedBorder, other.cardMatchedBorder, t)!,
      cardMismatch: Color.lerp(cardMismatch, other.cardMismatch, t)!,
      cardMismatchBorder:
          Color.lerp(cardMismatchBorder, other.cardMismatchBorder, t)!,
      cardLabel: Color.lerp(cardLabel, other.cardLabel, t)!,
      boardBackground: Color.lerp(boardBackground, other.boardBackground, t)!,
    );
  }
}

extension MemoryColorsContext on BuildContext {
  MemoryColors get memoryColors => Theme.of(this).extension<MemoryColors>()!;
}
