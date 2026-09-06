import 'package:equatable/equatable.dart';

enum PuzzleStatus { notStarted, inProgress, completed }

/// Lightweight summary used by the puzzle-list screen — enough to render
/// a row and its progress marker without holding the full playable grid
/// in memory for every puzzle at once.
class PuzzleSummary extends Equatable {
  const PuzzleSummary({
    required this.assetPath,
    required this.id,
    required this.title,
    required this.status,
  });

  final String assetPath;
  final String id;
  final String title;
  final PuzzleStatus status;

  @override
  List<Object?> get props => [assetPath, id, title, status];
}
