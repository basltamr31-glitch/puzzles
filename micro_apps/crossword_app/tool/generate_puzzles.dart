// Generates puzzle JSON assets using CrosswordConstructor, validating every
// output through the app's real CrosswordGridGenerator before it's written.
//
// Run with: dart run tool/generate_puzzles.dart <languageCode>
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crossword_app/features/crossword/domain/clue_category.dart';
import 'package:crossword_app/features/crossword/domain/crossword_grid_generator.dart';
import 'package:crossword_app/features/crossword/domain/crossword_models.dart';

import 'crossword_constructor.dart';
import 'word_banks/ar_words.dart';
import 'word_banks/clue_categories.dart';
import 'word_banks/de_words.dart';
import 'word_banks/en_words.dart';
import 'word_banks/es_words.dart';
import 'word_banks/fr_words.dart';
import 'word_banks/it_words.dart';

class _TierConfig {
  const _TierConfig({
    required this.maxSize,
    required this.minWords,
    required this.targetWords,
    required this.puzzleTarget,
  });

  final int maxSize;
  final int minWords;
  final int targetWords;
  final int puzzleTarget;
}

// Difficulty is now driven by grid complexity and word count, not just
// vocabulary — each tier requires meaningfully more words than the last,
// on a meaningfully bigger board, so "easy" and "expert" read as
// structurally different puzzles, not just easier/harder words on the
// same small grid.
const _tierConfigs = {
  'easy': _TierConfig(maxSize: 7, minWords: 5, targetWords: 7, puzzleTarget: 100),
  'medium': _TierConfig(maxSize: 10, minWords: 8, targetWords: 10, puzzleTarget: 100),
  'hard': _TierConfig(maxSize: 13, minWords: 10, targetWords: 13, puzzleTarget: 100),
  'expert': _TierConfig(maxSize: 15, minWords: 12, targetWords: 16, puzzleTarget: 100),
};

class _LanguageConfig {
  const _LanguageConfig(this.titlePrefix, this.wordBanks);
  final String titlePrefix;
  final Map<String, List<WordClue>> wordBanks;
}

final _languageConfigs = <String, _LanguageConfig>{
  'en': const _LanguageConfig('Puzzle', wordBanksByDifficulty),
  'ar': const _LanguageConfig('اللغز', wordBanksByDifficultyAr),
  'de': const _LanguageConfig('Rätsel', wordBanksByDifficultyDe),
  'fr': const _LanguageConfig('Grille', wordBanksByDifficultyFr),
  'es': const _LanguageConfig('Crucigrama', wordBanksByDifficultyEs),
  'it': const _LanguageConfig('Cruciverba', wordBanksByDifficultyIt),
};

void main(List<String> args) {
  final language = args.isNotEmpty ? args[0] : 'en';
  final langConfig = _languageConfigs[language];
  if (langConfig == null) {
    stderr.writeln('Unknown language "$language". Known: ${_languageConfigs.keys.join(', ')}');
    exitCode = 1;
    return;
  }

  final root = Directory('assets/puzzles/$language');
  final rng = Random();
  final summary = <String, int>{};

  for (final difficulty in ['easy', 'medium', 'hard', 'expert']) {
    final config = _tierConfigs[difficulty]!;
    final pool = langConfig.wordBanks[difficulty]!;
    final dir = Directory('${root.path}/$difficulty');
    dir.createSync(recursive: true);

    var nextIndex = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .length +
        1;

    final seenWordSets = <String>{};
    var attempts = 0;
    var generated = 0;
    const maxAttempts = 6000;

    while (generated < config.puzzleTarget && attempts < maxAttempts) {
      attempts++;
      final constructor = CrosswordConstructor(rng);
      final build = constructor.tryBuild(
        pool: pool,
        maxSize: config.maxSize,
        minWords: config.minWords,
        targetWords: config.targetWords,
      );
      if (build == null) continue;

      final signature = (build.words.map((w) => w.wc.answer).toList()..sort()).join('|');
      if (!seenWordSets.add(signature)) continue;

      final id = '${language}_${difficulty}_${nextIndex.toString().padLeft(3, '0')}';
      final title = '${langConfig.titlePrefix} ${nextIndex.toString().padLeft(3, '0')}';

      // Supporting icons are an easy-tier aid only; the harder tiers are
      // largely abstract vocabulary that no icon could honestly represent.
      final categories = difficulty == 'easy'
          ? (categoriesByLanguage[language] ?? const {})
          : const <String, ClueCategory>{};

      final wordDefs = build.words.map((w) {
        return CrosswordWordDef(
          direction: w.across ? WordDirection.across : WordDirection.down,
          row: w.row,
          col: w.col,
          answer: w.wc.answer,
          clue: w.wc.clue,
          category: categories[w.wc.answer],
        );
      }).toList();

      final def = CrosswordPuzzleDef(
        id: id,
        language: language,
        difficulty: difficulty,
        title: title,
        rows: build.rows,
        cols: build.cols,
        words: wordDefs,
      );

      // Validate through the app's real grid generator before writing.
      try {
        final grid = CrosswordGridGenerator.generate(def);
        if (grid.acrossClues.isEmpty && grid.downClues.isEmpty) continue;
      } catch (_) {
        continue;
      }

      final json = {
        'id': id,
        'language': language,
        'difficulty': difficulty,
        'title': title,
        'rows': build.rows,
        'cols': build.cols,
        'words': build.words.map((w) {
          final category = categories[w.wc.answer];
          return {
            'direction': w.across ? 'across' : 'down',
            'row': w.row,
            'col': w.col,
            'answer': w.wc.answer,
            'clue': w.wc.clue,
            // Omitted entirely when absent, rather than written as null.
            if (category != null) 'category': category.id,
          };
        }).toList(),
      };

      final file = File('${dir.path}/puzzle_${nextIndex.toString().padLeft(3, '0')}.json');
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));

      nextIndex++;
      generated++;
    }

    summary['$language/$difficulty'] = generated;
    stdout.writeln(
      '$language/$difficulty: generated $generated puzzles in $attempts attempts '
      '(pool size ${pool.length})',
    );
  }

  stdout.writeln('\nSummary:');
  for (final entry in summary.entries) {
    stdout.writeln('  ${entry.key}: ${entry.value}');
  }
}
