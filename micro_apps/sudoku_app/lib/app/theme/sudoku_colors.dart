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
    required this.cellConflict,
    required this.cellSelectedBorder,
    required this.cellBorder,
    required this.gridBorder,
    required this.digitGiven,
    required this.digitEntered,
    required this.digitIncorrect,
    required this.digitOnSelected,
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

  /// A cell holding a digit that breaks the rules, or that the last Check
  /// found to disagree with the solution.
  ///
  /// This wins over every other fill, including the selection. A duplicate
  /// digit is a mistake the player is actively making; "which cell am I
  /// on" is something they already know, and the selection ring still
  /// shows it.
  final Color cellConflict;

  /// Ring around the selected cell, drawn over its fill.
  ///
  /// Selection is signalled twice — fill *and* outline — because an
  /// outline costs nothing in text contrast. Relying on fill alone is what
  /// previously capped the selected tint at a shade the player could
  /// barely pick out.
  final Color cellSelectedBorder;

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

  /// Digits and pencil marks on the selected cell, which is filled
  /// strongly enough that the ordinary digit colours would not read on it.
  final Color digitOnSelected;

  final Color noteText;

  static const light = SudokuColors(
    cellBackground: AppColors.cellBackgroundLight,
    cellGiven: AppColors.cellGivenLight,
    cellSelected: AppColors.cellSelectedLight,
    cellPeer: AppColors.cellPeerLight,
    cellSameValue: AppColors.cellSameValueLight,
    cellConflict: AppColors.cellConflictLight,
    cellSelectedBorder: AppColors.cellSelectedBorderLight,
    cellBorder: AppColors.cellBorderLight,
    gridBorder: AppColors.gridBorderLight,
    digitGiven: AppColors.textPrimaryLight,
    digitEntered: AppColors.digitEnteredLight,
    digitIncorrect: AppColors.digitIncorrectLight,
    digitOnSelected: AppColors.digitOnSelectedLight,
    noteText: AppColors.noteTextLight,
  );

  static const dark = SudokuColors(
    cellBackground: AppColors.cellBackgroundDark,
    cellGiven: AppColors.cellGivenDark,
    cellSelected: AppColors.cellSelectedDark,
    cellPeer: AppColors.cellPeerDark,
    cellSameValue: AppColors.cellSameValueDark,
    cellConflict: AppColors.cellConflictDark,
    cellSelectedBorder: AppColors.cellSelectedBorderDark,
    cellBorder: AppColors.cellBorderDark,
    gridBorder: AppColors.gridBorderDark,
    digitGiven: AppColors.textPrimaryDark,
    // The light theme's teal is too dark to read on a dark cell, so the
    // player's digits use a light tint of the brand instead.
    digitEntered: AppColors.digitEnteredDark,
    digitIncorrect: AppColors.digitIncorrectDark,
    digitOnSelected: AppColors.digitOnSelectedDark,
    noteText: AppColors.noteTextDark,
  );

  @override
  SudokuColors copyWith({
    Color? cellBackground,
    Color? cellGiven,
    Color? cellSelected,
    Color? cellPeer,
    Color? cellSameValue,
    Color? cellConflict,
    Color? cellSelectedBorder,
    Color? cellBorder,
    Color? gridBorder,
    Color? digitGiven,
    Color? digitEntered,
    Color? digitIncorrect,
    Color? digitOnSelected,
    Color? noteText,
  }) {
    return SudokuColors(
      cellBackground: cellBackground ?? this.cellBackground,
      cellGiven: cellGiven ?? this.cellGiven,
      cellSelected: cellSelected ?? this.cellSelected,
      cellPeer: cellPeer ?? this.cellPeer,
      cellSameValue: cellSameValue ?? this.cellSameValue,
      cellConflict: cellConflict ?? this.cellConflict,
      cellSelectedBorder: cellSelectedBorder ?? this.cellSelectedBorder,
      cellBorder: cellBorder ?? this.cellBorder,
      gridBorder: gridBorder ?? this.gridBorder,
      digitGiven: digitGiven ?? this.digitGiven,
      digitEntered: digitEntered ?? this.digitEntered,
      digitIncorrect: digitIncorrect ?? this.digitIncorrect,
      digitOnSelected: digitOnSelected ?? this.digitOnSelected,
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
      cellConflict: Color.lerp(cellConflict, other.cellConflict, t)!,
      cellSelectedBorder:
          Color.lerp(cellSelectedBorder, other.cellSelectedBorder, t)!,
      cellBorder: Color.lerp(cellBorder, other.cellBorder, t)!,
      gridBorder: Color.lerp(gridBorder, other.gridBorder, t)!,
      digitGiven: Color.lerp(digitGiven, other.digitGiven, t)!,
      digitEntered: Color.lerp(digitEntered, other.digitEntered, t)!,
      digitIncorrect: Color.lerp(digitIncorrect, other.digitIncorrect, t)!,
      digitOnSelected: Color.lerp(digitOnSelected, other.digitOnSelected, t)!,
      noteText: Color.lerp(noteText, other.noteText, t)!,
    );
  }
}

extension SudokuColorsContext on BuildContext {
  SudokuColors get sudokuColors => Theme.of(this).extension<SudokuColors>()!;
}
