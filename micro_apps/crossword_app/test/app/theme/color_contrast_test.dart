import 'dart:math' as math;

import 'package:crossword_app/app/theme/app_colors.dart';
import 'package:crossword_app/shared/models/difficulty.dart';
import 'package:crossword_app/shared/models/difficulty_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('light-mode grid legibility', () {
    // The active-word and active-cell tints were deepened to give light
    // mode more colour. Letters sit on top of them, so the deepening must
    // not cost readability.
    test('cell text stays readable on the active word highlight', () {
      expect(
        _contrast(AppColors.textPrimaryLight, AppColors.cellActiveWordLight),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('cell text stays readable on the selected cell highlight', () {
      expect(
        _contrast(AppColors.textPrimaryLight, AppColors.cellActiveCellLight),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('cell text stays readable on a normal cell', () {
      expect(
        _contrast(AppColors.textPrimaryLight, AppColors.cellBackgroundLight),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('the two active highlights are distinguishable from each other', () {
      // Selected cell vs the rest of its word must not look identical, or
      // the player loses track of where typing will land.
      expect(
        _contrast(AppColors.cellActiveWordLight, AppColors.cellActiveCellLight),
        greaterThan(1.2),
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
