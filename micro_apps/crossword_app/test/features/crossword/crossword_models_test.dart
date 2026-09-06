import 'package:crossword_app/core/errors/app_exception.dart';
import 'package:crossword_app/features/crossword/domain/crossword_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrosswordWordDef.fromJson', () {
    test('parses a valid entry and uppercases the answer', () {
      final word = CrosswordWordDef.fromJson({
        'direction': 'across',
        'row': 1,
        'col': 2,
        'answer': 'cat',
        'clue': 'A pet',
      });

      expect(word.direction, WordDirection.across);
      expect(word.answer, 'CAT');
      expect(word.length, 3);
    });

    test('throws InvalidPuzzleException for an unknown direction', () {
      expect(
        () => CrosswordWordDef.fromJson({
          'direction': 'diagonal',
          'row': 0,
          'col': 0,
          'answer': 'CAT',
          'clue': 'x',
        }),
        throwsA(isA<InvalidPuzzleException>()),
      );
    });

    test('throws InvalidPuzzleException when a required field is missing', () {
      expect(
        () => CrosswordWordDef.fromJson({
          'direction': 'across',
          'row': 0,
          'col': 0,
          'answer': 'CAT',
          // 'clue' missing
        }),
        throwsA(isA<InvalidPuzzleException>()),
      );
    });
  });

  group('CrosswordPuzzleDef.fromJson', () {
    test('parses a full valid puzzle document', () {
      final def = CrosswordPuzzleDef.fromJson({
        'id': 'en_easy_001',
        'language': 'en',
        'difficulty': 'easy',
        'title': 'Puzzle 001',
        'rows': 3,
        'cols': 3,
        'words': [
          {
            'direction': 'across',
            'row': 0,
            'col': 0,
            'answer': 'CAT',
            'clue': 'A pet',
          },
        ],
      });

      expect(def.id, 'en_easy_001');
      expect(def.words, hasLength(1));
    });

    test('throws InvalidPuzzleException when words is empty', () {
      expect(
        () => CrosswordPuzzleDef.fromJson({
          'id': 'x',
          'language': 'en',
          'difficulty': 'easy',
          'title': 'x',
          'rows': 3,
          'cols': 3,
          'words': <Map<String, dynamic>>[],
        }),
        throwsA(isA<InvalidPuzzleException>()),
      );
    });
  });
}
