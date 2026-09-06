import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/storage/local_storage_service.dart';
import 'package:word_search_app/core/storage/storage_keys.dart';
import 'package:word_search_app/features/puzzle_list/domain/puzzle_summary.dart';
import 'package:word_search_app/features/word_search/data/puzzle_repository.dart';
import 'package:word_search_app/features/word_search/domain/word_search_progress.dart';

class _FakeStorage implements LocalStorageService {
  final Map<String, Object> _values = {};

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _values.remove(key);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PuzzleRepository', () {
    test('loads and derives the bundled en/easy sample puzzles', () async {
      final repository = PuzzleRepository(_FakeStorage());

      final summaries = await repository.listPuzzleSummaries(
        language: 'en',
        difficulty: 'easy',
      );

      expect(summaries, isNotEmpty);
      expect(summaries.every((s) => s.status == PuzzleStatus.notStarted), isTrue);
      expect(summaries.every((s) => s.wordCount > 0), isTrue);

      final def = await repository.loadPuzzleDef(summaries.first.assetPath);
      expect(def.rows, hasLength(def.size));
      expect(def.placements, isNotEmpty);
    });

    test('progress and completion round-trip through storage', () async {
      final storage = _FakeStorage();
      final repository = PuzzleRepository(storage);

      expect(repository.statusFor('p1'), PuzzleStatus.notStarted);

      await repository.saveProgress(
        'p1',
        const WordSearchProgress(foundWords: {'CAT'}, elapsedSeconds: 12),
      );
      expect(repository.statusFor('p1'), PuzzleStatus.inProgress);
      expect(repository.loadProgress('p1')!.foundWords, {'CAT'});

      await repository.markCompleted('p1');
      expect(repository.statusFor('p1'), PuzzleStatus.completed);

      await repository.clearProgress('p1');
      expect(repository.statusFor('p1'), PuzzleStatus.notStarted);
      expect(repository.loadProgress('p1'), isNull);
    });

    test('corrupted progress JSON is treated as no progress, not a crash', () async {
      final storage = _FakeStorage();
      await storage.setString(StorageKeys.puzzleProgress('p1'), 'not valid json');
      final repository = PuzzleRepository(storage);

      expect(repository.loadProgress('p1'), isNull);
    });
  });
}
