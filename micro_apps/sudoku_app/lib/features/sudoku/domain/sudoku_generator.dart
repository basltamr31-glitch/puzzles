import 'dart:math';

import 'sudoku_models.dart';
import 'sudoku_solver.dart';

/// What makes a puzzle belong to one difficulty tier rather than another.
///
/// Two constraints, both required. Given count alone is the classic
/// (lazy) measure and is wrong often enough to matter; technique alone
/// produces tiers that look inconsistent to the player, because a grid
/// with 24 clues *reads* as harder than one with 45 even when a solver
/// disagrees. Requiring both keeps the tiers honest and legible.
class SudokuTierSpec {
  const SudokuTierSpec({
    required this.difficulty,
    required this.minGivens,
    required this.maxGivens,
    required this.hardestAllowed,
    required this.hardestRequired,
  });

  final String difficulty;

  /// The tier's clue-count window. Each puzzle picks a random target
  /// inside it and stops digging there, so one tier's grids vary the way
  /// a real puzzle book's do instead of all landing on the same number.
  ///
  /// The window matters more than it looks: greedy digging under the
  /// [hardestAllowed] cap alone will happily strip a naked-singles-only
  /// grid down to ~25 clues, which no player would accept as "Easy".
  /// Technique bounds what the tier *demands*; this bounds what it
  /// *looks like*.
  final int minGivens;
  final int maxGivens;

  /// A removal that would push the puzzle past this technique is undone.
  final SudokuTechnique hardestAllowed;

  /// A finished puzzle easier than this is rejected, so an unusually
  /// gentle grid can't slip into a harder tier's file.
  final SudokuTechnique hardestRequired;

  bool accepts(int givens, SudokuTechnique grade) {
    if (givens < minGivens || givens > maxGivens) return false;
    if (grade.isHarderThan(hardestAllowed)) return false;
    if (hardestRequired.isHarderThan(grade)) return false;
    return true;
  }
}

const Map<String, SudokuTierSpec> sudokuTiers = {
  // Solvable start to finish by "this cell has only one option left" —
  // no scanning for hidden singles required.
  'easy': SudokuTierSpec(
    difficulty: 'easy',
    minGivens: 36,
    maxGivens: 44,
    hardestAllowed: SudokuTechnique.nakedSingle,
    hardestRequired: SudokuTechnique.nakedSingle,
  ),
  'medium': SudokuTierSpec(
    difficulty: 'medium',
    minGivens: 30,
    maxGivens: 35,
    hardestAllowed: SudokuTechnique.hiddenSingle,
    hardestRequired: SudokuTechnique.hiddenSingle,
  ),
  'hard': SudokuTierSpec(
    difficulty: 'hard',
    minGivens: 26,
    maxGivens: 29,
    hardestAllowed: SudokuTechnique.nakedPair,
    hardestRequired: SudokuTechnique.lockedCandidates,
  ),
  // The only tier where the bundled techniques are not enough — an
  // expert grid needs the player to hold a chain in their head.
  'expert': SudokuTierSpec(
    difficulty: 'expert',
    minGivens: 22,
    maxGivens: 26,
    hardestAllowed: SudokuTechnique.guess,
    hardestRequired: SudokuTechnique.guess,
  ),
};

/// Builds Sudoku grids that are guaranteed to have exactly one solution.
///
/// Lives in `lib/` rather than `tool/` so the app's own tests can
/// generate throwaway puzzles with the same code that produced the
/// bundled ones — a generator that only exists in a build script is a
/// generator nothing ever tests.
class SudokuGenerator {
  SudokuGenerator._();

  /// A complete, valid 9x9 solution.
  static List<int> generateSolution(Random random) {
    final grid = List<int>.filled(sudokuCellCount, 0);
    if (!_fill(grid, 0, random)) {
      // Unreachable: an empty grid always has solutions. Guarding anyway
      // beats returning a half-filled grid if that ever stops being true.
      throw StateError('Failed to generate a solved Sudoku grid.');
    }
    return grid;
  }

  static bool _fill(List<int> grid, int index, Random random) {
    if (index == sudokuCellCount) return true;
    final digits = List<int>.generate(sudokuSize, (i) => i + 1)..shuffle(random);
    for (final digit in digits) {
      if (!SudokuSolver.isValidPlacement(grid, index, digit)) continue;
      grid[index] = digit;
      if (_fill(grid, index + 1, random)) return true;
      grid[index] = 0;
    }
    grid[index] = 0;
    return false;
  }

  /// Digs clues out of a fresh solution until [spec] is satisfied, or
  /// returns null if [maxAttempts] solutions in a row failed to land in
  /// the tier. Callers retry with a different seed rather than looping
  /// forever, so a badly specified tier fails loudly instead of hanging.
  static SudokuPuzzleDef? generate({
    required Random random,
    required SudokuTierSpec spec,
    required String id,
    int maxAttempts = 200,
  }) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final solution = generateSolution(random);
      final puzzle = List<int>.from(solution);
      final order = List<int>.generate(sudokuCellCount, (i) => i)..shuffle(random);
      final digTarget = spec.minGivens +
          random.nextInt(spec.maxGivens - spec.minGivens + 1);
      var givens = sudokuCellCount;
      // Skipping the per-removal grade for the tier that allows every
      // technique isn't just an optimization: with no cap there is
      // nothing for the check to reject, so it would be pure cost.
      final capped = spec.hardestAllowed != SudokuTechnique.guess;

      for (final index in order) {
        if (givens <= digTarget) break;
        final removed = puzzle[index];
        puzzle[index] = 0;

        if (SudokuSolver.countSolutions(puzzle, limit: 2) != 1) {
          puzzle[index] = removed;
          continue;
        }
        if (capped && SudokuSolver.grade(puzzle).isHarderThan(spec.hardestAllowed)) {
          puzzle[index] = removed;
          continue;
        }
        givens--;
      }

      final grade = SudokuSolver.grade(puzzle);
      if (!spec.accepts(givens, grade)) continue;

      return SudokuPuzzleDef(
        id: id,
        difficulty: spec.difficulty,
        givens: SudokuSolver.format(puzzle),
        solution: SudokuSolver.format(solution),
      );
    }
    return null;
  }
}
