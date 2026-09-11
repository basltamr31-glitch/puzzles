import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_app/core/analytics/analytics_events.dart';
import 'package:memory_app/core/storage/local_storage_service.dart';
import 'package:memory_app/features/memory/data/deck_repository.dart';
import 'package:memory_app/features/memory/domain/memory_models.dart';
import 'package:memory_app/features/memory/domain/memory_progress.dart';
import 'package:memory_app/features/memory/domain/memory_theme.dart';
import 'package:memory_app/features/memory/presentation/controllers/memory_controller.dart';
import 'package:memory_app/features/rewards/data/rewards_repository.dart';
import 'package:memory_app/features/rewards/domain/solve_reward.dart';
import 'package:memory_app/features/puzzle_list/domain/puzzle_summary.dart';

import '../../core/fake_analytics_service.dart';

/// A hand-written deck rather than a bundled one: everything under
/// assets/puzzles/ is owned by the generator and regenerated from time to
/// time, so asserting against a real slot would couple these tests to
/// whatever happens to live there today.
///
/// Laid out so the positions used below are easy to read:
///
///   0:A  1:B  2:C
///   3:D  4:A  5:B
///   6:C  7:D  8:E
///   9:F 10:E 11:F
const _deck = MemoryDeckDef(
  id: 'test_fixture_001',
  difficulty: 'easy',
  index: 0,
  rows: 4,
  cols: 3,
  theme: MemoryTheme.animals,
  cards: ['A', 'B', 'C', 'D', 'A', 'B', 'C', 'D', 'E', 'F', 'E', 'F'],
);

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

/// Serves [_deck] instead of reading the asset bundle, while leaving every
/// progress/status method on the real repository intact — those are
/// exactly what these tests are exercising.
class _FixtureRepository extends DeckRepository {
  _FixtureRepository(super.storage);

  @override
  Future<List<MemoryDeckDef>> loadDifficulty(String difficulty) async {
    return const [_deck];
  }
}

/// [MemoryController]'s constructor kicks off an async `_load()` that
/// isn't otherwise awaitable from outside, so tests poll `state.isLoading`
/// instead of guessing a fixed delay.
Future<void> _waitForLoad(MemoryController controller) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (controller.state.isLoading && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Reveals both cards of one pair, leaving them matched.
void _matchPair(MemoryController controller, int first, int second) {
  controller.flipCard(first);
  controller.flipCard(second);
}

/// Reveals two cards that do not match, and lets the reveal window expire
/// so they turn back over.
Future<void> _missPair(
  MemoryController controller,
  int first,
  int second,
) async {
  controller.flipCard(first);
  controller.flipCard(second);
  await Future<void>.delayed(
    mismatchRevealDuration + const Duration(milliseconds: 50),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _InMemoryStorage storage;
  late DeckRepository repository;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;
  final controllers = <MemoryController>[];

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
    // Guarded on `mounted` because one test disposes its own controller
    // to simulate leaving the screen — and a second dispose() throws,
    // which would abort this teardown and leak every later test's
    // controllers into the list.
    for (final controller in controllers) {
      if (controller.mounted) controller.dispose();
    }
    controllers.clear();
    container.dispose();
  });

  Future<MemoryController> loadController() async {
    final controller = MemoryController(
      repository,
      RewardsRepository(storage),
      analytics,
      container.read(Provider((ref) => ref)),
      (difficulty: 'easy', index: 0),
    );
    controllers.add(controller);
    await _waitForLoad(controller);
    return controller;
  }

  group('loading', () {
    test('opens with every card face down and nothing seen', () async {
      final controller = await loadController();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.deck?.id, _deck.id);
      expect(controller.state.matchedCards, isEmpty);
      expect(controller.state.faceUpCards, isEmpty);
      expect(controller.state.seenCards, isEmpty);
      expect(controller.state.totalPairs, 6);
      expect(analytics.events.map((e) => e.name), contains(AnalyticsEvents.puzzleStarted));
    });

    test('restores matched and seen cards from saved progress', () async {
      await repository.saveProgress(
        _deck.id,
        MemoryProgress(
          matchedCards: const {0, 4},
          seenCards: const {0, 4, 1},
          moves: 3,
          elapsedSeconds: 42,
          fingerprint: deckFingerprint(_deck.cards),
        ),
      );

      final controller = await loadController();

      expect(controller.state.matchedCards, {0, 4});
      expect(controller.state.seenCards, {0, 4, 1});
      expect(controller.state.moves, 3);
      expect(controller.state.elapsedSeconds, 42);
    });

    test('discards progress recorded against a different deal', () async {
      // The failure this guards against, in the shape a player would hit
      // it: the deck was regenerated behind a stable id, so position 4 is
      // no longer the partner of position 0. Replaying that progress
      // would mark two unrelated cards as a found pair, leaving a board
      // that can never be completed.
      await repository.saveProgress(
        _deck.id,
        const MemoryProgress(
          matchedCards: {0, 4},
          seenCards: {0, 4},
          moves: 3,
          elapsedSeconds: 42,
          fingerprint: 'deadbeef',
        ),
      );

      final controller = await loadController();

      expect(controller.state.matchedCards, isEmpty);
      expect(controller.state.seenCards, isEmpty);
      expect(controller.state.moves, 0);
    });

    test('a completed deck reopens fully face up', () async {
      await repository.markCompleted(_deck.id);

      final controller = await loadController();

      expect(controller.state.isCompleted, isTrue);
      expect(controller.state.matchedCards.length, _deck.cardCount);
    });
  });

  group('flipping', () {
    test('a matching pair stays face up', () async {
      final controller = await loadController();

      _matchPair(controller, 0, 4);

      expect(controller.state.matchedCards, {0, 4});
      expect(controller.state.faceUpCards, isEmpty);
      expect(controller.state.pairsFound, 1);
      expect(controller.state.moves, 1);
    });

    test('a mismatch turns both cards back over after the reveal window',
        () async {
      final controller = await loadController();

      controller.flipCard(0);
      controller.flipCard(1);
      expect(controller.state.faceUpCards, [0, 1]);
      expect(controller.state.mismatchedCards, {0, 1});

      await Future<void>.delayed(
        mismatchRevealDuration + const Duration(milliseconds: 50),
      );

      expect(controller.state.faceUpCards, isEmpty);
      expect(controller.state.mismatchedCards, isEmpty);
      // Both were still *seen* — that is the whole point of the reveal.
      expect(controller.state.seenCards, {0, 1});
    });

    test('a third tap resolves a showing mismatch instead of being swallowed',
        () async {
      final controller = await loadController();

      controller.flipCard(0);
      controller.flipCard(1);
      controller.flipCard(2);

      // The impatient tap turned the pair back over and started a new
      // reveal, rather than waiting out an animation the player has
      // already finished reading.
      expect(controller.state.faceUpCards, [2]);
      expect(controller.state.mismatchedCards, isEmpty);
    });

    test('tapping the same card twice does not complete a move', () async {
      final controller = await loadController();

      controller.flipCard(0);
      controller.flipCard(0);

      expect(controller.state.faceUpCards, [0]);
      expect(controller.state.moves, 0);
    });

    test('a matched card cannot be flipped again', () async {
      final controller = await loadController();
      _matchPair(controller, 0, 4);

      controller.flipCard(0);

      expect(controller.state.faceUpCards, isEmpty);
      expect(controller.state.moves, 1);
    });
  });

  group('what counts as a mistake', () {
    test('a mismatch on cards the player had never seen costs nothing',
        () async {
      final controller = await loadController();

      await _missPair(controller, 0, 1);

      // This is the game working as intended: turning over unknown cards
      // *is* memory. Charging for it would end most honest runs early.
      expect(controller.state.mistakes, 0);
      expect(controller.state.moves, 1);
    });

    test('a mismatch on two already-seen cards costs a life', () async {
      final controller = await loadController();

      // First pass: both cards are revealed, so the player has been shown
      // them and they enter the seen set.
      await _missPair(controller, 0, 1);
      // Second pass over the same two: the player had the information and
      // put them together anyway.
      await _missPair(controller, 0, 1);

      expect(controller.state.mistakes, 1);
    });

    test('a mismatch where only one card was known still costs nothing',
        () async {
      final controller = await loadController();

      await _missPair(controller, 0, 1);
      // 2 has never been revealed, so this pairing could not have been
      // avoided by remembering.
      await _missPair(controller, 0, 2);

      expect(controller.state.mistakes, 0);
    });

    test('three remembered mistakes end the run and lock the board', () async {
      final controller = await loadController();

      await _missPair(controller, 0, 1);
      for (var i = 0; i < maxMistakes; i++) {
        await _missPair(controller, 0, 1);
      }

      expect(controller.state.mistakes, maxMistakes);
      expect(controller.state.isFailed, isTrue);

      final movesBefore = controller.state.moves;
      controller.flipCard(2);
      expect(controller.state.faceUpCards, isEmpty, reason: 'board is locked');
      expect(controller.state.moves, movesBefore);
    });

    test('a failed run refuses a hint too', () async {
      final controller = await loadController();
      await _missPair(controller, 0, 1);
      for (var i = 0; i < maxMistakes; i++) {
        await _missPair(controller, 0, 1);
      }

      await controller.revealHint();

      // A run that is out of lives is over in both directions — a hint
      // that could rescue it would make the limit negotiable.
      expect(controller.state.matchedCards, isEmpty);
      expect(controller.state.hintsUsed, 0);
    });

    test('the seen set survives leaving and reopening the deck', () async {
      final first = await loadController();
      await _missPair(first, 0, 1);
      first.dispose();
      // dispose() persists fire-and-forget; give it the turn it needs.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final second = await loadController();
      await _missPair(second, 0, 1);

      // Without a persisted seen set, backing out to the list and walking
      // straight back in would be the cheapest strategy in the game.
      expect(second.state.mistakes, 1);
    });
  });

  group('hints', () {
    test('matches one whole pair and marks it seen', () async {
      final controller = await loadController();

      await controller.revealHint();

      expect(controller.state.pairsFound, 1);
      expect(controller.state.hintsUsed, 1);
      expect(controller.state.matchedCards.length, 2);
      expect(
        controller.state.seenCards.containsAll(controller.state.matchedCards),
        isTrue,
      );
      final revealed = controller.state.matchedCards.toList();
      expect(_deck.symbolAt(revealed[0]), _deck.symbolAt(revealed[1]));
      expect(
        analytics.events.map((e) => e.name),
        contains(AnalyticsEvents.hintUsed),
      );
    });

    test('costs a star rather than a life', () async {
      final controller = await loadController();

      await controller.revealHint();

      expect(controller.state.mistakes, 0);
      expect(controller.state.isFailed, isFalse);
    });
  });

  group('completion', () {
    Future<void> solve(MemoryController controller) async {
      for (var i = 0; i < _deck.pairCount; i++) {
        await controller.revealHint();
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    test('marks the deck completed and clears the live attempt', () async {
      final controller = await loadController();

      await solve(controller);

      expect(controller.state.isCompleted, isTrue);
      expect(repository.statusFor(_deck.id), PuzzleStatus.completed);
      expect(RewardsRepository(storage).loadAttempt(_deck.id).hintsUsed, 0);
      expect(
        analytics.events.map((e) => e.name),
        contains(AnalyticsEvents.puzzleCompleted),
      );
    });

    test('restart clears progress and gives the lives back', () async {
      final controller = await loadController();
      await _missPair(controller, 0, 1);
      await _missPair(controller, 0, 1);
      expect(controller.state.mistakes, 1);

      await controller.restart();

      expect(controller.state.mistakes, 0);
      expect(controller.state.matchedCards, isEmpty);
      expect(controller.state.seenCards, isEmpty);
      expect(controller.state.moves, 0);
      expect(repository.loadProgress(_deck.id), isNull);
    });
  });
}
