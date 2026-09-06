import 'package:crossword_app/core/errors/app_exception.dart';
import 'package:crossword_app/features/crossword/domain/crossword_grid_generator.dart';
import 'package:crossword_app/features/crossword/domain/crossword_models.dart';
import 'package:flutter_test/flutter_test.dart';

CrosswordPuzzleDef _validDef() {
  return const CrosswordPuzzleDef(
    id: 'test_001',
    language: 'en',
    difficulty: 'easy',
    title: 'Test Puzzle',
    rows: 3,
    cols: 3,
    words: [
      CrosswordWordDef(
        direction: WordDirection.across,
        row: 0,
        col: 0,
        answer: 'CAT',
        clue: 'A pet',
      ),
      CrosswordWordDef(
        direction: WordDirection.down,
        row: 0,
        col: 0,
        answer: 'CAR',
        clue: 'A vehicle',
      ),
      CrosswordWordDef(
        direction: WordDirection.down,
        row: 0,
        col: 2,
        answer: 'TOT',
        clue: 'A child',
      ),
      CrosswordWordDef(
        direction: WordDirection.across,
        row: 2,
        col: 0,
        answer: 'RAT',
        clue: 'A rodent',
      ),
    ],
  );
}

void main() {
  group('CrosswordGridGenerator', () {
    test('derives blocked cells from words alone', () {
      final grid = CrosswordGridGenerator.generate(_validDef());

      expect(grid.cellAt(1, 1).isBlocked, isTrue);
      expect(grid.cellAt(0, 0).isBlocked, isFalse);
      expect(grid.cellAt(0, 0).solutionLetter, 'C');
      expect(grid.cellAt(2, 2).solutionLetter, 'T');
    });

    test('numbers clues in row-major scan order, shared across directions', () {
      final grid = CrosswordGridGenerator.generate(_validDef());

      // (0,0) starts both CAT (across) and CAR (down) -> both get number 1.
      expect(grid.acrossClues.firstWhere((c) => c.answer == 'CAT').number, 1);
      expect(grid.downClues.firstWhere((c) => c.answer == 'CAR').number, 1);
      // (0,2) starts TOT (down) -> number 2.
      expect(grid.downClues.firstWhere((c) => c.answer == 'TOT').number, 2);
      // (2,0) starts RAT (across) -> number 3.
      expect(grid.acrossClues.firstWhere((c) => c.answer == 'RAT').number, 3);
    });

    test('word cells are listed in reading order', () {
      final grid = CrosswordGridGenerator.generate(_validDef());
      final cat = grid.acrossClues.firstWhere((c) => c.answer == 'CAT');
      expect(cat.cells, [(0, 0), (0, 1), (0, 2)]);
    });

    test('throws InvalidPuzzleException on conflicting overlap letters', () {
      const bad = CrosswordPuzzleDef(
        id: 'bad',
        language: 'en',
        difficulty: 'easy',
        title: 'Bad',
        rows: 3,
        cols: 3,
        words: [
          CrosswordWordDef(
            direction: WordDirection.across,
            row: 0,
            col: 0,
            answer: 'CAT',
            clue: 'x',
          ),
          CrosswordWordDef(
            direction: WordDirection.down,
            row: 0,
            col: 0,
            answer: 'DOG', // D at (0,0) conflicts with CAT's C
            clue: 'y',
          ),
        ],
      );

      expect(
        () => CrosswordGridGenerator.generate(bad),
        throwsA(isA<InvalidPuzzleException>()),
      );
    });

    test('throws InvalidPuzzleException when a word falls outside the grid', () {
      const bad = CrosswordPuzzleDef(
        id: 'bad',
        language: 'en',
        difficulty: 'easy',
        title: 'Bad',
        rows: 3,
        cols: 3,
        words: [
          CrosswordWordDef(
            direction: WordDirection.across,
            row: 0,
            col: 1,
            answer: 'CATS', // would run off the 3-wide grid
            clue: 'x',
          ),
        ],
      );

      expect(
        () => CrosswordGridGenerator.generate(bad),
        throwsA(isA<InvalidPuzzleException>()),
      );
    });

    test('throws InvalidPuzzleException for words shorter than 2 letters', () {
      const bad = CrosswordPuzzleDef(
        id: 'bad',
        language: 'en',
        difficulty: 'easy',
        title: 'Bad',
        rows: 3,
        cols: 3,
        words: [
          CrosswordWordDef(
            direction: WordDirection.across,
            row: 0,
            col: 0,
            answer: 'A',
            clue: 'x',
          ),
        ],
      );

      expect(
        () => CrosswordGridGenerator.generate(bad),
        throwsA(isA<InvalidPuzzleException>()),
      );
    });
  });
}
