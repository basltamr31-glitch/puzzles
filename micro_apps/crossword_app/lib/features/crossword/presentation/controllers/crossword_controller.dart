import 'package:characters/characters.dart';
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
import '../../domain/crossword_models.dart';

/// Finds the clue (in [direction]) that covers (row, col), or null if that
/// direction doesn't have a word through this cell.
CrosswordClue? clueAt(
  CrosswordGrid grid,
  int row,
  int col,
  WordDirection direction,
) {
  final clues = direction == WordDirection.across
      ? grid.acrossClues
      : grid.downClues;
  for (final clue in clues) {
    for (final cell in clue.cells) {
      if (cell.$1 == row && cell.$2 == col) return clue;
    }
  }
  return null;
}

class CrosswordGameState extends Equatable {
  const CrosswordGameState({
    this.grid,
    this.letters = const {},
    this.selectedRow,
    this.selectedCol,
    this.direction = WordDirection.across,
    this.incorrectCells = const {},
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.isCompleted = false,
    this.isLoading = true,
    this.errorMessage,
  });

  final CrosswordGrid? grid;
  final Map<String, String> letters;
  final int? selectedRow;
  final int? selectedCol;
  final WordDirection direction;
  final Set<String> incorrectCells;

  /// Clues filled in wrong on this run.
  final int mistakes;

  /// Hints spent on this run. Costs a star rather than a life.
  final int hintsUsed;

  /// True once the player has spent every mistake. The grid stops
  /// accepting letters — the only ways on are restarting or leaving.
  bool get isFailed => mistakes >= maxMistakes;

  final bool isCompleted;
  final bool isLoading;
  final String? errorMessage;

  CrosswordClue? get currentClue {
    final g = grid;
    if (g == null || selectedRow == null || selectedCol == null) return null;
    return clueAt(g, selectedRow!, selectedCol!, direction);
  }

  int get filledCount => letters.values.where((l) => l.isNotEmpty).length;

  CrosswordGameState copyWith({
    CrosswordGrid? grid,
    Map<String, String>? letters,
    int? selectedRow,
    int? selectedCol,
    WordDirection? direction,
    Set<String>? incorrectCells,
    int? mistakes,
    int? hintsUsed,
    bool? isCompleted,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CrosswordGameState(
      grid: grid ?? this.grid,
      letters: letters ?? this.letters,
      selectedRow: selectedRow ?? this.selectedRow,
      selectedCol: selectedCol ?? this.selectedCol,
      direction: direction ?? this.direction,
      incorrectCells: incorrectCells ?? this.incorrectCells,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    grid,
    letters,
    selectedRow,
    selectedCol,
    direction,
    incorrectCells,
    mistakes,
    hintsUsed,
    isCompleted,
    isLoading,
    errorMessage,
  ];
}

/// Owns all gameplay state for a single puzzle: selection, entered
/// letters, validation feedback, hints, completion, and progress
/// persistence. One instance per puzzle asset path (see
/// [crosswordControllerProvider]), so switching puzzles never leaks state.
class CrosswordController extends StateNotifier<CrosswordGameState> {
  CrosswordController(
    this._repository,
    this._rewards,
    this._analytics,
    this._ref,
    this.assetPath,
  ) : super(const CrosswordGameState()) {
    _load();
  }

  final PuzzleRepository _repository;
  final RewardsRepository _rewards;
  final AnalyticsService _analytics;
  final Ref _ref;
  final String assetPath;

  Future<void> _load() async {
    try {
      final grid = await _repository.loadGrid(assetPath);
      final savedLetters = _repository.loadProgress(grid.puzzleId) ?? {};
      final isCompleted =
          _repository.statusFor(grid.puzzleId) == PuzzleStatus.completed;
      final firstClue = grid.acrossClues.isNotEmpty
          ? grid.acrossClues.first
          : grid.downClues.first;

      // A completed puzzle carries no live attempt: its counters were
      // cleared on the solve, and re-reading them would show a spent
      // heart on a board that can no longer be lost.
      final attempt = isCompleted
          ? PuzzleAttempt.empty
          : _rewards.loadAttempt(grid.puzzleId);

      state = state.copyWith(
        grid: grid,
        letters: savedLetters,
        mistakes: attempt.mistakes,
        hintsUsed: attempt.hintsUsed,
        isLoading: false,
        isCompleted: isCompleted,
        selectedRow: firstClue.cells.first.$1,
        selectedCol: firstClue.cells.first.$2,
        direction: firstClue.direction,
      );

      // Pushes the inactivity reminder back — someone actively playing
      // should never be nudged to come play.
      _ref.read(reminderControllerProvider.notifier).recordPlayed();

      if (!isCompleted) {
        _analytics.logEvent(AnalyticsEvents.puzzleStarted, {
          'puzzle_id': grid.puzzleId,
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

  void selectCell(int row, int col) {
    final grid = state.grid;
    if (grid == null) return;
    if (grid.cellAt(row, col).isBlocked) return;

    final sameCell = state.selectedRow == row && state.selectedCol == col;
    final hasAcross = clueAt(grid, row, col, WordDirection.across) != null;
    final hasDown = clueAt(grid, row, col, WordDirection.down) != null;

    var direction = state.direction;
    if (sameCell && hasAcross && hasDown) {
      direction = direction == WordDirection.across
          ? WordDirection.down
          : WordDirection.across;
    } else if (!sameCell) {
      if (direction == WordDirection.across && !hasAcross) {
        direction = WordDirection.down;
      } else if (direction == WordDirection.down && !hasDown) {
        direction = WordDirection.across;
      }
    }

    state = state.copyWith(
      selectedRow: row,
      selectedCol: col,
      direction: direction,
      incorrectCells: const {},
    );
  }

  void selectClue(CrosswordClue clue) {
    final firstEmpty = clue.cells.firstWhere(
      (c) => (state.letters['${c.$1},${c.$2}'] ?? '').isEmpty,
      orElse: () => clue.cells.first,
    );
    state = state.copyWith(
      selectedRow: firstEmpty.$1,
      selectedCol: firstEmpty.$2,
      direction: clue.direction,
      incorrectCells: const {},
    );
  }

  void enterLetter(String rawInput) {
    final grid = state.grid;
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (grid == null || state.isCompleted || row == null || col == null) return;
    if (state.isFailed) return;
    if (grid.cellAt(row, col).isBlocked) return;
    if (rawInput.isEmpty) return;

    final letter = rawInput.characters.last.toUpperCase();
    final updated = Map<String, String>.from(state.letters);
    updated['$row,$col'] = letter;

    final wrongClue = _clueFinishedWrong(grid, row, col, updated);
    if (wrongClue != null) _struckClues.add(wrongClue);

    state = state.copyWith(
      letters: updated,
      mistakes: wrongClue != null ? state.mistakes + 1 : state.mistakes,
      // The wrong answer stays lit rather than being cleared like
      // ordinary Check feedback. Spending a life without showing which
      // word cost it would leave the player hunting for it.
      incorrectCells: wrongClue != null
          ? _wrongCellsIn(grid, row, col, updated)
          : const {},
    );
    _persist();
    if (wrongClue != null) {
      _persistAttempt();
      return;
    }
    _advance(grid, row, col);
    _checkCompletion();
  }

  /// Clues already charged for, keyed by clue and by the exact letters
  /// that were wrong.
  ///
  /// Without this, backspacing the last letter of a wrong answer and
  /// retyping the same one would charge again — and a player who cannot
  /// see why an answer is refused will do exactly that. Typing a
  /// *different* wrong answer is a new guess and does cost a life.
  final Set<String> _struckClues = {};

  /// The identity of the clue through (row, col) if the letter just
  /// entered completed it and the completed word is wrong — otherwise
  /// null.
  ///
  /// Only *finished* words are judged. A crossword is typed left to
  /// right, so every partial answer disagrees with the solution at some
  /// point; charging per keystroke would end the puzzle before the
  /// player had entered a single complete word.
  String? _clueFinishedWrong(
    CrosswordGrid grid,
    int row,
    int col,
    Map<String, String> letters,
  ) {
    final clue = clueAt(grid, row, col, state.direction);
    if (clue == null) return null;

    final entered = StringBuffer();
    var wrong = false;
    for (final cell in clue.cells) {
      final value = letters['${cell.$1},${cell.$2}'] ?? '';
      if (value.isEmpty) return null;
      entered.write(value);
      if (value != grid.cellAt(cell.$1, cell.$2).solutionLetter) wrong = true;
    }
    if (!wrong) return null;

    final identity = '${clue.direction.name}:${clue.cells.first}:$entered';
    return _struckClues.contains(identity) ? null : identity;
  }

  Set<String> _wrongCellsIn(
    CrosswordGrid grid,
    int row,
    int col,
    Map<String, String> letters,
  ) {
    final clue = clueAt(grid, row, col, state.direction);
    if (clue == null) return const {};
    return {
      for (final cell in clue.cells)
        if (letters['${cell.$1},${cell.$2}'] !=
            grid.cellAt(cell.$1, cell.$2).solutionLetter)
          '${cell.$1},${cell.$2}',
    };
  }

  void backspace() {
    final grid = state.grid;
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (grid == null || row == null || col == null) return;
    if (state.isFailed) return;

    final updated = Map<String, String>.from(state.letters);
    final key = '$row,$col';
    if ((updated[key] ?? '').isNotEmpty) {
      updated.remove(key);
      state = state.copyWith(letters: updated, incorrectCells: const {});
      _persist();
      return;
    }

    final clue = clueAt(grid, row, col, state.direction);
    if (clue == null) return;
    final idx = clue.cells.indexWhere((c) => c.$1 == row && c.$2 == col);
    if (idx <= 0) return;
    final prev = clue.cells[idx - 1];
    updated.remove('${prev.$1},${prev.$2}');
    state = state.copyWith(
      letters: updated,
      selectedRow: prev.$1,
      selectedCol: prev.$2,
      incorrectCells: const {},
    );
    _persist();
  }

  /// Reveals one letter, starting at the selected cell.
  ///
  /// A hint is paid for — with a rewarded ad, or by having bought the
  /// ad-free upgrade — so it must always visibly do something. Revealing
  /// the selected cell unconditionally did not: land on a cell that is
  /// already correct (which is where the caret sits after typing a word,
  /// or on any crossing letter) and the reward filled in a letter that was
  /// already there, which reads as "the ad gave me nothing". So the reveal
  /// falls forward to the first cell that is actually still unsolved: in
  /// the current word first, then anywhere in the grid.
  void revealHintAtSelectedCell() {
    final grid = state.grid;
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (grid == null || row == null || col == null) return;

    if (state.isFailed) return;

    final target = _firstUnsolvedCell(grid, row, col);
    if (target == null) return;

    final (targetRow, targetCol) = target;
    final solution = grid.cellAt(targetRow, targetCol).solutionLetter;
    if (solution == null) return;

    final updated = Map<String, String>.from(state.letters);
    updated['$targetRow,$targetCol'] = solution;
    state = state.copyWith(
      letters: updated,
      selectedRow: targetRow,
      selectedCol: targetCol,
      hintsUsed: state.hintsUsed + 1,
      incorrectCells: const {},
    );
    _persist();
    _persistAttempt();
    _advance(grid, targetRow, targetCol);
    _checkCompletion();
  }

  /// The cell a hint should fill: the selected one if it still needs
  /// solving, otherwise the first that does — searching the current word
  /// before the rest of the grid, so a hint stays near what the player is
  /// working on. Null only when the whole grid is already correct.
  (int, int)? _firstUnsolvedCell(CrosswordGrid grid, int row, int col) {
    bool needsSolving(int r, int c) {
      final cell = grid.cellAt(r, c);
      if (cell.isBlocked || cell.solutionLetter == null) return false;
      return state.letters['$r,$c'] != cell.solutionLetter;
    }

    if (needsSolving(row, col)) return (row, col);

    final clue = clueAt(grid, row, col, state.direction);
    if (clue != null) {
      for (final cell in clue.cells) {
        if (needsSolving(cell.$1, cell.$2)) return cell;
      }
    }

    for (var r = 0; r < grid.rows; r++) {
      for (var c = 0; c < grid.cols; c++) {
        if (needsSolving(r, c)) return (r, c);
      }
    }
    return null;
  }

  void checkAnswers() {
    final grid = state.grid;
    if (grid == null) return;
    final incorrect = <String>{};
    for (var r = 0; r < grid.rows; r++) {
      for (var c = 0; c < grid.cols; c++) {
        final cell = grid.cellAt(r, c);
        if (cell.isBlocked) continue;
        final key = '$r,$c';
        final entered = state.letters[key];
        if (entered != null && entered != cell.solutionLetter) {
          incorrect.add(key);
        }
      }
    }
    state = state.copyWith(incorrectCells: incorrect);
  }

  Future<void> restart() async {
    final grid = state.grid;
    if (grid == null) return;
    await _repository.clearProgress(grid.puzzleId);
    await _rewards.clearAttempt(grid.puzzleId);
    if (!mounted) return;
    _struckClues.clear();
    // The puzzle list's cached summaries (and therefore the sequential
    // unlock check) would otherwise keep showing this puzzle as completed.
    _ref.invalidate(puzzleSummariesProvider);
    final firstClue = grid.acrossClues.isNotEmpty
        ? grid.acrossClues.first
        : grid.downClues.first;
    state = state.copyWith(
      letters: const {},
      incorrectCells: const {},
      mistakes: 0,
      hintsUsed: 0,
      isCompleted: false,
      selectedRow: firstClue.cells.first.$1,
      selectedCol: firstClue.cells.first.$2,
      direction: firstClue.direction,
    );
  }

  void _advance(CrosswordGrid grid, int row, int col) {
    final clue = clueAt(grid, row, col, state.direction);
    if (clue == null) return;
    final idx = clue.cells.indexWhere((c) => c.$1 == row && c.$2 == col);
    if (idx == -1 || idx + 1 >= clue.cells.length) return;
    final next = clue.cells[idx + 1];
    state = state.copyWith(selectedRow: next.$1, selectedCol: next.$2);
  }

  /// Written separately from [_persist] because it changes far less
  /// often — only on a wrong answer or a hint.
  Future<void> _persistAttempt() async {
    final grid = state.grid;
    if (grid == null) return;
    await _rewards.saveAttempt(
      grid.puzzleId,
      PuzzleAttempt(mistakes: state.mistakes, hintsUsed: state.hintsUsed),
    );
  }

  Future<void> _persist() async {
    final grid = state.grid;
    if (grid == null) return;
    await _repository.saveProgress(grid.puzzleId, state.letters);
  }

  Future<void> _checkCompletion() async {
    final grid = state.grid;
    if (grid == null) return;
    for (var r = 0; r < grid.rows; r++) {
      for (var c = 0; c < grid.cols; c++) {
        final cell = grid.cellAt(r, c);
        if (cell.isBlocked) continue;
        if (state.letters['$r,$c'] != cell.solutionLetter) return;
      }
    }
    state = state.copyWith(isCompleted: true, incorrectCells: const {});
    await _repository.markCompleted(grid.puzzleId);
    // Every await here is a chance for the player to have left the puzzle;
    // reaching for the Ref afterwards throws on a disposed provider.
    if (!mounted) return;
    // The run is over, so its counters are dropped — a replay starts on
    // a full three lives. The tallies the solve earned have already
    // been read off the state by the screen.
    await _rewards.clearAttempt(grid.puzzleId);
    // FutureProvider.family caches per (language, difficulty) args and
    // never re-reads storage on its own — without this, the puzzle list
    // keeps showing this puzzle as unfinished and the next one stays
    // locked even though completion was just persisted.
    _ref.invalidate(puzzleSummariesProvider);
    _analytics.logEvent(AnalyticsEvents.puzzleCompleted, {
      'puzzle_id': grid.puzzleId,
    });
  }
}

final crosswordControllerProvider =
    StateNotifierProvider.family<
      CrosswordController,
      CrosswordGameState,
      String
    >(
      (ref, assetPath) => CrosswordController(
        ref.watch(puzzleRepositoryProvider),
        ref.watch(rewardsRepositoryProvider),
        ref.watch(analyticsServiceProvider),
        ref,
        assetPath,
      ),
    );
