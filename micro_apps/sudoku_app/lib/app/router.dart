import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/difficulty/difficulty_controller.dart';
import '../features/difficulty/presentation/difficulty_screen.dart';
import '../features/onboarding/onboarding_controller.dart';
import '../features/onboarding/presentation/welcome_screen.dart';
import '../features/puzzle_list/presentation/puzzle_list_screen.dart';
import '../features/settings/presentation/privacy_policy_screen.dart';
import '../features/settings/presentation/remove_ads_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/sudoku/presentation/sudoku_screen.dart';
import '../shared/models/difficulty.dart';

/// Onboarding is two screens, not three: with no puzzle language to pick,
/// a new player goes welcome → difficulty and straight into a grid.
const _onboardingPaths = {'/', '/difficulty'};

/// Single source of navigation truth. The redirect guard is what keeps
/// "no unnecessary screens" true structurally: a returning player can
/// never land back on onboarding, and a new player can never skip past it
/// by deep-linking.
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
      GoRoute(path: '/difficulty', builder: (context, state) => const DifficultyScreen()),
      GoRoute(
        path: '/puzzles/:difficulty',
        builder: (context, state) {
          final difficulty =
              Difficulty.fromStorageValue(state.pathParameters['difficulty']!);
          return PuzzleListScreen(difficulty: difficulty);
        },
      ),
      // Path parameters rather than `extra`: a Sudoku is fully identified
      // by (difficulty, position), so the route survives a restart and
      // can be linked to directly, which an `extra` payload cannot.
      GoRoute(
        path: '/sudoku/:difficulty/:index',
        builder: (context, state) {
          final difficulty =
              Difficulty.fromStorageValue(state.pathParameters['difficulty']!);
          final index = int.tryParse(state.pathParameters['index'] ?? '') ?? 0;
          return SudokuScreen(
            difficulty: difficulty.storageValue,
            index: index,
          );
        },
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/remove-ads', builder: (context, state) => const RemoveAdsScreen()),
    ],
  );
});
