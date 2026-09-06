import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/app/app_config.dart';
import 'package:word_search_app/core/storage/local_storage_service.dart';
import 'package:word_search_app/features/word_search/data/puzzle_repository.dart';
import 'package:word_search_app/features/word_search/domain/word_search_generator.dart';
import 'package:word_search_app/features/word_search/domain/word_search_models.dart';
import 'package:word_search_app/features/word_search/domain/word_search_scanner.dart';

/// Validates every shipped puzzle through the real repository and the
/// real scanner/validator.
///
/// This is a permanent test, not a throwaway generator script: content is
/// generated, and the only thing standing between a generator bug and an
/// unsolvable shipped puzzle is a check that runs over the real assets.
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

  for (final language in AppConfig.supportedGameLanguageCodes) {
    for (final difficulty in AppConfig.difficultyOrder) {
      group('assets/puzzles/$language/$difficulty', () {
        late List<WordSearchPuzzleDef> puzzles;

        setUpAll(() async {
          final summaries = await repository.listPuzzleSummaries(
            language: language,
            difficulty: difficulty,
          );
          puzzles = [
            for (final s in summaries) await repository.loadPuzzleDef(s.assetPath),
          ];
        });

        test('ships a full set of 100 puzzles', () {
          expect(puzzles.length, 100);
        });

        test('every puzzle validates against its own grid', () {
          for (final puzzle in puzzles) {
            final result = WordSearchValidator.validate(puzzle);
            expect(result.isValid, isTrue, reason: '${puzzle.id}:\n$result');
          }
        });

        test('every puzzle matches its declared tier shape', () {
          final tier = wordSearchTiers[difficulty]!;
          for (final puzzle in puzzles) {
            expect(puzzle.size, tier.size, reason: puzzle.id);
            expect(puzzle.placements.length, tier.wordCount, reason: puzzle.id);
            expect(puzzle.difficulty, difficulty, reason: puzzle.id);
            expect(puzzle.language, language, reason: puzzle.id);
          }
        });

        test('every placed word actually reads correctly off its grid', () {
          for (final puzzle in puzzles) {
            for (final placement in puzzle.placements) {
              final spelled = [
                for (final (row, col) in placement.cells) puzzle.rows[row][col],
              ].join();
              expect(spelled, placement.word, reason: puzzle.id);
            }
          }
        });

        test('ids are unique across the whole bundle', () {
          for (final puzzle in puzzles) {
            expect(seenIds.add(puzzle.id), isTrue, reason: 'duplicate id ${puzzle.id}');
          }
        });

        test('summaries expose the same word count as the full puzzle', () async {
          final summaries = await repository.listPuzzleSummaries(
            language: language,
            difficulty: difficulty,
          );
          expect(summaries.length, puzzles.length);
          for (var i = 0; i < summaries.length; i++) {
            expect(summaries[i].wordCount, puzzles[i].placements.length);
          }
        });
      });
    }
  }

  test('every difficulty the app can route to has a tier spec', () {
    for (final difficulty in AppConfig.difficultyOrder) {
      expect(wordSearchTiers.containsKey(difficulty), isTrue, reason: difficulty);
    }
  });
}
