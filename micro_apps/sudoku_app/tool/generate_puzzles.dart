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
    // Generated first, numbered second. Ids cannot be assigned during
    // generation any more because the file is sorted by difficulty before
    // it is written, and a puzzle's number has to match its position.
    final found = <SudokuPuzzleDef>[];
    final scores = <String, double>{};
    final seenGivens = <String>{};

    while (found.length < puzzlesPerDifficulty) {
      final puzzle = SudokuGenerator.generate(
        random: random,
        spec: spec,
        id: 'pending',
      );
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
      scores[puzzle.givens] =
          SudokuSolver.profile(SudokuSolver.parse(puzzle.givens)).score;
      found.add(puzzle);
    }

    // The ramp. Puzzles unlock sequentially, so without this the player
    // walks a randomly ordered difficulty path inside every tier — puzzle
    // 3 could be the hardest of the hundred and puzzle 40 the easiest.
    found.sort((a, b) => scores[a.givens]!.compareTo(scores[b.givens]!));

    final puzzles = [
      for (var i = 0; i < found.length; i++)
        SudokuPuzzleDef(
          id: '${difficulty}_${(i + 1).toString().padLeft(3, '0')}',
          difficulty: difficulty,
          givens: found[i].givens,
          solution: found[i].solution,
        ),
    ];

    final file = File('assets/puzzles/$difficulty.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'difficulty': difficulty,
        'count': puzzles.length,
        'puzzles': puzzles.map((p) => p.toJson()).toList(),
      }),
    );

    final givenCounts = puzzles.map((p) => p.givenCount).toList()..sort();
    final ordered = puzzles.map((p) => scores[p.givens]!).toList();
    final elapsed = DateTime.now().difference(started);
    stdout.writeln(
      '$difficulty: ${puzzles.length} puzzles, '
      'givens ${givenCounts.first}-${givenCounts.last} '
      '(median ${givenCounts[givenCounts.length ~/ 2]}), '
      'score ${ordered.first.toStringAsFixed(0)}-'
      '${ordered.last.toStringAsFixed(0)} '
      '(median ${ordered[ordered.length ~/ 2].toStringAsFixed(0)}), '
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
  // Every shipped puzzle must be finishable by logic alone. This is the
  // guarantee that replaced "expert means our solver gave up".
  final profile = SudokuSolver.profile(givens);
  if (!profile.solved) {
    throw StateError('${puzzle.id}: cannot be solved without guessing.');
  }
  for (var i = 0; i < sudokuCellCount; i++) {
    if (profile.grid[i] != solution[i]) {
      throw StateError('${puzzle.id}: logical solve disagrees with the '
          'solution at cell $i — a technique is eliminating wrongly.');
    }
  }

  final spec = sudokuTiers[puzzle.difficulty]!;
  if (!spec.accepts(puzzle.givenCount, profile)) {
    throw StateError('${puzzle.id}: ${puzzle.givenCount} givens, '
        'hardest ${profile.hardest.name}, score '
        '${profile.score.toStringAsFixed(1)} — outside the '
        '${puzzle.difficulty} tier.');
  }
}
