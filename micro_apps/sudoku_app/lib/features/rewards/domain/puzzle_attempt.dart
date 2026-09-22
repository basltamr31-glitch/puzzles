import 'dart:convert';

import 'solve_reward.dart';

/// What the current run at one puzzle has cost so far.
///
/// Stored under its own key rather than folded into each app's saved
/// progress, because a mistake limit that resets when the player backs out
/// to the puzzle list and walks straight back in is not a limit.
class PuzzleAttempt {
  const PuzzleAttempt({
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.bonusLives = 0,
  });

  final int mistakes;
  final int hintsUsed;

  /// Extra lives earned on this run, each one paid for with a rewarded ad
  /// (or granted free to a player who has removed ads).
  ///
  /// Deliberately a *separate* counter rather than a discount on
  /// [mistakes]: stars are scored from the real mistake count, so
  /// decrementing that would quietly let an ad buy a better result. This
  /// way the run continues while the scoreboard still remembers what it
  /// cost.
  final int bonusLives;

  static const empty = PuzzleAttempt();

  bool get isFailed => mistakes >= maxMistakes + bonusLives;

  /// Whether another life can still be earned on this run.
  bool get canEarnBonusLife => bonusLives < maxBonusLives;

  PuzzleAttempt copyWith({int? mistakes, int? hintsUsed, int? bonusLives}) =>
      PuzzleAttempt(
        mistakes: mistakes ?? this.mistakes,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        bonusLives: bonusLives ?? this.bonusLives,
      );

  String encode() => jsonEncode({
    'mistakes': mistakes,
    'hintsUsed': hintsUsed,
    'bonusLives': bonusLives,
  });

  /// Returns [empty] for anything unreadable — a corrupt counter must
  /// never be able to lock a player out of a puzzle they can still solve.
  ///
  /// A record written before bonus lives existed simply has no
  /// `bonusLives` key and decodes to 0, which is exactly the old
  /// behaviour.
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
        // Clamped to the *reachable* ceiling, not to maxMistakes: with a
        // bonus life in play a run legitimately passes three mistakes,
        // and clamping at three would hand the player a free extra life
        // every time the puzzle was reopened.
        mistakes: read('mistakes').clamp(0, maxMistakes + maxBonusLives),
        hintsUsed: read('hintsUsed'),
        bonusLives: read('bonusLives').clamp(0, maxBonusLives),
      );
    } catch (_) {
      return empty;
    }
  }
}
