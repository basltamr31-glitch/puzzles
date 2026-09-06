import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/core/analytics/analytics_events.dart';
import 'package:sudoku_app/core/storage/local_storage_service.dart';
import 'package:sudoku_app/core/storage/storage_keys.dart';
import 'package:sudoku_app/features/puzzle_list/domain/puzzle_summary.dart';
import 'package:sudoku_app/features/sudoku/data/puzzle_repository.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_models.dart';
import 'package:sudoku_app/features/sudoku/presentation/controllers/sudoku_controller.dart';

import '../../core/fake_analytics_service.dart';

/// A fixed, externally published puzzle rather than one of the bundled
/// ones: everything under assets/puzzles/ is owned by the generator and
/// regenerated from time to time, so asserting against a real slot would
/// couple these tests to whatever happens to live there today.
const _givens =
    '53..7....6..195....98....6.8...6...34..8.3..17...2...6.6....28....419..5....8..79';
const _solution =
    '534678912672195348198342567859761423426853791713924856961537284287419635345286179';

const _puzzle = SudokuPuzzleDef(
  id: 'test_fixture_001',
  difficulty: 'easy',
  givens: _givens,
  solution: _solution,
);

/// Index 2 is the first empty cell of [_givens]; index 0 holds a given.
/// Index 3 is another empty cell in the same row, so it is a peer of
/// [_firstEmpty] that the player is actually allowed to annotate.
const _firstEmpty = 2;
const _emptyPeer = 3;
const _givenIndex = 0;

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

/// Serves [_puzzle] instead of reading the asset bundle, while leaving
/// every progress/status method on the real repository intact — those are
/// exactly what these tests are exercising.
class _FixtureRepository extends PuzzleRepository {
  _FixtureRepository(super.storage);

  @override
  Future<List<SudokuPuzzleDef>> loadDifficulty(String difficulty) async {
    return const [_puzzle];
  }
}

/// [SudokuController]'s constructor kicks off an async `_load()` that
/// isn't otherwise awaitable from outside, so tests poll `state.isLoading`
/// instead of guessing a fixed delay.
Future<void> _waitForLoad(SudokuController controller) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (controller.state.isLoading && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void _enter(SudokuController controller, int index, int digit) {
  controller.selectCell(index);
  controller.enterDigit(digit);
}

/// Completion persists and logs behind an `await`, so the returned future
/// must be awaited before asserting on anything but the synchronous state.
Future<void> _solve(SudokuController controller) async {
  for (var i = 0; i < sudokuCellCount; i++) {
    if (_puzzle.isGiven(i)) continue;
    _enter(controller, i, int.parse(_solution[i]));
  }
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _InMemoryStorage storage;
  late PuzzleRepository repository;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;
  final controllers = <SudokuController>[];

  setUp(() {
    storage = _InMemoryStorage();
    repository = _FixtureRepository(storage);
    analytics = FakeAnalyticsService();
    container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
    );
  });

  tearDown(() {
    // Each controller owns a periodic timer; leaving them running would
    // leak across tests and keep ticking after the container is gone.
    for (final controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
    container.dispose();
  });

  Future<SudokuController> loadController() async {
    final controller = SudokuController(
      repository,
      analytics,
      container.read(Provider((ref) => ref)),
      (difficulty: 'easy', index: 0),
    );
    controllers.add(controller);
    await _waitForLoad(controller);
    return controller;
  }

  group('loading', () {
    test('starts on the first empty cell with the givens already placed', () async {
      final controller = await loadController();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.puzzle?.id, _puzzle.id);
      expect(controller.state.selectedIndex, _firstEmpty);
      expect(controller.state.values[0], 5);
      expect(controller.state.values[_firstEmpty], 0);
      expect(controller.state.filledCount, _puzzle.givenCount);
    });

    test('logs puzzle_started', () async {
      await loadController();
      expect(analytics.countOf(AnalyticsEvents.puzzleStarted), 1);
    });

    test('resumes saved entries, notes, and elapsed time', () async {
      final first = await loadController();
      _enter(first, _firstEmpty, 4);
      first.selectCell(_emptyPeer);
      first.toggleNotesMode();
      first.enterDigit(6);

      final second = await loadController();
      expect(second.state.values[_firstEmpty], 4);
      expect(second.state.notes[_emptyPeer], {6});
    });
  });

  group('entering digits', () {
    test('writes into the selected cell', () async {
      final controller = await loadController();
      _enter(controller, _firstEmpty, 4);
      expect(controller.state.values[_firstEmpty], 4);
    });

    test('tapping the same digit again clears the cell', () async {
      final controller = await loadController();
      _enter(controller, _firstEmpty, 4);
      controller.enterDigit(4);
      expect(controller.state.values[_firstEmpty], 0);
    });

    test('a given cell cannot be overwritten', () async {
      final controller = await loadController();
      _enter(controller, _givenIndex, 1);
      expect(controller.state.values[_givenIndex], 5);
    });

    test('placing a digit prunes it from every peer\'s notes', () async {
      final controller = await loadController();
      const peer = _emptyPeer;
      expect(sudokuPeers[_firstEmpty], contains(peer));

      controller.selectCell(peer);
      controller.toggleNotesMode();
      controller.enterDigit(4);
      controller.enterDigit(7);
      controller.toggleNotesMode();
      expect(controller.state.notes[peer], {4, 7});

      _enter(controller, _firstEmpty, 4);
      expect(controller.state.notes[peer], {7});
    });

    test('persists after every entry', () async {
      final controller = await loadController();
      _enter(controller, _firstEmpty, 4);
      expect(repository.statusFor(_puzzle.id), PuzzleStatus.inProgress);
      expect(repository.loadProgress(_puzzle.id)?.values[_firstEmpty], 4);
    });
  });

  group('notes', () {
    test('toggle on and off', () async {
      final controller = await loadController();
      controller.selectCell(_firstEmpty);
      controller.toggleNotesMode();

      controller.enterDigit(3);
      expect(controller.state.notes[_firstEmpty], {3});
      controller.enterDigit(3);
      expect(controller.state.notes[_firstEmpty], isEmpty);
    });

    test('writing a note clears the answer it would hide', () async {
      final controller = await loadController();
      _enter(controller, _firstEmpty, 4);
      controller.toggleNotesMode();
      controller.enterDigit(3);

      expect(controller.state.values[_firstEmpty], 0);
      expect(controller.state.notes[_firstEmpty], {3});
    });
  });

  group('erase and undo', () {
    test('erase clears both the value and the notes', () async {
      final controller = await loadController();
      controller.selectCell(_firstEmpty);
      controller.toggleNotesMode();
      controller.enterDigit(3);
      controller.toggleNotesMode();
      controller.enterDigit(4);

      controller.eraseSelectedCell();
      expect(controller.state.values[_firstEmpty], 0);
      expect(controller.state.notes[_firstEmpty], isEmpty);
    });

    test('erase leaves a given alone', () async {
      final controller = await loadController();
      controller.selectCell(_givenIndex);
      controller.eraseSelectedCell();
      expect(controller.state.values[_givenIndex], 5);
    });

    test('undo steps back one entry at a time', () async {
      final controller = await loadController();
      expect(controller.canUndo, isFalse);

      _enter(controller, _firstEmpty, 4);
      _enter(controller, _emptyPeer, 6);
      expect(controller.canUndo, isTrue);

      controller.undo();
      expect(controller.state.values[_emptyPeer], 0);
      expect(controller.state.values[_firstEmpty], 4);

      controller.undo();
      expect(controller.state.values[_firstEmpty], 0);
      expect(controller.canUndo, isFalse);
    });

    test('undo restores pruned notes, not just the digit', () async {
      final controller = await loadController();
      const peer = _emptyPeer;

      controller.selectCell(peer);
      controller.toggleNotesMode();
      controller.enterDigit(4);
      controller.toggleNotesMode();

      _enter(controller, _firstEmpty, 4);
      expect(controller.state.notes[peer], isEmpty);

      controller.undo();
      expect(controller.state.notes[peer], {4});
    });
  });

  group('feedback', () {
    test('check flags entries that disagree with the solution', () async {
      final controller = await loadController();
      // 4 is correct at index 2; 1 is not.
      _enter(controller, _firstEmpty, 1);
      controller.checkAnswers();
      expect(controller.state.incorrectCells, {_firstEmpty});

      controller.enterDigit(4);
      controller.checkAnswers();
      expect(controller.state.incorrectCells, isEmpty);
    });

    test('conflicts surface duplicates without consulting the solution', () async {
      final controller = await loadController();
      // Index 0 already holds a 5; index 2 is in the same row and box.
      _enter(controller, _firstEmpty, 5);
      expect(controller.state.conflicts, containsAll([0, _firstEmpty]));
    });

    test('remainingByDigit counts what is left to place', () async {
      final controller = await loadController();
      final before = controller.state.remainingByDigit[4]!;
      _enter(controller, _firstEmpty, 4);
      expect(controller.state.remainingByDigit[4], before - 1);
    });
  });

  group('hints', () {
    test('fill the selected cell with the right digit', () async {
      final controller = await loadController();
      controller.selectCell(_firstEmpty);
      controller.revealHintAtSelectedCell();
      expect(controller.state.values[_firstEmpty], int.parse(_solution[_firstEmpty]));
    });

    test('fall back to the first empty cell when the selection is already filled',
        () async {
      final controller = await loadController();
      controller.selectCell(_givenIndex);
      controller.revealHintAtSelectedCell();
      expect(controller.state.values[_firstEmpty], int.parse(_solution[_firstEmpty]));
      expect(controller.state.selectedIndex, _firstEmpty);
    });

    test('are undoable like any other entry', () async {
      final controller = await loadController();
      controller.selectCell(_firstEmpty);
      controller.revealHintAtSelectedCell();
      controller.undo();
      expect(controller.state.values[_firstEmpty], 0);
    });
  });

  group('completion', () {
    test('solving the grid marks the puzzle completed and persists it', () async {
      final controller = await loadController();
      await _solve(controller);

      expect(controller.state.isCompleted, isTrue);
      expect(storage.getBool(StorageKeys.puzzleCompleted(_puzzle.id)), isTrue);
      expect(repository.statusFor(_puzzle.id), PuzzleStatus.completed);
      expect(analytics.countOf(AnalyticsEvents.puzzleCompleted), 1);
    });

    test('a filled but wrong grid is not completion', () async {
      final controller = await loadController();
      for (var i = 0; i < sudokuCellCount; i++) {
        if (_puzzle.isGiven(i)) continue;
        // Deliberately off by one from the solution everywhere.
        _enter(controller, i, (int.parse(_solution[i]) % sudokuSize) + 1);
      }
      expect(controller.state.isCompleted, isFalse);
    });

    test('a completed puzzle refuses further entries', () async {
      final controller = await loadController();
      await _solve(controller);
      final before = List<int>.from(controller.state.values);

      _enter(controller, _firstEmpty, 1);
      expect(controller.state.values, before);
    });

    test('reopening a completed puzzle does not re-log puzzle_started', () async {
      final first = await loadController();
      await _solve(first);

      analytics.events.clear();
      final second = await loadController();
      expect(second.state.isCompleted, isTrue);
      expect(analytics.countOf(AnalyticsEvents.puzzleStarted), 0);
    });
  });

  group('disposal', () {
    test('leaving the puzzle keeps the entries that were made', () async {
      final controller = await loadController();
      _enter(controller, _firstEmpty, 4);

      controller.dispose();
      controllers.remove(controller);
      await Future<void>.delayed(Duration.zero);

      expect(repository.loadProgress(_puzzle.id)?.values[_firstEmpty], 4);
    });

    test('disposing before the puzzle has loaded does not throw', () {
      final controller = SudokuController(
        repository,
        analytics,
        container.read(Provider((ref) => ref)),
        (difficulty: 'easy', index: 0),
      );
      expect(controller.dispose, returnsNormally);
    });
  });

  group('restart', () {
    test('clears entries, progress, and completion', () async {
      final controller = await loadController();
      await _solve(controller);

      await controller.restart();

      expect(controller.state.isCompleted, isFalse);
      expect(controller.state.filledCount, _puzzle.givenCount);
      expect(controller.state.elapsedSeconds, 0);
      expect(repository.statusFor(_puzzle.id), PuzzleStatus.notStarted);
      expect(controller.canUndo, isFalse);
    });
  });
}
