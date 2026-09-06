import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Grid-specific colors that don't map cleanly onto Material's
/// [ColorScheme], exposed via [ThemeExtension] so widgets read them the
/// same way they read any other theme value (`Theme.of(context)...`) and
/// they animate correctly with `AnimatedTheme`/theme transitions.
@immutable
class SudokuColors extends ThemeExtension<SudokuColors> {
  const SudokuColors({
    required this.cellBackground,
    required this.cellGiven,
    required this.cellSelected,
    required this.cellPeer,
    required this.cellSameValue,
    required this.cellBorder,
    required this.gridBorder,
    required this.digitGiven,
    required this.digitEntered,
    required this.digitIncorrect,
    required this.noteText,
  });

  final Color cellBackground;

  /// Background of a pre-filled clue cell.
  final Color cellGiven;

  /// The one cell the player has tapped.
  final Color cellSelected;

  /// Cells sharing a row, column, or 3x3 box with the selection. Tinted
  /// so the constraint the player is reasoning about is visible without
  /// them having to trace lines by eye.
  final Color cellPeer;

  /// Cells elsewhere in the grid holding the same digit as the selected
  /// cell — the single most useful scanning aid in a Sudoku app.
  final Color cellSameValue;

  final Color cellBorder;

  /// The heavy 3x3 box separators.
  final Color gridBorder;

  /// Digits that came with the puzzle. Deliberately the highest-contrast
  /// text color: they are the fixed truth of the grid.
  final Color digitGiven;

  /// Digits the player entered — brand-colored so at a glance it is
  /// obvious which half of the grid is theirs.
  final Color digitEntered;

  final Color digitIncorrect;
  final Color noteText;

  static const light = SudokuColors(
    cellBackground: AppColors.cellBackgroundLight,
    cellGiven: AppColors.cellGivenLight,
    cellSelected: AppColors.cellSelectedLight,
    cellPeer: AppColors.cellPeerLight,
    cellSameValue: AppColors.cellSameValueLight,
    cellBorder: AppColors.cellBorderLight,
    gridBorder: AppColors.gridBorderLight,
    digitGiven: AppColors.textPrimaryLight,
    digitEntered: AppColors.primary,
    digitIncorrect: AppColors.error,
    noteText: AppColors.textSecondaryLight,
  );

  static const dark = SudokuColors(
    cellBackground: AppColors.cellBackgroundDark,
    cellGiven: AppColors.cellGivenDark,
    cellSelected: AppColors.cellSelectedDark,
    cellPeer: AppColors.cellPeerDark,
    cellSameValue: AppColors.cellSameValueDark,
    cellBorder: AppColors.cellBorderDark,
    gridBorder: AppColors.gridBorderDark,
    digitGiven: AppColors.textPrimaryDark,
    // The light theme's teal is too dark to read on a dark cell, so the
    // player's digits use the light tint of the brand instead of primary.
    digitEntered: AppColors.primaryLight,
    digitIncorrect: AppColors.error,
    noteText: AppColors.textSecondaryDark,
  );

  @override
  SudokuColors copyWith({
    Color? cellBackground,
    Color? cellGiven,
    Color? cellSelected,
    Color? cellPeer,
    Color? cellSameValue,
    Color? cellBorder,
    Color? gridBorder,
    Color? digitGiven,
    Color? digitEntered,
    Color? digitIncorrect,
    Color? noteText,
  }) {
    return SudokuColors(
      cellBackground: cellBackground ?? this.cellBackground,
      cellGiven: cellGiven ?? this.cellGiven,
      cellSelected: cellSelected ?? this.cellSelected,
      cellPeer: cellPeer ?? this.cellPeer,
      cellSameValue: cellSameValue ?? this.cellSameValue,
      cellBorder: cellBorder ?? this.cellBorder,
      gridBorder: gridBorder ?? this.gridBorder,
      digitGiven: digitGiven ?? this.digitGiven,
      digitEntered: digitEntered ?? this.digitEntered,
      digitIncorrect: digitIncorrect ?? this.digitIncorrect,
      noteText: noteText ?? this.noteText,
    );
  }

  @override
  SudokuColors lerp(ThemeExtension<SudokuColors>? other, double t) {
    if (other is! SudokuColors) return this;
    return SudokuColors(
      cellBackground: Color.lerp(cellBackground, other.cellBackground, t)!,
      cellGiven: Color.lerp(cellGiven, other.cellGiven, t)!,
      cellSelected: Color.lerp(cellSelected, other.cellSelected, t)!,
      cellPeer: Color.lerp(cellPeer, other.cellPeer, t)!,
      cellSameValue: Color.lerp(cellSameValue, other.cellSameValue, t)!,
      cellBorder: Color.lerp(cellBorder, other.cellBorder, t)!,
      gridBorder: Color.lerp(gridBorder, other.gridBorder, t)!,
      digitGiven: Color.lerp(digitGiven, other.digitGiven, t)!,
      digitEntered: Color.lerp(digitEntered, other.digitEntered, t)!,
      digitIncorrect: Color.lerp(digitIncorrect, other.digitIncorrect, t)!,
      noteText: Color.lerp(noteText, other.noteText, t)!,
    );
  }
}

extension SudokuColorsContext on BuildContext {
  SudokuColors get sudokuColors => Theme.of(this).extension<SudokuColors>()!;
}
