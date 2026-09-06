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
    this._analytics,
    this._ref,
    this.assetPath,
  ) : super(const CrosswordGameState()) {
    _load();
  }

  final PuzzleRepository _repository;
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

      state = state.copyWith(
        grid: grid,
        letters: savedLetters,
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
    if (grid.cellAt(row, col).isBlocked) return;
    if (rawInput.isEmpty) return;

    final letter = rawInput.characters.last.toUpperCase();
    final updated = Map<String, String>.from(state.letters);
    updated['$row,$col'] = letter;

    state = state.copyWith(letters: updated, incorrectCells: const {});
    _persist();
    _advance(grid, row, col);
    _checkCompletion();
  }

  void backspace() {
    final grid = state.grid;
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (grid == null || row == null || col == null) return;

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

  void revealHintAtSelectedCell() {
    final grid = state.grid;
    final row = state.selectedRow;
    final col = state.selectedCol;
    if (grid == null || row == null || col == null) return;
    final cell = grid.cellAt(row, col);
    if (cell.isBlocked || cell.solutionLetter == null) return;

    final updated = Map<String, String>.from(state.letters);
    updated['$row,$col'] = cell.solutionLetter!;
    state = state.copyWith(letters: updated, incorrectCells: const {});
    _persist();
    _advance(grid, row, col);
    _checkCompletion();
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
    // The puzzle list's cached summaries (and therefore the sequential
    // unlock check) would otherwise keep showing this puzzle as completed.
    _ref.invalidate(puzzleSummariesProvider);
    final firstClue = grid.acrossClues.isNotEmpty
        ? grid.acrossClues.first
        : grid.downClues.first;
    state = state.copyWith(
      letters: const {},
      incorrectCells: const {},
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
        ref.watch(analyticsServiceProvider),
        ref,
        assetPath,
      ),
    );
