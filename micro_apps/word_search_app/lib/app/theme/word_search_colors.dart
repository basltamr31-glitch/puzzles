import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Grid-specific colors that don't map cleanly onto Material's
/// [ColorScheme], exposed via [ThemeExtension] so widgets read them the
/// same way they read any other theme value (`Theme.of(context)...`) and
/// they animate correctly with `AnimatedTheme`/theme transitions.
@immutable
class WordSearchColors extends ThemeExtension<WordSearchColors> {
  const WordSearchColors({
    required this.cellBackground,
    required this.cellSelected,
    required this.cellFound,
    required this.cellBorder,
    required this.letterText,
    required this.foundLetterText,
    required this.selectionLine,
    required this.foundLine,
    required this.wrongSelection,
  });

  final Color cellBackground;

  /// Cells under the player's finger while dragging out a selection.
  final Color cellSelected;

  /// Background of a cell belonging to an already-found word.
  final Color cellFound;

  final Color cellBorder;

  /// Letters not yet claimed by any found word.
  final Color letterText;

  /// Letters inside an already-found word — brand-tinted so the claimed
  /// half of the grid is obvious at a glance.
  final Color foundLetterText;

  /// The line drawn along the cells currently being dragged over.
  final Color selectionLine;

  /// The line drawn permanently over a found word's cells.
  final Color foundLine;

  /// Brief feedback when a released selection doesn't match any word.
  final Color wrongSelection;

  static const light = WordSearchColors(
    cellBackground: AppColors.cellBackgroundLight,
    cellSelected: AppColors.cellSelectedLight,
    cellFound: AppColors.cellFoundLight,
    cellBorder: AppColors.cellBorderLight,
    letterText: AppColors.textPrimaryLight,
    foundLetterText: AppColors.foundLetterLight,
    selectionLine: AppColors.selectionLineLight,
    foundLine: AppColors.foundLineLight,
    wrongSelection: AppColors.wrongSelectionLight,
  );

  static const dark = WordSearchColors(
    cellBackground: AppColors.cellBackgroundDark,
    cellSelected: AppColors.cellSelectedDark,
    cellFound: AppColors.cellFoundDark,
    cellBorder: AppColors.cellBorderDark,
    letterText: AppColors.textPrimaryDark,
    foundLetterText: AppColors.foundLetterDark,
    selectionLine: AppColors.selectionLineDark,
    foundLine: AppColors.foundLineDark,
    wrongSelection: AppColors.wrongSelectionDark,
  );

  @override
  WordSearchColors copyWith({
    Color? cellBackground,
    Color? cellSelected,
    Color? cellFound,
    Color? cellBorder,
    Color? letterText,
    Color? foundLetterText,
    Color? selectionLine,
    Color? foundLine,
    Color? wrongSelection,
  }) {
    return WordSearchColors(
      cellBackground: cellBackground ?? this.cellBackground,
      cellSelected: cellSelected ?? this.cellSelected,
      cellFound: cellFound ?? this.cellFound,
      cellBorder: cellBorder ?? this.cellBorder,
      letterText: letterText ?? this.letterText,
      foundLetterText: foundLetterText ?? this.foundLetterText,
      selectionLine: selectionLine ?? this.selectionLine,
      foundLine: foundLine ?? this.foundLine,
      wrongSelection: wrongSelection ?? this.wrongSelection,
    );
  }

  @override
  WordSearchColors lerp(ThemeExtension<WordSearchColors>? other, double t) {
    if (other is! WordSearchColors) return this;
    return WordSearchColors(
      cellBackground: Color.lerp(cellBackground, other.cellBackground, t)!,
      cellSelected: Color.lerp(cellSelected, other.cellSelected, t)!,
      cellFound: Color.lerp(cellFound, other.cellFound, t)!,
      cellBorder: Color.lerp(cellBorder, other.cellBorder, t)!,
      letterText: Color.lerp(letterText, other.letterText, t)!,
      foundLetterText: Color.lerp(
        foundLetterText,
        other.foundLetterText,
        t,
      )!,
      selectionLine: Color.lerp(selectionLine, other.selectionLine, t)!,
      foundLine: Color.lerp(foundLine, other.foundLine, t)!,
      wrongSelection: Color.lerp(wrongSelection, other.wrongSelection, t)!,
    );
  }
}

extension WordSearchColorsContext on BuildContext {
  WordSearchColors get wordSearchColors =>
      Theme.of(this).extension<WordSearchColors>()!;
}
