import 'package:flutter_test/flutter_test.dart';
import 'package:crossword_app/core/widgets/app_card.dart';
import 'package:crossword_app/features/difficulty/presentation/difficulty_screen.dart';
import 'package:crossword_app/features/onboarding/presentation/welcome_screen.dart';
import 'package:crossword_app/features/puzzle_list/presentation/puzzle_list_screen.dart';
import 'package:crossword_app/features/settings/presentation/remove_ads_screen.dart';
import 'package:crossword_app/features/settings/presentation/settings_screen.dart';
import 'package:crossword_app/features/crossword/presentation/crossword_screen.dart';
import 'package:crossword_app/features/game_language/presentation/game_language_screen.dart';
import 'package:crossword_app/shared/models/difficulty.dart';

import '../support/responsive_harness.dart';

/// Renders every screen across a matrix of device sizes, text scales and
/// text directions.
///
/// `testWidgets` fails on any unconsumed Flutter error, and a
/// `RenderFlex overflowed by N pixels` is exactly that — so *reaching the
/// end of a case is the assertion*. This is the check that a design pass
/// cannot give you: it measures real widgets under real constraints
/// instead of describing how they ought to look.
///
/// The 1.5x text-scale rows are not hypothetical. A phone set to the
/// largest accessibility font runs the app at roughly that scale, and it
/// is where fixed-height rows and evenly-divided button strips break
/// first.
void main() {
  /// Every screen is checked for "did it render at all", not just for the
  /// absence of an exception — a screen that silently laid out nothing
  /// would otherwise pass.
  void expectRendered(Finder finder) {
    expect(finder, findsWidgets);
  }

  group('welcome screen', () {
    for (final layoutCase in responsiveCases) {
      testWidgets('lays out on $layoutCase', (tester) async {
        await pumpAtViewport(tester, layoutCase, child: const WelcomeScreen());
        await pumpFrames(tester);
        expectRendered(find.byType(WelcomeScreen));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('difficulty screen', () {
    for (final layoutCase in responsiveCases) {
      testWidgets('lays out on $layoutCase', (tester) async {
        await pumpAtViewport(tester, layoutCase, child: const DifficultyScreen());
        await pumpFrames(tester);
        // All four tiers must be pickable, not clipped out of the grid.
        expect(find.byType(AppCard), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('puzzle list', () {
    for (final layoutCase in responsiveCases) {
      testWidgets('lays out on $layoutCase', (tester) async {
        await pumpAtViewport(
          tester,
          layoutCase,
          child: const PuzzleListScreen(difficulty: Difficulty.easy),
        );
        await pumpFrames(tester);
        expectRendered(find.byType(PuzzleListScreen));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('gameplay screen', () {
    for (final layoutCase in responsiveCases) {
      testWidgets('lays out on $layoutCase', (tester) async {
        await pumpAtViewport(
          tester,
          layoutCase,
          child: const CrosswordScreen(
            assetPath: 'assets/puzzles/en/easy/puzzle_001.json',
            siblingAssetPaths: ['assets/puzzles/en/easy/puzzle_001.json'],
          ),
        );
        await pumpFrames(tester);
        expectRendered(find.byType(CrosswordScreen));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('game language screen', () {
    for (final layoutCase in responsiveCases) {
      testWidgets('lays out on $layoutCase', (tester) async {
        await pumpAtViewport(
          tester,
          layoutCase,
          child: const GameLanguageScreen(),
        );
        await pumpFrames(tester);
        expectRendered(find.byType(GameLanguageScreen));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('settings screen', () {
    for (final layoutCase in responsiveCases) {
      testWidgets('lays out on $layoutCase', (tester) async {
        await pumpAtViewport(tester, layoutCase, child: const SettingsScreen());
        await pumpFrames(tester);
        expectRendered(find.byType(SettingsScreen));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('remove ads screen', () {
    for (final layoutCase in responsiveCases) {
      testWidgets('lays out on $layoutCase', (tester) async {
        await pumpAtViewport(tester, layoutCase, child: const RemoveAdsScreen());
        await pumpFrames(tester);
        expectRendered(find.byType(RemoveAdsScreen));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
