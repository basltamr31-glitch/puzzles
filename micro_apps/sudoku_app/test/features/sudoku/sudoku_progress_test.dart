import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_models.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_progress.dart';

void main() {
  group('SudokuProgress', () {
    test('empty() starts blank', () {
      final progress = SudokuProgress.empty();
      expect(progress.values.length, sudokuCellCount);
      expect(progress.values.every((v) => v == 0), isTrue);
      expect(progress.notes.every((n) => n.isEmpty), isTrue);
      expect(progress.elapsedSeconds, 0);
    });

    test('round-trips values, notes, and elapsed time', () {
      final progress = SudokuProgress.empty();
      progress.values[0] = 5;
      progress.values[80] = 9;
      progress.notes[3].addAll({1, 4, 7});

      final restored = SudokuProgress.decode(
        SudokuProgress(
          values: progress.values,
          notes: progress.notes,
          elapsedSeconds: 137,
        ).encode(),
      );

      expect(restored.values[0], 5);
      expect(restored.values[80], 9);
      expect(restored.values[1], 0);
      expect(restored.notes[3], {1, 4, 7});
      expect(restored.notes[4], isEmpty);
      expect(restored.elapsedSeconds, 137);
    });

    test('only annotated cells are written out', () {
      final progress = SudokuProgress.empty();
      progress.notes[10].add(6);
      final encoded = progress.encode();

      expect(encoded, contains('"10":"6"'));
      expect(encoded, isNot(contains('"11"')));
    });

    test('a saved grid uses the same 81-character format as the assets', () {
      final progress = SudokuProgress.empty();
      progress.values[0] = 7;
      expect(progress.encode(), contains('"values":"7${'.' * 80}"'));
    });

    test('rejects a grid of the wrong length', () {
      expect(
        () => SudokuProgress.decode('{"values":"123","notes":{}}'),
        throwsFormatException,
      );
    });

    test('tolerates missing notes and elapsed time', () {
      final restored = SudokuProgress.decode('{"values":"${'.' * 81}"}');
      expect(restored.elapsedSeconds, 0);
      expect(restored.notes.every((n) => n.isEmpty), isTrue);
    });

    test('ignores a note for a cell that does not exist', () {
      final restored = SudokuProgress.decode(
        '{"values":"${'.' * 81}","notes":{"999":"5"}}',
      );
      expect(restored.notes.every((n) => n.isEmpty), isTrue);
    });
  });
}
