import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/notifications/reminder_controller.dart';
import '../../../puzzle_list/domain/puzzle_summary.dart';
import '../../../puzzle_list/puzzle_list_providers.dart';
import '../../../rewards/data/rewards_repository.dart';
import '../../../rewards/domain/puzzle_attempt.dart';
import '../../../rewards/domain/solve_reward.dart';
import '../../data/deck_repository.dart';
import '../../domain/memory_models.dart';
import '../../domain/memory_progress.dart';

/// Identifies one deck: which difficulty bundle, and which entry in it.
typedef MemoryDeckRef = ({String difficulty, int index});

/// How long a mismatched pair stays face up before turning back over.
///
/// Long enough to actually read two cards and commit them to memory,
/// short enough that it never feels like the game is holding the board
/// hostage. Tapping a third card resolves the pair immediately, so an
/// impatient player is never made to wait this out.
const Duration mismatchRevealDuration = Duration(milliseconds: 900);

class MemoryGameState extends Equatable {
  const MemoryGameState({
    this.deck,
    this.matchedCards = const {},
    this.faceUpCards = const [],
    this.seenCards = const {},
    this.mismatchedCards = const {},
    this.moves = 0,
    this.elapsedSeconds = 0,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.isCompleted = false,
    this.isLoading = true,
    this.errorMessage,
  });

  final MemoryDeckDef? deck;

  /// Board positions whose pair has been found. Stay face up for good.
  final Set<int> matchedCards;

  /// The one or two cards the player is currently looking at, in the
  /// order they were turned over. A list rather than a set because which
  /// card came first decides which one a third tap leaves on screen.
  final List<int> faceUpCards;

  /// Every position that has been revealed at least once this run —
  /// what "you should have remembered that" is measured against.
  final Set<int> seenCards;

  /// The two cards that just failed to match, for the moment before they
  /// turn back over.
  final Set<int> mismatchedCards;

  /// Completed reveals of two cards. The number memory players actually
  /// compete against.
  final int moves;

  final int elapsedSeconds;

  /// Mismatches on cards the player had already been shown — see
  /// [MemoryController.flipCard] for why only those count.
  final int mistakes;

  /// Hints spent on this run. Costs a star rather than a life.
  final int hintsUsed;

  /// True once the player has spent every mistake. The board is read-only
  /// from here — the only ways on are restarting or leaving.
  bool get isFailed => mistakes >= maxMistakes;

  final bool isCompleted;
  final bool isLoading;
  final String? errorMessage;

  int get pairsFound => matchedCards.length ~/ 2;
  int get totalPairs => deck?.pairCount ?? 0;

  bool isMatched(int index) => matchedCards.contains(index);
  bool isFaceUp(int index) =>
      matchedCards.contains(index) || faceUpCards.contains(index);
  bool isMismatched(int index) => mismatchedCards.contains(index);

  MemoryGameState copyWith({
    MemoryDeckDef? deck,
    Set<int>? matchedCards,
    List<int>? faceUpCards,
    Set<int>? seenCards,
    Set<int>? mismatchedCards,
    int? moves,
    int? elapsedSeconds,
    int? mistakes,
    int? hintsUsed,
    bool? isCompleted,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MemoryGameState(
      deck: deck ?? this.deck,
      matchedCards: matchedCards ?? this.matchedCards,
      faceUpCards: faceUpCards ?? this.faceUpCards,
      seenCards: seenCards ?? this.seenCards,
      mismatchedCards: mismatchedCards ?? this.mismatchedCards,
      moves: moves ?? this.moves,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    deck,
    matchedCards,
    faceUpCards,
    seenCards,
    mismatchedCards,
    moves,
    elapsedSeconds,
    mistakes,
    hintsUsed,
    isCompleted,
    isLoading,
    errorMessage,
  ];
}

/// Owns all gameplay state for a single deck: which cards are face up,
/// which are matched, the seen set the mistake rule reads, the timer,
/// hints, completion, and progress persistence. One instance per deck
/// (see [memoryControllerProvider]), so switching decks never leaks
/// state.
class MemoryController extends StateNotifier<MemoryGameState> {
  MemoryController(
    this._repository,
    this._rewards,
    this._analytics,
    this._ref,
    this.deckRef,
  ) : super(const MemoryGameState()) {
    _load();
  }

  final DeckRepository _repository;
  final RewardsRepository _rewards;
  final AnalyticsService _analytics;
  final Ref _ref;
  final MemoryDeckRef deckRef;
  final _random = Random();

  /// Elapsed time is written back only this often. A save per second
  /// would mean 3,600 SharedPreferences writes an hour for a number the
  /// player only ever sees rounded to seconds.
  static const int _persistTimerEvery = 15;

  Timer? _timer;
  Timer? _mismatchTimer;
  bool _paused = false;

  Future<void> _load() async {
    try {
      final deck = await _repository.loadDeck(
        difficulty: deckRef.difficulty,
        index: deckRef.index,
      );
      // Loading the bundle is asynchronous, and the player can back out of
      // the deck before it finishes. Writing state on a disposed notifier
      // throws, so every await here is followed by this check.
      if (!mounted) return;

      final saved = _repository.loadProgress(deck.id);
      final isCompleted =
          _repository.statusFor(deck.id) == PuzzleStatus.completed;
      final progress = _usableProgress(deck, saved) ?? const MemoryProgress.empty();

      // A completed deck carries no live attempt: its counters were
      // cleared on the solve, and re-reading them would show a spent
      // heart on a board that can no longer be lost.
      final attempt = isCompleted
          ? PuzzleAttempt.empty
          : _rewards.loadAttempt(deck.id);

      state = state.copyWith(
        deck: deck,
        // A completed deck opens fully face up — it is a board the player
        // has already beaten, and showing it face down would invite them
        // to "finish" a game that is over.
        matchedCards: isCompleted
            ? {for (var i = 0; i < deck.cardCount; i++) i}
            : progress.matchedCards,
        seenCards: progress.seenCards,
        moves: progress.moves,
        elapsedSeconds: progress.elapsedSeconds,
        mistakes: attempt.mistakes,
        hintsUsed: attempt.hintsUsed,
        isLoading: false,
        isCompleted: isCompleted,
      );

      // Pushes the inactivity reminder back — someone actively playing
      // should never be nudged to come play.
      _ref.read(reminderControllerProvider.notifier).recordPlayed();

      if (!isCompleted) {
        _analytics.logEvent(AnalyticsEvents.puzzleStarted, {
          'puzzle_id': deck.id,
        });
        _startTimer();
      }
    } on AppException catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'This puzzle could not be loaded.',
      );
    }
  }

  /// [saved] if it still belongs to [deck], otherwise null.
  ///
  /// Progress is a set of *board positions*, and positions only mean
  /// anything against the deal they were recorded on. Deck ids are stable
  /// across releases while the layouts behind them are regenerated
  /// content, so without this check a player mid-way through the old
  /// `easy_007` would return to find matched cards sitting on symbols
  /// that no longer pair up — a board that cannot be finished. There is
  /// no way to repair that, so it is discarded and the deck starts clean.
  static MemoryProgress? _usableProgress(
    MemoryDeckDef deck,
    MemoryProgress? saved,
  ) {
    if (saved == null) return null;
    if (saved.fingerprint != deckFingerprint(deck.cards)) return null;
    if (saved.matchedCards.any((i) => i < 0 || i >= deck.cardCount)) return null;
    return saved;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused || state.isCompleted || state.isLoading) return;
      final elapsed = state.elapsedSeconds + 1;
      state = state.copyWith(elapsedSeconds: elapsed);
      if (elapsed % _persistTimerEvery == 0) _persist();
    });
  }

  /// Called when the app leaves the foreground: a board left open on a
  /// locked phone shouldn't keep counting against the player's time.
  void pauseTimer() {
    if (_paused) return;
    _paused = true;
    _persist();
  }

  void resumeTimer() => _paused = false;

  /// Turns [index] face up, and resolves the pair once two are showing.
  ///
  /// **What counts as a mistake is the one genuinely per-app decision in
  /// the shared three-lives rule, and here it is narrow on purpose.** A
  /// memory game *is* turning over cards you have not seen: charging a
  /// life for every mismatch would end most honest runs of a 15-pair
  /// board before half of it was uncovered, and would punish the
  /// exploration the game is made of. So a mismatch costs a life only
  /// when the player had **already been shown both cards** — that is the
  /// moment they forgot something they knew, which is the only thing a
  /// memory game can fairly ask of them.
  void flipCard(int index) {
    final deck = state.deck;
    if (deck == null || state.isCompleted || state.isFailed) return;
    if (index < 0 || index >= deck.cardCount) return;
    if (state.matchedCards.contains(index)) return;
    if (state.faceUpCards.contains(index)) return;

    // A tap while a mismatched pair is still showing resolves it now
    // rather than being swallowed. Waiting out an animation the player
    // has already finished reading is the fastest way to make a board
    // feel unresponsive.
    if (state.faceUpCards.length >= 2) {
      _resolveMismatch();
    }

    final faceUp = [...state.faceUpCards, index];
    if (faceUp.length < 2) {
      state = state.copyWith(faceUpCards: faceUp, mismatchedCards: const {});
      return;
    }

    final first = faceUp[0];
    final second = faceUp[1];
    final isMatch = deck.symbolAt(first) == deck.symbolAt(second);
    // Read *before* this reveal is folded in: a card the player is seeing
    // for the first time right now was not something they could have
    // remembered.
    final bothKnown =
        state.seenCards.contains(first) && state.seenCards.contains(second);
    final seen = {...state.seenCards, first, second};

    if (isMatch) {
      state = state.copyWith(
        matchedCards: {...state.matchedCards, first, second},
        faceUpCards: const [],
        seenCards: seen,
        mismatchedCards: const {},
        moves: state.moves + 1,
      );
      _persist();
      _checkCompletion();
      return;
    }

    state = state.copyWith(
      faceUpCards: faceUp,
      seenCards: seen,
      mismatchedCards: {first, second},
      moves: state.moves + 1,
      mistakes: bothKnown ? state.mistakes + 1 : state.mistakes,
    );
    _persist();
    if (bothKnown) _persistAttempt();

    _mismatchTimer?.cancel();
    _mismatchTimer = Timer(mismatchRevealDuration, _resolveMismatch);
  }

  /// Turns the two mismatched cards back over. Safe to call twice — the
  /// timer and an impatient third tap race each other by design.
  void _resolveMismatch() {
    _mismatchTimer?.cancel();
    _mismatchTimer = null;
    if (!mounted || state.faceUpCards.length < 2) return;
    state = state.copyWith(faceUpCards: const [], mismatchedCards: const {});
  }

  /// Matches one pair outright, the same way the crossword app's hint
  /// reveals a letter and the word search's finds a whole word — a hint
  /// always makes direct, immediate progress rather than offering a
  /// glimpse the player still has to act on.
  ///
  /// The revealed cards join the seen set, so a hinted pair cannot later
  /// be "forgotten" for free.
  Future<void> revealHint() async {
    final deck = state.deck;
    if (deck == null || state.isCompleted || state.isFailed) return;

    final unmatched = [
      for (var i = 0; i < deck.cardCount; i++)
        if (!state.matchedCards.contains(i)) i,
    ];
    if (unmatched.isEmpty) return;

    final first = unmatched[_random.nextInt(unmatched.length)];
    final symbol = deck.symbolAt(first);
    final second = unmatched.firstWhere(
      (i) => i != first && deck.symbolAt(i) == symbol,
      orElse: () => -1,
    );
    // Only reachable if a deck shipped with an unpaired symbol, which
    // MemoryDeckDef.fromJson refuses to parse — but a hint that threw on
    // the player's screen would be a far worse way to find out.
    if (second < 0) return;

    _mismatchTimer?.cancel();
    _analytics.logEvent(AnalyticsEvents.hintUsed, {'puzzle_id': deck.id});
    state = state.copyWith(
      matchedCards: {...state.matchedCards, first, second},
      seenCards: {...state.seenCards, first, second},
      faceUpCards: const [],
      mismatchedCards: const {},
      hintsUsed: state.hintsUsed + 1,
    );
    await _persist();
    await _persistAttempt();
    await _checkCompletion();
  }

  Future<void> restart() async {
    final deck = state.deck;
    if (deck == null) return;
    _mismatchTimer?.cancel();
    await _repository.clearProgress(deck.id);
    await _rewards.clearAttempt(deck.id);
    if (!mounted) return;
    // The puzzle list's cached summaries (and therefore the sequential
    // unlock check) would otherwise keep showing this deck as completed.
    _ref.invalidate(puzzleSummariesProvider);

    state = state.copyWith(
      matchedCards: const {},
      faceUpCards: const [],
      seenCards: const {},
      mismatchedCards: const {},
      moves: 0,
      elapsedSeconds: 0,
      mistakes: 0,
      hintsUsed: 0,
      isCompleted: false,
    );
    _startTimer();
  }

  /// Written separately from [_persist] because it changes far less often
  /// — only on a real mistake or a hint, never on the timer tick.
  Future<void> _persistAttempt() async {
    final deck = state.deck;
    if (deck == null) return;
    await _rewards.saveAttempt(
      deck.id,
      PuzzleAttempt(mistakes: state.mistakes, hintsUsed: state.hintsUsed),
    );
  }

  Future<void> _persist() async {
    final deck = state.deck;
    if (deck == null) return;
    await _repository.saveProgress(deck.id, _snapshot(deck));
  }

  MemoryProgress _snapshot(MemoryDeckDef deck) {
    return MemoryProgress(
      matchedCards: state.matchedCards,
      seenCards: state.seenCards,
      moves: state.moves,
      elapsedSeconds: state.elapsedSeconds,
      fingerprint: deckFingerprint(deck.cards),
    );
  }

  Future<void> _checkCompletion() async {
    final deck = state.deck;
    if (deck == null) return;
    if (state.matchedCards.length < deck.cardCount) return;

    _timer?.cancel();
    state = state.copyWith(isCompleted: true, faceUpCards: const []);
    await _repository.markCompleted(deck.id);
    // Every await here is a chance for the player to have left the deck;
    // reaching for the Ref afterwards throws on a disposed provider.
    if (!mounted) return;
    // The run is over, so its counters are dropped — a replay starts on a
    // full three lives. The tallies the solve earned have already been
    // read off the state by the screen.
    await _rewards.clearAttempt(deck.id);
    if (!mounted) return;
    // FutureProvider.family caches per difficulty and never re-reads
    // storage on its own — without this, the puzzle list keeps showing
    // this deck as unfinished and the next one stays locked even though
    // completion was just persisted.
    _ref.invalidate(puzzleSummariesProvider);
    _analytics.logEvent(AnalyticsEvents.puzzleCompleted, {
      'puzzle_id': deck.id,
      'elapsed_seconds': state.elapsedSeconds,
      'moves': state.moves,
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mismatchTimer?.cancel();
    // The timer only writes elapsed time every 15 seconds, so leaving the
    // screen would otherwise discard up to that much of the player's
    // solve time. Fire-and-forget: state is unreadable after dispose().
    final deck = state.deck;
    if (deck != null) {
      unawaited(_repository.saveProgress(deck.id, _snapshot(deck)));
    }
    super.dispose();
  }
}

/// **autoDispose is load-bearing.** The controller owns a per-second
/// timer; without disposal, backing out to the puzzle list would leave it
/// running forever and the player's next visit would show a solve time
/// that includes however long the app sat on another screen.
final memoryControllerProvider = StateNotifierProvider.autoDispose
    .family<MemoryController, MemoryGameState, MemoryDeckRef>(
      (ref, deckRef) => MemoryController(
        ref.watch(deckRepositoryProvider),
        ref.watch(rewardsRepositoryProvider),
        ref.watch(analyticsServiceProvider),
        ref,
        deckRef,
      ),
    );
