import 'dart:convert';

import 'sudoku_models.dart';

/// Everything worth restoring when a player reopens a puzzle: what they
/// entered, the pencil marks they were reasoning with, and how long
/// they've spent.
///
/// Notes are as much a part of "where I was" as the digits — losing them
/// on a phone call would throw away the actual work — so they are
/// persisted alongside [values] rather than treated as scratch state.
class SudokuProgress {
  const SudokuProgress({
    required this.values,
    required this.notes,
    required this.elapsedSeconds,
  });

  SudokuProgress.empty()
      : values = List<int>.filled(sudokuCellCount, 0),
        notes = List<Set<int>>.generate(sudokuCellCount, (_) => <int>{}),
        elapsedSeconds = 0;

  /// 81 entries, 0 meaning empty. Includes the puzzle's givens, so this
  /// alone is the full grid state.
  final List<int> values;

  /// 81 candidate sets. Empty for cells the player hasn't annotated.
  final List<Set<int>> notes;

  final int elapsedSeconds;

  /// Values go out as the same 81-character format the assets use, so a
  /// saved grid can be pasted straight into the solver when debugging.
  /// Notes are sparse — only annotated cells appear.
  String encode() {
    return jsonEncode({
      'values': values.map((v) => v == 0 ? emptyCell : '$v').join(),
      'notes': {
        for (var i = 0; i < sudokuCellCount; i++)
          if (notes[i].isNotEmpty) '$i': (notes[i].toList()..sort()).join(),
      },
      'elapsedSeconds': elapsedSeconds,
    });
  }

  static SudokuProgress decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final rawValues = json['values'] as String;
    if (rawValues.length != sudokuCellCount) {
      throw const FormatException('Saved grid is not 81 cells.');
    }

    final values = List<int>.generate(
      sudokuCellCount,
      (i) => rawValues[i] == emptyCell ? 0 : int.parse(rawValues[i]),
    );

    final notes = List<Set<int>>.generate(sudokuCellCount, (_) => <int>{});
    final rawNotes = json['notes'] as Map<String, dynamic>? ?? const {};
    rawNotes.forEach((key, value) {
      final index = int.parse(key);
      if (index < 0 || index >= sudokuCellCount) return;
      notes[index] = (value as String).split('').map(int.parse).toSet();
    });

    return SudokuProgress(
      values: values,
      notes: notes,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
