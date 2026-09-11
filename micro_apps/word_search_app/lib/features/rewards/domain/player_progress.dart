import 'dart:convert';

import 'package:equatable/equatable.dart';

/// The player's local calendar day, as `yyyy-mm-dd`.
///
/// Local rather than UTC on purpose: a streak is a promise about the
/// player's own days, and someone playing at 11pm in UTC+3 has not
/// skipped a day just because it is already tomorrow in Greenwich.
String dayKey(DateTime moment) {
  final local = moment.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

/// Everything the player carries between puzzles: how many they have
/// solved, how well, how many days in a row, and which badges that has
/// earned them.
///
/// Deliberately a plain value object with no I/O of its own — the streak
/// arithmetic in [afterSolve] is the part most worth testing, and it is
/// pure.
class PlayerProgress extends Equatable {
  const PlayerProgress({
    this.totalSolved = 0,
    this.flawlessSolves = 0,
    this.totalStars = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastSolvedDay,
    this.unlockedAchievements = const {},
  });

  final int totalSolved;

  /// Solves that cost neither a mistake nor a hint.
  final int flawlessSolves;

  /// Stars banked across every puzzle, counting each puzzle's best result
  /// once — re-solving a puzzle can raise its stars but never double them.
  final int totalStars;

  final int currentStreak;
  final int bestStreak;

  /// [dayKey] of the last solve, or null before the first one.
  final String? lastSolvedDay;

  final Set<String> unlockedAchievements;

  static const empty = PlayerProgress();

  /// This progress updated for a solve on [now].
  ///
  /// [starsGained] is the *improvement* on that puzzle's previous best, so
  /// replaying a puzzle for a better result tops up the total instead of
  /// counting the whole thing twice. [countsAsNew] is false for a replay,
  /// which is what keeps "puzzles solved" a count of puzzles rather than
  /// of solves.
  ///
  /// A second solve on a day the player has already played extends nothing
  /// — the streak counts days, not puzzles, so it must not be possible to
  /// farm it by finishing five puzzles in one sitting.
  PlayerProgress afterSolve({
    required DateTime now,
    required int starsGained,
    required bool isFlawless,
    required bool countsAsNew,
  }) {
    final today = dayKey(now);
    final yesterday = dayKey(now.subtract(const Duration(days: 1)));

    final int streak;
    if (lastSolvedDay == today) {
      streak = currentStreak == 0 ? 1 : currentStreak;
    } else if (lastSolvedDay == yesterday) {
      streak = currentStreak + 1;
    } else {
      streak = 1;
    }

    return PlayerProgress(
      totalSolved: countsAsNew ? totalSolved + 1 : totalSolved,
      flawlessSolves: isFlawless && countsAsNew
          ? flawlessSolves + 1
          : flawlessSolves,
      totalStars: totalStars + starsGained,
      currentStreak: streak,
      bestStreak: streak > bestStreak ? streak : bestStreak,
      lastSolvedDay: today,
      unlockedAchievements: unlockedAchievements,
    );
  }

  /// The streak as it should *read* on [now], which is not always the
  /// stored number: a stored streak whose last solve was two days ago is
  /// already broken, and showing it until the next solve would tell the
  /// player they still have something they have in fact lost.
  int streakOn(DateTime now) {
    if (lastSolvedDay == null) return 0;
    final today = dayKey(now);
    final yesterday = dayKey(now.subtract(const Duration(days: 1)));
    if (lastSolvedDay == today || lastSolvedDay == yesterday) {
      return currentStreak;
    }
    return 0;
  }

  PlayerProgress withAchievements(Set<String> ids) {
    return PlayerProgress(
      totalSolved: totalSolved,
      flawlessSolves: flawlessSolves,
      totalStars: totalStars,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      lastSolvedDay: lastSolvedDay,
      unlockedAchievements: ids,
    );
  }

  Map<String, Object?> toJson() => {
    'totalSolved': totalSolved,
    'flawlessSolves': flawlessSolves,
    'totalStars': totalStars,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'lastSolvedDay': lastSolvedDay,
    'unlockedAchievements': unlockedAchievements.toList()..sort(),
  };

  String encode() => jsonEncode(toJson());

  /// Returns [empty] for anything unreadable. Progress is a nice-to-have
  /// layered on top of the game; a corrupted record must never be able to
  /// stop a player from opening a puzzle.
  static PlayerProgress decode(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return empty;
      int readInt(String key) {
        final value = json[key];
        return value is int && value >= 0 ? value : 0;
      }

      final day = json['lastSolvedDay'];
      final badges = json['unlockedAchievements'];
      return PlayerProgress(
        totalSolved: readInt('totalSolved'),
        flawlessSolves: readInt('flawlessSolves'),
        totalStars: readInt('totalStars'),
        currentStreak: readInt('currentStreak'),
        bestStreak: readInt('bestStreak'),
        lastSolvedDay: day is String && day.isNotEmpty ? day : null,
        unlockedAchievements: badges is List
            ? {for (final b in badges) if (b is String) b}
            : const {},
      );
    } catch (_) {
      return empty;
    }
  }

  @override
  List<Object?> get props => [
    totalSolved,
    flawlessSolves,
    totalStars,
    currentStreak,
    bestStreak,
    lastSolvedDay,
    (unlockedAchievements.toList()..sort()).join(','),
  ];
}
