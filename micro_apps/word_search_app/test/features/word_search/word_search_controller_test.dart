import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/analytics/analytics_events.dart';
import 'package:word_search_app/core/storage/local_storage_service.dart';
import 'package:word_search_app/features/puzzle_list/domain/puzzle_summary.dart';
import 'package:word_search_app/features/word_search/data/puzzle_repository.dart';
import 'package:word_search_app/features/word_search/presentation/controllers/word_search_controller.dart';

import '../../core/fake_analytics_service.dart';

/// A dedicated, stable test fixture (not a real shipped puzzle) — a
/// hand-verified 4x4:
///   C A T D
///   O X X O
///   X W X G
///   X X L X
/// (CAT east from (0,0), DOG south from (0,3), OWL south-east from
/// (1,0)). Puzzle content under assets/puzzles/ is generated and
/// regenerated periodically, so these tests intentionally assert against
/// a fixture the generator never touches.
const _assetPath = 'assets/test_fixtures/sample_puzzle.json';
const _puzzleId = 'test_fixture_001';

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

/// [WordSearchController]'s constructor kicks off an async `_load()` that
/// isn't otherwise awaitable from outside, so tests poll `state.isLoading`
/// instead of guessing a fixed delay.
Future<void> _waitForLoad(WordSearchController controller) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (controller.state.isLoading && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void _drag(WordSearchController controller, (int, int) from, (int, int) to) {
  controller.startDrag(from.$1, from.$2);
  controller.updateDrag(to.$1, to.$2);
  controller.endDrag();
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
    container = ProviderContainer(
      overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<WordSearchController> loadController() async {
    // CrosswordController/WordSearchController invalidate
    // puzzleSummariesProvider through this Ref on completion/restart; a
    // plain ProviderContainer gives it a real one to call into without
    // needing the full wordSearchControllerProvider wiring in these unit
    // tests — same technique the crossword app's own controller test uses.
    final controller = WordSearchController(
      repository,
      analytics,
      container.read(Provider((ref) => ref)),
      _assetPath,
    );
    await _waitForLoad(controller);
    return controller;
  }

  group('snappedSelection', () {
    test('a single tap selects one cell', () {
      expect(
        snappedSelection(start: (2, 2), end: (2, 2), gridSize: 8),
        [(2, 2)],
      );
    });

    test('snaps a straight horizontal drag', () {
      expect(
        snappedSelection(start: (0, 0), end: (0, 3), gridSize: 8),
        [(0, 0), (0, 1), (0, 2), (0, 3)],
      );
    });

    test('snaps a diagonal drag', () {
      expect(
        snappedSelection(start: (0, 0), end: (3, 3), gridSize: 8),
        [(0, 0), (1, 1), (2, 2), (3, 3)],
      );
    });

    test('a drag that would leave the grid returns nothing', () {
      expect(snappedSelection(start: (0, 0), end: (0, 20), gridSize: 8), isEmpty);
    });

    test('a wobbly, mostly-horizontal drag still snaps to the row', () {
      // The 8 directions sit 45 degrees apart, so any drag snaps to
      // whichever is closest — a real finger is never pixel-perfect, and
      // the game would be unplayable if only an exact diagonal counted.
      expect(
        snappedSelection(start: (0, 0), end: (1, 5), gridSize: 8),
        [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5)],
      );
    });
  });

  test('loads the puzzle and starts with nothing found', () async {
    final controller = await loadController();
    final state = controller.state;

    expect(state.errorMessage, isNull);
    expect(state.puzzle, isNotNull);
    expect(state.puzzle!.id, _puzzleId);
    expect(state.foundWords, isEmpty);
    expect(state.isCompleted, isFalse);
  });

  test('dragging exactly over a word finds it', () async {
    final controller = await loadController();

    _drag(controller, (0, 0), (0, 2)); // CAT, east
    expect(controller.state.foundWords, {'CAT'});
    expect(
      controller.state.foundCells,
      {'0,0', '0,1', '0,2'},
    );
    expect(controller.state.wrongSelectionCells, isEmpty);
  });

  test('a word can be dragged from either end', () async {
    final controller = await loadController();

    _drag(controller, (2, 3), (0, 3)); // DOG, dragged backwards (north)
    expect(controller.state.foundWords, {'DOG'});
  });

  test('a selection matching no word flashes as wrong and finds nothing', () async {
    final controller = await loadController();

    _drag(controller, (0, 0), (0, 3)); // CATD - not a real word
    expect(controller.state.foundWords, isEmpty);
    expect(controller.state.wrongSelectionCells, isNotEmpty);
  });

  test('finding every word marks the puzzle complete and persists it', () async {
    final controller = await loadController();

    _drag(controller, (0, 0), (0, 2)); // CAT
    _drag(controller, (0, 3), (2, 3)); // DOG
    expect(controller.state.isCompleted, isFalse);

    _drag(controller, (1, 0), (3, 2)); // OWL
    // endDrag() is sync and hands off to an unawaited async chain
    // (persist -> check completion -> invalidate -> analytics), same as
    // the crossword app's enterLetter(); give it a turn to finish before
    // asserting on its far side.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.state.isCompleted, isTrue);
    expect(repository.statusFor(_puzzleId), PuzzleStatus.completed);
    expect(analytics.hasEvent(AnalyticsEvents.puzzleCompleted), isTrue);
  });

  test('a hint finds one unfound word without being asked which', () async {
    final controller = await loadController();

    await controller.revealHint();
    expect(controller.state.foundWords, hasLength(1));
    expect(analytics.hasEvent(AnalyticsEvents.hintUsed), isTrue);
  });

  test('restart clears found words and stored progress', () async {
    final controller = await loadController();
    _drag(controller, (0, 0), (0, 2)); // CAT
    expect(controller.state.foundWords, isNotEmpty);

    await controller.restart();

    expect(controller.state.foundWords, isEmpty);
    expect(controller.state.foundCells, isEmpty);
    expect(controller.state.isCompleted, isFalse);
    expect(repository.loadProgress(_puzzleId), isNull);
  });

  test('progress round-trips through a fresh controller instance', () async {
    final first = await loadController();
    _drag(first, (0, 0), (0, 2)); // CAT

    final second = WordSearchController(
      repository,
      analytics,
      container.read(Provider((ref) => ref)),
      _assetPath,
    );
    await _waitForLoad(second);

    expect(second.state.foundWords, {'CAT'});
  });
}
