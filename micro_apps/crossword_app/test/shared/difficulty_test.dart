import 'package:crossword_app/shared/models/difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Difficulty', () {
    test('storageValue and fromStorageValue round-trip', () {
      for (final difficulty in Difficulty.values) {
        expect(Difficulty.fromStorageValue(difficulty.storageValue), difficulty);
      }
    });

    test('fromStorageValue falls back to easy for unknown values', () {
      expect(Difficulty.fromStorageValue('nonsense'), Difficulty.easy);
    });
  });
}
