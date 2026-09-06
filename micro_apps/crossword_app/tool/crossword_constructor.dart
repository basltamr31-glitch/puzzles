import 'dart:math';

/// One candidate answer + clue a puzzle can be built from.
class WordClue {
  const WordClue(this.answer, this.clue);

  final String answer;
  final String clue;
}

class PlacedWord {
  PlacedWord(this.wc, this.row, this.col, this.across);

  final WordClue wc;
  final int row;
  final int col;
  final bool across;
}

class CrosswordBuild {
  CrosswordBuild(this.words, this.rows, this.cols);

  final List<PlacedWord> words;
  final int rows;
  final int cols;
}

class _Cell {
  const _Cell(this.row, this.col);
  final int row;
  final int col;

  @override
  bool operator ==(Object other) => other is _Cell && other.row == row && other.col == col;

  @override
  int get hashCode => row * 1000003 + col;
}

/// A minimal but structurally correct crossword constructor.
///
/// Places words one at a time, always crossing an already-placed letter,
/// and rejects any placement that would create an accidental adjacency
/// (two words running side-by-side with no gap, which the app's grid
/// model can't represent as anything but one ambiguous run of letters).
/// This mirrors the two invariants [CrosswordGridGenerator] itself relies
/// on: every letter comes from an explicit word, and overlapping letters
/// must always agree.
class CrosswordConstructor {
  CrosswordConstructor(this.rng);

  final Random rng;

  /// Attempts one build. Returns null if the resulting grid doesn't meet
  /// [minWords] or exceeds [maxSize] in either dimension — callers should
  /// retry with a fresh shuffle when that happens.
  CrosswordBuild? tryBuild({
    required List<WordClue> pool,
    required int maxSize,
    required int minWords,
    required int targetWords,
  }) {
    final candidates = {for (final w in pool) w.answer: w}.values
        .where((w) => w.answer.length <= maxSize)
        .toList();
    if (candidates.isEmpty) return null;
    candidates.shuffle(rng);

    final placed = <PlacedWord>[];
    final grid = <_Cell, String>{};
    final used = <String>{};
    var bbox = (minR: 1 << 30, minC: 1 << 30, maxR: -(1 << 30), maxC: -(1 << 30));

    final seedPoolSize = min(10, candidates.length);
    final seed = candidates[rng.nextInt(seedPoolSize)];
    bbox = _place(placed, grid, seed, 0, 0, true, bbox);
    used.add(seed.answer);

    var progressed = true;
    while (placed.length < targetWords && progressed) {
      progressed = false;
      for (final cand in candidates) {
        if (placed.length >= targetWords) break;
        if (used.contains(cand.answer)) continue;
        final placement = _findPlacement(grid, cand.answer, maxSize, bbox);
        if (placement != null) {
          bbox = _place(
            placed,
            grid,
            cand,
            placement.row,
            placement.col,
            placement.across,
            bbox,
          );
          used.add(cand.answer);
          progressed = true;
        }
      }
    }

    if (placed.length < minWords) return null;

    final rows = bbox.maxR - bbox.minR + 1;
    final cols = bbox.maxC - bbox.minC + 1;
    if (rows > maxSize || cols > maxSize) return null;

    final normalized = placed
        .map((p) => PlacedWord(p.wc, p.row - bbox.minR, p.col - bbox.minC, p.across))
        .toList();
    return CrosswordBuild(normalized, rows, cols);
  }

  ({int minR, int minC, int maxR, int maxC}) _place(
    List<PlacedWord> placed,
    Map<_Cell, String> grid,
    WordClue wc,
    int row,
    int col,
    bool across,
    ({int minR, int minC, int maxR, int maxC}) bbox,
  ) {
    var minR = bbox.minR, minC = bbox.minC, maxR = bbox.maxR, maxC = bbox.maxC;
    for (var i = 0; i < wc.answer.length; i++) {
      final r = across ? row : row + i;
      final c = across ? col + i : col;
      grid[_Cell(r, c)] = wc.answer[i];
      minR = min(minR, r);
      minC = min(minC, c);
      maxR = max(maxR, r);
      maxC = max(maxC, c);
    }
    placed.add(PlacedWord(wc, row, col, across));
    return (minR: minR, minC: minC, maxR: maxR, maxC: maxC);
  }

  ({int row, int col, bool across})? _findPlacement(
    Map<_Cell, String> grid,
    String answer,
    int maxSize,
    ({int minR, int minC, int maxR, int maxC}) bbox,
  ) {
    final options = <({int row, int col, bool across, int score})>[];
    for (var i = 0; i < answer.length; i++) {
      final letter = answer[i];
      for (final entry in grid.entries) {
        if (entry.value != letter) continue;
        final cell = entry.key;
        for (final across in [true, false]) {
          final row = across ? cell.row : cell.row - i;
          final col = across ? cell.col - i : cell.col;
          if (!_fitsBbox(bbox, answer.length, row, col, across, maxSize)) continue;
          final intersections = _isValid(grid, answer, row, col, across);
          if (intersections == null) continue;
          final growth = _bboxGrowth(bbox, answer.length, row, col, across);
          // Favor placements that cross more existing words and grow the
          // grid the least, so puzzles read as tightly woven rather than
          // words dangling off a single shared letter.
          final score = intersections * 20 - growth;
          options.add((row: row, col: col, across: across, score: score));
        }
      }
    }
    if (options.isEmpty) return null;
    options.sort((a, b) => b.score.compareTo(a.score));
    final topCount = max(1, (options.length * 0.25).ceil());
    final top = options.take(topCount).toList()..shuffle(rng);
    final chosen = top.first;
    return (row: chosen.row, col: chosen.col, across: chosen.across);
  }

  int _bboxGrowth(
    ({int minR, int minC, int maxR, int maxC}) bbox,
    int length,
    int row,
    int col,
    bool across,
  ) {
    final endRow = across ? row : row + length - 1;
    final endCol = across ? col + length - 1 : col;
    final minR = min(bbox.minR, row);
    final minC = min(bbox.minC, col);
    final maxR = max(bbox.maxR, endRow);
    final maxC = max(bbox.maxC, endCol);
    final before = (bbox.maxR - bbox.minR + 1) * (bbox.maxC - bbox.minC + 1);
    final after = (maxR - minR + 1) * (maxC - minC + 1);
    return after - before;
  }

  bool _fitsBbox(
    ({int minR, int minC, int maxR, int maxC}) bbox,
    int length,
    int row,
    int col,
    bool across,
    int maxSize,
  ) {
    final endRow = across ? row : row + length - 1;
    final endCol = across ? col + length - 1 : col;
    final minR = min(bbox.minR, row);
    final minC = min(bbox.minC, col);
    final maxR = max(bbox.maxR, endRow);
    final maxC = max(bbox.maxC, endCol);
    return (maxR - minR + 1) <= maxSize && (maxC - minC + 1) <= maxSize;
  }

  /// Returns the number of letters this placement shares with the
  /// existing grid, or null if the placement is invalid.
  int? _isValid(Map<_Cell, String> grid, String answer, int row, int col, bool across) {
    var intersections = 0;
    for (var i = 0; i < answer.length; i++) {
      final r = across ? row : row + i;
      final c = across ? col + i : col;
      final existing = grid[_Cell(r, c)];
      if (existing != null) {
        if (existing != answer[i]) return null;
        intersections++;
        continue;
      }
      if (across) {
        if (grid.containsKey(_Cell(r - 1, c)) || grid.containsKey(_Cell(r + 1, c))) return null;
      } else {
        if (grid.containsKey(_Cell(r, c - 1)) || grid.containsKey(_Cell(r, c + 1))) return null;
      }
    }
    if (intersections == 0) return null;
    if (across) {
      if (grid.containsKey(_Cell(row, col - 1))) return null;
      if (grid.containsKey(_Cell(row, col + answer.length))) return null;
    } else {
      if (grid.containsKey(_Cell(row - 1, col))) return null;
      if (grid.containsKey(_Cell(row + answer.length, col))) return null;
    }
    return intersections;
  }
}
