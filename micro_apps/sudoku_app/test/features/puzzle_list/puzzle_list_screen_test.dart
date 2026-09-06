import 'package:sudoku_app/features/puzzle_list/domain/puzzle_summary.dart';
import 'package:sudoku_app/features/puzzle_list/presentation/puzzle_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

var _nextIndex = 0;

PuzzleSummary _summary(String id, PuzzleStatus status) {
  return PuzzleSummary(
    id: id,
    difficulty: 'easy',
    index: _nextIndex++,
    givenCount: 40,
    status: status,
  );
}

void main() {
  group('isPuzzleLocked', () {
    test('the first puzzle is never locked, even if not started', () {
      final summaries = [_summary('p1', PuzzleStatus.notStarted)];
      expect(isPuzzleLocked(summaries, 0), isFalse);
    });

    test('a not-started puzzle is locked when the previous one is unfinished', () {
      final summaries = [
        _summary('p1', PuzzleStatus.notStarted),
        _summary('p2', PuzzleStatus.notStarted),
      ];
      expect(isPuzzleLocked(summaries, 1), isTrue);
    });

    test('a not-started puzzle unlocks once the previous one is completed', () {
      final summaries = [
        _summary('p1', PuzzleStatus.completed),
        _summary('p2', PuzzleStatus.notStarted),
      ];
      expect(isPuzzleLocked(summaries, 1), isFalse);
    });

    test('a not-started puzzle stays locked while the previous is only in progress', () {
      final summaries = [
        _summary('p1', PuzzleStatus.inProgress),
        _summary('p2', PuzzleStatus.notStarted),
      ];
      expect(isPuzzleLocked(summaries, 1), isTrue);
    });

    test('a puzzle already in progress is never shown as locked', () {
      final summaries = [
        _summary('p1', PuzzleStatus.notStarted),
        _summary('p2', PuzzleStatus.inProgress),
      ];
      expect(isPuzzleLocked(summaries, 1), isFalse);
    });

    test('a puzzle already completed is never shown as locked', () {
      final summaries = [
        _summary('p1', PuzzleStatus.notStarted),
        _summary('p2', PuzzleStatus.completed),
      ];
      expect(isPuzzleLocked(summaries, 1), isFalse);
    });
  });
}
