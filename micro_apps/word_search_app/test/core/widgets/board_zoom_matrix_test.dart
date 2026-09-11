import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/widgets/board_zoom_controls.dart';

/// The bug these cover: [boardZoomMatrix] used to be a bare
/// `Matrix4.identity()..scale(s)`. An [InteractiveViewer]'s matrix maps
/// board coordinates to viewport coordinates, so with no translation the
/// board's top-left corner stays pinned to the viewport's top-left — every
/// press of "zoom in" magnified that same corner, and the other three
/// quarters of the board were unreachable without a manual pan.
void main() {
  const viewport = Size(300, 300);

  /// Where a point of the board lands on screen under [matrix].
  Offset project(Matrix4 matrix, Offset boardPoint) {
    return MatrixUtils.transformPoint(matrix, boardPoint);
  }

  Matrix4 forQuadrant(BoardQuadrant quadrant, double scale) {
    return boardZoomMatrix(
      viewport: viewport,
      scale: scale,
      focal: Offset(
        viewport.width * quadrant.fractionX,
        viewport.height * quadrant.fractionY,
      ),
    );
  }

  group('boardZoomMatrix', () {
    test('every quadrant produces a different view of the board', () {
      final matrices = [
        for (final q in BoardQuadrant.values) forQuadrant(q, 2),
      ];
      expect(matrices.toSet().length, BoardQuadrant.values.length);
    });

    test('at 2x each quadrant exactly fills the frame', () {
      // The quarter's own corners land on the viewport's corners.
      final cases = {
        BoardQuadrant.topLeft: const Offset(0, 0),
        BoardQuadrant.topRight: const Offset(150, 0),
        BoardQuadrant.bottomLeft: const Offset(0, 150),
        BoardQuadrant.bottomRight: const Offset(150, 150),
      };
      cases.forEach((quadrant, topLeftOfQuadrant) {
        final matrix = forQuadrant(quadrant, 2);
        expect(
          project(matrix, topLeftOfQuadrant),
          within(distance: 0.01, from: Offset.zero),
          reason: '$quadrant should start at the top-left of the frame',
        );
        expect(
          project(matrix, topLeftOfQuadrant + const Offset(150, 150)),
          within(distance: 0.01, from: const Offset(300, 300)),
          reason: '$quadrant should end at the bottom-right of the frame',
        );
      });
    });

    test('the board never leaves a gap at the frame edges', () {
      for (final quadrant in BoardQuadrant.values) {
        for (final scale in [1.4, 2.0, 2.8, 4.0]) {
          final matrix = forQuadrant(quadrant, scale);
          final origin = project(matrix, Offset.zero);
          final end = project(matrix, const Offset(300, 300));
          expect(origin.dx, lessThanOrEqualTo(0.01), reason: '$quadrant @$scale');
          expect(origin.dy, lessThanOrEqualTo(0.01), reason: '$quadrant @$scale');
          expect(end.dx, greaterThanOrEqualTo(299.99), reason: '$quadrant @$scale');
          expect(end.dy, greaterThanOrEqualTo(299.99), reason: '$quadrant @$scale');
        }
      }
    });

    test('zooming further keeps the same quadrant in view', () {
      // Stepping the magnification must not drift back to the corner the
      // old implementation was stuck on.
      for (final quadrant in BoardQuadrant.values) {
        final centreOfQuadrant = Offset(
          viewport.width * quadrant.fractionX,
          viewport.height * quadrant.fractionY,
        );
        for (final scale in [2.0, 2.8, 4.0]) {
          expect(
            project(forQuadrant(quadrant, scale), centreOfQuadrant),
            within(distance: 0.01, from: const Offset(150, 150)),
            reason: '$quadrant should stay centred at $scale',
          );
        }
      }
    });

    test('is the identity at or below 1x, and for an unmeasured board', () {
      expect(forQuadrant(BoardQuadrant.bottomRight, 1), Matrix4.identity());
      expect(forQuadrant(BoardQuadrant.bottomRight, 0.5), Matrix4.identity());
      expect(
        boardZoomMatrix(
          viewport: Size.zero,
          scale: 3,
          focal: const Offset(10, 10),
        ),
        Matrix4.identity(),
      );
    });
  });
}
