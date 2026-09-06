import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/widgets/app_card.dart';

/// The word list, chip-per-word, struck through and checked once found.
///
/// A [Wrap] rather than a fixed grid: word lists vary from 6 entries
/// (easy) to 12 (expert), and their lengths vary widely by language, so a
/// rigid column count either wastes space or wraps awkwardly.
class WordListPanel extends StatelessWidget {
  const WordListPanel({
    super.key,
    required this.words,
    required this.foundWords,
  });

  final List<String> words;
  final Set<String> foundWords;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.wordsFoundLabel(foundWords.length, words.length),
                style: theme.textTheme.labelLarge,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: words.isEmpty ? 0 : foundWords.length / words.length,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final word in words)
                _WordChip(word: word, isFound: foundWords.contains(word)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.isFound});

  final String word;
  final bool isFound;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isFound
            ? AppColors.primaryLight
            : theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFound) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            word,
            style: theme.textTheme.labelMedium?.copyWith(
              decoration: isFound ? TextDecoration.lineThrough : null,
              color: isFound
                  ? AppColors.primaryDark
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
