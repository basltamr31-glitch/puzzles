// Generates the bundled Sudoku puzzles.
//
//   dart run tool/generate_puzzles.dart            # every difficulty
//   dart run tool/generate_puzzles.dart hard       # just one
//
// Writes assets/puzzles/<difficulty>.json. Nothing under assets/puzzles/
// is ever hand-edited: this script owns those files, and it validates
// every puzzle through the same solver the app plays with before writing.
//
// Runs under plain `dart run` (no Flutter engine) because everything it
// imports from lib/ is pure Dart.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:sudoku_app/features/sudoku/domain/sudoku_generator.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_models.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_solver.dart';

const int puzzlesPerDifficulty = 100;

/// Fixed per tier so a regeneration reproduces the same set instead of
/// silently reshuffling every player's puzzle numbering.
const Map<String, int> _seeds = {
  'easy': 20260826,
  'medium': 20260827,
  'hard': 20260828,
  'expert': 20260829,
};

Future<void> main(List<String> args) async {
  final requested = args.isEmpty ? sudokuTiers.keys.toList() : args;

  for (final difficulty in requested) {
    final spec = sudokuTiers[difficulty];
    if (spec == null) {
      stderr.writeln('Unknown difficulty "$difficulty". '
          'Expected one of: ${sudokuTiers.keys.join(', ')}');
      exitCode = 1;
      return;
    }

    final started = DateTime.now();
    final random = Random(_seeds[difficulty]!);
    final puzzles = <SudokuPuzzleDef>[];
    final seenGivens = <String>{};
    final givenCounts = <int>[];

    while (puzzles.length < puzzlesPerDifficulty) {
      final id = '${difficulty}_${(puzzles.length + 1).toString().padLeft(3, '0')}';
      final puzzle = SudokuGenerator.generate(random: random, spec: spec, id: id);
      if (puzzle == null) {
        stderr.writeln('Gave up generating a "$difficulty" puzzle after the '
            'attempt limit. Loosen the tier spec in sudoku_generator.dart.');
        exitCode = 1;
        return;
      }
      // Two identical grids in one file would look like a bug to a player
      // who reaches both, so a duplicate is discarded rather than shipped.
      if (!seenGivens.add(puzzle.givens)) continue;

      _validate(puzzle);
      puzzles.add(puzzle);
      givenCounts.add(puzzle.givenCount);
    }

    final file = File('assets/puzzles/$difficulty.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'difficulty': difficulty,
        'count': puzzles.length,
        'puzzles': puzzles.map((p) => p.toJson()).toList(),
      }),
    );

    givenCounts.sort();
    final elapsed = DateTime.now().difference(started);
    stdout.writeln(
      '$difficulty: ${puzzles.length} puzzles, '
      'givens ${givenCounts.first}-${givenCounts.last} '
      '(median ${givenCounts[givenCounts.length ~/ 2]}), '
      '${elapsed.inSeconds}s -> ${file.path}',
    );
  }
}

/// Every property the app relies on, checked here rather than trusted:
/// a puzzle that fails any of these is a bug in the generator, and
/// shipping it would surface as an unsolvable grid in a player's hands.
void _validate(SudokuPuzzleDef puzzle) {
  final givens = SudokuSolver.parse(puzzle.givens);
  final solution = SudokuSolver.parse(puzzle.solution);

  if (solution.contains(0)) {
    throw StateError('${puzzle.id}: solution has empty cells.');
  }
  if (!SudokuSolver.isConsistent(solution)) {
    throw StateError('${puzzle.id}: solution breaks Sudoku rules.');
  }
  for (var i = 0; i < sudokuCellCount; i++) {
    if (givens[i] != 0 && givens[i] != solution[i]) {
      throw StateError('${puzzle.id}: given at $i contradicts the solution.');
    }
  }
  if (SudokuSolver.countSolutions(givens, limit: 2) != 1) {
    throw StateError('${puzzle.id}: puzzle does not have exactly one solution.');
  }

  final spec = sudokuTiers[puzzle.difficulty]!;
  final grade = SudokuSolver.grade(givens);
  if (!spec.accepts(puzzle.givenCount, grade)) {
    throw StateError('${puzzle.id}: ${puzzle.givenCount} givens graded '
        '${grade.name}, outside the ${puzzle.difficulty} tier.');
  }
}
