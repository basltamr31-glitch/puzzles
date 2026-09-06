import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../shared/models/difficulty.dart';
import '../../../shared/models/difficulty_presentation.dart';
import '../../onboarding/onboarding_controller.dart';
import '../difficulty_controller.dart';

/// Final onboarding step. Choosing a difficulty here completes onboarding
/// (the step the router's redirect guard treats as "done") — but unlike
/// the rest of onboarding, the choice itself isn't a one-time thing: see
/// the difficulty switcher on [PuzzleListScreen] for changing it later.
class DifficultyScreen extends ConsumerWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // The tints are tuned for light surfaces; on dark they'd glow, so the
    // accent hue is used at low opacity instead.
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      showBackButton: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.chooseDifficultyTitle,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.chooseDifficultySubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                // Derived from what the tile actually has to hold, rather
                // than a fixed 1.3 that happened to look right on one
                // device: a 44dp badge, a gap, a line of label at the
                // current text scale, and the card's own padding. A fixed
                // ratio overflowed both on a 320dp phone and at a large
                // accessibility text scale.
                childAspectRatio: _tileAspectRatio(context, constraints),
                children: Difficulty.values.map((difficulty) {
                  return AppCard(
                    onTap: () async {
                      ref
                          .read(hapticServiceProvider)
                          .play(HapticIntent.selection);
                      await ref
                          .read(difficultyControllerProvider.notifier)
                          .select(difficulty);
                      await ref
                          .read(onboardingControllerProvider.notifier)
                          .complete();
                      if (context.mounted) {
                        context.go('/puzzles/${difficulty.storageValue}');
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // A tinted badge per tier: four identical indigo icons
                        // gave every level the same weight and was a big part
                        // of why this screen read as flat.
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isDark
                                ? difficultyColor(
                                    difficulty,
                                  ).withValues(alpha: 0.18)
                                : difficultyTint(difficulty),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            difficultyIcons[difficulty],
                            size: 28,
                            color: difficultyColor(difficulty),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // FittedBox rather than a fixed style: at large
                        // accessibility text-scale factors this card's fixed
                        // aspect ratio can't grow, so the label must shrink
                        // to fit instead of clipping or overflowing.
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              difficultyLabel(l10n, difficulty),
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Width-to-height ratio for one difficulty tile.
  ///
  /// The badge is a fixed 44dp (a 28dp icon plus its padding) and does not
  /// scale with text, so the only part that grows is the label — which is
  /// why the height has a fixed part and a scaled part rather than one
  /// ratio for every device.
  static double _tileAspectRatio(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    const badgeHeight = 44.0;
    const cardPadding = AppSpacing.lg * 2;
    const gap = AppSpacing.sm;
    // titleMedium is 16px at height 1.4 (22.4), and the tile still
    // overflowed by 2px at exactly that — rounding plus the card's border.
    // Rather than shave the estimate to the bone, leave a little slack.
    const labelLineHeight = 26.0;

    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final tileWidth = (constraints.maxWidth - AppSpacing.md) / 2;
    final tileHeight =
        badgeHeight + gap + labelLineHeight * scale + cardPadding;
    return tileWidth / tileHeight;
  }
}
