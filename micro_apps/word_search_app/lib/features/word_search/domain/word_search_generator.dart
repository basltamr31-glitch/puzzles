import 'dart:math';

import 'puzzle_theme.dart';
import 'word_search_models.dart';
import 'word_search_scanner.dart';

/// What one difficulty tier actually means.
///
/// Three levers, not one. Grid size alone is the lazy measure — a 14x14
/// grid holding six three-letter words placed left-to-right is easier than
/// an 8x8 one that hides them backwards. The tiers move all three together:
/// the board grows, the list grows, and the set of directions a word may
/// run in opens up.
class WordSearchTier {
  const WordSearchTier({
    required this.id,
    required this.size,
    required this.wordCount,
    required this.directions,
    required this.minWordLength,
    required this.maxWordLength,
    required this.seed,
  });

  final String id;
  final int size;
  final int wordCount;
  final Set<WordDirection> directions;
  final int minWordLength;
  final int maxWordLength;

  /// Fixed per tier so a regeneration reproduces the same content rather
  /// than silently reshuffling every player's puzzle numbering.
  final int seed;
}

/// The shipped tiers.
///
/// | tier   | grid  | words | directions                |
/// | ------ | ----- | ----- | ------------------------- |
/// | easy   | 8x8   | 6     | right, down               |
/// | medium | 10x10 | 8     | + down-right              |
/// | hard   | 12x12 | 10    | + up-right, **backwards** |
/// | expert | 14x14 | 12    | all eight                 |
///
/// "Backwards" is the real difficulty cliff, which is why it arrives at
/// hard and not before: a player scanning for a word reads in one
/// direction, and reversed words defeat that habit entirely.
const wordSearchTiers = <String, WordSearchTier>{
  'easy': WordSearchTier(
    id: 'easy',
    size: 8,
    wordCount: 6,
    directions: {WordDirection.east, WordDirection.south},
    minWordLength: 3,
    maxWordLength: 7,
    seed: 20260101,
  ),
  'medium': WordSearchTier(
    id: 'medium',
    size: 10,
    wordCount: 8,
    directions: {
      WordDirection.east,
      WordDirection.south,
      WordDirection.southEast,
    },
    minWordLength: 3,
    maxWordLength: 9,
    seed: 20260202,
  ),
  'hard': WordSearchTier(
    id: 'hard',
    size: 12,
    wordCount: 10,
    directions: {
      WordDirection.east,
      WordDirection.south,
      WordDirection.southEast,
      WordDirection.northEast,
      WordDirection.west,
    },
    minWordLength: 4,
    maxWordLength: 11,
    seed: 20260303,
  ),
  'expert': WordSearchTier(
    id: 'expert',
    size: 14,
    wordCount: 12,
    directions: {
      WordDirection.east,
      WordDirection.southEast,
      WordDirection.south,
      WordDirection.southWest,
      WordDirection.west,
      WordDirection.northWest,
      WordDirection.north,
      WordDirection.northEast,
    },
    minWordLength: 4,
    maxWordLength: 13,
    seed: 20260404,
  ),
};

/// Builds one playable grid from a themed word list.
///
/// Shared by `tool/generate_puzzles.dart` and the test suite — no Flutter
/// import, so it runs under plain `dart run`.
class WordSearchGenerator {
  const WordSearchGenerator._();

  /// Attempts one puzzle. Returns null when this particular draw could not
  /// be laid out; the caller re-draws rather than the generator looping
  /// forever on a word list that does not fit.
  static WordSearchPuzzleDef? tryGenerate({
    required String id,
    required String language,
    required String difficulty,
    required int index,
    required PuzzleTheme theme,
    required List<String> words,
    required WordSearchTier tier,
    required List<String> fillerAlphabet,
    required Random random,
  }) {
    if (words.length != tier.wordCount) return null;

    final grid = List.generate(
      tier.size,
      (_) => List<String?>.filled(tier.size, null),
      growable: false,
    );

    // Longest first: the long words are the ones with few legal homes, and
    // placing them last is how a generator paints itself into a corner.
    final ordered = [...words]..sort((a, b) => b.length.compareTo(a.length));
    final placements = <WordPlacement>[];

    for (final word in ordered) {
      final placement = _place(word, grid, tier, random);
      if (placement == null) return null;
      placements.add(placement);
    }

    placements.sort((a, b) => a.word.compareTo(b.word));

    // Fill, then verify. A filler letter can accidentally complete a second
    // copy of a listed word, which would let a player select cells that
    // spell the word and be told they are wrong. Refill from scratch rather
    // than patching one cell — a patch can create the next clash.
    for (var attempt = 0; attempt < 40; attempt++) {
      final def = WordSearchPuzzleDef(
        id: id,
        language: language,
        difficulty: difficulty,
        index: index,
        size: tier.size,
        rows: _fill(grid, fillerAlphabet, random),
        placements: placements,
        theme: theme,
      );
      if (WordSearchValidator.validate(def).isValid) return def;
    }
    return null;
  }

  static WordPlacement? _place(
    String word,
    List<List<String?>> grid,
    WordSearchTier tier,
    Random random,
  ) {
    final size = tier.size;
    final candidates = <WordPlacement>[];

    for (final direction in tier.directions) {
      for (var row = 0; row < size; row++) {
        for (var col = 0; col < size; col++) {
          final endRow = row + direction.rowStep * (word.length - 1);
          final endCol = col + direction.colStep * (word.length - 1);
          if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) {
            continue;
          }

          var fits = true;
          for (var i = 0; i < word.length; i++) {
            final existing =
                grid[row + direction.rowStep * i][col + direction.colStep * i];
            if (existing != null && existing != word[i]) {
              fits = false;
              break;
            }
          }
          if (fits) {
            candidates.add(
              WordPlacement(
                word: word,
                row: row,
                col: col,
                direction: direction,
              ),
            );
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    // Prefer placements that cross an already-placed word. Crossings are
    // what make a grid feel woven rather than like a list of stripes, and
    // they leave more empty cells for the words still to come.
    var best = -1;
    final tied = <WordPlacement>[];
    for (final candidate in candidates) {
      final overlap = _overlap(candidate, grid);
      if (overlap > best) {
        best = overlap;
        tied
          ..clear()
          ..add(candidate);
      } else if (overlap == best) {
        tied.add(candidate);
      }
    }
    final chosen = tied[random.nextInt(tied.length)];

    for (var i = 0; i < word.length; i++) {
      grid[chosen.row + chosen.direction.rowStep * i][chosen.col +
          chosen.direction.colStep * i] = word[i];
    }
    return chosen;
  }

  static int _overlap(WordPlacement placement, List<List<String?>> grid) {
    var count = 0;
    for (final (row, col) in placement.cells) {
      if (grid[row][col] != null) count++;
    }
    return count;
  }

  static List<String> _fill(
    List<List<String?>> grid,
    List<String> alphabet,
    Random random,
  ) {
    return [
      for (final row in grid)
        [
          for (final cell in row)
            cell ?? alphabet[random.nextInt(alphabet.length)],
        ].join(),
    ];
  }

  /// Picks [WordSearchTier.wordCount] words from [pool] that can coexist in
  /// one puzzle, or null when the pool cannot supply them.
  ///
  /// The one rule that is not about length: **no word may contain
  /// another**. With CAT and CATS both listed, CAT necessarily appears
  /// twice, and the uniqueness check would reject every grid built from
  /// that pair — after the generator had already spent its retries.
  static List<String>? pickWords({
    required List<String> pool,
    required WordSearchTier tier,
    required Random random,
  }) {
    final eligible =
        pool
            .where(
              (w) =>
                  w.length >= tier.minWordLength &&
                  w.length <= tier.maxWordLength &&
                  w.length <= tier.size,
            )
            .toList()
          ..shuffle(random);

    final chosen = <String>[];
    for (final word in eligible) {
      final clashes = chosen.any(
        (other) => other.contains(word) || word.contains(other),
      );
      if (clashes) continue;
      chosen.add(word);
      if (chosen.length == tier.wordCount) return chosen;
    }
    return null;
  }

  /// The letters empty cells are filled with: every distinct letter the
  /// language's own words use.
  ///
  /// Deliberately derived from the content rather than from a hardcoded
  /// alphabet per language. A Spanish grid padded with letters Spanish
  /// words never contain reads as noise and makes the real words stand
  /// out; the same table would also have to be kept in step with every new
  /// language by hand.
  static List<String> fillerAlphabetFor(Iterable<String> allWords) {
    final letters = <String>{};
    for (final word in allWords) {
      for (var i = 0; i < word.length; i++) {
        letters.add(word[i]);
      }
    }
    return letters.toList()..sort();
  }
}
