import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_generator.dart';
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
      // Still true with the extended ladder: Inkala's grid needs chains
      // well past an X-Wing. It is the check that "expert" has not been
      // quietly redefined to mean "anything our solver cannot do" again.
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
      const ladder = [
        SudokuTechnique.nakedSingle,
        SudokuTechnique.hiddenSingle,
        SudokuTechnique.lockedCandidates,
        SudokuTechnique.nakedPair,
        SudokuTechnique.hiddenPair,
        SudokuTechnique.nakedTriple,
        SudokuTechnique.xWing,
        SudokuTechnique.guess,
      ];
      expect(ladder, SudokuTechnique.values,
          reason: 'the enum order *is* the difficulty order');
      for (var i = 1; i < ladder.length; i++) {
        expect(ladder[i].isHarderThan(ladder[i - 1]), isTrue);
        expect(ladder[i - 1].isHarderThan(ladder[i]), isFalse);
      }
    });

    test('every technique has a score weight', () {
      // A technique added without a weight would throw on the null
      // assertion inside `score`, but only for a grid that happens to
      // need it — which could be long after it was added.
      for (final technique in SudokuTechnique.values) {
        expect(SudokuProfile.weights[technique], isNotNull,
            reason: technique.name);
      }
    });
  });

  group('profile', () {
    test('counts every application, not just the hardest one', () {
      final profile = SudokuSolver.profile(SudokuSolver.parse(_wikipediaSample));

      expect(profile.solved, isTrue);
      expect(profile.hardest, SudokuTechnique.nakedSingle);
      expect(profile.uses[SudokuTechnique.nakedSingle], greaterThan(1));
      expect(profile.steps, greaterThan(1));
      expect(SudokuSolver.format(profile.grid), _wikipediaSolution);
    });

    test('reports an unsolvable-by-logic grid rather than guessing', () {
      final givens = SudokuSolver.parse(_inkala2012);
      final profile = SudokuSolver.profile(givens);

      expect(profile.solved, isFalse);
      expect(profile.hardest, SudokuTechnique.guess);

      // Inkala's grid defeats the ladder on the very first step — not one
      // cell falls to any of the seven techniques, so the stalled grid is
      // still exactly the 21 givens. Asserted precisely rather than as
      // "some progress": that was the assumption, and it was wrong.
      expect(profile.grid, givens);
      expect(profile.grid.where((v) => v != 0).length, 21);
    });

    test('a harder puzzle scores above an easier one', () {
      final gentle = SudokuSolver.profile(SudokuSolver.parse(_wikipediaSample));
      final harsh = SudokuSolver.profile(SudokuSolver.parse(_inkala2012));
      expect(harsh.score, greaterThan(gentle.score));
    });

    test('every digit logic places agrees with the real solution', () {
      // The regression guard for the extended techniques. A hidden pair,
      // naked triple, or X-Wing that eliminates a candidate it should not
      // fails silently: the solve still completes, just wrongly.
      final random = Random(21);
      for (var i = 0; i < 40; i++) {
        final solution = SudokuGenerator.generateSolution(random);
        final puzzle = List<int>.from(solution);
        final order = List<int>.generate(sudokuCellCount, (j) => j)
          ..shuffle(random);
        for (final index in order.take(55)) {
          final removed = puzzle[index];
          puzzle[index] = 0;
          if (SudokuSolver.countSolutions(puzzle, limit: 2) != 1) {
            puzzle[index] = removed;
          }
        }
        final profile = SudokuSolver.profile(puzzle);
        for (var c = 0; c < sudokuCellCount; c++) {
          if (profile.grid[c] == 0) continue;
          expect(profile.grid[c], solution[c], reason: 'grid $i cell $c');
        }
      }
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
