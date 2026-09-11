import 'package:flutter_test/flutter_test.dart';
import 'package:memory_app/features/memory/domain/memory_progress.dart';

void main() {
  group('encode/decode', () {
    test('round-trips everything a reopened board needs', () {
      const progress = MemoryProgress(
        matchedCards: {0, 4, 7, 11},
        seenCards: {0, 1, 4, 7, 9, 11},
        moves: 12,
        elapsedSeconds: 95,
        fingerprint: 'a1b2c3d4',
      );

      final restored = MemoryProgress.decode(progress.encode());

      expect(restored.matchedCards, progress.matchedCards);
      expect(restored.seenCards, progress.seenCards);
      expect(restored.moves, progress.moves);
      expect(restored.elapsedSeconds, progress.elapsedSeconds);
      expect(restored.fingerprint, progress.fingerprint);
    });

    test('an empty board round-trips too', () {
      final restored = MemoryProgress.decode(
        const MemoryProgress.empty().encode(),
      );

      expect(restored.matchedCards, isEmpty);
      expect(restored.seenCards, isEmpty);
      expect(restored.moves, 0);
    });

    test('reads progress written before a field existed', () {
      // Saved progress outlives the code that wrote it: a player upgrades
      // mid-board. Every field added later has to decode to a sane
      // default rather than throwing and costing them the game.
      final restored = MemoryProgress.decode('{"matched":[0,4]}');

      expect(restored.matchedCards, {0, 4});
      expect(restored.seenCards, isEmpty);
      expect(restored.moves, 0);
      expect(restored.elapsedSeconds, 0);
      expect(restored.fingerprint, '');
    });

    test('copyWith replaces only what it is given', () {
      const progress = MemoryProgress(
        matchedCards: {1},
        seenCards: {1, 2},
        moves: 3,
        elapsedSeconds: 10,
        fingerprint: 'abc',
      );

      final updated = progress.copyWith(moves: 4);

      expect(updated.moves, 4);
      expect(updated.matchedCards, {1});
      expect(updated.seenCards, {1, 2});
      expect(updated.elapsedSeconds, 10);
      expect(updated.fingerprint, 'abc');
    });
  });
}
