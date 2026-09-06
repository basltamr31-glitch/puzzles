import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_search_app/app/app_config.dart';
import 'package:word_search_app/core/localization/generated/app_localizations.dart';
import 'package:word_search_app/core/storage/local_storage_service.dart';
import 'package:word_search_app/features/puzzle_list/presentation/difficulty_switcher.dart';
import 'package:word_search_app/shared/models/difficulty.dart';
import 'package:word_search_app/shared/models/difficulty_presentation.dart';

/// The four tier labels share one row, and their length varies a lot by
/// language — "Hard" is 4 characters in English and "Difficile" is 9 in
/// French and Italian. On a narrow phone that used to wrap mid-word, so a
/// segment read "Diffici / le" across two lines.
///
/// A wrapped label is exactly what these tests forbid: every label must
/// render on a single line, in every supported language, at the narrowest
/// width the app targets.
void main() {
  /// Number of lines the label actually rendered on.
  int lineCount(WidgetTester tester, String label) {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byType(DifficultySwitcher), matching: find.text(label)),
    );
    // Measure the same text unconstrained to get one line's height, then
    // compare — robust against font metrics changing between Flutter
    // versions, which a hardcoded pixel threshold would not be.
    final painter = TextPainter(
      text: TextSpan(text: label, style: paragraph.text.style),
      textDirection: paragraph.textDirection,
    )..layout();
    return (paragraph.size.height / painter.height).round();
  }

  Future<void> pumpSwitcher(
    WidgetTester tester, {
    required Size size,
    required Locale locale,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferencesStorageService.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppConfig.supportedUILanguageCodes.map(Locale.new),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(
              body: DifficultySwitcher(current: Difficulty.easy),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // 320dp is the narrowest phone the app targets (4-inch iPhone SE, small
  // Android). If the labels survive here they survive everywhere.
  for (final code in AppConfig.supportedUILanguageCodes) {
    testWidgets('no tier label wraps at 320dp in "$code"', (tester) async {
      await pumpSwitcher(
        tester,
        size: const Size(320, 640),
        locale: Locale(code),
      );

      final l10n = await AppLocalizations.delegate.load(Locale(code));
      for (final difficulty in Difficulty.values) {
        final label = difficultyLabel(l10n, difficulty);
        expect(
          lineCount(tester, label),
          1,
          reason: '"$label" ($code) wrapped onto more than one line',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('labels survive a large accessibility text scale', (tester) async {
    // Italian has the longest labels; 1.3x is a common accessibility
    // setting, and a fixed-width segment cannot grow to absorb it.
    await pumpSwitcher(
      tester,
      size: const Size(320, 640),
      locale: const Locale('it'),
      textScale: 1.3,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('it'));
    for (final difficulty in Difficulty.values) {
      expect(
        lineCount(tester, difficultyLabel(l10n, difficulty)),
        1,
        reason: 'wrapped at 1.3x text scale',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('every tier stays reachable, not truncated away', (tester) async {
    await pumpSwitcher(
      tester,
      size: const Size(320, 640),
      locale: const Locale('fr'),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    for (final difficulty in Difficulty.values) {
      // Shrinking is fine, ellipsising the word away is not: the player
      // has to be able to read which tier they are picking.
      expect(
        find.text(difficultyLabel(l10n, difficulty)),
        findsOneWidget,
        reason: '${difficulty.storageValue} label missing',
      );
    }
  });
}
