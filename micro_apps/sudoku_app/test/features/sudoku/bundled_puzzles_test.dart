import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/app/app_config.dart';
import 'package:sudoku_app/core/errors/app_exception.dart';
import 'package:sudoku_app/core/storage/local_storage_service.dart';
import 'package:sudoku_app/features/sudoku/data/puzzle_repository.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_generator.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_models.dart';
import 'package:sudoku_app/features/sudoku/domain/sudoku_solver.dart';

/// Validates every shipped puzzle through the real repository and the
/// real solver.
///
/// The crossword app does this with a throwaway script that is written,
/// run once, and deleted. Here it is a permanent test instead: Sudoku
/// content is language-independent and the whole check runs in seconds,
/// so there is no reason for "are the puzzles we ship actually solvable"
/// to be a question anyone has to remember to ask by hand.
class _NullStorage implements LocalStorageService {
  @override
  bool? getBool(String key) => null;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  String? getString(String key) => null;
  @override
  Future<bool> setString(String key, String value) async => true;
  @override
  int? getInt(String key) => null;
  @override
  Future<bool> setInt(String key, int value) async => true;
  @override
  Future<bool> remove(String key) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = PuzzleRepository(_NullStorage());
  final seenIds = <String>{};
  final seenGivens = <String>{};

  for (final difficulty in AppConfig.difficultyOrder) {
    group('assets/puzzles/$difficulty.json', () {
      late List<SudokuPuzzleDef> puzzles;

      setUpAll(() async {
        puzzles = await repository.loadDifficulty(difficulty);
      });

      test('ships a full set of 100 puzzles', () {
        expect(puzzles.length, 100);
      });

      test('every puzzle has exactly one solution', () {
        for (final puzzle in puzzles) {
          expect(
            SudokuSolver.countSolutions(SudokuSolver.parse(puzzle.givens), limit: 2),
            1,
            reason: puzzle.id,
          );
        }
      });

      test('every solution is complete and rule-abiding', () {
        for (final puzzle in puzzles) {
          final solution = SudokuSolver.parse(puzzle.solution);
          expect(solution.contains(0), isFalse, reason: puzzle.id);
          expect(SudokuSolver.isConsistent(solution), isTrue, reason: puzzle.id);
        }
      });

      test('every given agrees with its solution', () {
        for (final puzzle in puzzles) {
          for (var i = 0; i < sudokuCellCount; i++) {
            if (puzzle.givens[i] == emptyCell) continue;
            expect(puzzle.givens[i], puzzle.solution[i], reason: '${puzzle.id} cell $i');
          }
        }
      });

      test('every puzzle lands inside its own tier', () {
        final spec = sudokuTiers[difficulty]!;
        for (final puzzle in puzzles) {
          expect(puzzle.difficulty, difficulty, reason: puzzle.id);
          final grade = SudokuSolver.grade(SudokuSolver.parse(puzzle.givens));
          expect(
            spec.accepts(puzzle.givenCount, grade),
            isTrue,
            reason: '${puzzle.id}: ${puzzle.givenCount} givens, graded ${grade.name}',
          );
        }
      });

      test('ids and grids are unique across the whole bundle', () {
        for (final puzzle in puzzles) {
          expect(seenIds.add(puzzle.id), isTrue, reason: 'duplicate id ${puzzle.id}');
          expect(
            seenGivens.add(puzzle.givens),
            isTrue,
            reason: 'duplicate grid at ${puzzle.id}',
          );
        }
      });

      test('summaries expose the same puzzles in bundle order', () async {
        final summaries = await repository.listPuzzleSummaries(difficulty: difficulty);
        expect(summaries.length, puzzles.length);
        for (var i = 0; i < summaries.length; i++) {
          expect(summaries[i].id, puzzles[i].id);
          expect(summaries[i].index, i);
          expect(summaries[i].givenCount, puzzles[i].givenCount);
        }
      });
    });
  }

  test('a missing bundle surfaces as a handled failure, not a crash', () async {
    // expectLater, not expect: loadDifficulty reports the failure through
    // its future, and a sync expect would pass on merely being handed one.
    await expectLater(
      PuzzleRepository(_NullStorage()).loadDifficulty('nonexistent'),
      throwsA(isA<PuzzleNotFoundException>()),
    );
  });

  test('every difficulty the app can route to has a tier spec', () {
    for (final difficulty in AppConfig.difficultyOrder) {
      expect(sudokuTiers.containsKey(difficulty), isTrue, reason: difficulty);
    }
    expect(sudokuTiers.keys.toSet(), AppConfig.difficultyOrder.toSet());
  });
}
