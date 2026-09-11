import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/billing/premium_state.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../rewards/presentation/widgets/star_rating.dart';
import '../../rewards/rewards_controller.dart';
import '../../../core/widgets/decorative_art.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../shared/models/difficulty.dart';
import '../../../shared/models/difficulty_presentation.dart';
import '../../game_language/game_language_controller.dart';
import 'difficulty_switcher.dart';
import '../domain/puzzle_summary.dart';
import '../puzzle_list_providers.dart';

/// Sequential unlock: a not-started puzzle stays locked until the one
/// before it is completed. Anything the player already has progress on
/// (or completed) stays open regardless, so this can't retroactively lock
/// puzzles played before this feature existed.
bool isPuzzleLocked(List<PuzzleSummary> summaries, int index) {
  return summaries[index].status == PuzzleStatus.notStarted &&
      index > 0 &&
      summaries[index - 1].status != PuzzleStatus.completed;
}

/// Shows every puzzle available for the current game language + a chosen
/// difficulty, with a clear progress marker per spec §14. The difficulty
/// switcher up top means the player is never locked into whatever they
/// picked during onboarding — tapping another difficulty here re-routes
/// this same screen to it instantly.
class PuzzleListScreen extends ConsumerWidget {
  const PuzzleListScreen({super.key, required this.difficulty});

  final Difficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final gameLanguage =
        ref.watch(gameLanguageControllerProvider) ??
        AppConfig.fallbackUILanguageCode;
    final args = (language: gameLanguage, difficulty: difficulty.storageValue);
    final summariesAsync = ref.watch(puzzleSummariesProvider(args));

    return AppScaffold(
      title: l10n.puzzleListTitle(difficultyLabel(l10n, difficulty)),
      showBackButton: false,
      actions: [
        IconButton(
          onPressed: () => context.push('/progress'),
          icon: const Icon(Icons.emoji_events_outlined),
          tooltip: l10n.achievementsTitle,
        ),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
          tooltip: l10n.settingsTitle,
        ),
      ],
      padHorizontal: false,
      body: Column(
        children: [
          DifficultySwitcher(current: difficulty),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: summariesAsync.when(
                loading: () => const LoadingIndicator(key: ValueKey('loading')),
                error: (error, stackTrace) => ErrorState(
                  key: const ValueKey('error'),
                  message: l10n.errorGeneric,
                  onRetry: () => ref.invalidate(puzzleSummariesProvider(args)),
                ),
                data: (summaries) {
                  if (summaries.isEmpty) {
                    return EmptyState(
                      key: const ValueKey('empty'),
                      icon: Icons.extension_outlined,
                      title: l10n.noPuzzlesTitle,
                      message: l10n.noPuzzlesMessage,
                    );
                  }
                  final assetPaths = summaries.map((s) => s.assetPath).toList();
                  final solved = summaries
                      .where((s) => s.status == PuzzleStatus.completed)
                      .length;
                  return ListView.separated(
                    key: const ValueKey('list'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    // +1 for the banner, which scrolls with the list rather
                    // than pinning and eating vertical space on small phones.
                    itemCount: summaries.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, rawIndex) {
                      if (rawIndex == 0) {
                        return _DifficultyBanner(
                          difficulty: difficulty,
                          solved: solved,
                          total: summaries.length,
                        );
                      }
                      final index = rawIndex - 1;
                      final summary = summaries[index];
                      final isLocked = isPuzzleLocked(summaries, index);
                      // Watched, not read: finishing a puzzle and
                      // coming straight back should show the stars it
                      // earned without the list being rebuilt from
                      // storage first.
                      final stars = ref.watch(
                        rewardsControllerProvider.select(
                          (_) => ref
                              .read(rewardsControllerProvider.notifier)
                              .starsFor(summary.id),
                        ),
                      );
                      return AppCard(
                        onTap: () {
                          if (isLocked) {
                            ref
                                .read(hapticServiceProvider)
                                .play(HapticIntent.light);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(l10n.puzzleLockedMessage),
                                ),
                              );
                            return;
                          }
                          ref
                              .read(hapticServiceProvider)
                              .play(HapticIntent.selection);
                          context.push(
                            '/crossword',
                            extra: {
                              'assetPath': summary.assetPath,
                              'siblingAssetPaths': assetPaths,
                            },
                          );
                        },
                        child: Opacity(
                          opacity: isLocked ? 0.5 : 1.0,
                          child: Row(
                            children: [
                              _StatusIcon(
                                status: summary.status,
                                isLocked: isLocked,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  l10n.puzzleNumberLabel(
                                    (index + 1).toString().padLeft(3, '0'),
                                  ),
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              // A solved puzzle shows what it was
                              // solved *for*. "Completed" is the same
                              // word on every row; the stars are the
                              // part worth scrolling back to improve.
                              if (!isLocked &&
                                  summary.status == PuzzleStatus.completed &&
                                  stars > 0)
                                StarRating(stars: stars, size: 16)
                              else
                                Text(
                                  isLocked
                                      ? l10n.puzzleStatusLocked
                                      : _statusLabel(l10n, summary.status),
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(
                                        color: theme
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const _PuzzleListBanner(),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, PuzzleStatus status) {
    return switch (status) {
      PuzzleStatus.completed => l10n.puzzleStatusCompleted,
      PuzzleStatus.inProgress => l10n.puzzleStatusInProgress,
      PuzzleStatus.notStarted => l10n.puzzleStatusNotStarted,
    };
  }
}

/// Header for the current difficulty: its colour, its icon, and how many
/// puzzles are solved.
///
/// Doubles as the light-mode colour the list was missing and as genuine
/// feedback — a bare list of 100 identical rows gave no sense of progress.
class _DifficultyBanner extends StatelessWidget {
  const _DifficultyBanner({
    required this.difficulty,
    required this.solved,
    required this.total,
  });

  final Difficulty difficulty;
  final int solved;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isLight = theme.brightness == Brightness.light;
    final accent = difficultyColor(difficulty);
    final progress = total == 0 ? 0.0 : solved / total;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [difficultyTint(difficulty), theme.colorScheme.surface]
              : [accent.withValues(alpha: 0.22), theme.colorScheme.surface],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: CellScatterBackdrop(
        color: accent,
        count: 8,
        seed: difficulty.index + 3,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  difficultyIcons[difficulty],
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      difficultyLabel(l10n, difficulty),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.puzzlesSolvedLabel(solved, total),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.18),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner placement for this non-gameplay screen (spec §19). Absent
/// entirely for premium users; [AdService.buildBanner] itself collapses
/// to nothing while a real ad is loading, so this never reserves dead
/// space in the layout.
class _PuzzleListBanner extends ConsumerWidget {
  const _PuzzleListBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdsRemoved = ref.watch(isAdsRemovedProvider);
    if (isAdsRemoved) return const SizedBox.shrink();
    return ref
        .watch(adServiceProvider)
        .buildBanner(placementId: 'puzzle_list_bottom');
  }
}

/// Purely decorative for screen readers: the status text right next to it
/// in the row already says "Completed"/"In progress"/"Not started", so
/// without this the icon would surface as its own meaningless "icon"
/// stop when swiping through with TalkBack/VoiceOver.
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.isLocked});

  final PuzzleStatus status;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLocked) {
      return ExcludeSemantics(
        child: Icon(
          Icons.lock_outline_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final icon = switch (status) {
      PuzzleStatus.completed => const Icon(
        Icons.check_circle_rounded,
        color: AppColors.success,
      ),
      PuzzleStatus.inProgress => const Icon(
        Icons.adjust_rounded,
        color: AppColors.accent,
      ),
      PuzzleStatus.notStarted => Icon(
        Icons.circle_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    };
    return ExcludeSemantics(child: icon);
  }
}
