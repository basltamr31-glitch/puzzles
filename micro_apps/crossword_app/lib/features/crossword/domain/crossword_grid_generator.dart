import '../../../core/errors/app_exception.dart';
import 'crossword_models.dart';

/// Derives a playable [CrosswordGrid] from a [CrosswordPuzzleDef].
///
/// This is the only place grid shape, blocked cells, and clue numbering
/// are computed — puzzle JSON never states them directly, which makes it
/// structurally impossible for content to specify letters and a blocked
/// map that disagree with each other. Any inconsistency (out-of-bounds
/// word, conflicting overlapping letters, too-short word) surfaces as an
/// [InvalidPuzzleException] rather than a silently wrong grid.
class CrosswordGridGenerator {
  const CrosswordGridGenerator._();

  static CrosswordGrid generate(CrosswordPuzzleDef def) {
    if (def.rows <= 0 || def.cols <= 0) {
      throw InvalidPuzzleException(
        'Puzzle "${def.id}" has an invalid grid size.',
      );
    }

    // solutionLetters[row][col] == null means "blocked" until a word
    // claims that cell.
    final solutionLetters = List.generate(
      def.rows,
      (_) => List<String?>.filled(def.cols, null),
    );

    for (final word in def.words) {
      if (word.length < 2) {
        throw InvalidPuzzleException(
          'Puzzle "${def.id}" has a word shorter than 2 letters ("${word.answer}").',
        );
      }

      final endRow = word.direction == WordDirection.down
          ? word.row + word.length - 1
          : word.row;
      final endCol = word.direction == WordDirection.across
          ? word.col + word.length - 1
          : word.col;

      if (word.row < 0 ||
          word.col < 0 ||
          endRow >= def.rows ||
          endCol >= def.cols) {
        throw InvalidPuzzleException(
          'Puzzle "${def.id}" has a word ("${word.answer}") that falls outside the ${def.rows}x${def.cols} grid.',
        );
      }

      for (var i = 0; i < word.length; i++) {
        final r = word.direction == WordDirection.down
            ? word.row + i
            : word.row;
        final c = word.direction == WordDirection.across
            ? word.col + i
            : word.col;
        final letter = word.answer[i];
        final existing = solutionLetters[r][c];
        if (existing != null && existing != letter) {
          throw InvalidPuzzleException(
            'Puzzle "${def.id}" has conflicting letters at row $r, col $c '
            '("$existing" vs "$letter").',
          );
        }
        solutionLetters[r][c] = letter;
      }
    }

    final numberByCell = _computeClueNumbers(def);

    final cells = List.generate(def.rows, (r) {
      return List.generate(def.cols, (c) {
        final letter = solutionLetters[r][c];
        return CrosswordCell(
          row: r,
          col: c,
          isBlocked: letter == null,
          solutionLetter: letter,
          clueNumber: numberByCell['$r,$c'],
        );
      });
    });

    final acrossClues = <CrosswordClue>[];
    final downClues = <CrosswordClue>[];

    for (final word in def.words) {
      final number = numberByCell['${word.row},${word.col}']!;
      final wordCells = List.generate(word.length, (i) {
        final r = word.direction == WordDirection.down
            ? word.row + i
            : word.row;
        final c = word.direction == WordDirection.across
            ? word.col + i
            : word.col;
        return (r, c);
      });
      final clue = CrosswordClue(
        number: number,
        direction: word.direction,
        clue: word.clue,
        answer: word.answer,
        cells: wordCells,
        category: word.category,
      );
      if (word.direction == WordDirection.across) {
        acrossClues.add(clue);
      } else {
        downClues.add(clue);
      }
    }

    acrossClues.sort((a, b) => a.number.compareTo(b.number));
    downClues.sort((a, b) => a.number.compareTo(b.number));

    return CrosswordGrid(
      puzzleId: def.id,
      language: def.language,
      title: def.title,
      rows: def.rows,
      cols: def.cols,
      cells: cells,
      acrossClues: acrossClues,
      downClues: downClues,
    );
  }

  /// Standard crossword numbering: scan non-blocked cells row-major; a
  /// cell gets the next number if it is the start of an across and/or
  /// down word (shared by both if it starts both).
  static Map<String, int> _computeClueNumbers(CrosswordPuzzleDef def) {
    final starts = <String>{};
    for (final word in def.words) {
      starts.add('${word.row},${word.col}');
    }

    final numberByCell = <String, int>{};
    var next = 1;
    for (var r = 0; r < def.rows; r++) {
      for (var c = 0; c < def.cols; c++) {
        final key = '$r,$c';
        if (starts.contains(key)) {
          numberByCell[key] = next;
          next++;
        }
      }
    }
    return numberByCell;
  }
}
