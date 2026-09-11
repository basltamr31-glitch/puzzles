import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../memory/data/deck_repository.dart';
import 'domain/puzzle_summary.dart';

/// Summaries for one difficulty. Keyed by difficulty alone — decks hold
/// emoji rather than words, so unlike the crossword and word search apps
/// there is no language dimension to cache across.
final puzzleSummariesProvider =
    FutureProvider.family<List<PuzzleSummary>, String>((ref, difficulty) {
  final repository = ref.watch(deckRepositoryProvider);
  return repository.listPuzzleSummaries(difficulty: difficulty);
});
