import 'package:flutter_test/flutter_test.dart';
import 'package:memory_app/core/storage/local_storage_service.dart';
import 'package:memory_app/features/rewards/data/rewards_repository.dart';
import 'package:memory_app/features/rewards/domain/achievement.dart';
import 'package:memory_app/features/rewards/domain/player_progress.dart';
import 'package:memory_app/features/rewards/domain/puzzle_attempt.dart';
import 'package:memory_app/features/rewards/domain/solve_reward.dart';
import 'package:memory_app/features/rewards/rewards_controller.dart';

class _InMemoryStorage implements LocalStorageService {
  final Map<String, Object> _values = {};

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _values.remove(key);
    return true;
  }
}

void main() {
  group('starsForSolve', () {
    test('three stars only for a solve that cost nothing', () {
      expect(starsForSolve(mistakes: 0, hintsUsed: 0), 3);
      expect(starsForSolve(mistakes: 1, hintsUsed: 0), 2);
      expect(starsForSolve(mistakes: 0, hintsUsed: 1), 2);
    });

    test('a messy solve is still worth a star, never zero', () {
      // Finishing a hard puzzle the slow way should not read as failure.
      expect(starsForSolve(mistakes: 2, hintsUsed: 9), 1);
      expect(starsForSolve(mistakes: maxMistakes, hintsUsed: 99), 1);
    });
  });

  group('PlayerProgress streaks', () {
    final monday = DateTime(2026, 3, 2, 20);
    final tuesday = DateTime(2026, 3, 3, 9);
    final thursday = DateTime(2026, 3, 5, 9);

    PlayerProgress solve(PlayerProgress from, DateTime when) => from.afterSolve(
      now: when,
      starsGained: 3,
      isFlawless: true,
      countsAsNew: true,
    );

    test('a first solve starts the streak at one', () {
      expect(solve(PlayerProgress.empty, monday).currentStreak, 1);
    });

    test('a solve the next day extends it', () {
      final after = solve(solve(PlayerProgress.empty, monday), tuesday);
      expect(after.currentStreak, 2);
      expect(after.bestStreak, 2);
    });

    test('a second solve the same day does not extend it', () {
      // Otherwise the streak would count puzzles, not days, and could be
      // farmed in one sitting.
      final once = solve(PlayerProgress.empty, monday);
      final twice = solve(once, DateTime(2026, 3, 2, 23));
      expect(twice.currentStreak, 1);
      expect(twice.totalSolved, 2);
    });

    test('a skipped day restarts the streak but keeps the best', () {
      final tue = solve(solve(PlayerProgress.empty, monday), tuesday);
      final thu = solve(tue, thursday);
      expect(thu.currentStreak, 1);
      expect(thu.bestStreak, 2);
    });

    test('a stale streak reads as broken before the next solve', () {
      // The stored number is still 2; what the player has *today* is 0.
      final tue = solve(solve(PlayerProgress.empty, monday), tuesday);
      expect(tue.currentStreak, 2);
      expect(tue.streakOn(thursday), 0);
      expect(tue.streakOn(DateTime(2026, 3, 4, 9)), 2);
    });
  });

  group('PlayerProgress serialization', () {
    test('round-trips', () {
      const progress = PlayerProgress(
        totalSolved: 12,
        flawlessSolves: 4,
        totalStars: 30,
        currentStreak: 3,
        bestStreak: 9,
        lastSolvedDay: '2026-03-02',
        unlockedAchievements: {'first_solve', 'ten_solves'},
      );
      expect(PlayerProgress.decode(progress.encode()), progress);
    });

    test('unreadable storage decodes to empty rather than throwing', () {
      // Progress is a layer on top of the game; a corrupt record must
      // never stop a player opening a puzzle.
      expect(PlayerProgress.decode(null), PlayerProgress.empty);
      expect(PlayerProgress.decode('not json'), PlayerProgress.empty);
      expect(PlayerProgress.decode('[]'), PlayerProgress.empty);
      expect(
        PlayerProgress.decode('{"totalSolved":-5,"bestStreak":"x"}'),
        PlayerProgress.empty,
      );
    });
  });

  group('PuzzleAttempt', () {
    test('round-trips and clamps a corrupt mistake count', () {
      const attempt = PuzzleAttempt(mistakes: 2, hintsUsed: 1);
      expect(PuzzleAttempt.decode(attempt.encode()).mistakes, 2);
      expect(PuzzleAttempt.decode(attempt.encode()).hintsUsed, 1);
      // The ceiling is what a run can actually reach, which a bonus life
      // raises by one — not maxMistakes.
      expect(
        PuzzleAttempt.decode('{"mistakes":99}').mistakes,
        maxMistakes + maxBonusLives,
      );
      expect(PuzzleAttempt.decode('rubbish'), PuzzleAttempt.empty);
    });

    test('is failed exactly at the limit', () {
      expect(const PuzzleAttempt(mistakes: maxMistakes - 1).isFailed, isFalse);
      expect(const PuzzleAttempt(mistakes: maxMistakes).isFailed, isTrue);
    });

    test('a bonus life extends the limit by exactly one mistake', () {
      expect(
        const PuzzleAttempt(mistakes: maxMistakes, bonusLives: 1).isFailed,
        isFalse,
      );
      expect(
        const PuzzleAttempt(mistakes: maxMistakes + 1, bonusLives: 1).isFailed,
        isTrue,
      );
    });

    test('bonus lives round-trip and are capped', () {
      const revived = PuzzleAttempt(mistakes: 3, hintsUsed: 1, bonusLives: 1);
      expect(PuzzleAttempt.decode(revived.encode()).bonusLives, 1);
      expect(
        PuzzleAttempt.decode('{"mistakes":0,"bonusLives":99}').bonusLives,
        maxBonusLives,
      );
    });

    // The regression this guards: clamping `mistakes` at maxMistakes meant
    // a run continuing on a bonus life came back from storage with its
    // fourth mistake erased, so reopening the puzzle handed out a fresh
    // extra life every time.
    test('a revived run survives a reload without gaining a free life', () {
      const spent = PuzzleAttempt(mistakes: maxMistakes + 1, bonusLives: 1);
      final reloaded = PuzzleAttempt.decode(spent.encode());
      expect(reloaded.mistakes, maxMistakes + 1);
      expect(reloaded.bonusLives, 1);
      expect(reloaded.isFailed, isTrue);
      expect(reloaded.canEarnBonusLife, isFalse);
    });

    test('a record written before bonus lives existed decodes to none', () {
      final legacy = PuzzleAttempt.decode('{"mistakes":1,"hintsUsed":2}');
      expect(legacy.mistakes, 1);
      expect(legacy.hintsUsed, 2);
      expect(legacy.bonusLives, 0);
      expect(legacy.canEarnBonusLife, isTrue);
    });

    test('an extra life buys another go, never a better result', () {
      // Same three mistakes either way: the star score reads the real
      // count, so the ad cannot move it.
      expect(
        starsForSolve(mistakes: maxMistakes, hintsUsed: 0),
        starsForSolve(mistakes: maxMistakes, hintsUsed: 0),
      );
      const revived = PuzzleAttempt(mistakes: maxMistakes, bonusLives: 1);
      expect(revived.mistakes, maxMistakes);
    });
  });

  group('RewardsController', () {
    late _InMemoryStorage storage;
    late RewardsController controller;

    setUp(() {
      storage = _InMemoryStorage();
      controller = RewardsController(RewardsRepository(storage));
    });

    tearDown(() => controller.dispose());

    test('a first solve banks stars and counts the puzzle', () {
      final reward = controller.recordSolve(
        puzzleId: 'easy_001',
        mistakes: 0,
        hintsUsed: 0,
      );
      expect(reward.stars, 3);
      expect(reward.isFirstSolveOfPuzzle, isTrue);
      expect(controller.state.totalSolved, 1);
      expect(controller.state.totalStars, 3);
      expect(controller.starsFor('easy_001'), 3);
    });

    test('replaying a puzzle does not double-count it', () {
      controller.recordSolve(puzzleId: 'easy_001', mistakes: 2, hintsUsed: 0);
      final replay = controller.recordSolve(
        puzzleId: 'easy_001',
        mistakes: 0,
        hintsUsed: 0,
      );

      expect(replay.isFirstSolveOfPuzzle, isFalse);
      expect(controller.state.totalSolved, 1, reason: 'still one puzzle');
      // 1 star first time, improved to 3 — the total moves by the
      // difference, not by the whole result again.
      expect(controller.state.totalStars, 3);
      expect(controller.starsFor('easy_001'), 3);
    });

    test('a worse replay never lowers the recorded stars', () {
      controller.recordSolve(puzzleId: 'easy_001', mistakes: 0, hintsUsed: 0);
      controller.recordSolve(puzzleId: 'easy_001', mistakes: 2, hintsUsed: 4);
      expect(controller.starsFor('easy_001'), 3);
      expect(controller.state.totalStars, 3);
    });

    test('a badge is reported once, on the solve that earns it', () {
      final first = controller.recordSolve(
        puzzleId: 'easy_001',
        mistakes: 0,
        hintsUsed: 0,
      );
      expect(
        first.newAchievements.map((a) => a.id),
        contains(Achievement.firstSolve.id),
      );

      final second = controller.recordSolve(
        puzzleId: 'easy_002',
        mistakes: 0,
        hintsUsed: 0,
      );
      expect(second.newAchievements, isEmpty);
      expect(
        controller.state.unlockedAchievements,
        contains(Achievement.firstSolve.id),
      );
    });

    test('progress survives a fresh controller over the same storage', () {
      controller.recordSolve(puzzleId: 'easy_001', mistakes: 0, hintsUsed: 0);
      final reloaded = RewardsController(RewardsRepository(storage));
      addTearDown(reloaded.dispose);

      expect(reloaded.state.totalSolved, 1);
      expect(reloaded.state.totalStars, 3);
      expect(reloaded.starsFor('easy_001'), 3);
    });

    test('the flawless badge counts only three-star solves', () {
      for (var i = 0; i < 5; i++) {
        controller.recordSolve(
          puzzleId: 'easy_00$i',
          mistakes: 1,
          hintsUsed: 0,
        );
      }
      expect(controller.state.flawlessSolves, 0);
      expect(
        Achievement.flawlessFive.isEarnedBy(controller.state),
        isFalse,
      );

      for (var i = 0; i < 5; i++) {
        controller.recordSolve(
          puzzleId: 'hard_00$i',
          mistakes: 0,
          hintsUsed: 0,
        );
      }
      expect(controller.state.flawlessSolves, 5);
      expect(Achievement.flawlessFive.isEarnedBy(controller.state), isTrue);
    });
  });
}
