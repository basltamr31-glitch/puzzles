import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/word_search/presentation/word_search_screen.dart';
import '../features/difficulty/difficulty_controller.dart';
import '../features/difficulty/presentation/difficulty_screen.dart';
import '../features/game_language/presentation/game_language_screen.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/puzzle_list/presentation/puzzle_list_screen.dart';
import '../features/settings/presentation/privacy_policy_screen.dart';
import '../features/settings/presentation/remove_ads_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../shared/models/difficulty.dart';

const _onboardingPaths = {'/', '/language', '/difficulty'};

/// Single source of navigation truth. The redirect guard is what makes
/// spec §9's "no unnecessary screens" hold structurally: a returning
/// player can never land back on onboarding, and a new player can never
/// skip past it by deep-linking.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final onboardingComplete = ref.read(onboardingControllerProvider);
      final path = state.matchedLocation;

      if (!onboardingComplete && !_onboardingPaths.contains(path)) {
        return '/';
      }
      if (onboardingComplete && _onboardingPaths.contains(path)) {
        final lastDifficulty = ref.read(difficultyControllerProvider);
        return '/puzzles/${lastDifficulty.storageValue}';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/language',
        builder: (context, state) => const GameLanguageScreen(),
      ),
      GoRoute(
        path: '/difficulty',
        builder: (context, state) => const DifficultyScreen(),
      ),
      GoRoute(
        path: '/puzzles/:difficulty',
        builder: (context, state) {
          final difficulty = Difficulty.fromStorageValue(
            state.pathParameters['difficulty']!,
          );
          return PuzzleListScreen(difficulty: difficulty);
        },
      ),
      GoRoute(
        path: '/play',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return WordSearchScreen(
            assetPath: extra['assetPath'] as String,
            siblingAssetPaths: (extra['siblingAssetPaths'] as List)
                .cast<String>(),
          );
        },
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/remove-ads',
        builder: (context, state) => const RemoveAdsScreen(),
      ),
    ],
  );
});
