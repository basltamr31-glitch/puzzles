import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/features/word_search/domain/word_search_models.dart';
import 'package:word_search_app/features/word_search/domain/word_search_scanner.dart';

void main() {
  group('WordSearchScanner.findAll', () {
    test('finds a word placed left to right', () {
      // A full square grid, not just its first two rows: the scanner
      // uses `rows.length` as both the row and column bound, which is
      // only valid for a square grid — every real puzzle is one, per
      // WordSearchValidator, but a non-square slice here would silently
      // clip the very column this word needs.
      final placements = WordSearchScanner.findAll([
        'CATD',
        'OXXO',
        'XWXG',
        'XXLX',
      ], 'CAT');
      expect(placements, hasLength(1));
      expect(placements.first.row, 0);
      expect(placements.first.col, 0);
      expect(placements.first.direction, WordDirection.east);
    });

    test('finds a word placed diagonally', () {
      final placements = WordSearchScanner.findAll([
        'CATD',
        'OXXO',
        'XWXG',
        'XXLX',
      ], 'OWL');
      expect(placements, hasLength(1));
      expect(placements.first.row, 1);
      expect(placements.first.col, 0);
      expect(placements.first.direction, WordDirection.southEast);
    });

    test('a palindrome counts once, not twice, for its two readings', () {
      // "ANNA" read east from (0,0) and read west from (0,3) occupy the
      // same four cells — that must collapse to a single occurrence, or
      // every real palindrome would look like a duplicate word to the
      // uniqueness check.
      final placements = WordSearchScanner.findAll(['ANNA'], 'ANNA');
      expect(placements, hasLength(1));
    });

    test('returns nothing when the word is not present', () {
      expect(WordSearchScanner.findAll(['CATD', 'OXXO'], 'DOG'), isEmpty);
    });
  });

  group('WordSearchValidator', () {
    WordSearchPuzzleDef fixture() => WordSearchPuzzleDef(
      id: 'fixture',
      language: 'en',
      difficulty: 'easy',
      index: 0,
      size: 4,
      rows: const ['CATD', 'OXXO', 'XWXG', 'XXLX'],
      placements: const [
        WordPlacement(word: 'CAT', row: 0, col: 0, direction: WordDirection.east),
        WordPlacement(word: 'DOG', row: 0, col: 3, direction: WordDirection.south),
        WordPlacement(
          word: 'OWL',
          row: 1,
          col: 0,
          direction: WordDirection.southEast,
        ),
      ],
    );

    test('accepts a puzzle whose words each appear exactly once', () {
      expect(WordSearchValidator.validate(fixture()).isValid, isTrue);
    });

    test('rejects a word that does not actually spell out where it is placed', () {
      final broken = WordSearchPuzzleDef(
        id: 'broken',
        language: 'en',
        difficulty: 'easy',
        index: 0,
        size: 4,
        rows: fixture().rows,
        placements: const [
          WordPlacement(word: 'DOG', row: 0, col: 0, direction: WordDirection.east),
        ],
      );
      final result = WordSearchValidator.validate(broken);
      expect(result.isValid, isFalse);
      expect(result.problems.single, contains('placed where the grid spells'));
    });

    test('rejects a word that appears more than once in the grid', () {
      // "XX" appears at (1,1)-(1,2) and, read the other way, nowhere else
      // in this fixture — so instead we construct a grid where the target
      // word genuinely repeats.
      final duplicated = WordSearchPuzzleDef(
        id: 'duplicated',
        language: 'en',
        difficulty: 'easy',
        index: 0,
        size: 3,
        rows: const ['CAT', 'XXX', 'CAT'],
        placements: const [
          WordPlacement(word: 'CAT', row: 0, col: 0, direction: WordDirection.east),
        ],
      );
      final result = WordSearchValidator.validate(duplicated);
      expect(result.isValid, isFalse);
      expect(result.problems.single, contains('appears 2 times'));
    });

    test('rejects a word listed twice', () {
      final def = fixture();
      final withDuplicate = WordSearchPuzzleDef(
        id: def.id,
        language: def.language,
        difficulty: def.difficulty,
        index: def.index,
        size: def.size,
        rows: def.rows,
        placements: [...def.placements, def.placements.first],
      );
      final result = WordSearchValidator.validate(withDuplicate);
      expect(result.isValid, isFalse);
      expect(result.problems, contains('"CAT" is listed twice'));
    });
  });
}
