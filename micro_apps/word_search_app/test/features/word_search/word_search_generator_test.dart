import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/features/word_search/domain/puzzle_theme.dart';
import 'package:word_search_app/features/word_search/domain/word_search_generator.dart';
import 'package:word_search_app/features/word_search/domain/word_search_scanner.dart';

void main() {
  group('WordSearchGenerator.pickWords', () {
    test('excludes words that are substrings of each other', () {
      // CAT and CATS can never coexist: CAT would necessarily appear
      // twice (once on its own, once inside CATS), which fails the
      // one-occurrence-per-word rule every shipped puzzle is held to.
      final words = WordSearchGenerator.pickWords(
        // 7 candidates for a 6-word tier: CAT/CATS conflict costs one of
        // them, and FROG is there to still leave 6 eligible afterwards.
        pool: ['CAT', 'CATS', 'DOG', 'BIRD', 'FISH', 'LION', 'FROG'],
        tier: wordSearchTiers['easy']!,
        random: Random(1),
      );
      expect(words, isNotNull);
      expect(words!.contains('CAT') && words.contains('CATS'), isFalse);
    });

    test('respects the tier\'s length window', () {
      final tier = wordSearchTiers['easy']!;
      final words = WordSearchGenerator.pickWords(
        // 'A' and 'AB' are too short and SUPERCALIFRAGILISTIC is too long
        // for the easy tier; the other six sit inside its window.
        pool: [
          'A',
          'AB',
          'CAT',
          'DOG',
          'BIRD',
          'FISH',
          'LION',
          'FROG',
          'SUPERCALIFRAGILISTIC',
        ],
        tier: tier,
        random: Random(1),
      );
      expect(words, isNotNull);
      for (final word in words!) {
        expect(word.length, greaterThanOrEqualTo(tier.minWordLength));
        expect(word.length, lessThanOrEqualTo(tier.maxWordLength));
      }
    });

    test('returns null when the pool cannot supply enough words', () {
      final words = WordSearchGenerator.pickWords(
        pool: ['CAT', 'DOG'],
        tier: wordSearchTiers['easy']!,
        random: Random(1),
      );
      expect(words, isNull);
    });
  });

  group('WordSearchGenerator.tryGenerate', () {
    test('produces a puzzle where every word validates against its grid', () {
      final tier = wordSearchTiers['easy']!;
      final words = ['CAT', 'DOG', 'BIRD', 'FISH', 'LION', 'FROG'];
      final alphabet = WordSearchGenerator.fillerAlphabetFor(words);

      final def = WordSearchGenerator.tryGenerate(
        id: 'test',
        language: 'en',
        difficulty: 'easy',
        index: 0,
        theme: PuzzleTheme.animals,
        words: words,
        tier: tier,
        fillerAlphabet: alphabet,
        random: Random(42),
      );

      expect(def, isNotNull);
      expect(def!.placements.length, words.length);
      final validation = WordSearchValidator.validate(def);
      expect(validation.isValid, isTrue, reason: '$validation');
    });

    test('returns null when the word count does not match the tier', () {
      final tier = wordSearchTiers['easy']!;
      final def = WordSearchGenerator.tryGenerate(
        id: 'test',
        language: 'en',
        difficulty: 'easy',
        index: 0,
        theme: PuzzleTheme.animals,
        words: ['CAT', 'DOG'],
        tier: tier,
        fillerAlphabet: const ['A', 'B', 'C'],
        random: Random(1),
      );
      expect(def, isNull);
    });
  });

  group('WordSearchGenerator.fillerAlphabetFor', () {
    test('collects every distinct letter across the given words', () {
      final alphabet = WordSearchGenerator.fillerAlphabetFor(['CAT', 'DOG']);
      expect(alphabet.toSet(), {'C', 'A', 'T', 'D', 'O', 'G'});
    });
  });
}
