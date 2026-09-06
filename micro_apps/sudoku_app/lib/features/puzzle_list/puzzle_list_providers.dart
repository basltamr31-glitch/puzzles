import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sudoku/data/puzzle_repository.dart';
import 'domain/puzzle_summary.dart';

/// Summaries for one difficulty. Keyed by difficulty alone — Sudoku has
/// no per-language puzzle content, so unlike the crossword app there is
/// no language dimension to cache across.
final puzzleSummariesProvider =
    FutureProvider.family<List<PuzzleSummary>, String>((ref, difficulty) {
  final repository = ref.watch(puzzleRepositoryProvider);
  return repository.listPuzzleSummaries(difficulty: difficulty);
});
