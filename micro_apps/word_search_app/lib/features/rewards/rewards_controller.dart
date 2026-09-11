import 'package:flutter_riverpod/legacy.dart';

import 'data/rewards_repository.dart';
import 'domain/achievement.dart';
import 'domain/player_progress.dart';
import 'domain/solve_reward.dart';

/// Owns the player's cross-puzzle progress: totals, streak, and badges.
///
/// Deliberately separate from the per-puzzle game controllers: those are
/// `autoDispose`d the moment the player leaves a puzzle, and a streak that
/// evaporated on navigation would be worse than no streak at all.
class RewardsController extends StateNotifier<PlayerProgress> {
  RewardsController(this._repository) : super(_repository.loadProgress());

  final RewardsRepository _repository;

  /// Records a solved puzzle and returns what it earned.
  ///
  /// Safe to call again for a puzzle already solved: the star total only
  /// ever moves by the *improvement* on that puzzle's previous best, and
  /// the solved count does not move at all. Replaying a puzzle for a
  /// cleaner result is meant to be worth something, without being a way to
  /// inflate the totals by grinding the same easy grid.
  SolveReward recordSolve({
    required String puzzleId,
    required int mistakes,
    required int hintsUsed,
    DateTime? now,
  }) {
    final previous = state;
    final moment = now ?? DateTime.now();
    final stars = starsForSolve(mistakes: mistakes, hintsUsed: hintsUsed);
    final previousStars = _repository.starsFor(puzzleId);
    final isFirstSolve = previousStars == 0;

    final updated = previous.afterSolve(
      now: moment,
      starsGained: stars > previousStars ? stars - previousStars : 0,
      isFlawless: stars == 3,
      countsAsNew: isFirstSolve,
    );

    final newlyEarned = [
      for (final achievement in Achievement.values)
        if (achievement.isEarnedBy(updated) &&
            !previous.unlockedAchievements.contains(achievement.id))
          achievement,
    ];

    final next = updated.withAchievements({
      ...previous.unlockedAchievements,
      for (final achievement in newlyEarned) achievement.id,
    });
    state = next;

    if (stars > previousStars) {
      _repository.saveStars(puzzleId, stars);
    }
    _repository.saveProgress(next);

    return SolveReward(
      stars: stars,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      streak: next.currentStreak,
      isNewBestStreak: next.bestStreak > previous.bestStreak,
      isFirstSolveOfPuzzle: isFirstSolve,
      newAchievements: newlyEarned,
    );
  }

  /// The best star result the player has recorded for [puzzleId].
  int starsFor(String puzzleId) => _repository.starsFor(puzzleId);
}

final rewardsControllerProvider =
    StateNotifierProvider<RewardsController, PlayerProgress>(
      (ref) => RewardsController(ref.watch(rewardsRepositoryProvider)),
    );
