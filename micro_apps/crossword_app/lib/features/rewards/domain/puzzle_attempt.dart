import 'dart:convert';

import 'solve_reward.dart';

/// What the current run at one puzzle has cost so far.
///
/// Stored under its own key rather than folded into each app's saved
/// progress, because a mistake limit that resets when the player backs out
/// to the puzzle list and walks straight back in is not a limit at all.
class PuzzleAttempt {
  const PuzzleAttempt({this.mistakes = 0, this.hintsUsed = 0});

  final int mistakes;
  final int hintsUsed;

  static const empty = PuzzleAttempt();

  bool get isFailed => mistakes >= maxMistakes;

  PuzzleAttempt copyWith({int? mistakes, int? hintsUsed}) => PuzzleAttempt(
    mistakes: mistakes ?? this.mistakes,
    hintsUsed: hintsUsed ?? this.hintsUsed,
  );

  String encode() => jsonEncode({'mistakes': mistakes, 'hintsUsed': hintsUsed});

  /// Returns [empty] for anything unreadable — a corrupt counter must
  /// never be able to lock a player out of a puzzle they can still solve.
  static PuzzleAttempt decode(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return empty;
      int read(String key) {
        final value = json[key];
        return value is int && value >= 0 ? value : 0;
      }

      return PuzzleAttempt(
        mistakes: read('mistakes').clamp(0, maxMistakes),
        hintsUsed: read('hintsUsed'),
      );
    } catch (_) {
      return empty;
    }
  }
}
