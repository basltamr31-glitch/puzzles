import 'achievement.dart';

/// How many mistakes a puzzle allows before it is failed.
const int maxMistakes = 3;

/// How many extra lives one run may buy with a rewarded ad.
///
/// One, not unlimited. A mistake limit you can always pay your way past
/// is not a limit, and an endless continue button would quietly turn a
/// three-mistake rule into "how many ads will you sit through". The cap
/// is per attempt and resets with it, so a restart or a solve always
/// begins on a clean three.
///
/// Note this does *not* enter `starsForSolve`: a bought life buys another
/// go at the puzzle, never a better result on it.
const int maxBonusLives = 1;

/// Stars for a solve. Three is the clean solve players chase: no mistakes
/// and no hints. Two allows a wobble. One is still a solve, and is
/// deliberately never zero — finishing a hard puzzle the messy way should
/// not read as a failure.
int starsForSolve({required int mistakes, required int hintsUsed}) {
  if (mistakes == 0 && hintsUsed == 0) return 3;
  if (mistakes <= 1 && hintsUsed <= 2) return 2;
  return 1;
}

/// What one solve earned, handed to the celebration dialog.
class SolveReward {
  const SolveReward({
    required this.stars,
    required this.mistakes,
    required this.hintsUsed,
    required this.streak,
    required this.isNewBestStreak,
    required this.isFirstSolveOfPuzzle,
    required this.newAchievements,
  });

  final int stars;
  final int mistakes;
  final int hintsUsed;
  final int streak;
  final bool isNewBestStreak;

  /// False when the player has solved this puzzle before — what keeps
  /// "puzzles solved" a count of puzzles rather than of solves.
  final bool isFirstSolveOfPuzzle;

  final List<Achievement> newAchievements;

  bool get isFlawless => stars == 3;
}
