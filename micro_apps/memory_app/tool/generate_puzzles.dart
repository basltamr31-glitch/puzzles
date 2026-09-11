// Generates the bundled Memory Match decks.
//
//   dart run tool/generate_puzzles.dart            # every difficulty
//   dart run tool/generate_puzzles.dart hard       # just one
//
// Writes assets/puzzles/<difficulty>.json. Nothing under assets/puzzles/
// is ever hand-edited: this script owns those files, and it validates
// every deck through the same validator the bundled-decks test uses
// before writing.
//
// Runs under plain `dart run` (no Flutter engine) because everything it
// imports from lib/ is pure Dart.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:memory_app/features/memory/domain/memory_deck_generator.dart';
import 'package:memory_app/features/memory/domain/memory_models.dart';

import 'symbol_banks.dart';

const int decksPerDifficulty = 100;

Future<void> main(List<String> args) async {
  final requested = args.isEmpty ? memoryTiers.keys.toList() : args;

  for (final difficulty in requested) {
    final tier = memoryTiers[difficulty];
    if (tier == null) {
      stderr.writeln(
        'Unknown difficulty "$difficulty". '
        'Expected one of: ${memoryTiers.keys.join(', ')}',
      );
      exitCode = 1;
      return;
    }

    final started = DateTime.now();
    final generator = MemoryDeckGenerator(
      symbolsByTheme: symbolBanks,
      random: Random(tier.seed),
    );
    const validator = MemoryDeckValidator();

    final decks = <MemoryDeckDef>[];
    final seenLayouts = <String>{};
    var attempts = 0;

    while (decks.length < decksPerDifficulty) {
      attempts++;
      if (attempts > decksPerDifficulty * 50) {
        stderr.writeln(
          '$difficulty: gave up after $attempts attempts with only '
          '${decks.length} distinct decks. The symbol banks are probably '
          'too small for ${tier.pairCount} pairs.',
        );
        exitCode = 1;
        return;
      }

      final deck = generator.generate(tier: tier, index: decks.length);
      // Two identical boards in one file look like a bug to the player who
      // reaches both, and on the mixed tiers — where only 6 of the 16
      // available symbols are drawn — a collision is likelier than it
      // sounds. A repeat deal is discarded, not renumbered.
      if (!seenLayouts.add(deck.cards.join())) continue;

      final problems = validator.validate(deck);
      if (problems.isNotEmpty) {
        stderr.writeln('${deck.id}: ${problems.join('; ')}');
        exitCode = 1;
        return;
      }
      decks.add(deck);
    }

    final file = File('assets/puzzles/$difficulty.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'difficulty': difficulty,
        'count': decks.length,
        'decks': decks.map((d) => d.toJson()).toList(),
      }),
    );

    final themed = decks.where((d) => d.theme != null).length;
    final elapsed = DateTime.now().difference(started);
    stdout.writeln(
      '$difficulty: ${decks.length} decks, '
      '${tier.rows}x${tier.cols} (${tier.pairCount} pairs), '
      '$themed themed, '
      '${elapsed.inMilliseconds}ms -> ${file.path}',
    );
  }
}
