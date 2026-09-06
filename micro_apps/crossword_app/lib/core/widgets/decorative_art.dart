import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-drawn decorative artwork.
///
/// Vector rather than bitmap on purpose: it stays crisp at any size, costs
/// effectively nothing in the bundle, and follows the theme automatically
/// instead of needing a light and a dark copy of every image. If licensed
/// artwork is added later it can replace these widgets in place — the
/// screens only ask for "decoration here", not for a specific technique.

/// A scatter of rounded squares, echoing crossword cells, used as a soft
/// backdrop motif.
///
/// Positions come from a fixed seed so the pattern is identical on every
/// rebuild — a scatter that reshuffled itself mid-animation would read as
/// a glitch rather than decoration.
class CellScatterPainter extends CustomPainter {
  const CellScatterPainter({
    required this.color,
    this.count = 14,
    this.seed = 7,
  });

  final Color color;
  final int count;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < count; i++) {
      final side = 18.0 + random.nextDouble() * 46;
      final left = random.nextDouble() * size.width - side * 0.3;
      final top = random.nextDouble() * size.height - side * 0.3;
      // Fainter as they get bigger, so large shapes stay in the background
      // instead of turning into blocks that compete with the content.
      final alpha = 0.10 - (side / 64) * 0.05;

      canvas.save();
      canvas.translate(left + side / 2, top + side / 2);
      canvas.rotate((random.nextDouble() - 0.5) * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: side, height: side),
          Radius.circular(side * 0.22),
        ),
        paint..color = color.withValues(alpha: alpha.clamp(0.03, 0.10)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CellScatterPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.count != count ||
      oldDelegate.seed != seed;
}

/// Radiating rays plus a few scattered dots — the classic "something good
/// happened" burst, drawn behind the completion badge.
class CelebrationBurstPainter extends CustomPainter {
  const CelebrationBurstPainter({
    required this.color,
    required this.accent,
    this.rayCount = 12,
  });

  final Color color;
  final Color accent;
  final int rayCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * math.pi * 2;
      // Alternating lengths keep the burst from looking like a mechanical
      // starburst stamp.
      final isLong = i.isEven;
      final inner = radius * 0.42;
      final outer = radius * (isLong ? 0.95 : 0.72);
      const halfWidth = 0.055;

      final path = Path()
        ..moveTo(
          center.dx + math.cos(angle - halfWidth) * inner,
          center.dy + math.sin(angle - halfWidth) * inner,
        )
        ..lineTo(
          center.dx + math.cos(angle) * outer,
          center.dy + math.sin(angle) * outer,
        )
        ..lineTo(
          center.dx + math.cos(angle + halfWidth) * inner,
          center.dy + math.sin(angle + halfWidth) * inner,
        )
        ..close();

      canvas.drawPath(
        path,
        paint
          ..color = (isLong ? color : accent).withValues(
            alpha: isLong ? 0.30 : 0.20,
          ),
      );
    }

    final random = math.Random(11);
    for (var i = 0; i < 8; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance = radius * (0.55 + random.nextDouble() * 0.45);
      canvas.drawCircle(
        center + Offset(math.cos(angle) * distance, math.sin(angle) * distance),
        1.5 + random.nextDouble() * 2.5,
        paint..color = (i.isEven ? accent : color).withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(CelebrationBurstPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
}

/// Convenience wrapper: paints [CellScatterPainter] behind [child].
class CellScatterBackdrop extends StatelessWidget {
  const CellScatterBackdrop({
    super.key,
    required this.child,
    required this.color,
    this.count = 14,
    this.seed = 7,
  });

  final Widget child;
  final Color color;
  final int count;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: CellScatterPainter(
                color: color,
                count: count,
                seed: seed,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
