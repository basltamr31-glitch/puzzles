// Generates the bundled Word Search puzzles.
//
//   dart run tool/generate_puzzles.dart              # every language
//   dart run tool/generate_puzzles.dart en           # just one language
//
// Writes assets/puzzles/<language>/<difficulty>/puzzle_NNN.json. Nothing
// under assets/puzzles/ is ever hand-edited: this script owns those
// files, and it validates every puzzle through the same
// WordSearchValidator the app's tests run over the shipped assets.
//
// Runs under plain `dart run` (no Flutter engine) because everything it
// imports from lib/ is pure Dart.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:word_search_app/features/word_search/domain/puzzle_theme.dart';
import 'package:word_search_app/features/word_search/domain/word_search_generator.dart';
import 'package:word_search_app/features/word_search/domain/word_search_models.dart';
import 'package:word_search_app/features/word_search/domain/word_search_scanner.dart';

import 'word_banks/ar_words.dart';
import 'word_banks/de_words.dart';
import 'word_banks/en_words.dart';
import 'word_banks/es_words.dart';
import 'word_banks/fr_words.dart';
import 'word_banks/it_words.dart';

const int puzzlesPerDifficulty = 100;

/// Fixed per language so a regeneration reproduces the same set instead
/// of silently reshuffling every player's puzzle numbering.
const Map<String, int> _languageSeeds = {
  'en': 20260901,
  'ar': 20260902,
  'de': 20260903,
  'fr': 20260904,
  'es': 20260905,
  'it': 20260906,
};

final _wordBanksByLanguage = <String, Map<PuzzleTheme, List<String>>>{
  'en': wordsByThemeEn,
  'ar': wordsByThemeAr,
  'de': wordsByThemeDe,
  'fr': wordsByThemeFr,
  'es': wordsByThemeEs,
  'it': wordsByThemeIt,
};

Future<void> main(List<String> args) async {
  final requested = args.isEmpty ? _wordBanksByLanguage.keys.toList() : args;

  for (final language in requested) {
    final wordBanks = _wordBanksByLanguage[language];
    if (wordBanks == null) {
      stderr.writeln(
        'Unknown language "$language". '
        'Expected one of: ${_wordBanksByLanguage.keys.join(', ')}',
      );
      exitCode = 1;
      return;
    }
    await _generateLanguage(language, wordBanks);
  }
}

Future<void> _generateLanguage(
  String language,
  Map<PuzzleTheme, List<String>> wordBanks,
) async {
  final started = DateTime.now();
  final random = Random(_languageSeeds[language]!);
  final allWords = wordBanks.values.expand((words) => words);
  final fillerAlphabet = WordSearchGenerator.fillerAlphabetFor(allWords);
  final themes = wordBanks.keys.toList();

  for (final tierId in wordSearchTiers.keys) {
    final tier = wordSearchTiers[tierId]!;
    final puzzles = <WordSearchPuzzleDef>[];
    final seenGrids = <String>{};
    var themeCursor = 0;

    while (puzzles.length < puzzlesPerDifficulty) {
      final index = puzzles.length;
      final id = '${language}_${tierId}_'
          '${(index + 1).toString().padLeft(3, '0')}';

      final def = _generateOne(
        id: id,
        language: language,
        difficulty: tierId,
        index: index,
        wordBanks: wordBanks,
        themes: themes,
        startThemeIndex: themeCursor,
        tier: tier,
        fillerAlphabet: fillerAlphabet,
        random: random,
      );
      themeCursor = (themeCursor + 1) % themes.length;

      if (def == null) {
        stderr.writeln(
          'Gave up generating a "$language/$tierId" puzzle after the '
          'attempt limit. Widen the word pools in tool/word_banks/.',
        );
        exitCode = 1;
        return;
      }
      // Two identical grids in one language/difficulty would look like a
      // bug to a player who reaches both, so a duplicate is discarded
      // rather than shipped.
      if (!seenGrids.add(def.rows.join())) continue;

      final validation = WordSearchValidator.validate(def);
      if (!validation.isValid) {
        throw StateError('$id failed validation:\n$validation');
      }
      puzzles.add(def);
    }

    final dir = Directory('assets/puzzles/$language/$tierId');
    await dir.create(recursive: true);
    for (final puzzle in puzzles) {
      final file = File(
        '${dir.path}/puzzle_'
        '${(puzzle.index + 1).toString().padLeft(3, '0')}.json',
      );
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(puzzle.toJson()),
      );
    }

    final elapsed = DateTime.now().difference(started);
    stdout.writeln(
      '$language/$tierId: ${puzzles.length} puzzles, '
      'size ${tier.size}x${tier.size}, ${tier.wordCount} words, '
      '${elapsed.inSeconds}s -> ${dir.path}/',
    );
  }
}

/// Tries the puzzle's assigned theme first, then falls back through the
/// remaining themes (merging pools as it goes) so a theme whose pool is
/// briefly exhausted of eligible words for this tier doesn't block the
/// whole batch — it costs variety on that one puzzle, not a failed build.
WordSearchPuzzleDef? _generateOne({
  required String id,
  required String language,
  required String difficulty,
  required int index,
  required Map<PuzzleTheme, List<String>> wordBanks,
  required List<PuzzleTheme> themes,
  required int startThemeIndex,
  required WordSearchTier tier,
  required List<String> fillerAlphabet,
  required Random random,
}) {
  var pool = <String>[];
  for (var offset = 0; offset < themes.length; offset++) {
    final theme = themes[(startThemeIndex + offset) % themes.length];
    pool = [...pool, ...wordBanks[theme]!];

    for (var attempt = 0; attempt < 60; attempt++) {
      final words = WordSearchGenerator.pickWords(
        pool: pool,
        tier: tier,
        random: random,
      );
      if (words == null) break;

      final def = WordSearchGenerator.tryGenerate(
        id: id,
        language: language,
        difficulty: difficulty,
        index: index,
        theme: theme,
        words: words,
        tier: tier,
        fillerAlphabet: fillerAlphabet,
        random: random,
      );
      if (def != null) return def;
    }
  }
  return null;
}
