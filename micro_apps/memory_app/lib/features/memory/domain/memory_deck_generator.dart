import 'dart:math';

import 'memory_models.dart';
import 'memory_theme.dart';

/// What one difficulty tier actually means.
///
/// Two levers, not one. Pair count alone is the lazy measure — a 15-pair
/// board of a dog, a plane, a pizza and a trumpet is easier to hold in
/// your head than an 8-pair board of eight different birds. So the tiers
/// move the board size *and* how alike the symbols on it are.
class MemoryTier {
  const MemoryTier({
    required this.id,
    required this.rows,
    required this.cols,
    required this.singleTheme,
    required this.seed,
  });

  final String id;
  final int rows;
  final int cols;

  /// When true every symbol on the board comes from one theme, so the
  /// cards look like siblings and the player has to remember *which*
  /// bird, not just "a bird". When false the symbols are spread across
  /// themes, at most two per theme, which is what keeps the early tiers
  /// genuinely gentle.
  final bool singleTheme;

  /// Fixed per tier so a regeneration reproduces the same content rather
  /// than silently reshuffling every player's deck numbering.
  final int seed;

  int get cardCount => rows * cols;
  int get pairCount => cardCount ~/ 2;
}

/// The shipped tiers.
///
/// | tier   | board | pairs | symbols        |
/// | ------ | ----- | ----- | -------------- |
/// | easy   | 4x3   | 6     | mixed themes   |
/// | medium | 4x4   | 8     | mixed themes   |
/// | hard   | 6x4   | 12    | one theme      |
/// | expert | 6x5   | 15    | one theme      |
///
/// Boards are taller than they are wide because phones are: a 5x6 board
/// laid out landscape would shrink every card to a thumbnail on the
/// device almost everyone plays on.
const memoryTiers = <String, MemoryTier>{
  'easy': MemoryTier(
    id: 'easy',
    rows: 4,
    cols: 3,
    singleTheme: false,
    seed: 20260401,
  ),
  'medium': MemoryTier(
    id: 'medium',
    rows: 4,
    cols: 4,
    singleTheme: false,
    seed: 20260402,
  ),
  'hard': MemoryTier(
    id: 'hard',
    rows: 6,
    cols: 4,
    singleTheme: true,
    seed: 20260403,
  ),
  'expert': MemoryTier(
    id: 'expert',
    rows: 6,
    cols: 5,
    singleTheme: true,
    seed: 20260404,
  ),
};

/// Raised when a deck cannot be built from the symbols on hand — a bank
/// too small for the tier, or a shuffle that never satisfied the layout
/// rule. Generation-time only: it can never reach a player, because
/// `tool/generate_puzzles.dart` fails the build instead of writing the
/// asset.
class DeckGenerationException implements Exception {
  const DeckGenerationException(this.message);
  final String message;
  @override
  String toString() => 'DeckGenerationException: $message';
}

/// Builds decks from symbol banks.
///
/// Pure Dart with no Flutter import, so `tool/generate_puzzles.dart` can run
/// it under plain `dart run` — the generator and the app share one engine
/// rather than keeping two implementations of the layout rules that can
/// drift apart.
class MemoryDeckGenerator {
  MemoryDeckGenerator({required this.symbolsByTheme, Random? random})
    : _random = random ?? Random();

  /// One symbol list per theme. Symbols are emoji, and the app renders
  /// them straight from the deck — nothing here is translated.
  final Map<MemoryTheme, List<String>> symbolsByTheme;

  final Random _random;

  /// How many shuffles to try before giving up on the layout rule.
  ///
  /// A random deal puts some pair side by side about four times out of
  /// five, so a handful of retries is the normal case; the cap only
  /// exists so a bad bank can't hang the generator forever.
  static const int _maxLayoutAttempts = 200;

  MemoryDeckDef generate({required MemoryTier tier, required int index}) {
    final symbols = tier.singleTheme
        ? _pickSingleThemeSymbols(tier.pairCount)
        : _pickMixedSymbols(tier.pairCount);

    final cards = _deal(symbols.symbols, rows: tier.rows, cols: tier.cols);

    return MemoryDeckDef(
      id: '${tier.id}_${(index + 1).toString().padLeft(3, '0')}',
      difficulty: tier.id,
      index: index,
      rows: tier.rows,
      cols: tier.cols,
      cards: cards,
      theme: symbols.theme,
    );
  }

  ({List<String> symbols, MemoryTheme? theme}) _pickSingleThemeSymbols(
    int pairCount,
  ) {
    final candidates = symbolsByTheme.entries
        .where((e) => e.value.length >= pairCount)
        .toList();
    if (candidates.isEmpty) {
      throw DeckGenerationException(
        'No theme has $pairCount symbols to draw from.',
      );
    }
    final chosen = candidates[_random.nextInt(candidates.length)];
    final pool = [...chosen.value]..shuffle(_random);
    return (symbols: pool.take(pairCount).toList(), theme: chosen.key);
  }

  /// Symbols spread across themes, **at most two per theme**.
  ///
  /// The cap is the whole point: drawing six symbols freely from a pooled
  /// list regularly produced four animals and two of everything else,
  /// which is exactly the "everything looks alike" difficulty the mixed
  /// tiers are supposed to avoid.
  ({List<String> symbols, MemoryTheme? theme}) _pickMixedSymbols(
    int pairCount,
  ) {
    final themes = symbolsByTheme.keys.toList()..shuffle(_random);
    final pools = {
      for (final theme in themes) theme: [...symbolsByTheme[theme]!]
        ..shuffle(_random),
    };

    final picked = <String>[];
    // Two passes over the shuffled theme order: one symbol from each
    // theme, then a second from each, until the deck is full.
    for (var round = 0; round < 2 && picked.length < pairCount; round++) {
      for (final theme in themes) {
        if (picked.length == pairCount) break;
        final pool = pools[theme]!;
        if (pool.isEmpty) continue;
        picked.add(pool.removeLast());
      }
    }

    if (picked.length < pairCount) {
      throw DeckGenerationException(
        'Only ${picked.length} symbols available for a $pairCount-pair '
        'deck at two per theme.',
      );
    }
    // No theme label: a mixed deck is not "about" anything, and naming it
    // after whichever theme happened to contribute first would be a lie
    // on the puzzle-list row.
    return (symbols: picked, theme: null);
  }

  /// Lays two of each symbol onto the board so that **no pair sits in
  /// orthogonally adjacent cells**.
  ///
  /// A pair dealt side by side is found by accident on the first two taps,
  /// which on a six-pair board is a third of the game gone before it
  /// started. Rejecting the whole deal rather than swapping the offending
  /// card keeps this honest: a swap can create the collision it was meant
  /// to fix, and only a full re-check would know.
  List<String> _deal(
    List<String> symbols, {
    required int rows,
    required int cols,
  }) {
    final deck = [
      for (final symbol in symbols) ...[symbol, symbol],
    ];

    for (var attempt = 0; attempt < _maxLayoutAttempts; attempt++) {
      deck.shuffle(_random);
      if (!_hasAdjacentPair(deck, rows: rows, cols: cols)) {
        return List<String>.unmodifiable(deck);
      }
    }
    throw DeckGenerationException(
      'Could not lay out a ${rows}x$cols board with no adjacent pair in '
      '$_maxLayoutAttempts attempts.',
    );
  }

  static bool _hasAdjacentPair(
    List<String> cards, {
    required int rows,
    required int cols,
  }) {
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final symbol = cards[row * cols + col];
        if (col + 1 < cols && cards[row * cols + col + 1] == symbol) {
          return true;
        }
        if (row + 1 < rows && cards[(row + 1) * cols + col] == symbol) {
          return true;
        }
      }
    }
    return false;
  }
}

/// Validation that a shipped deck is actually playable, run by the
/// generator before an asset is written and again by
/// `bundled_decks_test.dart` against what was written.
///
/// [MemoryDeckDef.fromJson] already refuses a deck whose symbols are not
/// all paired; this adds the rules that are about *quality* rather than
/// correctness, which the app cannot enforce at load time without
/// refusing content it could otherwise play.
class MemoryDeckValidator {
  const MemoryDeckValidator();

  /// Returns the problems with [deck] — empty means it is fit to ship.
  List<String> validate(MemoryDeckDef deck) {
    final problems = <String>[];

    if (deck.cardCount.isOdd) {
      problems.add('board holds an odd number of cards');
    }
    if (deck.cards.length != deck.rows * deck.cols) {
      problems.add('card count does not match the ${deck.rows}x${deck.cols} board');
    }

    final counts = <String, int>{};
    for (final symbol in deck.cards) {
      counts[symbol] = (counts[symbol] ?? 0) + 1;
    }
    for (final entry in counts.entries) {
      if (entry.value != 2) {
        problems.add('"${entry.key}" appears ${entry.value} times, not twice');
      }
    }
    if (counts.length != deck.pairCount) {
      problems.add(
        'deck has ${counts.length} distinct symbols for ${deck.pairCount} pairs',
      );
    }

    if (MemoryDeckGenerator._hasAdjacentPair(
      deck.cards,
      rows: deck.rows,
      cols: deck.cols,
    )) {
      problems.add('a pair sits in two adjacent cells');
    }

    final tier = memoryTiers[deck.difficulty];
    if (tier == null) {
      problems.add('unknown difficulty "${deck.difficulty}"');
    } else if (deck.rows != tier.rows || deck.cols != tier.cols) {
      problems.add(
        'board is ${deck.rows}x${deck.cols}, but the ${tier.id} tier is '
        '${tier.rows}x${tier.cols}',
      );
    }

    return problems;
  }
}
