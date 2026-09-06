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
    this.elapsedSeconds = 0,
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

  final int elapsedSeconds;
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
    int? elapsedSeconds,
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
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
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
        elapsedSeconds,
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
  SudokuController(this._repository, this._analytics, this._ref, this.puzzleRef)
      : super(SudokuGameState()) {
    _load();
  }

  final PuzzleRepository _repository;
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

      final progress = saved ?? _initialProgress(puzzle);
      state = state.copyWith(
        puzzle: puzzle,
        values: progress.values,
        notes: progress.notes,
        elapsedSeconds: progress.elapsedSeconds,
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
    state = state.copyWith(selectedIndex: index, incorrectCells: const {});
  }

  void toggleNotesMode() {
    state = state.copyWith(notesMode: !state.notesMode);
  }

  /// Writes [digit] into the selected cell — as an answer, or as a pencil
  /// mark when [SudokuGameState.notesMode] is on. Tapping the digit
  /// already in the cell clears it, which is how players expect a number
  /// pad to behave.
  void enterDigit(int digit) {
    final index = state.selectedIndex;
    final puzzle = state.puzzle;
    if (puzzle == null || index == null || state.isCompleted) return;
    if (puzzle.isGiven(index)) return;
    if (digit < 1 || digit > sudokuSize) return;

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

    state = state.copyWith(
      values: values,
      notes: notes,
      incorrectCells: const {},
    );
    _persist();
    _checkCompletion();
  }

  void eraseSelectedCell() {
    final index = state.selectedIndex;
    final puzzle = state.puzzle;
    if (puzzle == null || index == null || state.isCompleted) return;
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
    if (_undoStack.isEmpty || state.isCompleted) return;
    final snapshot = _undoStack.removeLast();
    state = state.copyWith(
      values: snapshot.values,
      notes: snapshot.notes,
      incorrectCells: const {},
    );
    _persist();
  }

  /// Fills the selected cell with its solution digit. If nothing is
  /// selected, the first empty cell is used, so a hint is never wasted on
  /// a no-op just because the player hadn't tapped anywhere yet.
  void revealHintAtSelectedCell() {
    final puzzle = state.puzzle;
    if (puzzle == null || state.isCompleted) return;
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
      incorrectCells: const {},
    );
    _persist();
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

  Future<void> restart() async {
    final puzzle = state.puzzle;
    if (puzzle == null) return;
    await _repository.clearProgress(puzzle.id);
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
      incorrectCells: const {},
      isCompleted: false,
      selectedIndex: _firstEmptyCell(puzzle, progress.values),
    );
    _startTimer();
  }

  void _pushUndo() {
    _undoStack.add(_Snapshot(state.values, state.notes));
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
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
    ref.watch(analyticsServiceProvider),
    ref,
    puzzleRef,
  ),
);
