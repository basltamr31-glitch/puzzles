import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/solve_reward.dart';

/// Shown when the player spends their third mistake.
///
/// Not dismissible, and with no "keep playing" option, because a mistake
/// limit that can be waved away is not a limit — the board behind it is
/// already locked by the controller. The two ways out are the two honest
/// ones: start this puzzle again, or go pick a different one.
class OutOfLivesDialog extends StatelessWidget {
  const OutOfLivesDialog({
    super.key,
    required this.onRestart,
    required this.onBackToPuzzles,
  });

  final VoidCallback onRestart;
  final VoidCallback onBackToPuzzles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
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
              l10n.outOfLivesMessage(maxMistakes),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
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
    );
  }
}
