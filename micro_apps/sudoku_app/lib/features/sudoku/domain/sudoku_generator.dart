import 'dart:math';

import 'sudoku_models.dart';
import 'sudoku_solver.dart';

/// What makes a puzzle belong to one difficulty tier rather than another.
///
/// Three constraints, all required.
///
/// **Clue count** is the classic (lazy) measure and is wrong often enough
/// to matter on its own — but it cannot be dropped either, because a grid
/// with 24 clues *reads* as harder than one with 45 even when a solver
/// disagrees. It bounds what the tier looks like.
///
/// **A technique band** bounds what the tier demands: the hardest step a
/// logical solver needs, and the hardest it is allowed to need.
///
/// **A score window** bounds how much work the tier actually is. This is
/// the one that was missing, and its absence is what let a specific
/// Expert be easier than a specific Medium: the technique ceiling reports
/// only the single hardest step, so a grid needing one hidden pair and a
/// grid needing eleven of them graded identically. [SudokuProfile.score]
/// counts every application and adds the cost of *finding* each move, so
/// two puzzles in the same technique band can still be ordered.
class SudokuTierSpec {
  const SudokuTierSpec({
    required this.difficulty,
    required this.minGivens,
    required this.maxGivens,
    required this.hardestAllowed,
    required this.hardestRequired,
    required this.minScore,
    required this.maxScore,
  });

  final String difficulty;

  /// The tier's clue-count window. Each puzzle picks a random target
  /// inside it and stops digging there, so one tier's grids vary the way
  /// a real puzzle book's do instead of all landing on the same number.
  ///
  /// The window matters more than it looks: greedy digging under the
  /// [hardestAllowed] cap alone will happily strip a naked-singles-only
  /// grid down to ~25 clues, which no player would accept as "Easy".
  final int minGivens;
  final int maxGivens;

  /// A removal that would push the puzzle past this technique is undone.
  final SudokuTechnique hardestAllowed;

  /// A finished puzzle easier than this is rejected, so an unusually
  /// gentle grid can't slip into a harder tier's file.
  final SudokuTechnique hardestRequired;

  /// The tier's [SudokuProfile.score] window. Windows do not overlap
  /// between tiers, which is what makes "an Expert is harder than an
  /// Easy" true of *every* pair rather than only on average.
  ///
  /// The windows are separated by small deliberate gaps. Adjacent tiers
  /// whose windows merely touch still produce a hardest-Easy and an
  /// easiest-Medium that feel identical; the gap is what a player
  /// perceives as changing tier. The gaps are kept narrow because every
  /// score that falls in one is a generated puzzle thrown away.
  final double minScore;
  final double maxScore;

  bool accepts(int givens, SudokuProfile profile) {
    if (givens < minGivens || givens > maxGivens) return false;
    // A puzzle that logic cannot finish is rejected outright, at every
    // tier. It used to be what Expert required; that is why Expert had no
    // ceiling. A grid needing trial and error is a worse puzzle, not a
    // harder one.
    if (!profile.solved) return false;
    if (profile.hardest.isHarderThan(hardestAllowed)) return false;
    if (hardestRequired.isHarderThan(profile.hardest)) return false;
    if (profile.score < minScore || profile.score > maxScore) return false;
    return true;
  }
}

/// The four tiers, and the reason each boundary sits where it does.
///
/// Score windows are contiguous and non-overlapping by construction:
/// easy ends where medium begins, and so on. The gaps between the
/// technique bands and the clue windows are deliberate too — adjacent
/// tiers that merely touch produce puzzles a player experiences as
/// identical.
const Map<String, SudokuTierSpec> sudokuTiers = {
  // Solvable start to finish by "this cell has only one option left" —
  // no scanning for hidden singles required. The clue floor was raised
  // from 36 to 40: every easy puzzle grades the same, so clue count is
  // the *only* thing separating a gentle one from a tedious one, and a
  // 36-clue grid leaves so few cells placeable at a time that players
  // reported it as "an Easy that was extremely difficult".
  'easy': SudokuTierSpec(
    difficulty: 'easy',
    minGivens: 40,
    maxGivens: 46,
    hardestAllowed: SudokuTechnique.nakedSingle,
    hardestRequired: SudokuTechnique.nakedSingle,
    // Measured: this band produces scores 2-26, median 8.
    minScore: 0,
    maxScore: 20,
  ),
  'medium': SudokuTierSpec(
    difficulty: 'medium',
    minGivens: 32,
    maxGivens: 38,
    hardestAllowed: SudokuTechnique.hiddenSingle,
    hardestRequired: SudokuTechnique.hiddenSingle,
    // Measured: 8-60, median 15. The floor is what does the work here —
    // hidden singles cost only a little more than naked ones, so without
    // it a Medium can genuinely be lighter than an Easy.
    minScore: 24,
    maxScore: 65,
  ),
  'hard': SudokuTierSpec(
    difficulty: 'hard',
    minGivens: 28,
    maxGivens: 32,
    hardestAllowed: SudokuTechnique.nakedPair,
    hardestRequired: SudokuTechnique.lockedCandidates,
    // Measured: 33-126, median 79.
    minScore: 70,
    maxScore: 130,
  ),
  // Expert demands a technique that reasons about *shapes* rather than
  // single cells, and is still fully solvable by logic — the ceiling that
  // did not exist before.
  'expert': SudokuTierSpec(
    difficulty: 'expert',
    minGivens: 24,
    maxGivens: 30,
    hardestAllowed: SudokuTechnique.xWing,
    hardestRequired: SudokuTechnique.hiddenPair,
    // Measured: 92-316, median 156. No practical ceiling is needed — the
    // technique band already supplies one, which is the whole point of
    // Expert no longer meaning "beyond our solver".
    minScore: 140,
    maxScore: 100000,
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
  ///
  /// The default budget is sized from measurement, not taste: one expert
  /// puzzle costs a median of 78 attempts and as many as 305 on an
  /// unlucky seed, because the tier's score floor rejects most otherwise
  /// valid grids. At the old default of 200 roughly one seed in six
  /// failed outright. Attempts are only spent on *failures* — the loop
  /// returns on the first success — so a generous budget costs nothing
  /// when generation is going well.
  static SudokuPuzzleDef? generate({
    required Random random,
    required SudokuTierSpec spec,
    required String id,
    int maxAttempts = 800,
  }) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final solution = generateSolution(random);
      final puzzle = List<int>.from(solution);
      final order = List<int>.generate(sudokuCellCount, (i) => i)..shuffle(random);
      final digTarget = spec.minGivens +
          random.nextInt(spec.maxGivens - spec.minGivens + 1);
      var givens = sudokuCellCount;

      for (final index in order) {
        if (givens <= digTarget) break;
        final removed = puzzle[index];
        puzzle[index] = 0;

        if (SudokuSolver.countSolutions(puzzle, limit: 2) != 1) {
          puzzle[index] = removed;
          continue;
        }
        // Every tier now has a real ceiling, so this check always runs.
        // [grade] rather than [profile] on purpose: this fires once per
        // trial removal and only the ceiling matters here, so the extra
        // bookkeeping a profile does would be pure cost.
        if (SudokuSolver.grade(puzzle).isHarderThan(spec.hardestAllowed)) {
          puzzle[index] = removed;
          continue;
        }
        givens--;
      }

      final profile = SudokuSolver.profile(puzzle);
      if (!spec.accepts(givens, profile)) continue;

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
