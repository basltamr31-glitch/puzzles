import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Grid-specific colors that don't map cleanly onto Material's
/// [ColorScheme], exposed via [ThemeExtension] so widgets read them the
/// same way they read any other theme value (`Theme.of(context)...`) and
/// they animate correctly with `AnimatedTheme`/theme transitions.
@immutable
class CrosswordColors extends ThemeExtension<CrosswordColors> {
  const CrosswordColors({
    required this.cellBackground,
    required this.cellBlocked,
    required this.cellActiveWord,
    required this.cellActiveCell,
    required this.cellBorder,
    required this.cellTextCorrect,
    required this.cellTextIncorrect,
  });

  final Color cellBackground;
  final Color cellBlocked;
  final Color cellActiveWord;
  final Color cellActiveCell;
  final Color cellBorder;
  final Color cellTextCorrect;
  final Color cellTextIncorrect;

  static const light = CrosswordColors(
    cellBackground: AppColors.cellBackgroundLight,
    cellBlocked: AppColors.cellBlockedLight,
    cellActiveWord: AppColors.cellActiveWordLight,
    cellActiveCell: AppColors.cellActiveCellLight,
    cellBorder: AppColors.cellBorderLight,
    cellTextCorrect: AppColors.success,
    cellTextIncorrect: AppColors.error,
  );

  static const dark = CrosswordColors(
    cellBackground: AppColors.cellBackgroundDark,
    cellBlocked: AppColors.cellBlockedDark,
    cellActiveWord: AppColors.cellActiveWordDark,
    cellActiveCell: AppColors.cellActiveCellDark,
    cellBorder: AppColors.cellBorderDark,
    cellTextCorrect: AppColors.success,
    cellTextIncorrect: AppColors.error,
  );

  @override
  CrosswordColors copyWith({
    Color? cellBackground,
    Color? cellBlocked,
    Color? cellActiveWord,
    Color? cellActiveCell,
    Color? cellBorder,
    Color? cellTextCorrect,
    Color? cellTextIncorrect,
  }) {
    return CrosswordColors(
      cellBackground: cellBackground ?? this.cellBackground,
      cellBlocked: cellBlocked ?? this.cellBlocked,
      cellActiveWord: cellActiveWord ?? this.cellActiveWord,
      cellActiveCell: cellActiveCell ?? this.cellActiveCell,
      cellBorder: cellBorder ?? this.cellBorder,
      cellTextCorrect: cellTextCorrect ?? this.cellTextCorrect,
      cellTextIncorrect: cellTextIncorrect ?? this.cellTextIncorrect,
    );
  }

  @override
  CrosswordColors lerp(ThemeExtension<CrosswordColors>? other, double t) {
    if (other is! CrosswordColors) return this;
    return CrosswordColors(
      cellBackground: Color.lerp(cellBackground, other.cellBackground, t)!,
      cellBlocked: Color.lerp(cellBlocked, other.cellBlocked, t)!,
      cellActiveWord: Color.lerp(cellActiveWord, other.cellActiveWord, t)!,
      cellActiveCell: Color.lerp(cellActiveCell, other.cellActiveCell, t)!,
      cellBorder: Color.lerp(cellBorder, other.cellBorder, t)!,
      cellTextCorrect: Color.lerp(cellTextCorrect, other.cellTextCorrect, t)!,
      cellTextIncorrect: Color.lerp(
        cellTextIncorrect,
        other.cellTextIncorrect,
        t,
      )!,
    );
  }
}

extension CrosswordColorsContext on BuildContext {
  CrosswordColors get crosswordColors =>
      Theme.of(this).extension<CrosswordColors>()!;
}
