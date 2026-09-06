import 'word_search_models.dart';

/// Finds every place a word actually sits in a filled grid.
///
/// Pure Dart with no Flutter import on purpose: `tool/generate_puzzles.dart`
/// runs this under plain `dart run` to reject a bad grid *before* it is
/// written, and the test suite runs the same code over every shipped
/// asset. A second, tool-only copy of these rules is how a puzzle ships
/// with a word the player can never find.
class WordSearchScanner {
  const WordSearchScanner._();

  /// All placements of [word] in [rows], as distinct occupied-cell sets.
  ///
  /// A palindrome laid out east also reads west from its far end — the
  /// same cells, one occurrence. Deduplicating by cell set rather than by
  /// (start, direction) is what keeps "ANNA" from looking like a
  /// duplicate to the uniqueness check below.
  static List<WordPlacement> findAll(List<String> rows, String word) {
    if (word.isEmpty || rows.isEmpty) return const [];
    final size = rows.length;
    final found = <String, WordPlacement>{};

    for (var row = 0; row < size; row++) {
      for (var col = 0; col < rows[row].length; col++) {
        for (final direction in WordDirection.values) {
          final endRow = row + direction.rowStep * (word.length - 1);
          final endCol = col + direction.colStep * (word.length - 1);
          if (endRow < 0 || endRow >= size || endCol < 0 || endCol >= size) {
            continue;
          }

          var matches = true;
          for (var i = 0; i < word.length; i++) {
            final r = row + direction.rowStep * i;
            final c = col + direction.colStep * i;
            if (rows[r][c] != word[i]) {
              matches = false;
              break;
            }
          }
          if (!matches) continue;

          final placement = WordPlacement(
            word: word,
            row: row,
            col: col,
            direction: direction,
          );
          // Sorted cell list as the identity, so a palindrome's two
          // readings collapse into one entry.
          final cells = placement.cells.toList()
            ..sort((a, b) => a.$1 == b.$1 ? a.$2 - b.$2 : a.$1 - b.$1);
          found.putIfAbsent(cells.join('|'), () => placement);
        }
      }
    }

    return found.values.toList(growable: false);
  }

  static int countOccurrences(List<String> rows, String word) =>
      findAll(rows, word).length;
}

/// The result of checking a puzzle against its own grid.
class PuzzleValidation {
  const PuzzleValidation(this.problems);

  final List<String> problems;

  bool get isValid => problems.isEmpty;

  @override
  String toString() => problems.join('\n');
}

/// Checks that a puzzle's word list and its letter grid actually agree.
///
/// Every bundled puzzle is run through this in
/// `test/features/word_search/bundled_puzzles_test.dart`. It is a
/// permanent test, not a throwaway generator script: content is generated,
/// and the only thing standing between a generator bug and an unsolvable
/// shipped puzzle is a check that runs over the real assets.
class WordSearchValidator {
  const WordSearchValidator._();

  static PuzzleValidation validate(WordSearchPuzzleDef def) {
    final problems = <String>[];

    if (def.rows.length != def.size) {
      problems.add('grid has ${def.rows.length} rows, expected ${def.size}');
    }
    for (final row in def.rows) {
      if (row.length != def.size) {
        problems.add('row "$row" is ${row.length} long, expected ${def.size}');
      }
    }
    if (problems.isNotEmpty) return PuzzleValidation(problems);

    final seen = <String>{};
    for (final placement in def.placements) {
      if (!seen.add(placement.word)) {
        problems.add('"${placement.word}" is listed twice');
      }

      for (final (row, col) in placement.cells) {
        if (row < 0 || row >= def.size || col < 0 || col >= def.size) {
          problems.add('"${placement.word}" runs off the grid');
          break;
        }
      }
      if (problems.isNotEmpty && problems.last.endsWith('off the grid')) {
        continue;
      }

      final spelled = [
        for (final (row, col) in placement.cells) def.rows[row][col],
      ].join();
      if (spelled != placement.word) {
        problems.add(
          '"${placement.word}" is placed where the grid spells "$spelled"',
        );
        continue;
      }

      final occurrences = WordSearchScanner.countOccurrences(
        def.rows,
        placement.word,
      );
      if (occurrences != 1) {
        problems.add(
          '"${placement.word}" appears $occurrences times — a listed word '
          'must have exactly one home, or tapping the wrong copy fails',
        );
      }
    }

    return PuzzleValidation(problems);
  }
}
