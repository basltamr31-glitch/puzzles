import 'package:flutter/material.dart';

import '../utils/motion.dart';

/// A small, bespoke illustration for empty/error states — an organic
/// gradient blob (not a stock asset) behind a single icon, with a soft
/// scale-and-fade entrance. Exists so every "dead" screen in the app
/// (no puzzles yet, couldn't load, etc.) has some personality instead of
/// a flat gray Material icon, per the app's illustration guardrail:
/// different contexts get different colors/icons, never the same badge
/// reused verbatim.
class IllustrationBadge extends StatelessWidget {
  const IllustrationBadge({
    super.key,
    required this.icon,
    required this.colors,
    this.size = 96,
  });

  final IconData icon;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motionDuration(context, const Duration(milliseconds: 400)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0, 1.2),
          child: Opacity(opacity: value.clamp(0, 1), child: child),
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _BlobPainter(colors: colors),
            ),
            Icon(icon, size: size * 0.4, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// An asymmetric, organic rounded shape (built from four cubic Bézier
/// arcs) rather than a plain circle — deliberately a little irregular so
/// it reads as "drawn" rather than a default shape primitive.
class _BlobPainter extends CustomPainter {
  const _BlobPainter({required this.colors});

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.86, 0, w, h * 0.22, w, h * 0.5)
      ..cubicTo(w, h * 0.83, w * 0.81, h, w * 0.47, h)
      ..cubicTo(w * 0.14, h, 0, h * 0.79, 0, h * 0.45)
      ..cubicTo(0, h * 0.15, w * 0.17, 0, w * 0.5, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
