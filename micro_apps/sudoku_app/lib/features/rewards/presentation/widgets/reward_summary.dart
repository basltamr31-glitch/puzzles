import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../domain/solve_reward.dart';
import 'star_rating.dart';

/// What the player just earned, shown inside each app's completion dialog.
///
/// Kept as a fragment rather than a whole dialog because each app's
/// celebration has its own artwork and its own "next puzzle" wiring; this
/// is only the part that has to say the same thing in all three.
class RewardSummary extends StatelessWidget {
  const RewardSummary({super.key, required this.reward});

  final SolveReward reward;

  /// The headline earns its variety: three identical solves in a row that
  /// all say "Puzzle complete!" stop meaning anything, and the point of a
  /// star rating is undercut if the words never acknowledge it.
  String _headline(AppLocalizations l10n) {
    if (reward.isFlawless) return l10n.rewardHeadlineFlawless;
    if (reward.stars == 2) return l10n.rewardHeadlineGreat;
    return l10n.rewardHeadlineSolved;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StarRating(stars: reward.stars, size: 40, animate: true),
        const SizedBox(height: AppSpacing.md),
        Text(
          _headline(l10n),
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          reward.mistakes == 0
              ? l10n.rewardNoMistakes
              : l10n.rewardMistakesMade(reward.mistakes),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (reward.streak > 1) ...[
          const SizedBox(height: AppSpacing.md),
          _Chip(
            icon: Icons.local_fire_department_rounded,
            label: reward.isNewBestStreak
                ? l10n.rewardBestStreak(reward.streak)
                : l10n.rewardStreakDays(reward.streak),
            background: theme.colorScheme.tertiaryContainer,
            foreground: theme.colorScheme.onTertiaryContainer,
          ),
        ],
        for (final achievement in reward.newAchievements) ...[
          const SizedBox(height: AppSpacing.sm),
          _Chip(
            icon: achievement.icon,
            label: l10n.rewardBadgeUnlocked(achievement.title(l10n)),
            background: theme.colorScheme.primaryContainer,
            foreground: theme.colorScheme.onPrimaryContainer,
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpacing.sm),
          // Flexible + scale-down: a translated badge name at a large
          // accessibility text scale is wider than the dialog, and a chip
          // that overflows is worse than one whose text is a size down.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
