import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_app/app/theme/app_colors.dart';
import 'package:memory_app/app/theme/memory_colors.dart';
import 'package:memory_app/shared/models/difficulty.dart';
import 'package:memory_app/shared/models/difficulty_presentation.dart';

/// WCAG relative luminance.
double _luminance(Color c) {
  double channel(double v) {
    return v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
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
/// The right tool for "can a player tell these two cards apart", which
/// WCAG contrast is not: two colours of the same lightness but different
/// hue score ~1.0 on contrast while being obviously different to look at.
/// Contrast answers "can I read this on that"; distance answers "is this
/// a different colour".
int _channelDistance(Color a, Color b) {
  int ch(double x, double y) => ((x - y).abs() * 255).round();
  return ch(a.r, b.r) + ch(a.g, b.g) + ch(a.b, b.b);
}

/// The board is the whole game, and a card's state is carried entirely by
/// its colour — there is no label saying "matched" or "wrong". A state
/// that stops being distinguishable is a real bug that no widget test
/// would catch, so the palette is asserted directly.
void main() {
  const light = MemoryColors.light;
  const dark = MemoryColors.dark;

  /// How far each card state must sit from a revealed, undecided card.
  ///
  /// The face is the reference rather than "a plain cell" (as in the
  /// sudoku app) because every state here is a *change to a card the
  /// player is already looking at* — except the back, which is the state
  /// they are looking away from, and which therefore has by far the
  /// largest floor.
  const minVisibility = <String, int>{
    'back': 120,
    'matched': 45,
    'mismatch': 60,
  };

  void assertStates(String theme, MemoryColors c) {
    group('$theme: every card state is visible against a revealed card', () {
      test('each state clears its own visibility floor', () {
        final measured = <String, int>{
          'back': _channelDistance(c.cardBack, c.cardFace),
          'matched': _channelDistance(c.cardMatched, c.cardFace),
          'mismatch': _channelDistance(c.cardMismatch, c.cardFace),
        };
        measured.forEach((name, value) {
          expect(
            value,
            greaterThanOrEqualTo(minVisibility[name]!),
            reason: '$theme $name is only $value steps from a card face',
          );
        });
      });

      test('matched and mismatched are told apart, not just both tinted', () {
        // The bug this pins: a mismatch flash the player reads as a match
        // because both states are "the card went a slightly different
        // colour". These are the two states with opposite meanings and
        // under a second of overlap in which to tell them apart.
        expect(
          _channelDistance(c.cardMatched, c.cardMismatch),
          greaterThan(70),
          reason: '$theme matched vs mismatched',
        );
      });

      test('a face-down card is unmistakably not a face-up one', () {
        // Contrast as well as distance: at a glance across a board, the
        // back has to separate from the face in brightness too, or a
        // half-solved board reads as visual noise.
        expect(_contrast(c.cardBack, c.cardFace), greaterThanOrEqualTo(2.0));
      });

      test('the state borders read against the fills they outline', () {
        expect(
          _contrast(c.cardMatchedBorder, c.cardMatched),
          greaterThanOrEqualTo(3.0),
          reason: '$theme matched border',
        );
        expect(
          _contrast(c.cardMismatchBorder, c.cardMismatch),
          greaterThanOrEqualTo(3.0),
          reason: '$theme mismatch border',
        );
      });

      test('the motif on the card back reads against the back', () {
        // The motif is what stops a face-down board from being a grid of
        // flat rectangles, so it has to actually be visible — this is a
        // non-text element, hence the 3.0 floor rather than 4.5.
        expect(
          _contrast(c.cardBackPattern, c.cardBack),
          greaterThanOrEqualTo(3.0),
        );
      });

      test('text on a card reads on every face a card can wear', () {
        for (final entry in <String, Color>{
          'a revealed card': c.cardFace,
          'a matched card': c.cardMatched,
          'a mismatched card': c.cardMismatch,
        }.entries) {
          expect(
            _contrast(c.cardLabel, entry.value),
            greaterThanOrEqualTo(4.5),
            reason: 'card text on ${entry.key}',
          );
        }
      });
    });
  }

  assertStates('light mode', light);
  assertStates('dark mode', dark);

  group('the board surface', () {
    test('the felt is distinguishable from the cards lying on it', () {
      // Not a big distance — the board is meant to recede — but a board
      // that is *exactly* the card face colour loses the edges of every
      // card in the top row.
      expect(
        _channelDistance(light.boardBackground, light.cardFace),
        greaterThan(20),
      );
      expect(
        _channelDistance(dark.boardBackground, dark.cardFace),
        greaterThan(20),
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

  group('page text', () {
    test('secondary text clears AA on both page backgrounds', () {
      // The warm greys this app uses instead of the sudoku app's slate
      // are the easiest token to nudge one shade too pale.
      expect(
        _contrast(AppColors.textSecondaryLight, AppColors.backgroundLight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(AppColors.textSecondaryDark, AppColors.backgroundDark),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('primary text clears AA on both page backgrounds', () {
      expect(
        _contrast(AppColors.textPrimaryLight, AppColors.backgroundLight),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(AppColors.textPrimaryDark, AppColors.backgroundDark),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
