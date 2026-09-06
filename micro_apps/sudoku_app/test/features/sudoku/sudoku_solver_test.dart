import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_models.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_solver.dart';

/// Published puzzles, used as fixed reference points. Grading is the one
/// piece of this app with no obvious "correct" answer to assert against,
/// so it is pinned to grids whose difficulty is externally agreed on
/// rather than to whatever the implementation currently happens to say.
const _wikipediaSample =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const _wikipediaSolution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

/// Arto Inkala's 2012 grid, widely published as one of the hardest.
const _inkala2012 =
    '8..........36......7..9.2...5...7.......457.....1...3...1....68..85...1..9....4..';

void main() {
  group('parse/format', () {
    test('round-trips a puzzle string', () {
      expect(SudokuSolver.format(SudokuSolver.parse(_wikipediaSample)), _wikipediaSample);
    });

    test('empty cells become 0', () {
      final grid = SudokuSolver.parse(_wikipediaSample);
      expect(grid[0], 5);
      expect(grid[2], 0);
    });

    test('rejects a string that is not 81 characters', () {
      expect(() => SudokuSolver.parse('123'), throwsArgumentError);
    });
  });

  group('solve', () {
    test('finds the published solution', () {
      final solved = SudokuSolver.solve(SudokuSolver.parse(_wikipediaSample));
      expect(SudokuSolver.format(solved!), _wikipediaSolution);
    });

    test('returns null for a grid with no solution', () {
      // Two 5s in the first row: unsatisfiable before search even starts.
      final broken = SudokuSolver.parse('55${'.' * 79}');
      expect(SudokuSolver.solve(broken), isNull);
    });
  });

  group('countSolutions', () {
    test('a published puzzle has exactly one solution', () {
      expect(SudokuSolver.countSolutions(SudokuSolver.parse(_wikipediaSample)), 1);
    });

    test('an empty grid stops at the limit instead of enumerating everything', () {
      final empty = SudokuSolver.parse('.' * sudokuCellCount);
      expect(SudokuSolver.countSolutions(empty, limit: 2), 2);
    });

    test('a solved grid counts as one solution', () {
      expect(SudokuSolver.countSolutions(SudokuSolver.parse(_wikipediaSolution)), 1);
    });

    test('a grid missing one digit has exactly one solution', () {
      final almost = SudokuSolver.parse('${_wikipediaSolution.substring(0, 40)}.'
          '${_wikipediaSolution.substring(41)}');
      expect(SudokuSolver.countSolutions(almost), 1);
    });
  });

  group('isConsistent', () {
    test('accepts a valid solution', () {
      expect(SudokuSolver.isConsistent(SudokuSolver.parse(_wikipediaSolution)), isTrue);
    });

    test('rejects a repeated digit in a box', () {
      final grid = SudokuSolver.parse(_wikipediaSolution);
      grid[indexOf(1, 1)] = grid[indexOf(0, 0)];
      expect(SudokuSolver.isConsistent(grid), isFalse);
    });

    test('ignores empty cells', () {
      expect(SudokuSolver.isConsistent(SudokuSolver.parse('.' * sudokuCellCount)), isTrue);
    });
  });

  group('grade', () {
    test('a gentle published puzzle needs nothing beyond naked singles', () {
      expect(
        SudokuSolver.grade(SudokuSolver.parse(_wikipediaSample)),
        SudokuTechnique.nakedSingle,
      );
    });

    test("a famously hard puzzle can't be finished by the bundled techniques", () {
      expect(
        SudokuSolver.grade(SudokuSolver.parse(_inkala2012)),
        SudokuTechnique.guess,
      );
    });

    test('an empty grid needs guessing', () {
      expect(
        SudokuSolver.grade(SudokuSolver.parse('.' * sudokuCellCount)),
        SudokuTechnique.guess,
      );
    });

    test('techniques are ordered easiest to hardest', () {
      expect(SudokuTechnique.guess.isHarderThan(SudokuTechnique.nakedPair), isTrue);
      expect(SudokuTechnique.nakedPair.isHarderThan(SudokuTechnique.lockedCandidates),
          isTrue);
      expect(SudokuTechnique.nakedSingle.isHarderThan(SudokuTechnique.hiddenSingle),
          isFalse);
    });
  });

  group('peers and units', () {
    test('every cell has exactly 20 peers', () {
      for (var i = 0; i < sudokuCellCount; i++) {
        expect(sudokuPeers[i].length, 20, reason: 'cell $i');
      }
    });

    test('peers never include the cell itself', () {
      for (var i = 0; i < sudokuCellCount; i++) {
        expect(sudokuPeers[i], isNot(contains(i)));
      }
    });

    test('there are 27 units of 9 cells', () {
      expect(sudokuUnits.length, 27);
      for (final unit in sudokuUnits) {
        expect(unit.length, sudokuSize);
      }
    });

    test('row/col/box index helpers agree with each other', () {
      expect(rowOf(indexOf(4, 7)), 4);
      expect(colOf(indexOf(4, 7)), 7);
      expect(boxOf(indexOf(4, 7)), 5);
      expect(boxOf(indexOf(0, 0)), 0);
      expect(boxOf(indexOf(8, 8)), 8);
    });
  });
}
