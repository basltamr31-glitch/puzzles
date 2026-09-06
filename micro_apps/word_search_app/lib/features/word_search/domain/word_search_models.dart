import 'package:equatable/equatable.dart';

import '../../../core/errors/app_exception.dart';
import 'puzzle_theme.dart';

/// The eight directions a word can run in.
///
/// Coordinates are **logical**, not visual: `east` means "towards
/// increasing column". For a right-to-left game language the grid is
/// rendered mirrored, so an `east` word still reads in that language's
/// natural direction. Keeping the engine in one coordinate system is why
/// the generator, the validator, and the tests never need to know which
/// language a puzzle belongs to.
enum WordDirection {
  east('E', 0, 1),
  southEast('SE', 1, 1),
  south('S', 1, 0),
  southWest('SW', 1, -1),
  west('W', 0, -1),
  northWest('NW', -1, -1),
  north('N', -1, 0),
  northEast('NE', -1, 1);

  const WordDirection(this.id, this.rowStep, this.colStep);

  final String id;
  final int rowStep;
  final int colStep;

  /// True for the four directions whose words read backwards or upwards —
  /// the single biggest jump in perceived difficulty, and the reason the
  /// tiers gate them rather than the grid size alone.
  bool get isReversed =>
      this == WordDirection.west ||
      this == WordDirection.northWest ||
      this == WordDirection.north ||
      this == WordDirection.southWest;

  static WordDirection fromId(String id) {
    for (final direction in WordDirection.values) {
      if (direction.id == id) return direction;
    }
    throw InvalidPuzzleException('Unknown word direction "$id".');
  }
}

/// One word as it sits in the grid: where it starts and which way it runs.
/// [row]/[col] are 0-based coordinates of the word's first letter.
class WordPlacement extends Equatable {
  const WordPlacement({
    required this.word,
    required this.row,
    required this.col,
    required this.direction,
  });

  final String word;
  final int row;
  final int col;
  final WordDirection direction;

  int get length => word.length;

  /// Every cell the word occupies, in reading order.
  List<(int row, int col)> get cells => [
    for (var i = 0; i < word.length; i++)
      (row + direction.rowStep * i, col + direction.colStep * i),
  ];

  (int row, int col) get lastCell => cells.last;

  factory WordPlacement.fromJson(Map<String, dynamic> json) {
    final word = json['word'] as String?;
    final row = json['row'];
    final col = json['col'];
    final directionRaw = json['dir'] as String?;

    if (word == null ||
        word.isEmpty ||
        row is! int ||
        col is! int ||
        directionRaw == null) {
      throw const InvalidPuzzleException(
        'A word entry is missing required fields (word, row, col, dir).',
      );
    }

    return WordPlacement(
      word: word,
      row: row,
      col: col,
      direction: WordDirection.fromId(directionRaw),
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'row': row,
    'col': col,
    'dir': direction.id,
  };

  @override
  List<Object?> get props => [word, row, col, direction];
}

/// The content-authored definition of a puzzle, parsed from a
/// `assets/puzzles/<lang>/<difficulty>/*.json` asset.
///
/// Unlike the crossword app, the **filled grid is stored**, not derived:
/// the filler letters are part of the puzzle's identity (they are what
/// makes a word hard to spot), so regenerating them at runtime would give
/// two players different puzzles under the same id. The placements are
/// stored alongside so the app can check a selection without searching,
/// and so tests can prove the grid and the word list agree.
class WordSearchPuzzleDef extends Equatable {
  const WordSearchPuzzleDef({
    required this.id,
    required this.language,
    required this.difficulty,
    required this.index,
    required this.size,
    required this.rows,
    required this.placements,
    this.theme,
  });

  final String id;
  final String language;
  final String difficulty;

  /// Zero-based position within its difficulty — the routing key and the
  /// number shown to the player (as [index] + 1).
  final int index;

  /// Grids are square; [size] is both the row and the column count.
  final int size;

  /// One string per row, [size] characters each, already filled.
  final List<String> rows;

  final List<WordPlacement> placements;

  /// Null when the asset names a theme this build does not know.
  final PuzzleTheme? theme;

  List<String> get words => [for (final p in placements) p.word];

  String letterAt(int row, int col) => rows[row][col];

  factory WordSearchPuzzleDef.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final language = json['language'] as String?;
    final difficulty = json['difficulty'] as String?;
    final index = json['index'];
    final size = json['size'];
    final rowsJson = json['rows'];
    final wordsJson = json['words'];

    if (id == null ||
        language == null ||
        difficulty == null ||
        index is! int ||
        size is! int ||
        rowsJson is! List ||
        wordsJson is! List ||
        wordsJson.isEmpty) {
      throw const InvalidPuzzleException(
        'Puzzle file is missing required fields '
        '(id, language, difficulty, index, size, rows, words).',
      );
    }

    final rows = rowsJson.cast<String>();
    if (rows.length != size || rows.any((r) => r.length != size)) {
      throw InvalidPuzzleException(
        'Puzzle "$id" declares size $size but its rows do not match it.',
      );
    }

    return WordSearchPuzzleDef(
      id: id,
      language: language,
      difficulty: difficulty,
      index: index,
      size: size,
      rows: rows,
      placements: wordsJson
          .map((w) => WordPlacement.fromJson(w as Map<String, dynamic>))
          .toList(growable: false),
      theme: PuzzleTheme.fromId(json['theme'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'language': language,
    'difficulty': difficulty,
    'index': index,
    if (theme != null) 'theme': theme!.id,
    'size': size,
    'rows': rows,
    'words': [for (final p in placements) p.toJson()],
  };

  @override
  List<Object?> get props => [
    id,
    language,
    difficulty,
    index,
    size,
    rows,
    placements,
    theme,
  ];
}
