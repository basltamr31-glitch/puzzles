import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../localization/generated/app_localizations.dart';

/// The quarter of the board that the zoom buttons magnify.
///
/// Coordinates are *viewport* fractions, not grid row/column indices, so
/// the mapping holds for right-to-left boards too: `topLeft` always means
/// the quarter the player sees in the top-left, whichever way the grid
/// itself is laid out.
enum BoardQuadrant {
  topLeft(0.25, 0.25),
  topRight(0.75, 0.25),
  bottomLeft(0.25, 0.75),
  bottomRight(0.75, 0.75);

  const BoardQuadrant(this.fractionX, this.fractionY);

  /// Centre of this quarter, as a fraction of the board's width/height.
  final double fractionX;
  final double fractionY;

  bool get isRight => fractionX > 0.5;
  bool get isBottom => fractionY > 0.5;

  String label(AppLocalizations l10n) => switch (this) {
    BoardQuadrant.topLeft => l10n.zoomAreaTopLeft,
    BoardQuadrant.topRight => l10n.zoomAreaTopRight,
    BoardQuadrant.bottomLeft => l10n.zoomAreaBottomLeft,
    BoardQuadrant.bottomRight => l10n.zoomAreaBottomRight,
  };
}

/// The [InteractiveViewer] transform that shows the board at [scale] with
/// [focal] — a point in the board's own, unscaled coordinates — centred in
/// a [viewport]-sized frame.
///
/// The matrix maps board coordinates to viewport coordinates, so a bare
/// scale matrix pins the board's top-left corner to the viewport's
/// top-left: that is why zooming used to magnify that one corner and
/// nothing else, however far in you went. Translating by
/// `centre - scale * focal` puts the chosen point in the middle instead,
/// and the clamp keeps the board from being pulled off the viewport edges
/// into empty space.
Matrix4 boardZoomMatrix({
  required Size viewport,
  required double scale,
  required Offset focal,
}) {
  if (scale <= 1 || viewport.isEmpty) return Matrix4.identity();
  final tx = (viewport.width / 2 - scale * focal.dx).clamp(
    viewport.width * (1 - scale),
    0.0,
  );
  final ty = (viewport.height / 2 - scale * focal.dy).clamp(
    viewport.height * (1 - scale),
    0.0,
  );
  return Matrix4.identity()
    ..translateByDouble(tx, ty, 0, 1)
    ..scaleByDouble(scale, scale, scale, 1);
}

/// Zoom buttons plus the quarter-of-the-board picker they act on.
///
/// The picker exists because zoom buttons on their own can only magnify
/// one fixed point, and on a phone-sized expert grid that leaves three
/// quarters of the board unreachable without a pan the player has to
/// discover for themselves. Tapping a quarter aims the magnifier at it;
/// the +/- buttons then step the magnification without moving the aim.
class BoardZoomControls extends StatelessWidget {
  const BoardZoomControls({
    super.key,
    required this.scale,
    required this.minScale,
    required this.maxScale,
    required this.selectedQuadrant,
    required this.onQuadrantSelected,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final double scale;
  final double minScale;
  final double maxScale;

  /// The quarter the zoom is currently aimed at. Null once the player has
  /// pinched or panned by hand, since the view no longer matches any one
  /// quarter and highlighting a stale one would be a lie.
  final BoardQuadrant? selectedQuadrant;
  final ValueChanged<BoardQuadrant> onQuadrantSelected;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      // A Wrap rather than a Row: the percentage label is the one part of
      // this strip that grows with the accessibility text scale, and at
      // 2x on a small phone the single-line version overflows.
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          _QuadrantPicker(
            selected: selectedQuadrant,
            onSelected: onQuadrantSelected,
            l10n: l10n,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: scale > minScale ? onZoomOut : null,
                icon: const Icon(Icons.zoom_out_rounded),
                tooltip: l10n.zoomOutButton,
              ),
              TextButton(
                onPressed: scale > minScale ? onReset : null,
                child: Text('${(scale * 100).round()}%'),
              ),
              IconButton(
                onPressed: scale < maxScale ? onZoomIn : null,
                icon: const Icon(Icons.zoom_in_rounded),
                tooltip: l10n.zoomInButton,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A 2x2 miniature of the board; tapping a cell aims the zoom there.
///
/// Laid out with [Stack] and [Positioned] rather than nested [Row]s so the
/// cells keep their literal screen positions under a right-to-left locale
/// — a Row would mirror them, and the top-left cell would then aim at the
/// top-right of the board.
class _QuadrantPicker extends StatelessWidget {
  const _QuadrantPicker({
    required this.selected,
    required this.onSelected,
    required this.l10n,
  });

  final BoardQuadrant? selected;
  final ValueChanged<BoardQuadrant> onSelected;
  final AppLocalizations l10n;

  /// Sized so each quarter is a 44dp touch target — the smallest a
  /// control this fiddly can be without becoming a mis-tap generator.
  static const double _cellSize = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: l10n.zoomAreaLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: SizedBox(
          width: _cellSize * 2,
          height: _cellSize * 2,
          child: Stack(
            children: [
              for (final quadrant in BoardQuadrant.values)
                Positioned(
                  left: quadrant.isRight ? _cellSize : 0,
                  top: quadrant.isBottom ? _cellSize : 0,
                  width: _cellSize,
                  height: _cellSize,
                  child: _QuadrantCell(
                    quadrant: quadrant,
                    isSelected: quadrant == selected,
                    onTap: () => onSelected(quadrant),
                    label: quadrant.label(l10n),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuadrantCell extends StatelessWidget {
  const _QuadrantCell({
    required this.quadrant,
    required this.isSelected,
    required this.onTap,
    required this.label,
  });

  final BoardQuadrant quadrant;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                border: Border.all(
                  color: isSelected ? scheme.primary : scheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
