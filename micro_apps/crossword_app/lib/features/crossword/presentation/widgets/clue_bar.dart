import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/crossword_models.dart';
import 'clue_category_icon.dart';

/// Shows the clue for the currently selected word, prominently, right
/// above the grid — the player should never have to hunt through a list
/// to know what they're solving.
class ClueBar extends StatelessWidget {
  const ClueBar({
    super.key,
    required this.clue,
    this.onTap,
    this.onPrevious,
    this.onNext,
  });

  final CrosswordClue? clue;
  final VoidCallback? onTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final activeClue = clue;
    if (activeClue == null) return const SizedBox.shrink();

    final directionLabel = activeClue.direction == WordDirection.across
        ? l10n.acrossLabel
        : l10n.downLabel;

    // Row already mirrors child *position* automatically under RTL
    // Directionality, but chevron glyphs don't mirror themselves — without
    // this swap, "previous" would land on the right edge (correct) while
    // still pointing left (wrong): pointing away from, not toward, the
    // backward direction in RTL reading order.
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final isLight = theme.brightness == Brightness.light;

    return _ClueBarSurface(
      isLight: isLight,
      onTap: onTap,
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onPrevious,
            icon: Icon(
              isRtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
            ),
            tooltip: l10n.previousClueTooltip,
          ),
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              '${activeClue.number}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      directionLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    // Sits next to the direction label rather than the clue
                    // text, so it reads as metadata about the word instead
                    // of competing with the clue itself.
                    if (activeClue.category != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      ClueCategoryIcon(
                        category: activeClue.category!,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                Text(
                  activeClue.clue,
                  style: theme.textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onNext,
            icon: Icon(
              isRtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            ),
            tooltip: l10n.nextClueTooltip,
          ),
        ],
      ),
    );
  }
}

/// The clue bar's container.
///
/// In light mode this is a tinted panel with a coloured leading stripe
/// rather than another plain white card — the clue is the single most
/// important thing on the screen and should look like it. Dark mode keeps
/// the existing flat card, which already reads well.
class _ClueBarSurface extends StatelessWidget {
  const _ClueBarSurface({
    required this.isLight,
    required this.child,
    this.onTap,
  });

  final bool isLight;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    if (!isLight) return AppCard(onTap: onTap, child: child);

    final content = Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.45),
        borderRadius: radius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Leading accent stripe: a small amount of solid brand colour
          // anchors the panel and stops it reading as another grey box.
          Container(width: 5, height: 64, color: theme.colorScheme.primary),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}
