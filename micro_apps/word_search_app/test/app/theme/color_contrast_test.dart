import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/app/theme/app_colors.dart';
import 'package:word_search_app/app/theme/word_search_colors.dart';
import 'package:word_search_app/shared/models/difficulty.dart';
import 'package:word_search_app/shared/models/difficulty_presentation.dart';

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
/// different colour". See sudoku_app's CLAUDE.md for the incident this
/// pattern comes from.
int _channelDistance(Color a, Color b) {
  int ch(double x, double y) => ((x - y).abs() * 255).round();
  return ch(a.r, b.r) + ch(a.g, b.g) + ch(a.b, b.b);
}

/// The grid is the whole game, and every cell state tints its background.
/// A letter that stops being readable on one of those tints is a real bug
/// no widget test would catch — so the palette is asserted directly.
void main() {
  const light = WordSearchColors.light;
  const dark = WordSearchColors.dark;

  group('light-mode grid legibility', () {
    test('unclaimed letters read on every cell state', () {
      for (final entry in <String, Color>{
        'normal cell': light.cellBackground,
        'live selection': light.cellSelected,
      }.entries) {
        expect(
          _contrast(light.letterText, entry.value),
          greaterThanOrEqualTo(4.5),
          reason: entry.key,
        );
      }
    });

    test('a found word\'s letters read on the found tint', () {
      expect(
        _contrast(light.foundLetterText, light.cellFound),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('dark-mode grid legibility', () {
    test('unclaimed letters read on every cell state', () {
      for (final entry in <String, Color>{
        'normal cell': dark.cellBackground,
        'live selection': dark.cellSelected,
      }.entries) {
        expect(
          _contrast(dark.letterText, entry.value),
          greaterThanOrEqualTo(4.5),
          reason: entry.key,
        );
      }
    });

    test('a found word\'s letters read on the found tint', () {
      expect(
        _contrast(dark.foundLetterText, dark.cellFound),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('cell states are distinguishable from each other', () {
    // A live selection, a found word, and a wrong-guess flash are three
    // different messages. If two of them look alike the highlight means
    // nothing.
    test('light mode: selected, found, and background are visibly different', () {
      expect(
        _channelDistance(AppColors.cellSelectedLight, AppColors.cellFoundLight),
        greaterThan(60),
      );
      expect(
        _channelDistance(AppColors.cellSelectedLight, AppColors.cellBackgroundLight),
        greaterThan(60),
      );
      expect(
        _channelDistance(AppColors.cellFoundLight, AppColors.cellBackgroundLight),
        greaterThan(40),
      );
      expect(
        _channelDistance(AppColors.wrongSelectionLight, AppColors.cellSelectedLight),
        greaterThan(60),
      );
    });

    test('dark mode: selected, found, and background are visibly different', () {
      expect(
        _channelDistance(AppColors.cellSelectedDark, AppColors.cellFoundDark),
        greaterThan(60),
      );
      expect(
        _channelDistance(AppColors.cellFoundDark, AppColors.cellBackgroundDark),
        greaterThan(40),
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
