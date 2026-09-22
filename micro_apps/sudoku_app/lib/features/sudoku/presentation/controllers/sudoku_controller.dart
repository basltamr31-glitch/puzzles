import 'dart:async';

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
import '../../domain/sudoku_models.dart';
import '../../domain/sudoku_progress.dart';

/// Identifies one puzzle: which difficulty bundle, and which entry in it.
typedef SudokuPuzzleRef = ({String difficulty, int index});

class SudokuGameState extends Equatable {
  SudokuGameState({
    this.puzzle,
    List<int>? values,
    List<Set<int>>? notes,
    this.selectedIndex,
    this.notesMode = false,
    this.incorrectCells = const {},
    this.blockedCells = const {},
    this.elapsedSeconds = 0,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.bonusLives = 0,
    this.isCompleted = false,
    this.isLoading = true,
    this.errorMessage,
  })  : values = values ?? List<int>.filled(sudokuCellCount, 0),
        notes = notes ?? List<Set<int>>.generate(sudokuCellCount, (_) => <int>{});

  final SudokuPuzzleDef? puzzle;
  final List<int> values;
  final List<Set<int>> notes;
  final int? selectedIndex;

  /// When true, tapping a digit writes a pencil mark instead of an answer.
  final bool notesMode;

  /// Cells the last explicit Check found to disagree with the solution.
  /// Cleared on the next edit — it's feedback about a moment, not state.
  final Set<int> incorrectCells;

  /// The cell of a refused entry, plus the filled cells that refused it.
  ///
  /// Populated only when [SudokuController.enterDigit] blocks a digit that
  /// would duplicate one already visible from that cell. Both halves are
  /// included on purpose: telling the player "no" without showing them
  /// *what* it clashed with leaves them stuck, which matters because the
  /// blocker is often one of their own earlier mistakes rather than a
  /// given. Cleared by the next action, like [incorrectCells].
  final Set<int> blockedCells;

  final int elapsedSeconds;

  /// Digits entered on this run that disagreed with the solution.
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

  /// True once the player has spent every mistake. The board is read-only
  /// from here — the only ways on are restarting or leaving.
  bool get isFailed => mistakes >= maxMistakes + bonusLives;

  final bool isCompleted;
  final bool isLoading;
  final String? errorMessage;

  bool isGiven(int index) => puzzle?.isGiven(index) ?? false;

  /// Cells holding a digit that already appears in their row, column, or
  /// box. Shown continuously because it's a *rule* violation, visible to
  /// anyone looking at the grid — unlike [incorrectCells], which compares
  /// against the solution and so is only revealed when the player asks.
  Set<int> get conflicts {
    final conflicting = <int>{};
    for (var i = 0; i < sudokuCellCount; i++) {
      final digit = values[i];
      if (digit == 0) continue;
      for (final peer in sudokuPeers[i]) {
        if (values[peer] == digit) {
          conflicting..add(i)..add(peer);
        }
      }
    }
    return conflicting;
  }

  /// How many of each digit are still unplaced — drives the number pad
  /// dimming a digit once all nine are on the board.
  Map<int, int> get remainingByDigit {
    final remaining = {for (var d = 1; d <= sudokuSize; d++) d: sudokuSize};
    for (final value in values) {
      if (value != 0) remaining[value] = remaining[value]! - 1;
    }
    return remaining;
  }

  int get filledCount => values.where((v) => v != 0).length;

  SudokuGameState copyWith({
    SudokuPuzzleDef? puzzle,
    List<int>? values,
    List<Set<int>>? notes,
    int? selectedIndex,
    bool? notesMode,
    Set<int>? incorrectCells,
    Set<int>? blockedCells,
    int? elapsedSeconds,
    int? mistakes,
    int? hintsUsed,
    int? bonusLives,
    bool? isCompleted,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SudokuGameState(
      puzzle: puzzle ?? this.puzzle,
      values: values ?? this.values,
      notes: notes ?? this.notes,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      notesMode: notesMode ?? this.notesMode,
      incorrectCells: incorrectCells ?? this.incorrectCells,
      blockedCells: blockedCells ?? this.blockedCells,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
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
        // Equatable compares lists element-wise, but a Set inside a List
        // is compared by identity unless flattened, so notes are folded
        // into a comparable form here. Without this, toggling a pencil
        // mark would mutate-and-replace the list without the UI noticing.
        values,
        notes.map((n) => (n.toList()..sort()).join()).toList(),
        selectedIndex,
        notesMode,
        incorrectCells,
        blockedCells,
        elapsedSeconds,
        mistakes,
        hintsUsed,
        bonusLives,
        isCompleted,
        isLoading,
        errorMessage,
      ];
}

/// One entry on the undo stack. Full snapshots rather than inverse
/// operations: entering a digit also prunes that digit from every peer's
/// pencil marks, and reconstructing that from an inverse op is exactly
/// the kind of thing that quietly drifts out of sync.
class _Snapshot {
  _Snapshot(List<int> values, List<Set<int>> notes)
      : values = List<int>.from(values),
        notes = notes.map((n) => Set<int>.from(n)).toList();

  final List<int> values;
  final List<Set<int>> notes;
}

/// Owns all gameplay state for a single puzzle: selection, entries,
/// pencil marks, undo, the timer, validation feedback, hints, completion,
/// and progress persistence. One instance per puzzle (see
/// [sudokuControllerProvider]), so switching puzzles never leaks state.
class SudokuController extends StateNotifier<SudokuGameState> {
  SudokuController(
    this._repository,
    this._rewards,
    this._analytics,
    this._ref,
    this.puzzleRef,
  ) : super(SudokuGameState()) {
    _load();
  }

  final PuzzleRepository _repository;
  final RewardsRepository _rewards;
  final AnalyticsService _analytics;
  final Ref _ref;
  final SudokuPuzzleRef puzzleRef;

  final List<_Snapshot> _undoStack = [];
  static const int _maxUndo = 100;

  /// Elapsed time is written back only this often. A save per second
  /// would mean 3,600 SharedPreferences writes an hour for a number the
  /// player only ever sees rounded to seconds.
  static const int _persistTimerEvery = 15;

  Timer? _timer;
  bool _paused = false;

  bool get canUndo => _undoStack.isNotEmpty;

  Future<void> _load() async {
    try {
      final puzzle = await _repository.loadPuzzle(
        difficulty: puzzleRef.difficulty,
        index: puzzleRef.index,
      );
      // Loading the bundle is asynchronous, and the player can back out
      // of the puzzle before it finishes. Writing state on a disposed
      // notifier throws, so every await here is followed by this check.
      if (!mounted) return;

      final saved = _repository.loadProgress(puzzle.id);
      final isCompleted =
          _repository.statusFor(puzzle.id) == PuzzleStatus.completed;

      final progress = _usableProgress(puzzle, saved) ?? _initialProgress(puzzle);
      // A completed puzzle carries no live attempt: its counters were
      // cleared on the solve, and re-reading them would show a fresh
      // player three hearts on a board they cannot lose.
      final attempt = isCompleted
          ? PuzzleAttempt.empty
          : _rewards.loadAttempt(puzzle.id);
      state = state.copyWith(
        puzzle: puzzle,
        values: progress.values,
        notes: progress.notes,
        elapsedSeconds: progress.elapsedSeconds,
        mistakes: attempt.mistakes,
        hintsUsed: attempt.hintsUsed,
        bonusLives: attempt.bonusLives,
        isLoading: false,
        isCompleted: isCompleted,
        selectedIndex: _firstEmptyCell(puzzle, progress.values),
      );

      // Pushes the inactivity reminder back — someone actively playing
      // should never be nudged to come play.
      _ref.read(reminderControllerProvider.notifier).recordPlayed();

      if (!isCompleted) {
        _analytics.logEvent(AnalyticsEvents.puzzleStarted, {'puzzle_id': puzzle.id});
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

  /// [saved] if it still belongs to [puzzle], otherwise null.
  ///
  /// Saved progress is keyed by puzzle id, and ids are stable across
  /// releases while the grids behind them are regenerated content. If a
  /// bundle is ever rebuilt, a player mid-way through the old `easy_007`
  /// would have their entries replayed onto a different grid — which
  /// surfaces as a puzzle that "came with" a duplicate digit in a row and
  /// cannot be solved. There is no way to repair such a grid, so it is
  /// discarded and the puzzle starts clean.
  ///
  /// Cheap enough to run on every open (81 character comparisons) that
  /// there is no reason to gate it behind a version stamp that could
  /// itself be forgotten.
  static SudokuProgress? _usableProgress(
    SudokuPuzzleDef puzzle,
    SudokuProgress? saved,
  ) {
    if (saved == null) return null;
    for (var i = 0; i < sudokuCellCount; i++) {
      if (!puzzle.isGiven(i)) continue;
      if (saved.values[i] != int.parse(puzzle.givens[i])) return null;
    }
    return saved;
  }

  static SudokuProgress _initialProgress(SudokuPuzzleDef puzzle) {
    return SudokuProgress(
      values: List<int>.generate(
        sudokuCellCount,
        (i) => puzzle.givens[i] == emptyCell ? 0 : int.parse(puzzle.givens[i]),
      ),
      notes: List<Set<int>>.generate(sudokuCellCount, (_) => <int>{}),
      elapsedSeconds: 0,
    );
  }

  static int? _firstEmptyCell(SudokuPuzzleDef puzzle, List<int> values) {
    for (var i = 0; i < sudokuCellCount; i++) {
      if (values[i] == 0) return i;
    }
    return null;
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

  /// Called when the app leaves the foreground: a puzzle left open on a
  /// locked phone shouldn't keep counting against the player's time.
  void pauseTimer() {
    if (_paused) return;
    _paused = true;
    _persist();
  }

  void resumeTimer() => _paused = false;

  void selectCell(int index) {
    if (index < 0 || index >= sudokuCellCount) return;
    state = state.copyWith(
      selectedIndex: index,
      incorrectCells: const {},
      blockedCells: const {},
    );
  }

  void toggleNotesMode() {
    state = state.copyWith(notesMode: !state.notesMode);
  }

  /// Cells already showing [digit] that [index] can see — the reason an
  /// entry is refused, and empty when the entry is legal.
  Set<int> _clashesFor(int index, int digit) {
    return {
      for (final peer in sudokuPeers[index])
        if (state.values[peer] == digit) peer,
    };
  }

  /// Writes [digit] into the selected cell — as an answer, or as a pencil
  /// mark when [SudokuGameState.notesMode] is on. Tapping the digit
  /// already in the cell clears it, which is how players expect a number
  /// pad to behave.
  ///
  /// An answer that would duplicate a digit the cell can already see is
  /// **refused** rather than written. The grid used to accept it and mark
  /// it after the fact, which failed in the way that matters: a player
  /// put a 7 under a column that already had one, the far-away clue lit
  /// up red while their own mistake sat under the selection highlight,
  /// and it read as "this puzzle contains two 7s" rather than "I slipped".
  /// Refusing is unambiguous — the digit never lands, so there is no
  /// wrong state to misread.
  ///
  /// Pencil marks are deliberately exempt: a note is a hypothesis, and
  /// the whole point of writing one is to reason about a digit before
  /// committing to it.
  void enterDigit(int digit) {
    final index = state.selectedIndex;
    final puzzle = state.puzzle;
    if (puzzle == null || index == null || state.isCompleted) return;
    if (state.isFailed) return;
    if (puzzle.isGiven(index)) return;
    if (digit < 1 || digit > sudokuSize) return;

    // Clearing the cell by re-tapping its own digit is never a clash, and
    // checking first would find the cell's own value on no peer anyway.
    final isClearing = !state.notesMode && state.values[index] == digit;
    if (!state.notesMode && !isClearing) {
      final clashes = _clashesFor(index, digit);
      if (clashes.isNotEmpty) {
        // Nothing is written and no undo entry is pushed — a refused tap
        // is not a move, so it must not cost the player an undo step.
        state = state.copyWith(
          incorrectCells: const {},
          blockedCells: {index, ...clashes},
        );
        return;
      }
    }

    _pushUndo();

    final values = List<int>.from(state.values);
    final notes = state.notes.map((n) => Set<int>.from(n)).toList();

    if (state.notesMode) {
      // A pencil mark on a cell that already has an answer would be
      // invisible, so writing a note clears the answer it would hide.
      values[index] = 0;
      if (notes[index].contains(digit)) {
        notes[index].remove(digit);
      } else {
        notes[index].add(digit);
      }
    } else if (values[index] == digit) {
      values[index] = 0;
    } else {
      values[index] = digit;
      notes[index].clear();
      // Placing a digit makes it impossible everywhere it can see, so
      // those pencil marks are removed for the player rather than left
      // as stale clutter they have to tidy up by hand.
      for (final peer in sudokuPeers[index]) {
        notes[peer].remove(digit);
      }
    }

    // A digit that is legal against everything the cell can see but still
    // disagrees with the solution is the mistake worth counting. The
    // obvious duplicates never get this far — they were refused above,
    // for free — so a spent life always means a real deduction error
    // rather than a slip of the thumb.
    final isWrong = !state.notesMode &&
        values[index] != 0 &&
        values[index] != int.parse(puzzle.solution[index]);

    state = state.copyWith(
      values: values,
      notes: notes,
      mistakes: isWrong ? state.mistakes + 1 : state.mistakes,
      // The offending cell is marked straight away. Counting a life
      // without showing which entry cost it would leave the player
      // hunting a mistake they cannot see.
      incorrectCells: isWrong ? {index} : const {},
      blockedCells: const {},
    );
    _persist();
    if (isWrong) {
      _persistAttempt();
      return;
    }
    _checkCompletion();
  }

  void eraseSelectedCell() {
    final index = state.selectedIndex;
    final puzzle = state.puzzle;
    if (puzzle == null || index == null || state.isCompleted) return;
    if (state.isFailed) return;
    if (puzzle.isGiven(index)) return;
    if (state.values[index] == 0 && state.notes[index].isEmpty) return;

    _pushUndo();
    final values = List<int>.from(state.values)..[index] = 0;
    final notes = state.notes.map((n) => Set<int>.from(n)).toList();
    notes[index].clear();

    state = state.copyWith(values: values, notes: notes, incorrectCells: const {});
    _persist();
  }

  void undo() {
    if (_undoStack.isEmpty || state.isCompleted || state.isFailed) return;
    final snapshot = _undoStack.removeLast();
    state = state.copyWith(
      values: snapshot.values,
      notes: snapshot.notes,
      incorrectCells: const {},
      blockedCells: const {},
    );
    _persist();
  }

  /// Fills the selected cell with its solution digit. If nothing is
  /// selected, the first empty cell is used, so a hint is never wasted on
  /// a no-op just because the player hadn't tapped anywhere yet.
  void revealHintAtSelectedCell() {
    final puzzle = state.puzzle;
    if (puzzle == null || state.isCompleted || state.isFailed) return;
    final index = state.selectedIndex != null && state.values[state.selectedIndex!] == 0
        ? state.selectedIndex!
        : _firstEmptyCell(puzzle, state.values) ?? -1;
    if (index < 0) return;

    _pushUndo();
    final digit = int.parse(puzzle.solution[index]);
    final values = List<int>.from(state.values)..[index] = digit;
    final notes = state.notes.map((n) => Set<int>.from(n)).toList();
    notes[index].clear();
    for (final peer in sudokuPeers[index]) {
      notes[peer].remove(digit);
    }

    state = state.copyWith(
      values: values,
      notes: notes,
      selectedIndex: index,
      hintsUsed: state.hintsUsed + 1,
      incorrectCells: const {},
      blockedCells: const {},
    );
    _persist();
    _persistAttempt();
    _checkCompletion();
  }

  void checkAnswers() {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    final incorrect = <int>{};
    for (var i = 0; i < sudokuCellCount; i++) {
      final value = state.values[i];
      if (value == 0) continue;
      if (value != int.parse(puzzle.solution[i])) incorrect.add(i);
    }
    state = state.copyWith(incorrectCells: incorrect);
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

    _undoStack.clear();
    final progress = _initialProgress(puzzle);
    state = state.copyWith(
      values: progress.values,
      notes: progress.notes,
      elapsedSeconds: 0,
      mistakes: 0,
      hintsUsed: 0,
      incorrectCells: const {},
      blockedCells: const {},
      isCompleted: false,
      selectedIndex: _firstEmptyCell(puzzle, progress.values),
    );
    _startTimer();
  }

  void _pushUndo() {
    _undoStack.add(_Snapshot(state.values, state.notes));
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
  }

  /// Written separately from [_persist] because it changes far less often
  /// — only on a mistake or a hint, never on the timer tick.
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
      SudokuProgress(
        values: state.values,
        notes: state.notes,
        elapsedSeconds: state.elapsedSeconds,
      ),
    );
  }

  Future<void> _checkCompletion() async {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    for (var i = 0; i < sudokuCellCount; i++) {
      if (state.values[i] != int.parse(puzzle.solution[i])) return;
    }

    _timer?.cancel();
    state = state.copyWith(isCompleted: true, incorrectCells: const {});
    await _repository.markCompleted(puzzle.id);
    // The run is over, so its counters are dropped — a replay starts on a
    // full three lives. The tallies the solve earned have already been
    // read off the state by the screen.
    await _rewards.clearAttempt(puzzle.id);
    if (!mounted) return;
    // FutureProvider.family caches per difficulty and never re-reads
    // storage on its own — without this, the puzzle list keeps showing
    // this puzzle as unfinished and the next one stays locked even though
    // completion was just persisted.
    _ref.invalidate(puzzleSummariesProvider);
    _analytics.logEvent(AnalyticsEvents.puzzleCompleted, {
      'puzzle_id': puzzle.id,
      'elapsed_seconds': state.elapsedSeconds,
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // The timer only writes elapsed time every 15 seconds, so leaving the
    // screen would otherwise discard up to that much of the player's
    // solve time. Fire-and-forget: state is unreadable after dispose().
    final puzzle = state.puzzle;
    if (puzzle != null) {
      unawaited(_repository.saveProgress(
        puzzle.id,
        SudokuProgress(
          values: state.values,
          notes: state.notes,
          elapsedSeconds: state.elapsedSeconds,
        ),
      ));
    }
    super.dispose();
  }
}

/// **autoDispose is load-bearing.** The controller owns a per-second
/// timer; without disposal, backing out to the puzzle list would leave it
/// running forever and the player's next visit would show a solve time
/// that includes however long the app sat on another screen.
final sudokuControllerProvider = StateNotifierProvider.autoDispose
    .family<SudokuController, SudokuGameState, SudokuPuzzleRef>(
  (ref, puzzleRef) => SudokuController(
    ref.watch(puzzleRepositoryProvider),
    ref.watch(rewardsRepositoryProvider),
    ref.watch(analyticsServiceProvider),
    ref,
    puzzleRef,
  ),
);
