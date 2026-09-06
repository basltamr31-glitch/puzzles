import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/sudoku_colors.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../domain/sudoku_models.dart';

/// The 1-9 entry row.
///
/// A single row of nine keys rather than a 3x3 keypad: it sits directly
/// under the grid without pushing it off-screen on a short phone, and it
/// puts every digit one tap away. Each key carries how many of that digit
/// are still unplaced, which is the cheapest form of progress feedback a
/// Sudoku can give, and keys for finished digits are dimmed rather than
/// removed so the row never reflows under the player's thumb.
class SudokuNumberPad extends StatelessWidget {
  const SudokuNumberPad({
    super.key,
    required this.remainingByDigit,
    required this.notesMode,
    required this.enabled,
    required this.onDigit,
  });

  final Map<int, int> remainingByDigit;
  final bool notesMode;
  final bool enabled;
  final void Function(int digit) onDigit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: List.generate(sudokuSize, (i) {
        final digit = i + 1;
        final remaining = remainingByDigit[digit] ?? 0;
        final isExhausted = remaining <= 0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _DigitKey(
              digit: digit,
              remaining: remaining,
              notesMode: notesMode,
              // An exhausted digit stays tappable when notes are on: a
              // pencil mark for a digit that is already placed nine times
              // is pointless, but so is a key that silently stops working
              // — this way the state reads as "done", not "broken".
              enabled: enabled && (!isExhausted || notesMode),
              semanticLabel: notesMode
                  ? l10n.numberPadNoteLabel(digit)
                  : l10n.numberPadDigitLabel(digit),
              onTap: () => onDigit(digit),
            ),
          ),
        );
      }),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({
    required this.digit,
    required this.remaining,
    required this.notesMode,
    required this.enabled,
    required this.semanticLabel,
    required this.onTap,
  });

  final int digit;
  final int remaining;
  final bool notesMode;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.sudokuColors;
    final foreground = notesMode ? colors.noteText : theme.colorScheme.primary;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: enabled ? colors.cellBackground : colors.cellGiven,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.cellBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$digit',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: enabled
                        ? foreground
                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontWeight: notesMode ? FontWeight.w600 : FontWeight.w700,
                  ),
                ),
                Text(
                  remaining > 0 ? '$remaining' : '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
