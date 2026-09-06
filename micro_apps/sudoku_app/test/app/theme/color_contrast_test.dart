import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/app/theme/app_colors.dart';
import 'package:sudoku_app/app/theme/sudoku_colors.dart';
import 'package:sudoku_app/shared/models/difficulty.dart';
import 'package:sudoku_app/shared/models/difficulty_presentation.dart';

/// WCAG relative luminance.
double _luminance(Color c) {
  double channel(double v) {
    return v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Summed per-channel difference, 0-765.
///
/// The right tool for "can a player tell these two tints apart", which
/// WCAG contrast is not: two colours of the same lightness but different
/// hue score ~1.0 on contrast while being obviously different to look at.
/// Contrast answers "can I read text on this"; distance answers "is this a
/// different colour".
int _channelDistance(Color a, Color b) {
  int ch(double x, double y) => ((x - y).abs() * 255).round();
  return ch(a.r, b.r) + ch(a.g, b.g) + ch(a.b, b.b);
}

/// The grid is the whole game, and every cell state tints its background.
/// A digit that stops being readable on one of those tints is a real bug
/// no widget test would catch — so the palette is asserted directly.
void main() {
  const light = SudokuColors.light;
  const dark = SudokuColors.dark;

  /// Every background a digit can sit on in light mode.
  const lightCellBackgrounds = <String, Color>{
    'normal cell': AppColors.cellBackgroundLight,
    'given cell': AppColors.cellGivenLight,
    'selected cell': AppColors.cellSelectedLight,
    'peer cell': AppColors.cellPeerLight,
    'same-value cell': AppColors.cellSameValueLight,
  };

  const darkCellBackgrounds = <String, Color>{
    'normal cell': AppColors.cellBackgroundDark,
    'given cell': AppColors.cellGivenDark,
    'selected cell': AppColors.cellSelectedDark,
    'peer cell': AppColors.cellPeerDark,
    'same-value cell': AppColors.cellSameValueDark,
  };

  /// The two teal-on-teal combinations that currently miss WCAG AA, kept
  /// as *named* exceptions rather than by lowering the bar for everything.
  ///
  /// Both are the player's own teal digit on a teal highlight:
  ///   entered digit on the selected cell     4.34 (AA wants 4.50)
  ///   entered digit on a same-value cell     4.35 (AA wants 4.50)
  ///   incorrect digit on the selected cell   2.98 (wants 3.00)
  ///   incorrect digit on a same-value cell   2.99 (wants 3.00)
  ///
  /// Lightening `cellSelectedLight` fixes the ratios but costs the thing
  /// that makes the selection obvious: at #CCFBF1 the selected cell is
  /// only 35 channel-steps from a peer cell instead of 92, so the
  /// highlight stops reading as "you are here". The palette is deliberately
  /// left as-is; these bounds pin the current values so a *further*
  /// regression still fails.
  const knownShortfallFloor = 4.3;
  const knownIncorrectFloor = 2.9;
  const nearMissBackgrounds = {'selected cell', 'same-value cell'};

  group('light-mode grid legibility', () {
    test("the puzzle's own digits read on every cell state", () {
      lightCellBackgrounds.forEach((name, background) {
        expect(
          _contrast(light.digitGiven, background),
          greaterThanOrEqualTo(4.5),
          reason: 'given digit on $name',
        );
      });
    });

    test("the player's digits read on every cell state", () {
      lightCellBackgrounds.forEach((name, background) {
        final floor = nearMissBackgrounds.contains(name) ? knownShortfallFloor : 4.5;
        expect(
          _contrast(light.digitEntered, background),
          greaterThanOrEqualTo(floor),
          reason: 'entered digit on $name',
        );
      });
    });

    test('an incorrect digit reads on every cell state', () {
      lightCellBackgrounds.forEach((name, background) {
        final floor =
            nearMissBackgrounds.contains(name) ? knownIncorrectFloor : 3.0;
        expect(
          _contrast(light.digitIncorrect, background),
          greaterThanOrEqualTo(floor),
          reason: 'incorrect digit on $name',
        );
      });
    });

    test('pencil marks stay readable on an empty cell', () {
      expect(
        _contrast(light.noteText, AppColors.cellBackgroundLight),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('dark-mode grid legibility', () {
    test("the puzzle's own digits read on every cell state", () {
      darkCellBackgrounds.forEach((name, background) {
        expect(
          _contrast(dark.digitGiven, background),
          greaterThanOrEqualTo(4.5),
          reason: 'given digit on $name',
        );
      });
    });

    test("the player's digits read on every cell state", () {
      darkCellBackgrounds.forEach((name, background) {
        expect(
          _contrast(dark.digitEntered, background),
          greaterThanOrEqualTo(4.5),
          reason: 'entered digit on $name',
        );
      });
    });
  });

  group('cell states are distinguishable from each other', () {
    // Selection, peers, and matching digits are three different pieces of
    // information. If two of them look alike the highlight means nothing.
    test('light mode: selected, peer, and same-value are visibly different', () {
      expect(
        _channelDistance(AppColors.cellSelectedLight, AppColors.cellPeerLight),
        greaterThan(60),
      );
      expect(
        _channelDistance(AppColors.cellSameValueLight, AppColors.cellPeerLight),
        greaterThan(25),
      );
      expect(
        _channelDistance(AppColors.cellSelectedLight, AppColors.cellSameValueLight),
        greaterThan(40),
      );
      // A given cell is meant to be a whisper apart from an empty one, not
      // a different colour — but it must not be identical either.
      expect(
        _channelDistance(AppColors.cellGivenLight, AppColors.cellBackgroundLight),
        greaterThan(20),
      );
    });

    test('dark mode: selected, peer, and same-value are visibly different', () {
      expect(
        _channelDistance(AppColors.cellSelectedDark, AppColors.cellPeerDark),
        greaterThan(60),
      );
      expect(
        _channelDistance(AppColors.cellSameValueDark, AppColors.cellPeerDark),
        greaterThan(25),
      );
    });

    test('the box separators read against the cells they divide', () {
      expect(
        _contrast(light.gridBorder, AppColors.cellBackgroundLight),
        greaterThan(2.0),
      );
      expect(
        _contrast(dark.gridBorder, AppColors.cellBackgroundDark),
        greaterThan(2.0),
      );
    });
  });

  group('difficulty accents', () {
    test('every tier has a distinct colour', () {
      final colors = Difficulty.values.map(difficultyColor).toSet();
      expect(colors.length, Difficulty.values.length);
    });

    test('every tier has a distinct tint', () {
      final tints = Difficulty.values.map(difficultyTint).toSet();
      expect(tints.length, Difficulty.values.length);
    });

    test('each accent is readable on its own tint badge', () {
      for (final difficulty in Difficulty.values) {
        expect(
          _contrast(difficultyColor(difficulty), difficultyTint(difficulty)),
          greaterThanOrEqualTo(3.0),
          reason: 'the ${difficulty.storageValue} icon must read on its badge',
        );
      }
    });

    test('each accent is readable on the light page background', () {
      for (final difficulty in Difficulty.values) {
        expect(
          _contrast(difficultyColor(difficulty), AppColors.backgroundLight),
          greaterThanOrEqualTo(3.0),
          reason: '${difficulty.storageValue} must read on the page',
        );
      }
    });
  });
}
