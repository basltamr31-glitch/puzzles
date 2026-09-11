import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../domain/achievement.dart';
import '../domain/player_progress.dart';
import '../rewards_controller.dart';

/// The player's standing: streak, totals, and the badge shelf.
///
/// One screen rather than a stat scattered across the puzzle list, because
/// the numbers only mean anything next to each other — a 4-day streak
/// reads as progress when the best is 9 and as a plateau when the best
/// is 4.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final progress = ref.watch(rewardsControllerProvider);
    // The stored streak can be stale by a day or more; ask what it is
    // *today* rather than showing a run the player has already lost.
    final streak = progress.streakOn(DateTime.now());

    return AppScaffold(
      title: l10n.achievementsTitle,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '$streak',
                  label: l10n.achievementsStreakLabel,
                  highlight: streak > 0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_rounded,
                  value: '${progress.totalSolved}',
                  label: l10n.achievementsSolvedLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.star_rounded,
                  value: '${progress.totalStars}',
                  label: l10n.achievementsStarsLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(
                  icon: Icons.emoji_events_rounded,
                  value: '${progress.bestStreak}',
                  label: l10n.achievementsBestStreakLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.achievementsBadgesTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final achievement in Achievement.values) ...[
            _BadgeRow(achievement: achievement, progress: progress),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: highlight ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: highlight ? scheme.onTertiaryContainer : scheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: highlight ? scheme.onTertiaryContainer : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: highlight
                  ? scheme.onTertiaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A badge, earned or not. Locked badges show how far off they are rather
/// than hiding behind a question mark: a target you can see is a reason to
/// play another puzzle, and a mystery is not.
class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.achievement, required this.progress});

  final Achievement achievement;
  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final earned = achievement.isEarnedBy(progress);
    final fraction = achievement.progressToward(progress);

    return Semantics(
      label: earned
          ? l10n.achievementsEarnedSemantics(achievement.title(l10n))
          : l10n.achievementsLockedSemantics(achievement.title(l10n)),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(
            color: earned ? scheme.primary : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: earned
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
              ),
              child: Icon(
                earned ? achievement.icon : Icons.lock_outline_rounded,
                size: 22,
                color: earned
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title(l10n),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: earned ? null : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    achievement.description(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (!earned) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
