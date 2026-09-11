import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_app/features/memory/domain/memory_deck_generator.dart';
import 'package:memory_app/features/memory/domain/memory_models.dart';
import 'package:memory_app/features/memory/domain/memory_theme.dart';

/// Small, obviously-shaped banks: these tests are about the generator's
/// rules, and real emoji in the expectations would make a failure message
/// unreadable in a terminal.
///
/// animals and food are large enough for every tier; nature and travel
/// are deliberately too small for the single-theme ones, which is what
/// the bank-size rule below is measured against.
final _banks = <MemoryTheme, List<String>>{
  MemoryTheme.animals: [for (var i = 1; i <= 16; i++) 'a$i'],
  MemoryTheme.food: [for (var i = 1; i <= 16; i++) 'f$i'],
  MemoryTheme.nature: const ['n1', 'n2', 'n3', 'n4'],
  MemoryTheme.travel: const ['t1', 't2', 't3', 't4'],
};

MemoryDeckGenerator _generator([int seed = 7]) =>
    MemoryDeckGenerator(symbolsByTheme: _banks, random: Random(seed));

bool _hasAdjacentPair(MemoryDeckDef deck) {
  for (var row = 0; row < deck.rows; row++) {
    for (var col = 0; col < deck.cols; col++) {
      final symbol = deck.cards[row * deck.cols + col];
      if (col + 1 < deck.cols &&
          deck.cards[row * deck.cols + col + 1] == symbol) {
        return true;
      }
      if (row + 1 < deck.rows &&
          deck.cards[(row + 1) * deck.cols + col] == symbol) {
        return true;
      }
    }
  }
  return false;
}

void main() {
  group('the shipped tiers', () {
    test('every tier deals an even number of cards', () {
      for (final tier in memoryTiers.values) {
        expect(
          tier.cardCount.isEven,
          isTrue,
          reason: '${tier.id} deals ${tier.cardCount} cards',
        );
      }
    });

    test('pair count rises with every tier', () {
      final counts = [
        for (final id in ['easy', 'medium', 'hard', 'expert'])
          memoryTiers[id]!.pairCount,
      ];
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThan(counts[i - 1]));
      }
    });

    test('boards are portrait, because phones are', () {
      // A tier that deals wider than it is tall would shrink every card
      // to a thumbnail on the device almost everyone plays on.
      for (final tier in memoryTiers.values) {
        expect(
          tier.rows,
          greaterThanOrEqualTo(tier.cols),
          reason: '${tier.id} is ${tier.rows}x${tier.cols}',
        );
      }
    });

    test('the difficulty story is size *and* symbol similarity', () {
      // The second lever, pinned so it cannot be quietly dropped back to
      // "bigger board, same idea": the two hard tiers draw every symbol
      // from one family, and the two gentle ones deliberately do not.
      expect(memoryTiers['easy']!.singleTheme, isFalse);
      expect(memoryTiers['medium']!.singleTheme, isFalse);
      expect(memoryTiers['hard']!.singleTheme, isTrue);
      expect(memoryTiers['expert']!.singleTheme, isTrue);
    });
  });

  group('generate', () {
    test('deals exactly two of every symbol, filling the board', () {
      final tier = memoryTiers['medium']!;
      final deck = _generator().generate(tier: tier, index: 3);

      expect(deck.cards.length, tier.cardCount);
      expect(deck.rows, tier.rows);
      expect(deck.cols, tier.cols);
      final counts = <String, int>{};
      for (final symbol in deck.cards) {
        counts[symbol] = (counts[symbol] ?? 0) + 1;
      }
      expect(counts.values.every((c) => c == 2), isTrue);
      expect(counts.length, tier.pairCount);
    });

    test('numbers the deck from its index', () {
      final deck = _generator().generate(tier: memoryTiers['easy']!, index: 6);
      expect(deck.id, 'easy_007');
      expect(deck.index, 6);
      expect(deck.difficulty, 'easy');
    });

    test('never leaves a pair in two adjacent cells', () {
      // A pair dealt side by side is found by accident on the first two
      // taps, which on a six-pair board is a third of the game gone
      // before it started. Run across many seeds because a single lucky
      // deal proves nothing.
      for (var seed = 0; seed < 60; seed++) {
        for (final tier in memoryTiers.values) {
          final deck = MemoryDeckGenerator(
            symbolsByTheme: _banks,
            random: Random(seed),
          ).generate(tier: tier, index: 0);
          expect(
            _hasAdjacentPair(deck),
            isFalse,
            reason: 'seed $seed, tier ${tier.id}',
          );
        }
      }
    });

    test('the same seed reproduces the same deck', () {
      // Regeneration must not silently reshuffle every player's deck
      // numbering — a saved game is keyed to a deal, not just an id.
      final a = _generator(99).generate(tier: memoryTiers['hard']!, index: 0);
      final b = _generator(99).generate(tier: memoryTiers['hard']!, index: 0);
      expect(a.cards, b.cards);
      expect(a.theme, b.theme);
    });

    test('different seeds produce different deals', () {
      final a = _generator(1).generate(tier: memoryTiers['hard']!, index: 0);
      final b = _generator(2).generate(tier: memoryTiers['hard']!, index: 0);
      expect(a.cards, isNot(b.cards));
    });
  });

  group('symbol selection', () {
    test('a single-theme deck draws every symbol from one bank', () {
      for (var seed = 0; seed < 25; seed++) {
        final deck = MemoryDeckGenerator(
          symbolsByTheme: _banks,
          random: Random(seed),
        ).generate(tier: memoryTiers['hard']!, index: 0);

        expect(deck.theme, isNotNull);
        final bank = _banks[deck.theme]!;
        expect(
          deck.cards.every(bank.contains),
          isTrue,
          reason: 'seed $seed drew outside ${deck.theme!.id}',
        );
      }
    });

    test('a single-theme deck only picks a bank big enough for the tier', () {
      // nature and travel hold four symbols each, so neither can fill a
      // 12-pair board — picking one would deal duplicates or throw.
      for (var seed = 0; seed < 25; seed++) {
        final deck = MemoryDeckGenerator(
          symbolsByTheme: _banks,
          random: Random(seed),
        ).generate(tier: memoryTiers['hard']!, index: 0);
        expect(deck.theme, isNot(MemoryTheme.nature));
        expect(deck.theme, isNot(MemoryTheme.travel));
      }
    });

    test('a mixed deck takes at most two symbols from any one theme', () {
      // The cap is the whole point of the gentle tiers: drawing freely
      // from a pooled list regularly produced four animals and two of
      // everything else, which is the "everything looks alike" difficulty
      // those tiers exist to avoid.
      for (var seed = 0; seed < 25; seed++) {
        final deck = MemoryDeckGenerator(
          symbolsByTheme: _banks,
          random: Random(seed),
        ).generate(tier: memoryTiers['medium']!, index: 0);

        final perTheme = <MemoryTheme, int>{};
        for (final symbol in deck.cards.toSet()) {
          final theme = _banks.entries
              .firstWhere((e) => e.value.contains(symbol))
              .key;
          perTheme[theme] = (perTheme[theme] ?? 0) + 1;
        }
        expect(
          perTheme.values.every((count) => count <= 2),
          isTrue,
          reason: 'seed $seed drew $perTheme',
        );
      }
    });

    test('a mixed deck carries no theme label', () {
      final deck = _generator().generate(tier: memoryTiers['easy']!, index: 0);
      // Naming it after whichever theme happened to contribute first
      // would be a lie on the puzzle-list row.
      expect(deck.theme, isNull);
    });

    test('gives up loudly when no bank can fill the tier', () {
      final generator = MemoryDeckGenerator(
        symbolsByTheme: const {
          MemoryTheme.animals: ['a1', 'a2'],
        },
        random: Random(1),
      );
      expect(
        () => generator.generate(tier: memoryTiers['expert']!, index: 0),
        throwsA(isA<DeckGenerationException>()),
      );
    });
  });

  group('MemoryDeckValidator', () {
    const validator = MemoryDeckValidator();

    test('passes a deck the generator built', () {
      final deck = _generator().generate(tier: memoryTiers['easy']!, index: 0);
      expect(validator.validate(deck), isEmpty);
    });

    test('catches a symbol that is not paired', () {
      const deck = MemoryDeckDef(
        id: 'easy_001',
        difficulty: 'easy',
        index: 0,
        rows: 4,
        cols: 3,
        cards: ['a', 'b', 'c', 'd', 'a', 'b', 'c', 'd', 'e', 'f', 'e', 'g'],
      );
      expect(validator.validate(deck), isNotEmpty);
    });

    test('catches a pair dealt into adjacent cells', () {
      const deck = MemoryDeckDef(
        id: 'easy_001',
        difficulty: 'easy',
        index: 0,
        rows: 4,
        cols: 3,
        cards: ['a', 'a', 'b', 'c', 'd', 'b', 'c', 'd', 'e', 'f', 'e', 'f'],
      );
      expect(
        validator.validate(deck).join(),
        contains('adjacent'),
      );
    });

    test('catches a board that is not the shape its tier declares', () {
      const deck = MemoryDeckDef(
        id: 'easy_001',
        difficulty: 'easy',
        index: 0,
        rows: 2,
        cols: 2,
        cards: ['a', 'b', 'b', 'a'],
      );
      expect(validator.validate(deck).join(), contains('easy tier'));
    });
  });

  group('MemoryDeckDef.fromJson', () {
    test('refuses a deck whose symbols are not all paired', () {
      // The app's own gate: such a deck can never be completed, and a
      // player would only discover that after finding every other pair.
      expect(
        () => MemoryDeckDef.fromJson(const {
          'id': 'easy_001',
          'difficulty': 'easy',
          'index': 0,
          'rows': 2,
          'cols': 2,
          'cards': ['a', 'a', 'b', 'c'],
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('refuses a card list that does not fill the board', () {
      expect(
        () => MemoryDeckDef.fromJson(const {
          'id': 'easy_001',
          'difficulty': 'easy',
          'index': 0,
          'rows': 4,
          'cols': 3,
          'cards': ['a', 'a'],
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('plays a deck whose theme this build does not know', () {
      // Shipping new themed content must never hard-fail an older app
      // version — it simply shows the generic title.
      final deck = MemoryDeckDef.fromJson(const {
        'id': 'easy_001',
        'difficulty': 'easy',
        'index': 0,
        'theme': 'dinosaurs',
        'rows': 2,
        'cols': 2,
        'cards': ['a', 'b', 'b', 'a'],
      });
      expect(deck.theme, isNull);
      expect(deck.pairCount, 2);
    });

    test('round-trips through toJson', () {
      final deck = _generator().generate(tier: memoryTiers['hard']!, index: 4);
      expect(MemoryDeckDef.fromJson(deck.toJson()), deck);
    });
  });

  group('deckFingerprint', () {
    test('changes when the deal changes', () {
      expect(
        deckFingerprint(const ['a', 'b', 'b', 'a']),
        isNot(deckFingerprint(const ['b', 'a', 'b', 'a'])),
      );
    });

    test('is stable for the same deal', () {
      expect(
        deckFingerprint(const ['a', 'b', 'b', 'a']),
        deckFingerprint(const ['a', 'b', 'b', 'a']),
      );
    });

    test('does not collide on symbols that concatenate the same way', () {
      // The reason the symbols are joined with a separator: without one,
      // ["ab", "c"] and ["a", "bc"] hash identically, and emoji really do
      // vary in code-unit length.
      expect(
        deckFingerprint(const ['ab', 'c']),
        isNot(deckFingerprint(const ['a', 'bc'])),
      );
    });
  });
}
