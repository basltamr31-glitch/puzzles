import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../shared/models/difficulty.dart';
import '../../../shared/models/difficulty_presentation.dart';
import '../../difficulty/difficulty_controller.dart';

/// Below this much width per segment, a 16dp icon costs more than it is
/// worth: the label is what tells the player which tier they are picking,
/// and on a 320dp phone the icon was squeezing "Difficile" down to a
/// couple of characters per line.
const double _minSegmentWidthForIcon = 96;

/// Lets the player switch difficulty at any time instead of being stuck
/// with whatever they picked during onboarding. Switching updates the
/// persisted "last difficulty" (so a relaunch resumes here, not always on
/// Easy) and re-routes this screen to the new difficulty's puzzle list.
///
/// **The layout is measured, not assumed.** A [SegmentedButton] divides
/// its width evenly between segments, so each of the four tiers gets a
/// quarter of the row no matter how long its word is — and the words vary
/// from "Hard" (4 characters) to "Difficile" (9). Left alone, the labels
/// wrapped mid-word, and at 320dp they broke down to one character per
/// line. Three things prevent that, in order of how much they buy:
///
///  1. Below [_minSegmentWidthForIcon] the tier icon becomes a coloured
///     dot, which keeps the colour-coding while returning ~12dp per
///     segment to the label.
///  2. `softWrap: false` + `maxLines: 1` means a label can never wrap.
///  3. A scale-down [FittedBox] shrinks a long word to fit instead of
///     ellipsising it away — the player must be able to read the tier.
///
/// Public, and in its own file, so `difficulty_switcher_layout_test.dart`
/// can pump it at a phone width in every language without dragging the
/// whole puzzle list (and its storage, ads and billing providers) along.
class DifficultySwitcher extends ConsumerWidget {
  const DifficultySwitcher({super.key, required this.current});

  final Difficulty current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final perSegment = constraints.maxWidth / Difficulty.values.length;
          final showIcons = perSegment >= _minSegmentWidthForIcon;

          return SizedBox(
            width: double.infinity,
            child: SegmentedButton<Difficulty>(
              segments: Difficulty.values.map((d) {
                return ButtonSegment(
                  value: d,
                  // Colour the marker even when unselected, so the four
                  // tiers are distinguishable at a glance rather than
                  // four grey glyphs.
                  icon: _TierMarker(difficulty: d, showIcon: showIcons),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      difficultyLabel(l10n, d),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                );
              }).toList(),
              selected: {current},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              ),
              onSelectionChanged: (selected) {
                final next = selected.first;
                if (next == current) return;
                ref.read(hapticServiceProvider).play(HapticIntent.selection);
                ref.read(difficultyControllerProvider.notifier).select(next);
                context.go('/puzzles/${next.storageValue}');
              },
            ),
          );
        },
      ),
    );
  }
}

/// The tier's colour, as a full icon where there is room and a dot where
/// there isn't. Excluded from semantics either way: the label beside it
/// already names the tier, so a screen reader announcing an unnamed icon
/// would just be noise.
class _TierMarker extends StatelessWidget {
  const _TierMarker({required this.difficulty, required this.showIcon});

  final Difficulty difficulty;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final color = difficultyColor(difficulty);
    if (showIcon) {
      return ExcludeSemantics(
        child: Icon(difficultyIcons[difficulty], size: 16, color: color),
      );
    }
    return ExcludeSemantics(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
