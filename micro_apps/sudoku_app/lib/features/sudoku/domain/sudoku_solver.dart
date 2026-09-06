import 'sudoku_models.dart';

/// Solving techniques, ordered from easiest to hardest. A puzzle is
/// graded by the *hardest* technique a solver needs to finish it, which
/// is a far better difficulty signal than counting givens: a 30-given
/// grid solvable by naked singles alone is easier than a 36-given grid
/// that needs pairs.
enum SudokuTechnique {
  /// A cell with exactly one remaining candidate.
  nakedSingle,

  /// A digit with exactly one possible cell left in a row, column, or box.
  hiddenSingle,

  /// Pointing/claiming: a digit confined to one row or column *within* a
  /// box (or to one box within a row/column) can be eliminated elsewhere.
  lockedCandidates,

  /// Two cells in a unit sharing the same two candidates lock those two
  /// digits away from the rest of the unit.
  nakedPair,

  /// None of the above make progress — finishing needs trial and error.
  guess;

  bool isHarderThan(SudokuTechnique other) => index > other.index;
}

/// Pure-Dart Sudoku engine: solving, uniqueness checking, and grading.
///
/// Deliberately free of any Flutter import so `tool/generate_puzzles.dart`
/// can run it under plain `dart run` — the generator and the app share
/// exactly one implementation, so a puzzle can never be generated against
/// different rules than the ones the app plays by.
class SudokuSolver {
  SudokuSolver._();

  static const int _allDigits = 0x1FF; // bits 0..8 == digits 1..9

  /// `"53..7...."` becomes `[5, 3, 0, 0, 7, 0, 0, 0, 0]`.
  static List<int> parse(String puzzle) {
    if (puzzle.length != sudokuCellCount) {
      throw ArgumentError(
        'Expected $sudokuCellCount characters, got ${puzzle.length}.',
      );
    }
    return List<int>.generate(
      sudokuCellCount,
      (i) => puzzle[i] == emptyCell ? 0 : int.parse(puzzle[i]),
      growable: false,
    );
  }

  static String format(List<int> grid) =>
      grid.map((v) => v == 0 ? emptyCell : '$v').join();

  /// Whether [digit] may legally go in [index] given the current [grid].
  static bool isValidPlacement(List<int> grid, int index, int digit) {
    for (final peer in sudokuPeers[index]) {
      if (grid[peer] == digit) return false;
    }
    return true;
  }

  /// Every filled cell agrees with the rules (empties are ignored).
  static bool isConsistent(List<int> grid) {
    for (var i = 0; i < sudokuCellCount; i++) {
      final digit = grid[i];
      if (digit == 0) continue;
      for (final peer in sudokuPeers[i]) {
        if (grid[peer] == digit) return false;
      }
    }
    return true;
  }

  /// Backtracking search, filling the most-constrained cell first so a
  /// contradiction surfaces as early as possible.
  ///
  /// [limit] caps the count so uniqueness checks can stop the moment a
  /// second solution appears — the difference between a fast generator
  /// and one that enumerates millions of solutions for a sparse grid.
  static int countSolutions(List<int> grid, {int limit = 2}) {
    // A grid that already breaks the rules has no solution, but the
    // search alone would not discover that for an astronomically long
    // time: candidate pruning only looks at empty cells, so two identical
    // givens in one row send it exhaustively down every branch. Corrupted
    // saved state must fail in microseconds, not hang the app.
    if (!isConsistent(grid)) return 0;
    return _count(List<int>.from(grid), limit);
  }

  static int _count(List<int> grid, int limit) {
    if (limit <= 0) return 0;
    final candidates = _computeCandidates(grid);
    if (candidates == null) return 0;

    final target = _mostConstrainedCell(grid, candidates);
    if (target == -1) return 1; // no empty cells left

    var found = 0;
    for (var digit = 1; digit <= sudokuSize; digit++) {
      if (candidates[target] & (1 << (digit - 1)) == 0) continue;
      grid[target] = digit;
      found += _count(grid, limit - found);
      grid[target] = 0;
      if (found >= limit) break;
    }
    return found;
  }

  /// The single solution, or null if the puzzle has none.
  static List<int>? solve(List<int> grid) {
    if (!isConsistent(grid)) return null; // see [countSolutions]
    final working = List<int>.from(grid);
    return _solve(working) ? working : null;
  }

  static bool _solve(List<int> grid) {
    final candidates = _computeCandidates(grid);
    if (candidates == null) return false;

    final target = _mostConstrainedCell(grid, candidates);
    if (target == -1) return true;

    for (var digit = 1; digit <= sudokuSize; digit++) {
      if (candidates[target] & (1 << (digit - 1)) == 0) continue;
      grid[target] = digit;
      if (_solve(grid)) return true;
      grid[target] = 0;
    }
    return false;
  }

  static int _mostConstrainedCell(List<int> grid, List<int> candidates) {
    var target = -1;
    var fewest = sudokuSize + 1;
    for (var i = 0; i < sudokuCellCount; i++) {
      if (grid[i] != 0) continue;
      final count = _bitCount(candidates[i]);
      if (count < fewest) {
        fewest = count;
        target = i;
        if (count == 1) break;
      }
    }
    return target;
  }

  /// The hardest technique needed to solve [grid] by pure logic, or
  /// [SudokuTechnique.guess] if the implemented techniques stall before
  /// the grid is full.
  static SudokuTechnique grade(List<int> grid) {
    final working = List<int>.from(grid);
    final candidates = _computeCandidates(working);
    if (candidates == null) return SudokuTechnique.guess;

    var hardest = SudokuTechnique.nakedSingle;
    void record(SudokuTechnique technique) {
      if (technique.isHarderThan(hardest)) hardest = technique;
    }

    while (true) {
      if (!working.contains(0)) return hardest;

      if (_applyNakedSingles(working, candidates)) {
        record(SudokuTechnique.nakedSingle);
        continue;
      }
      if (_applyHiddenSingles(working, candidates)) {
        record(SudokuTechnique.hiddenSingle);
        continue;
      }
      if (_applyLockedCandidates(working, candidates)) {
        record(SudokuTechnique.lockedCandidates);
        continue;
      }
      if (_applyNakedPairs(working, candidates)) {
        record(SudokuTechnique.nakedPair);
        continue;
      }
      return SudokuTechnique.guess;
    }
  }

  /// Candidate bitmask per cell (0 for filled cells), or null if some
  /// empty cell has no candidate left — i.e. the grid is already broken.
  static List<int>? _computeCandidates(List<int> grid) {
    final candidates = List<int>.filled(sudokuCellCount, 0);
    for (var i = 0; i < sudokuCellCount; i++) {
      if (grid[i] != 0) continue;
      var mask = _allDigits;
      for (final peer in sudokuPeers[i]) {
        final digit = grid[peer];
        if (digit != 0) mask &= ~(1 << (digit - 1));
      }
      if (mask == 0) return null;
      candidates[i] = mask;
    }
    return candidates;
  }

  static void _place(List<int> grid, List<int> candidates, int index, int digit) {
    grid[index] = digit;
    candidates[index] = 0;
    final without = ~(1 << (digit - 1));
    for (final peer in sudokuPeers[index]) {
      if (grid[peer] == 0) candidates[peer] &= without;
    }
  }

  static bool _applyNakedSingles(List<int> grid, List<int> candidates) {
    var progressed = false;
    for (var i = 0; i < sudokuCellCount; i++) {
      if (grid[i] != 0) continue;
      if (_bitCount(candidates[i]) != 1) continue;
      _place(grid, candidates, i, _lowestDigit(candidates[i]));
      progressed = true;
    }
    return progressed;
  }

  static bool _applyHiddenSingles(List<int> grid, List<int> candidates) {
    var progressed = false;
    for (final unit in sudokuUnits) {
      for (var digit = 1; digit <= sudokuSize; digit++) {
        final bit = 1 << (digit - 1);
        var seen = -1;
        var count = 0;
        var alreadyPlaced = false;
        for (final index in unit) {
          if (grid[index] == digit) {
            alreadyPlaced = true;
            break;
          }
          if (grid[index] == 0 && candidates[index] & bit != 0) {
            count++;
            seen = index;
          }
        }
        if (!alreadyPlaced && count == 1) {
          _place(grid, candidates, seen, digit);
          progressed = true;
        }
      }
    }
    return progressed;
  }

  /// Pointing and claiming, expressed as one loop over every pair of
  /// overlapping units: whenever all of a digit's candidates in one unit
  /// also fall inside another unit, the digit can be struck from the rest
  /// of that second unit.
  static bool _applyLockedCandidates(List<int> grid, List<int> candidates) {
    var progressed = false;
    for (var digit = 1; digit <= sudokuSize; digit++) {
      final bit = 1 << (digit - 1);
      for (final unit in sudokuUnits) {
        final places = [
          for (final i in unit)
            if (grid[i] == 0 && candidates[i] & bit != 0) i,
        ];
        // A single candidate is a hidden single, already handled above;
        // more than three cannot fit inside an intersecting unit.
        if (places.length < 2 || places.length > sudokuBoxSize) continue;

        for (final other in sudokuUnits) {
          if (identical(other, unit)) continue;
          if (!places.every(other.contains)) continue;
          for (final index in other) {
            if (grid[index] != 0) continue;
            if (places.contains(index)) continue;
            if (candidates[index] & bit == 0) continue;
            candidates[index] &= ~bit;
            progressed = true;
          }
        }
      }
    }
    return progressed;
  }

  static bool _applyNakedPairs(List<int> grid, List<int> candidates) {
    var progressed = false;
    for (final unit in sudokuUnits) {
      final pairCells = [
        for (final i in unit)
          if (grid[i] == 0 && _bitCount(candidates[i]) == 2) i,
      ];
      for (var a = 0; a < pairCells.length; a++) {
        for (var b = a + 1; b < pairCells.length; b++) {
          final mask = candidates[pairCells[a]];
          if (candidates[pairCells[b]] != mask) continue;
          for (final index in unit) {
            if (index == pairCells[a] || index == pairCells[b]) continue;
            if (grid[index] != 0) continue;
            if (candidates[index] & mask == 0) continue;
            candidates[index] &= ~mask;
            progressed = true;
          }
        }
      }
    }
    return progressed;
  }

  static int _bitCount(int mask) {
    var count = 0;
    var value = mask;
    while (value != 0) {
      value &= value - 1;
      count++;
    }
    return count;
  }

  static int _lowestDigit(int mask) {
    for (var digit = 1; digit <= sudokuSize; digit++) {
      if (mask & (1 << (digit - 1)) != 0) return digit;
    }
    throw StateError('Empty candidate mask has no digit.');
  }
}
