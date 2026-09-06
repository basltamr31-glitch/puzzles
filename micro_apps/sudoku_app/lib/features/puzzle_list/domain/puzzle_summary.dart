import 'package:equatable/equatable.dart';

enum PuzzleStatus { notStarted, inProgress, completed }

/// Lightweight summary used by the puzzle-list screen — enough to render
/// a row and its progress marker without holding every puzzle's grid and
/// saved progress in memory at once.
///
/// Puzzles have no titles here (unlike the crossword app, where the title
/// is authored content): a Sudoku is identified by its position in the
/// difficulty, so the row label is built from [number] in the player's
/// own language rather than from anything stored in the asset.
class PuzzleSummary extends Equatable {
  const PuzzleSummary({
    required this.id,
    required this.difficulty,
    required this.index,
    required this.givenCount,
    required this.status,
  });

  final String id;
  final String difficulty;

  /// Zero-based position within the difficulty — the routing key.
  final int index;

  /// How many clues the puzzle starts with. Shown in the list because it
  /// is the one at-a-glance signal of "how empty is this grid" that
  /// players actually use when picking one.
  final int givenCount;

  final PuzzleStatus status;

  /// One-based position, for display.
  int get number => index + 1;

  @override
  List<Object?> get props => [id, difficulty, index, givenCount, status];
}
