import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/app/app_config.dart';

/// Guards the six ARB files against the failure mode `flutter gen-l10n`
/// is relaxed about: a language quietly missing a string, or a
/// translation that dropped a `{placeholder}` and would render the wrong
/// text — or throw — only in that locale.
///
/// Reads the ARB files straight off disk rather than through the asset
/// bundle: they are build inputs, not assets, and are not shipped.
void main() {
  const arbDir = 'lib/core/localization/l10n';

  // Throws rather than `expect`s: the template is read at file-load time,
  // outside any test body, where the matcher library refuses to run.
  Map<String, dynamic> readArb(String code) {
    final file = File('$arbDir/app_$code.arb');
    if (!file.existsSync()) {
      throw StateError('Missing ARB file ${file.path}');
    }
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  final english = readArb('en');
  final messageKeys =
      english.keys.where((k) => !k.startsWith('@')).toSet();

  /// `{name}` occurrences — what the generated Dart will substitute into.
  Set<String> placeholdersIn(String value) {
    return RegExp(r'\{(\w+)\}')
        .allMatches(value)
        .map((m) => m.group(1)!)
        .toSet();
  }

  test('the template itself is non-trivial', () {
    expect(messageKeys.length, greaterThan(50));
    expect(english['@@locale'], 'en');
  });

  for (final code in AppConfig.supportedUILanguageCodes) {
    group('app_$code.arb', () {
      late Map<String, dynamic> arb;

      setUpAll(() => arb = readArb(code));

      test('declares its own locale', () {
        expect(arb['@@locale'], code);
      });

      test('translates every key the template defines', () {
        final keys = arb.keys.where((k) => !k.startsWith('@')).toSet();
        expect(
          messageKeys.difference(keys),
          isEmpty,
          reason: 'missing keys in app_$code.arb',
        );
        expect(
          keys.difference(messageKeys),
          isEmpty,
          reason: 'keys in app_$code.arb that the template does not define',
        );
      });

      test('keeps every placeholder the template uses', () {
        for (final key in messageKeys) {
          final expected = placeholdersIn(english[key] as String);
          if (expected.isEmpty) continue;
          expect(
            placeholdersIn(arb[key] as String),
            expected,
            reason: '$key in app_$code.arb',
          );
        }
      });

      test('leaves nothing blank', () {
        for (final key in messageKeys) {
          expect((arb[key] as String).trim(), isNotEmpty, reason: key);
        }
      });

      test('does not silently ship the English string for a translated key', () {
        // Legitimately identical to English: brand and format strings,
        // and cognates that really are the same word in that language
        // ("System"/"Vibration"/"Version" in German, "Note"/"Notes"/
        // "Expert" in French). Everything outside this set matching
        // English exactly is far more likely an untranslated leftover.
        const identicalByDesign = {
          'appName',
          'onboardingTitle',
          'okButton',
          'removeAdsPrice',
          'removeAdsPurchaseButton',
          'settingsDeveloperName',
          'settingsCopyright',
          'settingsVersion',
          'settingsVibration',
          'themeModeSystem',
          'musicTrackOff',
          'difficultyEasy',
          'difficultyMedium',
          'difficultyHard',
          'difficultyExpert',
          'notesButton',
          'numberPadNoteLabel',
          'settingsAbout',
          'errorGeneric',
          'settingsPrivacy',
          // "Badges" is the word French actually uses here; a
          // synonym picked only to look translated would be worse.
          'achievementsBadgesTitle',
        };
        if (code == 'en') return;

        final untranslated = <String>[];
        for (final key in messageKeys) {
          if (identicalByDesign.contains(key)) continue;
          if (arb[key] == english[key]) untranslated.add(key);
        }
        expect(untranslated, isEmpty, reason: 'untranslated in app_$code.arb');
      });
    });
  }
}
