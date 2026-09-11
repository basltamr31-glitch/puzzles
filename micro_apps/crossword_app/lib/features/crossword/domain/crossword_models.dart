import 'package:equatable/equatable.dart';

import '../../../core/errors/app_exception.dart';
import 'clue_category.dart';

enum WordDirection { across, down }

/// A single word entry as authored in puzzle JSON. Positions are 0-based
/// grid coordinates of the word's first letter.
class CrosswordWordDef extends Equatable {
  const CrosswordWordDef({
    required this.direction,
    required this.row,
    required this.col,
    required this.answer,
    required this.clue,
    this.category,
  });

  final WordDirection direction;
  final int row;
  final int col;
  final String answer;
  final String clue;

  /// Optional broad category, used to show a supporting icon. Absent for
  /// abstract words that can't be sensibly categorized.
  final ClueCategory? category;

  int get length => answer.length;

  factory CrosswordWordDef.fromJson(Map<String, dynamic> json) {
    final directionRaw = json['direction'] as String?;
    final answer = json['answer'] as String?;
    final clue = json['clue'] as String?;
    final row = json['row'];
    final col = json['col'];

    if (directionRaw == null ||
        answer == null ||
        answer.isEmpty ||
        clue == null ||
        row is! int ||
        col is! int) {
      throw const InvalidPuzzleException(
        'A word entry is missing required fields (direction, row, col, answer, clue).',
      );
    }

    final direction = switch (directionRaw) {
      'across' => WordDirection.across,
      'down' => WordDirection.down,
      _ => throw InvalidPuzzleException(
        'Unknown word direction "$directionRaw".',
      ),
    };

    return CrosswordWordDef(
      direction: direction,
      row: row,
      col: col,
      answer: answer.toUpperCase(),
      clue: clue,
      // Unknown/absent ids resolve to null rather than throwing, so adding
      // a new category to content can never break an older app build.
      category: ClueCategory.fromId(json['category'] as String?),
    );
  }

  @override
  List<Object?> get props => [direction, row, col, answer, clue, category];
}

/// The raw, content-authored definition of a puzzle, as parsed from a
/// `puzzles/<lang>/<difficulty>/*.json` asset. The grid itself (blocked
/// cells, clue numbers) is *derived* from [words] by
/// [CrosswordGridGenerator] rather than being part of this schema, so
/// content authors have a single source of truth to keep consistent.
class CrosswordPuzzleDef extends Equatable {
  const CrosswordPuzzleDef({
    required this.id,
    required this.language,
    required this.difficulty,
    required this.title,
    required this.rows,
    required this.cols,
    required this.words,
  });

  final String id;
  final String language;
  final String difficulty;
  final String title;
  final int rows;
  final int cols;
  final List<CrosswordWordDef> words;

  factory CrosswordPuzzleDef.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final language = json['language'] as String?;
    final difficulty = json['difficulty'] as String?;
    final title = json['title'] as String?;
    final rows = json['rows'];
    final cols = json['cols'];
    final wordsJson = json['words'];

    if (id == null ||
        language == null ||
        difficulty == null ||
        title == null ||
        rows is! int ||
        cols is! int ||
        wordsJson is! List ||
        wordsJson.isEmpty) {
      throw const InvalidPuzzleException(
        'Puzzle file is missing required fields (id, language, difficulty, title, rows, cols, words).',
      );
    }

    return CrosswordPuzzleDef(
      id: id,
      language: language,
      difficulty: difficulty,
      title: title,
      rows: rows,
      cols: cols,
      words: wordsJson
          .map((w) => CrosswordWordDef.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    language,
    difficulty,
    title,
    rows,
    cols,
    words,
  ];
}

/// One cell in the derived, playable grid.
class CrosswordCell extends Equatable {
  const CrosswordCell({
    required this.row,
    required this.col,
    required this.isBlocked,
    this.solutionLetter,
    this.clueNumber,
  });

  final int row;
  final int col;
  final bool isBlocked;
  final String? solutionLetter;
  final int? clueNumber;

  @override
  List<Object?> get props => [row, col, isBlocked, solutionLetter, clueNumber];
}

/// A clue entry ready for display, with the ordered list of grid
/// coordinates its answer occupies (used to highlight the active word and
/// to walk cell-by-cell during input).
class CrosswordClue extends Equatable {
  const CrosswordClue({
    required this.number,
    required this.direction,
    required this.clue,
    required this.answer,
    required this.cells,
    this.category,
  });

  final int number;
  final WordDirection direction;
  final String clue;
  final String answer;
  final List<(int row, int col)> cells;

  /// Drives the supporting icon beside the clue; null means no icon.
  final ClueCategory? category;

  @override
  List<Object?> get props => [number, direction, clue, answer, cells, category];
}

/// The fully derived, playable representation of a puzzle: grid shape,
/// per-cell metadata, and numbered clue lists split by direction.
class CrosswordGrid extends Equatable {
  const CrosswordGrid({
    required this.puzzleId,
    required this.language,
    required this.title,
    required this.rows,
    required this.cols,
    required this.cells,
    required this.acrossClues,
    required this.downClues,
  });

  final String puzzleId;

  /// The language the *content* is written in, carried through from the
  /// puzzle JSON. The board must be laid out in this language's reading
  /// direction — which is not necessarily the UI language's, since the
  /// two are chosen independently (spec §11/§12).
  final String language;

  final String title;
  final int rows;
  final int cols;
  final List<List<CrosswordCell>> cells;
  final List<CrosswordClue> acrossClues;
  final List<CrosswordClue> downClues;

  CrosswordCell cellAt(int row, int col) => cells[row][col];

  List<CrosswordClue> get allClues => [...acrossClues, ...downClues];

  @override
  List<Object?> get props => [
    puzzleId,
    language,
    title,
    rows,
    cols,
    cells,
    acrossClues,
    downClues,
  ];
}
