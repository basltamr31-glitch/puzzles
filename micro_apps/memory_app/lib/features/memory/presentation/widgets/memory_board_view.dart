import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/memory_colors.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/utils/motion.dart';
import '../../domain/memory_models.dart';

/// Renders the playable board.
///
/// Sized via [AspectRatio] from the deck's own row/column count rather
/// than a fixed square: the four tiers deal 4x3, 4x4, 6x4 and 6x5 boards,
/// and forcing any of them into a square would either stretch the cards
/// or waste half the screen. Every dimension inside — card radius, symbol
/// size, the motif on the back — is derived from the measured card size,
/// so the same code holds up on a 320pt phone and on a tablet.
class MemoryBoardView extends StatelessWidget {
  const MemoryBoardView({
    super.key,
    required this.deck,
    required this.matchedCards,
    required this.faceUpCards,
    required this.mismatchedCards,
    required this.isCompleted,
    required this.onCardTap,
  });

  final MemoryDeckDef deck;
  final Set<int> matchedCards;
  final List<int> faceUpCards;
  final Set<int> mismatchedCards;
  final bool isCompleted;
  final void Function(int index) onCardTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.memoryColors;
    final l10n = AppLocalizations.of(context);

    return AspectRatio(
      aspectRatio: deck.cols / deck.rows,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardSize = math.min(
            constraints.maxWidth / deck.cols,
            constraints.maxHeight / deck.rows,
          );
          return Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.boardBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: List.generate(deck.rows, (row) {
                return Expanded(
                  child: Row(
                    children: List.generate(deck.cols, (col) {
                      final index = row * deck.cols + col;
                      return Expanded(
                        child: MemoryCardView(
                          l10n: l10n,
                          symbol: deck.symbolAt(index),
                          row: row,
                          col: col,
                          size: cardSize,
                          isMatched: matchedCards.contains(index),
                          isFaceUp:
                              matchedCards.contains(index) ||
                              faceUpCards.contains(index),
                          isMismatched: mismatchedCards.contains(index),
                          onTap: isCompleted ? null : () => onCardTap(index),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

/// One card, and the flip between its two faces.
///
/// The flip is a real half-turn about the Y axis rather than a crossfade,
/// because the flip *is* the game's one piece of feedback: it says "this
/// card, the one you touched, is the one that moved". A crossfade at four
/// cards a second reads as flicker.
class MemoryCardView extends StatelessWidget {
  const MemoryCardView({
    super.key,
    required this.l10n,
    required this.symbol,
    required this.row,
    required this.col,
    required this.size,
    required this.isMatched,
    required this.isFaceUp,
    required this.isMismatched,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final String symbol;
  final int row;
  final int col;

  /// Measured card size, used to scale everything drawn inside it.
  final double size;

  final bool isMatched;
  final bool isFaceUp;
  final bool isMismatched;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.memoryColors;
    final position = l10n.cellSemanticLabel(row + 1, col + 1);

    return Semantics(
      button: onTap != null,
      // The symbol is only in the label once the card is face up: reading
      // a face-down card's symbol aloud would hand a screen-reader player
      // the whole board, which is the one thing this game is about not
      // knowing.
      label: isMatched
          ? '$position, ${l10n.cardMatchedLabel(symbol)}'
          : isFaceUp
          ? '$position, ${l10n.cardFaceUpLabel(symbol)}'
          : '$position, ${l10n.cardFaceDownLabel}',
      child: Padding(
        padding: EdgeInsets.all(size * 0.05),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: isFaceUp ? 1 : 0),
            duration: motionDuration(context, const Duration(milliseconds: 320)),
            curve: Curves.easeInOutCubic,
            builder: (context, turn, child) {
              // Past the halfway point the card is edge-on and the far
              // face takes over. Rotating the content back by pi is what
              // stops the symbol from being rendered mirrored.
              final showFace = turn >= 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  // A little perspective, or a flat rotation just looks
                  // like the card being squashed horizontally.
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(turn * math.pi),
                child: showFace
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _face(colors),
                      )
                    : _back(colors),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _face(MemoryColors colors) {
    final fill = isMismatched
        ? colors.cardMismatch
        : isMatched
        ? colors.cardMatched
        : colors.cardFace;
    final border = isMismatched
        ? colors.cardMismatchBorder
        : isMatched
        ? colors.cardMatchedBorder
        : colors.cardFaceBorder;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(
          color: border,
          // The mismatch and matched borders carry meaning, so they are
          // drawn thick enough to be seen at card size; the resting
          // border is just an edge.
          width: isMismatched || isMatched ? 2.5 : 1,
        ),
      ),
      child: Center(
        // Excluded from semantics because the card's own [Semantics] node
        // already names the symbol *and* says whether it is merely
        // showing or matched. Left in, the glyph merges into that node
        // and every card is read out as "…showing A, A".
        child: ExcludeSemantics(
          child: Text(
            symbol,
            style: TextStyle(fontSize: size * 0.46, color: colors.cardLabel),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _back(MemoryColors colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cardBack,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: colors.cardBackBorder),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.44,
          height: size * 0.44,
          child: ExcludeSemantics(
            child: CustomPaint(
              painter: _CardBackPainter(color: colors.cardBackPattern),
            ),
          ),
        ),
      ),
    );
  }
}

/// The motif on a face-down card: a four-point star inside a ring.
///
/// Painted rather than an asset or an icon glyph, for two reasons that
/// both bit the sibling apps first — an image asset would need four
/// densities to stay crisp on a card whose size is computed at layout
/// time, and a Material icon would be one more codepoint that
/// `--tree-shake-icons` has to be told about.
class _CardBackPainter extends CustomPainter {
  const _CardBackPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final ring = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12;
    canvas.drawCircle(center, radius * 0.88, ring);

    // A four-point star drawn as one path: the points reach the ring, the
    // waist pulls in to a quarter of the radius.
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final isPoint = i.isEven;
      final r = isPoint ? radius * 0.62 : radius * 0.18;
      final angle = (math.pi / 4) * i - math.pi / 2;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CardBackPainter oldDelegate) =>
      oldDelegate.color != color;
}
