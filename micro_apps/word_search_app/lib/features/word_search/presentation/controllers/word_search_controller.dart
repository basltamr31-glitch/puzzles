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
import '../../data/puzzle_repository.dart';
import '../../domain/word_search_models.dart';
import '../../domain/word_search_progress.dart';

/// Snaps a free-form drag from [start] to [end] onto the nearest of the
/// eight straight-line directions, and returns the cells that selection
/// actually covers.
///
/// Returns a single cell when [start] == [end], and an empty list when
/// [end] falls outside the grid — the caller treats that the same as "no
/// selection" rather than clamping to a truncated line, which would let a
/// drag past the edge silently shorten the word being spelled.
List<(int, int)> snappedSelection({
  required (int, int) start,
  required (int, int) end,
  required int gridSize,
}) {
  final dr = end.$1 - start.$1;
  final dc = end.$2 - start.$2;
  if (dr == 0 && dc == 0) return [start];

  // The 8 directions sit 45 degrees apart, so the drag is never more than
  // 22.5 degrees from its nearest one — there is no "too ambiguous to
  // snap" case to guard against; whichever direction's unit vector has
  // the largest cosine similarity to the drag is always a reasonable
  // pick. The diagonals' step vectors are longer (magnitude sqrt(2) vs
  // 1), so the raw dot product alone would bias every comparison toward
  // them — dividing by each direction's own magnitude is what makes this
  // an actual cosine comparison instead.
  WordDirection best = WordDirection.east;
  var bestScore = double.negativeInfinity;
  for (final direction in WordDirection.values) {
    final magnitude = sqrt(
      (direction.rowStep * direction.rowStep + direction.colStep * direction.colStep)
          .toDouble(),
    );
    final score =
        (dr * direction.rowStep + dc * direction.colStep) / magnitude;
    if (score > bestScore) {
      bestScore = score;
      best = direction;
    }
  }

  final steps = max(dr.abs(), dc.abs());
  final cells = <(int, int)>[];
  for (var i = 0; i <= steps; i++) {
    final row = start.$1 + best.rowStep * i;
    final col = start.$2 + best.colStep * i;
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) {
      return const [];
    }
    cells.add((row, col));
  }
  return cells;
}

class WordSearchGameState extends Equatable {
  const WordSearchGameState({
    this.puzzle,
    this.foundWords = const {},
    this.foundCells = const {},
    this.dragStart,
    this.dragCurrent,
    this.wrongSelectionCells = const {},
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.bonusLives = 0,
    this.isCompleted = false,
    this.isLoading = true,
    this.errorMessage,
  });

  final WordSearchPuzzleDef? puzzle;
  final Set<String> foundWords;

  /// Every cell belonging to any found word, as "row,col" keys — the fast
  /// lookup the grid paints from every frame.
  final Set<String> foundCells;

  final (int, int)? dragStart;
  final (int, int)? dragCurrent;

  /// Briefly non-empty after a released drag that matched no word, so the
  /// grid can flash it red before clearing on the next touch.
  final Set<String> wrongSelectionCells;

  /// Released drags on this run that spelled nothing.
  final int mistakes;

  /// Hints spent on this run. Costs a star rather than a life.
  final int hintsUsed;

  /// Extra lives earned on this run, each one paid for with a rewarded
  /// ad (or free for a player who has removed ads).
  ///
  /// Kept apart from [mistakes] rather than discounting it, because
  /// `starsForSolve` reads the mistake count — folding the two together
  /// would let an ad quietly buy a better star rating instead of just
  /// another go.
  final int bonusLives;

  /// True once the player has spent every mistake. The board stops
  /// accepting drags — the only ways on are restarting or leaving.
  bool get isFailed => mistakes >= maxMistakes + bonusLives;

  final bool isCompleted;
  final bool isLoading;
  final String? errorMessage;

  List<(int, int)> get liveSelection {
    final start = dragStart;
    final current = dragCurrent;
    final grid = puzzle;
    if (start == null || current == null || grid == null) return const [];
    return snappedSelection(start: start, end: current, gridSize: grid.size);
  }

  int get totalWords => puzzle?.placements.length ?? 0;

  WordSearchGameState copyWith({
    WordSearchPuzzleDef? puzzle,
    Set<String>? foundWords,
    Set<String>? foundCells,
    (int, int)? dragStart,
    bool clearDragStart = false,
    (int, int)? dragCurrent,
    bool clearDragCurrent = false,
    Set<String>? wrongSelectionCells,
    int? mistakes,
    int? hintsUsed,
    int? bonusLives,
    bool? isCompleted,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WordSearchGameState(
      puzzle: puzzle ?? this.puzzle,
      foundWords: foundWords ?? this.foundWords,
      foundCells: foundCells ?? this.foundCells,
      dragStart: clearDragStart ? null : (dragStart ?? this.dragStart),
      dragCurrent: clearDragCurrent
          ? null
          : (dragCurrent ?? this.dragCurrent),
      wrongSelectionCells: wrongSelectionCells ?? this.wrongSelectionCells,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      bonusLives: bonusLives ?? this.bonusLives,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    puzzle,
    foundWords,
    foundCells,
    dragStart,
    dragCurrent,
    wrongSelectionCells,
    mistakes,
    hintsUsed,
    bonusLives,
    isCompleted,
    isLoading,
    errorMessage,
  ];
}

/// Owns all gameplay state for a single puzzle: the live drag selection,
/// found words, hints, completion, and progress persistence. One instance
/// per puzzle asset path (see [wordSearchControllerProvider]), so
/// switching puzzles never leaks state.
class WordSearchController extends StateNotifier<WordSearchGameState> {
  WordSearchController(
    this._repository,
    this._rewards,
    this._analytics,
    this._ref,
    this.assetPath,
  ) : super(const WordSearchGameState()) {
    _load();
  }

  final PuzzleRepository _repository;
  final RewardsRepository _rewards;
  final AnalyticsService _analytics;
  final Ref _ref;
  final String assetPath;
  final _random = Random();

  Future<void> _load() async {
    try {
      final puzzle = await _repository.loadPuzzleDef(assetPath);
      final saved = _repository.loadProgress(puzzle.id);
      final isCompleted =
          _repository.statusFor(puzzle.id) == PuzzleStatus.completed;
      final foundWords = saved?.foundWords ?? const {};

      // A completed puzzle carries no live attempt: its counters were
      // cleared on the solve, and re-reading them would show a spent
      // heart on a board that can no longer be lost.
      final attempt = isCompleted
          ? PuzzleAttempt.empty
          : _rewards.loadAttempt(puzzle.id);

      state = state.copyWith(
        puzzle: puzzle,
        foundWords: foundWords,
        foundCells: _cellsFor(puzzle, foundWords),
        mistakes: attempt.mistakes,
        hintsUsed: attempt.hintsUsed,
        bonusLives: attempt.bonusLives,
        isLoading: false,
        isCompleted: isCompleted,
      );

      // Pushes the inactivity reminder back — someone actively playing
      // should never be nudged to come play.
      _ref.read(reminderControllerProvider.notifier).recordPlayed();

      if (!isCompleted) {
        _analytics.logEvent(AnalyticsEvents.puzzleStarted, {
          'puzzle_id': puzzle.id,
        });
      }
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'This puzzle could not be loaded.',
      );
    }
  }

  Set<String> _cellsFor(WordSearchPuzzleDef puzzle, Set<String> words) {
    final cells = <String>{};
    for (final placement in puzzle.placements) {
      if (!words.contains(placement.word)) continue;
      for (final (row, col) in placement.cells) {
        cells.add('$row,$col');
      }
    }
    return cells;
  }

  void startDrag(int row, int col) {
    if (state.isCompleted || state.isFailed) return;
    state = state.copyWith(
      dragStart: (row, col),
      dragCurrent: (row, col),
      wrongSelectionCells: const {},
    );
  }

  void updateDrag(int row, int col) {
    if (state.dragStart == null) return;
    state = state.copyWith(dragCurrent: (row, col));
  }

  void endDrag() {
    final puzzle = state.puzzle;
    final selection = state.liveSelection;
    state = state.copyWith(clearDragStart: true, clearDragCurrent: true);
    // A one-cell selection is a tap, not a guess — the player brushed
    // the board or thought better of a drag, and charging a life for
    // that would make the grid feel hostile to touch.
    if (puzzle == null || selection.length < 2) return;

    final match = _matchWord(puzzle, selection);
    if (match == null) {
      state = state.copyWith(
        mistakes: state.mistakes + 1,
        wrongSelectionCells: {for (final (r, c) in selection) '$r,$c'},
      );
      _persistAttempt();
      return;
    }
    _markFound(puzzle, match);
  }

  /// A selection matches a word if its cell set equals that word's
  /// placement cells, in either reading direction — a player may
  /// naturally drag from either end of a word.
  String? _matchWord(WordSearchPuzzleDef puzzle, List<(int, int)> selection) {
    for (final placement in puzzle.placements) {
      if (state.foundWords.contains(placement.word)) continue;
      final cells = placement.cells;
      if (cells.length != selection.length) continue;
      if (_sameSequence(cells, selection) ||
          _sameSequence(cells.reversed.toList(), selection)) {
        return placement.word;
      }
    }
    return null;
  }

  bool _sameSequence(List<(int, int)> a, List<(int, int)> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _markFound(WordSearchPuzzleDef puzzle, String word) async {
    final foundWords = {...state.foundWords, word};
    state = state.copyWith(
      foundWords: foundWords,
      foundCells: _cellsFor(puzzle, foundWords),
      wrongSelectionCells: const {},
    );
    await _persist();
    await _checkCompletion();
  }

  /// Finds one random unfound word for the player, the same way the
  /// crossword app's hint reveals one letter and the sudoku app's hint
  /// reveals one cell — a hint always makes direct, immediate progress.
  Future<void> revealHint() async {
    final puzzle = state.puzzle;
    if (puzzle == null || state.isCompleted || state.isFailed) return;
    final remaining = puzzle.placements
        .map((p) => p.word)
        .where((w) => !state.foundWords.contains(w))
        .toList();
    if (remaining.isEmpty) return;

    final word = remaining[_random.nextInt(remaining.length)];
    _analytics.logEvent(AnalyticsEvents.hintUsed, {'puzzle_id': puzzle.id});
    state = state.copyWith(hintsUsed: state.hintsUsed + 1);
    await _persistAttempt();
    await _markFound(puzzle, word);
  }

  /// Whether another life can still be bought on this run.
  bool get canEarnBonusLife => state.bonusLives < maxBonusLives;

  /// Hands back one life after the player has watched a rewarded ad (or
  /// immediately, for a player who has removed ads).
  ///
  /// Only ever called from a user action, and only while the run is
  /// actually failed — granting a life to a board that is still playable
  /// would silently raise the limit for the rest of the run. The cap is
  /// enforced here as well as in the dialog, because the dialog is one
  /// caller and this is the rule.
  Future<void> grantExtraLife() async {
    if (!state.isFailed || !canEarnBonusLife) return;
    state = state.copyWith(bonusLives: state.bonusLives + 1);
    await _persistAttempt();
  }

  Future<void> restart() async {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    await _repository.clearProgress(puzzle.id);
    await _rewards.clearAttempt(puzzle.id);
    if (!mounted) return;
    // The puzzle list's cached summaries (and therefore the sequential
    // unlock check) would otherwise keep showing this puzzle as completed.
    _ref.invalidate(puzzleSummariesProvider);
    state = state.copyWith(
      foundWords: const {},
      foundCells: const {},
      wrongSelectionCells: const {},
      mistakes: 0,
      hintsUsed: 0,
      isCompleted: false,
      clearDragStart: true,
      clearDragCurrent: true,
    );
  }

  /// Written separately from [_persist] because it changes far less
  /// often — only on a wrong guess or a hint.
  Future<void> _persistAttempt() async {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    await _rewards.saveAttempt(
      puzzle.id,
      PuzzleAttempt(
        mistakes: state.mistakes,
        hintsUsed: state.hintsUsed,
        bonusLives: state.bonusLives,
      ),
    );
  }

  Future<void> _persist() async {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    await _repository.saveProgress(
      puzzle.id,
      WordSearchProgress(foundWords: state.foundWords, elapsedSeconds: 0),
    );
  }

  Future<void> _checkCompletion() async {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    if (state.foundWords.length < puzzle.placements.length) return;

    state = state.copyWith(isCompleted: true);
    await _repository.markCompleted(puzzle.id);
    // Every await here is a chance for the player to have left the puzzle;
    // reaching for the Ref afterwards throws on a disposed provider.
    if (!mounted) return;
    // The run is over, so its counters are dropped — a replay starts on
    // a full three lives. The tallies the solve earned have already
    // been read off the state by the screen.
    await _rewards.clearAttempt(puzzle.id);
    // FutureProvider.family caches per (language, difficulty) args and
    // never re-reads storage on its own — without this, the puzzle list
    // keeps showing this puzzle as unfinished and the next one stays
    // locked even though completion was just persisted.
    _ref.invalidate(puzzleSummariesProvider);
    _analytics.logEvent(AnalyticsEvents.puzzleCompleted, {
      'puzzle_id': puzzle.id,
    });
  }
}

final wordSearchControllerProvider =
    StateNotifierProvider.family<
      WordSearchController,
      WordSearchGameState,
      String
    >(
      (ref, assetPath) => WordSearchController(
        ref.watch(puzzleRepositoryProvider),
        ref.watch(rewardsRepositoryProvider),
        ref.watch(analyticsServiceProvider),
        ref,
        assetPath,
      ),
    );
