import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/solve_reward.dart';

/// Shown when the player spends their last mistake.
///
/// Not dismissible, and with no "keep playing" option, because a mistake
/// limit that can be waved away is not a limit — the board behind it is
/// already locked by the controller.
///
/// There is now a third way out: one extra life, paid for with a rewarded
/// ad (or free for a player who has removed ads). It is capped at
/// [maxBonusLives] per run and [onExtraLife] is null once that cap is
/// spent, so the dialog cannot become an endless continue button. The
/// limit still exists — it just has a price once.
class OutOfLivesDialog extends StatelessWidget {
  const OutOfLivesDialog({
    super.key,
    required this.onRestart,
    required this.onBackToPuzzles,
    this.onExtraLife,
    this.extraLifeCostsAd = true,
  });

  final VoidCallback onRestart;
  final VoidCallback onBackToPuzzles;

  /// Null when another life cannot be earned — the cap is spent, or ads
  /// are unavailable on this platform.
  final VoidCallback? onExtraLife;

  /// False for players who have removed ads: they get the life without
  /// watching anything, the same trade the hint button already makes.
  final bool extraLifeCostsAd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final canRevive = onExtraLife != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        // Three actions at a large text scale are taller than a small
        // phone, and a dialog that cannot reach its own buttons is worse
        // than one that scrolls.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.errorContainer,
                  ),
                  child: Icon(
                    Icons.heart_broken_rounded,
                    size: 36,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.outOfLivesTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                canRevive
                    ? l10n.outOfLivesMessageRevive(maxMistakes)
                    : l10n.outOfLivesMessage(maxMistakes),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              // The extra life takes the primary slot when it is on
              // offer: it is the thing the player actually wants, and
              // burying it under "Try again" would be a dark pattern in
              // reverse — an ad they have to hunt for.
              if (canRevive) ...[
                PrimaryButton(
                  label: extraLifeCostsAd
                      ? l10n.outOfLivesWatchAd
                      : l10n.outOfLivesExtraLife,
                  icon: extraLifeCostsAd
                      ? Icons.play_circle_outline_rounded
                      : Icons.favorite_rounded,
                  onPressed: onExtraLife,
                ),
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: l10n.outOfLivesTryAgain,
                  onPressed: onRestart,
                ),
              ] else
                PrimaryButton(
                  label: l10n.outOfLivesTryAgain,
                  icon: Icons.refresh_rounded,
                  onPressed: onRestart,
                ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: l10n.backToPuzzlesButton,
                onPressed: onBackToPuzzles,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
