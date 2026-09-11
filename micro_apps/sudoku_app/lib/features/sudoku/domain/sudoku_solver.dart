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

  /// Two digits in a unit that can only go in the same two cells. The
  /// mirror of a naked pair, and materially harder to spot: a naked pair
  /// announces itself by the cells being short, a hidden pair is buried
  /// among other candidates.
  hiddenPair,

  /// Three cells in a unit whose candidates together span only three
  /// digits, in any distribution.
  nakedTriple,

  /// A digit whose candidates in two rows are confined to the same two
  /// columns (or vice versa) can be struck from those columns elsewhere.
  /// The first technique here that is not local to a single unit.
  xWing,

  /// None of the above make progress — finishing needs trial and error.
  ///
  /// This is deliberately *not* a difficulty tier any more. It used to be
  /// what "expert" required, which made expert unbounded in both
  /// directions: every technique past naked pair collapsed into it, so
  /// one expert grid might need a single hidden pair and the next a deep
  /// forcing chain. A puzzle that reaches this is now rejected by every
  /// tier — a Sudoku that cannot be finished by logic is a worse puzzle,
  /// not a harder one.
  guess;

  bool isHarderThan(SudokuTechnique other) => index > other.index;
}

/// What a logical solve of one grid actually cost.
///
/// The categorical [SudokuTechnique] alone was never enough to order
/// puzzles: it reports the single hardest step and says nothing about
/// whether that step happened once or eleven times, or about how long the
/// player hunts for each move in between. Both of those are what a player
/// experiences as difficulty.
class SudokuProfile {
  const SudokuProfile({
    required this.hardest,
    required this.uses,
    required this.steps,
    required this.scanLoad,
    required this.solved,
    required this.grid,
  });

  /// The hardest technique the solve needed.
  final SudokuTechnique hardest;

  /// How many times each technique was applied.
  final Map<SudokuTechnique, int> uses;

  /// Total technique applications.
  final int steps;

  /// Accumulated scanning effort: how hard it was to *find* each move,
  /// rather than how hard the move was once found.
  ///
  /// This is what separates a 36-clue "easy" from a 44-clue one. Both are
  /// naked-singles-only, so both grade identically, but the sparse one
  /// leaves only one or two placeable cells at a time and the player
  /// rescans the whole board for each. Measured as the shortfall below a
  /// comfortable frontier of ten simultaneous moves, summed over the
  /// solve.
  final double scanLoad;

  /// False when the technique ladder stalled before the grid was full.
  final bool solved;

  /// The grid as the technique ladder left it — complete when [solved],
  /// otherwise as far as pure logic got.
  ///
  /// Exposed so tests can assert that every digit the ladder placed
  /// agrees with the puzzle's real solution. A technique that eliminates
  /// a candidate it should not would otherwise fail silently: the solve
  /// still finishes, just with the wrong digits in it.
  final List<int> grid;

  /// A single ordering number for the whole puzzle.
  ///
  /// Weights are per *application*, so a grid needing three X-Wings
  /// outscores one needing a single X-Wing — which the technique ceiling
  /// alone could never express. The scan term is added at a deliberately
  /// modest coefficient: it should separate puzzles inside a tier without
  /// letting a tediously sparse easy grid outscore a genuinely tricky one.
  static const Map<SudokuTechnique, double> weights = {
    SudokuTechnique.nakedSingle: 1,
    SudokuTechnique.hiddenSingle: 3,
    SudokuTechnique.lockedCandidates: 14,
    SudokuTechnique.nakedPair: 22,
    SudokuTechnique.hiddenPair: 40,
    SudokuTechnique.nakedTriple: 50,
    SudokuTechnique.xWing: 80,
    SudokuTechnique.guess: 400,
  };

  double get score {
    var total = 0.0;
    uses.forEach((technique, count) {
      total += weights[technique]! * count;
    });
    return total + scanLoad * 1.5;
  }
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
      if (_applyHiddenPairs(working, candidates)) {
        record(SudokuTechnique.hiddenPair);
        continue;
      }
      if (_applyNakedTriples(working, candidates)) {
        record(SudokuTechnique.nakedTriple);
        continue;
      }
      if (_applyXWing(working, candidates)) {
        record(SudokuTechnique.xWing);
        continue;
      }
      return SudokuTechnique.guess;
    }
  }

  /// Solves [grid] the way a player would and reports what it cost.
  ///
  /// Structurally the same ladder as [grade], but it counts every
  /// application rather than only remembering the maximum, and measures
  /// how many placements were on offer at each step. [grade] is kept as a
  /// separate, cheaper method because the generator calls it once per
  /// trial removal, where the extra bookkeeping would be pure cost.
  static SudokuProfile profile(List<int> grid) {
    final working = List<int>.from(grid);
    final candidates = _computeCandidates(working);
    final uses = <SudokuTechnique, int>{};

    if (candidates == null) {
      return SudokuProfile(
        hardest: SudokuTechnique.guess,
        uses: const {SudokuTechnique.guess: 1},
        steps: 1,
        scanLoad: 0,
        solved: false,
        grid: working,
      );
    }

    var hardest = SudokuTechnique.nakedSingle;
    var steps = 0;
    var scanLoad = 0.0;

    // The frontier a player is comfortable with. Below this they are
    // rescanning the board to find the next move; above it, moves are
    // simply there to be taken.
    const comfortableFrontier = 10;

    bool step(SudokuTechnique technique, bool Function() apply) {
      if (!apply()) return false;
      uses[technique] = (uses[technique] ?? 0) + 1;
      steps++;
      if (technique.isHarderThan(hardest)) hardest = technique;
      return true;
    }

    while (working.contains(0)) {
      // Measured before the move is taken: this is what the player is
      // looking at when they go hunting for it.
      final available = _placeableCount(working, candidates);
      if (available > 0 && available < comfortableFrontier) {
        scanLoad += (comfortableFrontier - available) / available;
      }

      if (step(SudokuTechnique.nakedSingle,
          () => _applyNakedSingles(working, candidates))) {
        continue;
      }
      if (step(SudokuTechnique.hiddenSingle,
          () => _applyHiddenSingles(working, candidates))) {
        continue;
      }
      if (step(SudokuTechnique.lockedCandidates,
          () => _applyLockedCandidates(working, candidates))) {
        continue;
      }
      if (step(SudokuTechnique.nakedPair,
          () => _applyNakedPairs(working, candidates))) {
        continue;
      }
      if (step(SudokuTechnique.hiddenPair,
          () => _applyHiddenPairs(working, candidates))) {
        continue;
      }
      if (step(SudokuTechnique.nakedTriple,
          () => _applyNakedTriples(working, candidates))) {
        continue;
      }
      if (step(SudokuTechnique.xWing,
          () => _applyXWing(working, candidates))) {
        continue;
      }

      uses[SudokuTechnique.guess] = (uses[SudokuTechnique.guess] ?? 0) + 1;
      return SudokuProfile(
        hardest: SudokuTechnique.guess,
        uses: uses,
        steps: steps + 1,
        scanLoad: scanLoad,
        solved: false,
        grid: working,
      );
    }

    return SudokuProfile(
      hardest: hardest,
      uses: uses,
      steps: steps,
      scanLoad: scanLoad,
      solved: true,
      grid: working,
    );
  }

  /// Cells fillable right now by a naked or hidden single — the moves
  /// visibly on offer to the player at this moment.
  static int _placeableCount(List<int> grid, List<int> candidates) {
    final placeable = <int>{};
    for (var i = 0; i < sudokuCellCount; i++) {
      if (grid[i] == 0 && _bitCount(candidates[i]) == 1) placeable.add(i);
    }
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
        if (!alreadyPlaced && count == 1) placeable.add(seen);
      }
    }
    return placeable.length;
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

  /// Two digits in a unit whose only possible cells are the same two.
  /// Those cells must hold those digits, so every *other* candidate is
  /// struck from them. The elimination happens inside the pair, which is
  /// what makes it harder to see than a naked pair.
  static bool _applyHiddenPairs(List<int> grid, List<int> candidates) {
    var progressed = false;
    for (final unit in sudokuUnits) {
      // Where each still-unplaced digit could go in this unit.
      final places = <int, List<int>>{};
      for (var digit = 1; digit <= sudokuSize; digit++) {
        final bit = 1 << (digit - 1);
        if (unit.any((i) => grid[i] == digit)) continue;
        final cells = [
          for (final i in unit)
            if (grid[i] == 0 && candidates[i] & bit != 0) i,
        ];
        if (cells.length == 2) places[digit] = cells;
      }

      final digits = places.keys.toList();
      for (var a = 0; a < digits.length; a++) {
        for (var b = a + 1; b < digits.length; b++) {
          final first = places[digits[a]]!;
          final second = places[digits[b]]!;
          if (first[0] != second[0] || first[1] != second[1]) continue;

          final mask = (1 << (digits[a] - 1)) | (1 << (digits[b] - 1));
          for (final index in first) {
            if (candidates[index] == mask) continue;
            candidates[index] &= mask;
            progressed = true;
          }
        }
      }
    }
    return progressed;
  }

  /// Three cells in a unit whose candidates together span exactly three
  /// digits. Unlike a naked pair the cells need not each hold all three,
  /// which is why it sits above hidden pairs rather than beside naked
  /// pairs: the shape is much less obvious on the board.
  static bool _applyNakedTriples(List<int> grid, List<int> candidates) {
    var progressed = false;
    for (final unit in sudokuUnits) {
      final cells = [
        for (final i in unit)
          if (grid[i] == 0 && _bitCount(candidates[i]) <= sudokuBoxSize) i,
      ];
      for (var a = 0; a < cells.length; a++) {
        for (var b = a + 1; b < cells.length; b++) {
          for (var c = b + 1; c < cells.length; c++) {
            final mask = candidates[cells[a]] |
                candidates[cells[b]] |
                candidates[cells[c]];
            if (_bitCount(mask) != sudokuBoxSize) continue;

            for (final index in unit) {
              if (index == cells[a] || index == cells[b] || index == cells[c]) {
                continue;
              }
              if (grid[index] != 0) continue;
              if (candidates[index] & mask == 0) continue;
              candidates[index] &= ~mask;
              progressed = true;
            }
          }
        }
      }
    }
    return progressed;
  }

  /// Two rows in which a digit has exactly two possible columns, both
  /// rows using the *same* two columns. The digit must take one of those
  /// cells in each row, so it cannot appear anywhere else in either
  /// column — and symmetrically with rows and columns swapped.
  ///
  /// The first technique here that reasons across units rather than
  /// inside one, which is the real step up in difficulty.
  static bool _applyXWing(List<int> grid, List<int> candidates) {
    var progressed = false;
    for (var digit = 1; digit <= sudokuSize; digit++) {
      final bit = 1 << (digit - 1);

      // byRow scans rows and eliminates down columns; the second pass is
      // the transpose. Written once rather than twice because the two
      // halves differ only in how a line's cells are addressed.
      for (final byRow in const [true, false]) {
        int cellAt(int line, int offset) =>
            byRow ? indexOf(line, offset) : indexOf(offset, line);

        final lines = <int, List<int>>{};
        for (var line = 0; line < sudokuSize; line++) {
          final offsets = [
            for (var offset = 0; offset < sudokuSize; offset++)
              if (grid[cellAt(line, offset)] == 0 &&
                  candidates[cellAt(line, offset)] & bit != 0)
                offset,
          ];
          if (offsets.length == 2) lines[line] = offsets;
        }

        final keys = lines.keys.toList();
        for (var a = 0; a < keys.length; a++) {
          for (var b = a + 1; b < keys.length; b++) {
            final first = lines[keys[a]]!;
            final second = lines[keys[b]]!;
            if (first[0] != second[0] || first[1] != second[1]) continue;

            for (final offset in first) {
              for (var line = 0; line < sudokuSize; line++) {
                if (line == keys[a] || line == keys[b]) continue;
                final index = cellAt(line, offset);
                if (grid[index] != 0) continue;
                if (candidates[index] & bit == 0) continue;
                candidates[index] &= ~bit;
                progressed = true;
              }
            }
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
