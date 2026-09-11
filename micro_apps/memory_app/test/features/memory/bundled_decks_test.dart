import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memory_app/app/app_config.dart';
import 'package:memory_app/features/memory/domain/memory_deck_generator.dart';
import 'package:memory_app/features/memory/domain/memory_models.dart';

/// Validates every deck the app actually ships, through the same
/// validator `tool/generate_puzzles.dart` runs before writing them.
///
/// This is a permanent test, not a throwaway script. The generator is
/// where a bad deck would come from, and the generator is also what would
/// be changed by anyone editing the tiers or the banks — so the guarantee
/// has to be checked against the written asset, by something that runs on
/// every `flutter test`.
///
/// Reads the JSON off disk rather than through `rootBundle`: these are
/// build inputs here, the parse is the point, and going through the asset
/// bundle would need a widget binding for no benefit.
void main() {
  const validator = MemoryDeckValidator();

  List<MemoryDeckDef> load(String difficulty) {
    final file = File('assets/puzzles/$difficulty.json');
    expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return (json['decks'] as List)
        .map((e) => MemoryDeckDef.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  for (final difficulty in AppConfig.difficultyOrder) {
    group('assets/puzzles/$difficulty.json', () {
      late List<MemoryDeckDef> decks;

      setUpAll(() => decks = load(difficulty));

      test('ships a full set of 100 decks', () {
        expect(decks.length, 100);
      });

      test('every deck passes the generator\'s own validator', () {
        for (final deck in decks) {
          expect(
            validator.validate(deck),
            isEmpty,
            reason: '${deck.id}: ${validator.validate(deck).join('; ')}',
          );
        }
      });

      test('deck ids and indices match their position in the file', () {
        // The list screen routes by index and shows `index + 1` as the
        // deck number; an id that disagrees would send a player to a
        // different board than the row they tapped.
        for (var i = 0; i < decks.length; i++) {
          expect(decks[i].index, i);
          expect(decks[i].id, '${difficulty}_${(i + 1).toString().padLeft(3, '0')}');
          expect(decks[i].difficulty, difficulty);
        }
      });

      test('no two decks share a deal', () {
        // Two identical boards in one file look like a bug to the player
        // who reaches both.
        final layouts = decks.map((d) => d.cards.join()).toSet();
        expect(layouts.length, decks.length);
      });

      test('the board matches the tier it belongs to', () {
        final tier = memoryTiers[difficulty]!;
        for (final deck in decks) {
          expect(deck.rows, tier.rows);
          expect(deck.cols, tier.cols);
          expect(deck.pairCount, tier.pairCount);
        }
      });

      test('themes are present exactly where the tier calls for them', () {
        final tier = memoryTiers[difficulty]!;
        for (final deck in decks) {
          expect(
            deck.theme != null,
            tier.singleTheme,
            reason: '${deck.id} theme=${deck.theme?.id}',
          );
        }
      });

      test('every symbol renders as a single glyph on a card', () {
        // Two rules the symbol banks promise and the asset must keep:
        // no variation selector or ZWJ sequence (which splits into
        // several glyphs on a platform that does not know it), and
        // nothing above Unicode 9.0, which is a blank rectangle on the
        // older Android fonts `minSdk 21` invites in. A card showing a
        // rectangle is still matchable, so this would ship as a puzzle
        // that merely looks broken.
        for (final deck in decks) {
          for (final symbol in deck.cards.toSet()) {
            final runes = symbol.runes.toList();
            expect(
              runes.length,
              1,
              reason: '${deck.id}: "$symbol" is a multi-codepoint sequence',
            );
            expect(
              runes.single,
              lessThanOrEqualTo(0x1F9A0),
              reason: '${deck.id}: "$symbol" is newer than Unicode 9.0',
            );
          }
        }
      });
    });
  }

  test('the four difficulties together ship 400 decks', () {
    final total = AppConfig.difficultyOrder
        .map((d) => load(d).length)
        .reduce((a, b) => a + b);
    expect(total, 400);
  });
}
