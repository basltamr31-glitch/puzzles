import 'package:flutter/material.dart';

import '../../../../core/localization/generated/app_localizations.dart';

/// One to three stars, out of three.
///
/// [animate] staggers the earned stars in so the celebration dialog has a
/// beat of its own; the puzzle list uses the same widget without it, where
/// a row of animating stars scrolling past would be noise.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.stars,
    this.size = 20,
    this.animate = false,
  });

  final int stars;
  final double size;
  final bool animate;

  static const int maxStars = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.rewardStarsEarned(stars, maxStars),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < maxStars; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.08),
              child: _Star(
                earned: i < stars,
                size: size,
                colour: scheme.tertiary,
                emptyColour: scheme.outlineVariant,
                // Each star lands a beat after the one before it.
                delay: animate
                    ? Duration(milliseconds: 120 * i)
                    : Duration.zero,
                animate: animate && i < stars,
              ),
            ),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.earned,
    required this.size,
    required this.colour,
    required this.emptyColour,
    required this.delay,
    required this.animate,
  });

  final bool earned;
  final double size;
  final Color colour;
  final Color emptyColour;
  final Duration delay;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      earned ? Icons.star_rounded : Icons.star_outline_rounded,
      size: size,
      color: earned ? colour : emptyColour,
    );
    if (!animate) return icon;

    return TweenAnimationBuilder<double>(
      // The delay is folded into the tween rather than a Future.delayed:
      // a timer firing after the dialog is dismissed would call setState
      // on a widget that is already gone.
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400) + delay,
      curve: Interval(
        delay.inMilliseconds /
            (const Duration(milliseconds: 400) + delay).inMilliseconds,
        1,
        curve: Curves.elasticOut,
      ),
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: icon,
    );
  }
}
