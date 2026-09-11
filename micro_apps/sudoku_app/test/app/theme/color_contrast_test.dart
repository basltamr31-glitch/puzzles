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

  /// Every background a *normal* digit can sit on, per theme.
  ///
  /// The selected and conflicting cells are deliberately absent: both are
  /// filled strongly enough that they carry their own digit colour
  /// ([SudokuColors.digitOnSelected] / [SudokuColors.digitIncorrect]),
  /// which is what lets those fills be bold enough to actually see. They
  /// are asserted separately below.
  const lightCellBackgrounds = <String, Color>{
    'normal cell': AppColors.cellBackgroundLight,
    'given cell': AppColors.cellGivenLight,
    'peer cell': AppColors.cellPeerLight,
    'same-value cell': AppColors.cellSameValueLight,
  };

  const darkCellBackgrounds = <String, Color>{
    'normal cell': AppColors.cellBackgroundDark,
    'given cell': AppColors.cellGivenDark,
    'peer cell': AppColors.cellPeerDark,
    'same-value cell': AppColors.cellSameValueDark,
  };

  /// How far each cell state must sit from a plain, untouched cell.
  ///
  /// This is the test that matters for "I tap a cell and cannot tell what
  /// lit up". The tints form a deliberate ramp — a given is a whisper, a
  /// peer is a clear tint, a same-value cell is clearly stronger again,
  /// and the selection is unmistakable. Before this ramp existed a light
  /// peer cell sat 56 steps from a plain cell and only 12 from a given
  /// cell, so the row/column highlight was invisible in practice.
  const minVisibility = <String, int>{
    'given': 30,
    'peer': 90,
    'sameValue': 150,
    'selected': 230,
    'conflict': 70,
  };

  void assertRamp(String theme, SudokuColors c) {
    group('$theme: every cell state is visible against a plain cell', () {
      test('each state clears its own visibility floor', () {
        final measured = <String, int>{
          'given': _channelDistance(c.cellGiven, c.cellBackground),
          'peer': _channelDistance(c.cellPeer, c.cellBackground),
          'sameValue': _channelDistance(c.cellSameValue, c.cellBackground),
          'selected': _channelDistance(c.cellSelected, c.cellBackground),
          'conflict': _channelDistance(c.cellConflict, c.cellBackground),
        };
        measured.forEach((name, value) {
          expect(
            value,
            greaterThanOrEqualTo(minVisibility[name]!),
            reason: '$theme $name is only $value steps from a plain cell',
          );
        });
      });

      test('the ramp is strictly increasing, so each state outranks the last', () {
        final given = _channelDistance(c.cellGiven, c.cellBackground);
        final peer = _channelDistance(c.cellPeer, c.cellBackground);
        final same = _channelDistance(c.cellSameValue, c.cellBackground);
        final selected = _channelDistance(c.cellSelected, c.cellBackground);
        expect(peer, greaterThan(given));
        expect(same, greaterThan(peer));
        expect(selected, greaterThan(same));
      });

      test('adjacent states are told apart, not just ordered', () {
        // The bug this pins: a peer cell that looks exactly like a given
        // cell. Ordering alone would not have caught it — the two were 12
        // steps apart and both "correct" relative to a plain cell.
        expect(
          _channelDistance(c.cellPeer, c.cellGiven),
          greaterThan(45),
          reason: '$theme peer vs given',
        );
        expect(
          _channelDistance(c.cellSameValue, c.cellPeer),
          greaterThan(55),
          reason: '$theme same-value vs peer',
        );
        expect(
          _channelDistance(c.cellSelected, c.cellSameValue),
          greaterThan(60),
          reason: '$theme selected vs same-value',
        );
        expect(
          _channelDistance(c.cellConflict, c.cellSameValue),
          greaterThan(60),
          reason: '$theme conflict vs same-value',
        );
      });

      test('the selection ring reads against the cell it encircles', () {
        expect(_contrast(c.cellSelectedBorder, c.cellSelected),
            greaterThanOrEqualTo(3.0));
      });
    });
  }

  assertRamp('light mode', light);
  assertRamp('dark mode', dark);

  void assertLegibility(
    String theme,
    SudokuColors c,
    Map<String, Color> backgrounds,
  ) {
    group('$theme grid legibility', () {
      test("the puzzle's own digits read on every cell state", () {
        backgrounds.forEach((name, background) {
          expect(_contrast(c.digitGiven, background),
              greaterThanOrEqualTo(4.5), reason: 'given digit on $name');
        });
      });

      test("the player's digits read on every cell state", () {
        backgrounds.forEach((name, background) {
          expect(_contrast(c.digitEntered, background),
              greaterThanOrEqualTo(4.5), reason: 'entered digit on $name');
        });
      });

      // No exceptions list any more. The selected and conflicting cells
      // used to be the two that could not clear AA; giving each its own
      // digit colour is what removed the compromise.
      test("the selected cell digit reads on the selection fill", () {
        expect(_contrast(c.digitOnSelected, c.cellSelected),
            greaterThanOrEqualTo(4.5));
      });

      test('a wrong digit reads on the conflict wash', () {
        expect(_contrast(c.digitIncorrect, c.cellConflict),
            greaterThanOrEqualTo(4.5));
      });

      test('pencil marks stay readable everywhere they can appear', () {
        // Notes only render in an *empty* cell, so they can never sit on
        // a same-value fill — that state requires a matching digit.
        expect(_contrast(c.noteText, c.cellBackground),
            greaterThanOrEqualTo(4.5), reason: 'notes on a plain cell');
        expect(_contrast(c.noteText, c.cellPeer),
            greaterThanOrEqualTo(4.5), reason: 'notes on a peer cell');
        expect(_contrast(c.digitOnSelected, c.cellSelected),
            greaterThanOrEqualTo(4.5), reason: 'notes on the selected cell');
      });
    });
  }

  assertLegibility('light-mode', light, lightCellBackgrounds);
  assertLegibility('dark-mode', dark, darkCellBackgrounds);

  group('box separators', () {
    test('the box separators read against the cells they divide', () {
      expect(_contrast(light.gridBorder, AppColors.cellBackgroundLight),
          greaterThan(2.0));
      expect(_contrast(dark.gridBorder, AppColors.cellBackgroundDark),
          greaterThan(2.0));
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
