import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_generator.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_models.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_solver.dart';

void main() {
  group('generateSolution', () {
    test('produces a complete, rule-abiding grid', () {
      final solution = SudokuGenerator.generateSolution(Random(1));
      expect(solution.length, sudokuCellCount);
      expect(solution.contains(0), isFalse);
      expect(SudokuSolver.isConsistent(solution), isTrue);
    });

    test('the same seed produces the same grid', () {
      expect(
        SudokuGenerator.generateSolution(Random(42)),
        SudokuGenerator.generateSolution(Random(42)),
      );
    });

    test('different seeds produce different grids', () {
      expect(
        SudokuGenerator.generateSolution(Random(1)),
        isNot(SudokuGenerator.generateSolution(Random(2))),
      );
    });
  });

  group('generate', () {
    // One puzzle per tier rather than a hundred: this asserts the
    // generator's contract, and the bundled content itself is verified
    // wholesale in bundled_puzzles_test.dart.
    for (final entry in sudokuTiers.entries) {
      test('a ${entry.key} puzzle satisfies its own tier spec', () {
        final puzzle = SudokuGenerator.generate(
          random: Random(7),
          spec: entry.value,
          id: 'test',
        );

        expect(puzzle, isNotNull, reason: 'generator gave up on ${entry.key}');
        expect(puzzle!.difficulty, entry.key);
        expect(puzzle.givenCount, greaterThanOrEqualTo(entry.value.minGivens));
        expect(puzzle.givenCount, lessThanOrEqualTo(entry.value.maxGivens));

        final givens = SudokuSolver.parse(puzzle.givens);
        expect(
          entry.value.accepts(puzzle.givenCount, SudokuSolver.grade(givens)),
          isTrue,
        );
      });

      test('a ${entry.key} puzzle has exactly one solution', () {
        final puzzle = SudokuGenerator.generate(
          random: Random(11),
          spec: entry.value,
          id: 'test',
        )!;
        expect(SudokuSolver.countSolutions(SudokuSolver.parse(puzzle.givens)), 1);
      });

      test('a ${entry.key} puzzle\'s givens agree with its solution', () {
        final puzzle = SudokuGenerator.generate(
          random: Random(13),
          spec: entry.value,
          id: 'test',
        )!;
        for (var i = 0; i < sudokuCellCount; i++) {
          if (puzzle.givens[i] == emptyCell) continue;
          expect(puzzle.givens[i], puzzle.solution[i], reason: 'cell $i');
        }
      });
    }

    test('the tiers form an increasing difficulty ladder', () {
      final order = ['easy', 'medium', 'hard', 'expert'];
      for (var i = 1; i < order.length; i++) {
        final easier = sudokuTiers[order[i - 1]]!;
        final harder = sudokuTiers[order[i]]!;
        expect(
          harder.maxGivens,
          lessThan(easier.maxGivens),
          reason: '${order[i]} should start emptier than ${order[i - 1]}',
        );
        expect(
          harder.hardestAllowed.index,
          greaterThanOrEqualTo(easier.hardestAllowed.index),
        );
      }
    });

    test('gives up rather than looping forever on an impossible spec', () {
      const impossible = SudokuTierSpec(
        difficulty: 'impossible',
        minGivens: 81,
        maxGivens: 81,
        hardestAllowed: SudokuTechnique.nakedSingle,
        // Demanding a grid that needs guessing while forbidding every
        // removal that would make it so.
        hardestRequired: SudokuTechnique.guess,
      );
      expect(
        SudokuGenerator.generate(
          random: Random(3),
          spec: impossible,
          id: 'test',
          maxAttempts: 2,
        ),
        isNull,
      );
    });
  });
}
