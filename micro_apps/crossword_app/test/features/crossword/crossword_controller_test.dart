import 'package:crossword_app/core/analytics/analytics_events.dart';
import 'package:crossword_app/core/storage/local_storage_service.dart';
import 'package:crossword_app/core/storage/storage_keys.dart';
import 'package:crossword_app/features/rewards/data/rewards_repository.dart';
import 'package:crossword_app/features/rewards/domain/solve_reward.dart';
import 'package:crossword_app/features/crossword/data/puzzle_repository.dart';
import 'package:crossword_app/features/crossword/domain/crossword_models.dart';
import 'package:crossword_app/features/crossword/presentation/controllers/crossword_controller.dart';
import 'package:crossword_app/features/puzzle_list/domain/puzzle_summary.dart';
import 'package:crossword_app/features/puzzle_list/puzzle_list_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fake_analytics_service.dart';

/// A dedicated, stable test fixture (not a real shipped puzzle) — a
/// hand-verified 3x3:
///   C A T
///   A # O
///   R A T
/// (1 across CAT / 1 down CAR / 2 down TOT / 3 across RAT). Puzzle content
/// under assets/puzzles/ is owned by the crossword generator (tool/) and
/// regenerated periodically, so these tests intentionally assert against
/// a fixture the generator never touches rather than coupling to whatever
/// happens to be in a real puzzle slot today.
const _assetPath = 'assets/test_fixtures/sample_puzzle.json';
const _puzzleId = 'test_fixture_001';

const _solution = {
  '0,0': 'C', '0,1': 'A', '0,2': 'T',
  '1,0': 'A', '1,2': 'O',
  '2,0': 'R', '2,1': 'A', '2,2': 'T',
};

class _InMemoryStorage implements LocalStorageService {
  final Map<String, Object> _values = {};

  @override
  bool? getBool(String key) => _values[key] as bool?;
  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  String? getString(String key) => _values[key] as String?;
  @override
  Future<bool> setString(String key, String value) async {
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

/// [CrosswordController]'s constructor kicks off an async `_load()` that
/// isn't otherwise awaitable from outside, so tests poll `state.isLoading`
/// instead of guessing a fixed delay.
Future<void> _waitForLoad(CrosswordController controller) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (controller.state.isLoading && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void _enterSolutionCell(CrosswordController controller, String key, String letter) {
  final parts = key.split(',');
  controller.selectCell(int.parse(parts[0]), int.parse(parts[1]));
  controller.enterLetter(letter);
}

Future<CrosswordController> _completePuzzle(CrosswordController controller) async {
  for (final entry in _solution.entries) {
    _enterSolutionCell(controller, entry.key, entry.value);
  }
  return controller;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _InMemoryStorage storage;
  late PuzzleRepository repository;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;

  setUp(() {
    storage = _InMemoryStorage();
    repository = PuzzleRepository(storage);
    analytics = FakeAnalyticsService();
    // Same storage instance the controller writes through, so
    // puzzleSummariesProvider reads the completion state these tests
    // actually produce rather than a separate empty store.
    container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
    );
  });

  tearDown(() async {
    // Completion and restart do their persistence fire-and-forget, so a
    // test can finish with that work still queued. Disposing the
    // container out from under it invalidates the Ref the controller is
    // about to call `invalidate` on, and the failure surfaces on whatever
    // test runs next rather than on the one that caused it.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    container.dispose();
  });

  Future<CrosswordController> loadController() async {
    // CrosswordController invalidates puzzleSummariesProvider through this
    // Ref on completion/restart; a plain ProviderContainer gives it a real
    // one to call into without needing the full crosswordControllerProvider
    // wiring in these unit tests.
    final controller = CrosswordController(
      repository,
      RewardsRepository(storage),
      analytics,
      container.read(Provider((ref) => ref)),
      _assetPath,
    );
    await _waitForLoad(controller);
    return controller;
  }

  test('loads the grid and selects the first across clue', () async {
    final controller = await loadController();
    final state = controller.state;

    expect(state.errorMessage, isNull);
    expect(state.grid, isNotNull);
    expect(state.selectedRow, 0);
    expect(state.selectedCol, 0);
    expect(state.direction, WordDirection.across);
    expect(state.isCompleted, isFalse);
  });

  test('logs puzzle_started for a fresh puzzle', () async {
    await loadController();
    expect(analytics.hasEvent(AnalyticsEvents.puzzleStarted), isTrue);
  });

  test('does not log puzzle_started for an already-completed puzzle', () async {
    await storage.setBool(StorageKeys.puzzleCompleted(_puzzleId), true);
    await loadController();
    expect(analytics.hasEvent(AnalyticsEvents.puzzleStarted), isFalse);
  });

  group('selectCell', () {
    test('toggles direction when tapping the same cell twice, if both directions exist',
        () async {
      final controller = await loadController();
      expect(controller.state.direction, WordDirection.across); // (0,0): CAT & CAR

      controller.selectCell(0, 0);
      expect(controller.state.direction, WordDirection.down);

      controller.selectCell(0, 0);
      expect(controller.state.direction, WordDirection.across);
    });

    test('switches direction automatically when the current direction has no word there',
        () async {
      final controller = await loadController();
      // (1,0) only has a down word (CAR) through it, no across word.
      controller.selectCell(1, 0);
      expect(controller.state.direction, WordDirection.down);
      expect(controller.state.selectedRow, 1);
      expect(controller.state.selectedCol, 0);
    });

    test('ignores taps on blocked cells', () async {
      final controller = await loadController();
      controller.selectCell(1, 1); // blocked
      expect(controller.state.selectedRow, 0);
      expect(controller.state.selectedCol, 0);
    });
  });

  group('enterLetter', () {
    test('stores an uppercased letter and advances within the word', () async {
      final controller = await loadController();
      controller.enterLetter('c');
      expect(controller.state.letters['0,0'], 'C');
      expect(controller.state.selectedRow, 0);
      expect(controller.state.selectedCol, 1);
    });

    test('does not advance past the last cell of the word', () async {
      final controller = await loadController();
      controller.selectCell(0, 2); // last cell of CAT
      controller.enterLetter('t');
      expect(controller.state.selectedRow, 0);
      expect(controller.state.selectedCol, 2);
    });

    test('does nothing once the puzzle is completed', () async {
      final controller = await loadController();
      await _completePuzzle(controller);
      expect(controller.state.isCompleted, isTrue);

      controller.selectCell(0, 0);
      controller.enterLetter('x');
      expect(controller.state.letters['0,0'], 'C'); // unchanged
    });
  });

  group('backspace', () {
    test('clears the current cell without moving if it already has a letter', () async {
      final controller = await loadController();
      controller.enterLetter('c'); // (0,0) -> 'C', moves to (0,1)
      controller.selectCell(0, 0);
      controller.backspace();
      expect(controller.state.letters.containsKey('0,0'), isFalse);
      expect(controller.state.selectedRow, 0);
      expect(controller.state.selectedCol, 0);
    });

    test('moves to and clears the previous cell if the current one is already empty',
        () async {
      final controller = await loadController();
      controller.enterLetter('c'); // (0,0) -> 'C', moves to (0,1)
      controller.backspace(); // (0,1) empty -> moves back to (0,0), clears it
      expect(controller.state.selectedRow, 0);
      expect(controller.state.selectedCol, 0);
      expect(controller.state.letters.containsKey('0,0'), isFalse);
    });
  });

  group('revealHintAtSelectedCell', () {
    test('fills in the correct solution letter and advances', () async {
      final controller = await loadController();
      controller.revealHintAtSelectedCell();
      expect(controller.state.letters['0,0'], 'C');
      expect(controller.state.selectedCol, 1);
    });

    // A hint is paid for with a rewarded ad, so it must never spend one
    // rewriting a letter that is already there — that is what "the ad
    // gave me nothing" looks like from the player's side.
    test('skips a selected cell that is already correct', () async {
      final controller = await loadController();
      _enterSolutionCell(controller, '0,0', 'C');
      controller.selectCell(0, 0);
      final before = Map<String, String>.from(controller.state.letters);

      controller.revealHintAtSelectedCell();

      final revealed = controller.state.letters.keys
          .where((key) => !before.containsKey(key))
          .toList();
      expect(revealed, hasLength(1), reason: 'a hint must reveal something');
      expect(controller.state.letters[revealed.single], _solution[revealed.single]);
      expect(controller.state.letters['0,0'], 'C');
    });

    test('falls back to the rest of the grid once the word is solved', () async {
      final controller = await loadController();
      for (final entry in _solution.entries) {
        if (entry.key == '2,2') continue;
        _enterSolutionCell(controller, entry.key, entry.value);
      }
      // A fully solved word under the caret: the only cell a hint can
      // usefully fill is the one left at the far corner.
      controller.selectCell(0, 0);

      controller.revealHintAtSelectedCell();

      expect(controller.state.letters['2,2'], 'T');
    });

    test('replaces a wrong letter in the selected cell', () async {
      final controller = await loadController();
      _enterSolutionCell(controller, '0,0', 'X');
      controller.selectCell(0, 0);

      controller.revealHintAtSelectedCell();

      expect(controller.state.letters['0,0'], 'C');
    });
  });

  group('checkAnswers', () {
    test('marks only incorrect, filled cells', () async {
      final controller = await loadController();
      controller.enterLetter('x'); // wrong, at (0,0)
      controller.checkAnswers();
      expect(controller.state.incorrectCells, {'0,0'});
    });

    test('entering a new letter clears the previous check result', () async {
      final controller = await loadController();
      controller.enterLetter('x');
      controller.checkAnswers();
      expect(controller.state.incorrectCells, isNotEmpty);

      controller.selectCell(0, 0);
      controller.enterLetter('c');
      expect(controller.state.incorrectCells, isEmpty);
    });
  });

  group('completion', () {
    test('marks the puzzle completed once every cell matches the solution', () async {
      final controller = await loadController();
      await _completePuzzle(controller);
      expect(controller.state.isCompleted, isTrue);
    });

    test('persists completion to the repository', () async {
      final controller = await loadController();
      await _completePuzzle(controller);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repository.statusFor(_puzzleId), PuzzleStatus.completed);
    });

    test('logs puzzle_completed', () async {
      final controller = await loadController();
      await _completePuzzle(controller);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(analytics.hasEvent(AnalyticsEvents.puzzleCompleted), isTrue);
    });
  });

  group('restart', () {
    test('clears letters, completion, and persisted progress', () async {
      final controller = await loadController();
      controller.enterLetter('c');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repository.statusFor(_puzzleId), PuzzleStatus.inProgress);

      await controller.restart();

      expect(controller.state.letters, isEmpty);
      expect(controller.state.isCompleted, isFalse);
      expect(controller.state.selectedRow, 0);
      expect(controller.state.selectedCol, 0);
      expect(repository.statusFor(_puzzleId), PuzzleStatus.notStarted);
    });
  });

  group('progress restoration', () {
    test('a new controller for the same puzzle resumes saved letters', () async {
      final first = await loadController();
      first.enterLetter('c');
      first.selectCell(0, 1);
      first.enterLetter('a');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final second = await loadController();
      expect(second.state.letters['0,0'], 'C');
      expect(second.state.letters['0,1'], 'A');
    });
  });

  // Regression: completion persisted fine, but puzzleSummariesProvider is a
  // FutureProvider.family that caches per (language, difficulty) and never
  // re-reads storage on its own. Without an explicit invalidate, the puzzle
  // list kept serving pre-completion summaries, so the just-finished puzzle
  // still looked unfinished and the next one stayed locked.
  group('puzzle list refresh', () {
    test('completing a puzzle invalidates the cached puzzle summaries', () async {
      final controller = await loadController();
      const args = (language: 'en', difficulty: 'easy');

      // Prime the cache so there is something stale to invalidate.
      await container.read(puzzleSummariesProvider(args).future);
      var rebuilds = 0;
      container.listen(
        puzzleSummariesProvider(args),
        (_, _) => rebuilds++,
        fireImmediately: false,
      );

      await _completePuzzle(controller);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.statusFor(_puzzleId), PuzzleStatus.completed);
      expect(rebuilds, greaterThan(0),
          reason: 'the puzzle list must re-read storage after a completion');
    });

    test('restarting a puzzle invalidates the cached puzzle summaries', () async {
      final controller = await loadController();
      const args = (language: 'en', difficulty: 'easy');

      await container.read(puzzleSummariesProvider(args).future);
      var rebuilds = 0;
      container.listen(
        puzzleSummariesProvider(args),
        (_, _) => rebuilds++,
        fireImmediately: false,
      );

      await controller.restart();
      // invalidate() schedules the rebuild; give it a turn to land before
      // asserting the listener actually fired.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(rebuilds, greaterThan(0),
          reason: 'the puzzle list must re-read storage after a restart');
    });
  });

  group('the mistake limit', () {
    /// Types [word] into the currently selected clue, letter by letter.
    void type(CrosswordController controller, String word) {
      for (final letter in word.split('')) {
        controller.enterLetter(letter);
      }
    }

    /// The first across clue, and a wrong answer of the same length.
    ({CrosswordClue clue, String wrong, String right}) firstClue(
      CrosswordController controller,
    ) {
      final clue = controller.state.grid!.acrossClues.first;
      final right = [
        for (final cell in clue.cells)
          controller.state.grid!.cellAt(cell.$1, cell.$2).solutionLetter!,
      ].join();
      // Same length, definitely not the answer.
      final wrong = right.split('').map((l) => l == 'Z' ? 'Q' : 'Z').join();
      return (clue: clue, wrong: wrong, right: right);
    }

    test('a partly typed word is never charged', () async {
      // A crossword is typed left to right, so every partial answer
      // disagrees with the solution at some point. Charging per keystroke
      // would end the puzzle before a single word was finished.
      final controller = await loadController();
      final target = firstClue(controller);
      controller.selectClue(target.clue);

      type(controller, target.wrong.substring(0, target.wrong.length - 1));

      expect(controller.state.mistakes, 0);
    });

    test('a finished word that is wrong costs a life and stays marked',
        () async {
      final controller = await loadController();
      final target = firstClue(controller);
      controller.selectClue(target.clue);

      type(controller, target.wrong);

      expect(controller.state.mistakes, 1);
      expect(controller.state.incorrectCells, isNotEmpty);
    });

    test('a finished word that is right costs nothing', () async {
      final controller = await loadController();
      final target = firstClue(controller);
      controller.selectClue(target.clue);

      type(controller, target.right);

      expect(controller.state.mistakes, 0);
    });

    test('retyping the same wrong answer is not charged twice', () async {
      // A player who cannot see why an answer is refused will retype it;
      // that should not quietly drain the rest of their lives.
      final controller = await loadController();
      final target = firstClue(controller);
      controller.selectClue(target.clue);

      type(controller, target.wrong);
      controller.selectClue(target.clue);
      type(controller, target.wrong);

      expect(controller.state.mistakes, 1);
    });

    test('the third wrong answer fails the puzzle and locks the grid',
        () async {
      final controller = await loadController();
      final target = firstClue(controller);
      // Three *different* wrong guesses at the same clue. Each is a new
      // guess, so each costs a life.
      final firstLetters = const ['Z', 'Q', 'X', 'J']
          .where((letter) => letter != target.right[0])
          .take(maxMistakes);

      for (final letter in firstLetters) {
        controller.selectClue(target.clue);
        type(controller, letter + target.right.substring(1));
      }

      expect(controller.state.mistakes, maxMistakes);
      expect(controller.state.isFailed, isTrue);

      // The grid stops accepting letters, right answers included.
      controller.selectClue(target.clue);
      type(controller, target.right);
      expect(controller.state.isCompleted, isFalse);
    });

    test('restart gives the lives back', () async {
      final controller = await loadController();
      final target = firstClue(controller);
      controller.selectClue(target.clue);
      type(controller, target.wrong);

      await controller.restart();

      expect(controller.state.mistakes, 0);
      expect(controller.state.isFailed, isFalse);
    });

    test('a hint costs a star, not a life', () async {
      final controller = await loadController();
      controller.revealHintAtSelectedCell();

      expect(controller.state.hintsUsed, 1);
      expect(controller.state.mistakes, 0);
    });
  });
}
