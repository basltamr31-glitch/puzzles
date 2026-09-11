import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../domain/solve_reward.dart';

/// The player's remaining mistakes, as a row of hearts.
///
/// Hearts rather than a bare "2/3" counter because the limit has to be
/// legible at a glance mid-puzzle, and because the count going *down* is
/// the thing that needs to feel like it costs something. The most recently
/// spent heart pulses once, so a mistake is never something the player
/// only discovers later by counting.
class LivesIndicator extends StatelessWidget {
  const LivesIndicator({super.key, required this.mistakes, this.compact = false});

  /// Mistakes made so far, 0..[maxMistakes].
  final int mistakes;

  /// Tightens the spacing and shrinks the hearts for the app bar.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final remaining = (maxMistakes - mistakes).clamp(0, maxMistakes);
    final size = compact ? 18.0 : 22.0;

    return Semantics(
      label: l10n.livesRemaining(remaining, maxMistakes),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < maxMistakes; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 2),
              child: _Heart(
                // Hearts are spent left to right, so the rightmost ones
                // are the ones still available.
                spent: i < mistakes,
                // Only the heart just spent pulses, and only while it is
                // the newest one.
                isNewestSpent: i == mistakes - 1,
                size: size,
                spentColour: scheme.outlineVariant,
                colour: scheme.error,
              ),
            ),
        ],
      ),
    );
  }
}

class _Heart extends StatelessWidget {
  const _Heart({
    required this.spent,
    required this.isNewestSpent,
    required this.size,
    required this.colour,
    required this.spentColour,
  });

  final bool spent;
  final bool isNewestSpent;
  final double size;
  final Color colour;
  final Color spentColour;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      spent ? Icons.favorite_border_rounded : Icons.favorite_rounded,
      size: size,
      color: spent ? spentColour : colour,
    );
    if (!isNewestSpent) return icon;

    return TweenAnimationBuilder<double>(
      // Keyed on the heart's own index via the parent's list position, so
      // the tween restarts only when this heart is newly spent.
      key: ValueKey(spent),
      tween: Tween(begin: 1.6, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: icon,
    );
  }
}
