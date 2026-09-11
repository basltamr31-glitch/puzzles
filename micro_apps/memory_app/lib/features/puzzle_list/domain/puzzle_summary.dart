import 'package:equatable/equatable.dart';

import '../../memory/domain/memory_theme.dart';

enum PuzzleStatus { notStarted, inProgress, completed }

/// Lightweight summary used by the puzzle-list screen — enough to render
/// a row and its progress marker without holding every deck's layout and
/// saved progress in memory at once.
///
/// Decks have no titles (unlike the crossword app, where the title is
/// authored content): a deck is identified by its position in the
/// difficulty, so the row label is built from [number] in the player's
/// own language rather than from anything stored in the asset.
class PuzzleSummary extends Equatable {
  const PuzzleSummary({
    required this.id,
    required this.difficulty,
    required this.index,
    required this.pairCount,
    required this.status,
    this.theme,
  });

  final String id;
  final String difficulty;

  /// Zero-based position within the difficulty — the routing key.
  final int index;

  /// How many pairs the board holds. Shown in the list because it is the
  /// one at-a-glance signal of "how long is this going to take" that
  /// players actually use when picking a deck.
  final int pairCount;

  final PuzzleStatus status;

  /// The family every symbol on the board comes from, on the tiers that
  /// draw from one. Null on the mixed tiers, and null for a theme this
  /// build does not recognise — the row simply shows no theme then.
  final MemoryTheme? theme;

  /// One-based position, for display.
  int get number => index + 1;

  @override
  List<Object?> get props => [id, difficulty, index, pairCount, status, theme];
}
