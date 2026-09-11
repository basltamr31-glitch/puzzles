import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/localization/generated/app_localizations.dart';
import 'package:word_search_app/features/rewards/domain/achievement.dart';
import 'package:word_search_app/features/rewards/domain/solve_reward.dart';
import 'package:word_search_app/features/rewards/presentation/widgets/lives_indicator.dart';
import 'package:word_search_app/features/rewards/presentation/widgets/out_of_lives_dialog.dart';
import 'package:word_search_app/features/rewards/presentation/widgets/reward_summary.dart';

/// These exist because the reward strings use ICU plurals, and a malformed
/// plural in any one locale throws at *render* time, not at build time —
/// the unit tests around the scoring never touch a `MaterialApp`, so they
/// would all pass while the celebration crashed on the player's screen.
void main() {
  Widget harness(Widget child, Locale locale) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  SolveReward reward({
    int stars = 3,
    int mistakes = 0,
    int streak = 1,
    bool best = false,
    List<Achievement> badges = const [],
  }) {
    return SolveReward(
      stars: stars,
      mistakes: mistakes,
      hintsUsed: 0,
      streak: streak,
      isNewBestStreak: best,
      isFirstSolveOfPuzzle: true,
      newAchievements: badges,
    );
  }

  for (final locale in AppLocalizations.supportedLocales) {
    group('locale ${locale.languageCode}', () {
      testWidgets('the reward summary renders every headline and count',
          (tester) async {
        // Walks the plural boundaries (0, 1, 2) as well as every star tier.
        for (final stars in [1, 2, 3]) {
          for (final mistakes in [0, 1, 2]) {
            await tester.pumpWidget(
              harness(
                RewardSummary(reward: reward(stars: stars, mistakes: mistakes)),
                locale,
              ),
            );
            await tester.pump(const Duration(milliseconds: 600));
            expect(tester.takeException(), isNull);
          }
        }
      });

      testWidgets('a streak and a new badge render', (tester) async {
        for (final streak in [2, 7]) {
          await tester.pumpWidget(
            harness(
              RewardSummary(
                reward: reward(
                  streak: streak,
                  best: true,
                  badges: const [Achievement.weekStreak],
                ),
              ),
              locale,
            ),
          );
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('the lives indicator renders at every count',
          (tester) async {
        for (var mistakes = 0; mistakes <= maxMistakes; mistakes++) {
          await tester.pumpWidget(
            harness(LivesIndicator(mistakes: mistakes), locale),
          );
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('the out-of-lives dialog renders', (tester) async {
        await tester.pumpWidget(
          harness(
            OutOfLivesDialog(onRestart: () {}, onBackToPuzzles: () {}),
            locale,
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      });
    });
  }
}
