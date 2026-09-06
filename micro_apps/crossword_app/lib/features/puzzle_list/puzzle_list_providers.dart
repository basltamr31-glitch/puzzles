import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crossword/data/puzzle_repository.dart';
import 'domain/puzzle_summary.dart';

typedef PuzzleListArgs = ({String language, String difficulty});

final puzzleSummariesProvider =
    FutureProvider.family<List<PuzzleSummary>, PuzzleListArgs>((ref, args) {
      final repository = ref.watch(puzzleRepositoryProvider);
      return repository.listPuzzleSummaries(
        language: args.language,
        difficulty: args.difficulty,
      );
    });
