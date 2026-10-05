import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/word_search_colors.dart';
import '../../../../shared/models/game_locale.dart';
import '../../domain/word_search_models.dart';

/// A pan recognizer that wins the gesture arena against the scroll view
/// the grid sits inside.
///
/// The bug this exists to fix: a plain [PanGestureRecognizer] waits until
/// the finger has travelled `kPanSlop` (~36dp) before claiming a gesture,
/// while the enclosing [SingleChildScrollView] claims a *vertical* drag
/// at `kTouchSlop` (~18dp). The scrollable therefore won every drag with
/// a meaningful vertical component, and vertical words were impossible to
/// select — the board just scrolled. Horizontal drags worked only because
/// a vertical scrollable never contests them.
///
/// Accepting on the first move event puts this recognizer ahead of that
/// race. Two-finger gestures are deliberately left on the default slop so
/// [InteractiveViewer] can still recognize a pinch and zoom the grid.
class _GridPanGestureRecognizer extends PanGestureRecognizer {
  int _activePointers = 0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _activePointers++;
    super.addAllowedPointer(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _activePointers = 0;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    if (_activePointers > 1) {
      return super.hasSufficientGlobalDistanceToAccept(
        pointerDeviceKind,
        deviceTouchSlop,
      );
    }
    return true;
  }
}

/// Renders the playable grid and owns the drag gesture that selects a
/// line of cells.
///
/// A single [GestureDetector] wraps the whole grid rather than one per
/// cell: a continuous drag has to keep reporting `onPanUpdate` as the
/// finger crosses cell boundaries, which per-cell detectors can't do once
/// the pointer leaves the cell that captured it.
class WordSearchGridView extends StatelessWidget {
  const WordSearchGridView({
    super.key,
    required this.puzzle,
    required this.foundCells,
    required this.liveSelection,
    required this.wrongSelectionCells,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final WordSearchPuzzleDef puzzle;
  final Set<String> foundCells;
  final List<(int, int)> liveSelection;
  final Set<String> wrongSelectionCells;
  final void Function(int row, int col) onDragStart;
  final void Function(int row, int col) onDragUpdate;
  final VoidCallback onDragEnd;

  /// The board's reading direction comes from the **puzzle**, not the app.
  ///
  /// Inheriting the ambient direction was wrong in both directions,
  /// because the UI language and the game language are chosen separately:
  /// an English board under an Arabic UI was mirrored, and an Arabic board
  /// under an English UI was not.
  bool get _isRtl => GameLocale.byCode(puzzle.language).isRtl;

  /// Converts between a logical column and the one on screen.
  ///
  /// The engine keeps a single coordinate system — `east` always means
  /// "towards increasing column" — and a right-to-left board is *rendered*
  /// mirrored so an `east` word still reads the natural way. Every place
  /// that turns a coordinate into a position, or a position back into a
  /// coordinate, has to apply this. Mirroring is its own inverse, so one
  /// function serves both directions.
  static int mirrorCol(int col, int size, {required bool isRtl}) =>
      isRtl ? size - 1 - col : col;

  (int, int)? _cellAt(Offset local, double cellSize) {
    // `localPosition` has its origin at the top-left whatever the text
    // direction is, so this is a *visual* column and has to be mirrored
    // back to a logical one. Missing that is what made a drag in Arabic
    // select the cells opposite the finger, spell nothing, and cost a
    // life.
    final visualCol = (local.dx / cellSize).floor();
    final row = (local.dy / cellSize).floor();
    if (row < 0 ||
        row >= puzzle.size ||
        visualCol < 0 ||
        visualCol >= puzzle.size) {
      return null;
    }
    return (row, mirrorCol(visualCol, puzzle.size, isRtl: _isRtl));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.wordSearchColors;
    final liveSet = {for (final (r, c) in liveSelection) '$r,$c'};

    return Directionality(
      // Set here rather than inherited, so the board mirrors for an Arabic
      // *puzzle* and only for one. The Row below is what actually flips;
      // `_cellAt` and the painter mirror their own arithmetic to match.
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellSize = constraints.maxWidth / puzzle.size;

            void handlePan(Offset local) {
              final cell = _cellAt(local, cellSize);
              if (cell != null) onDragUpdate(cell.$1, cell.$2);
            }

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.cellBorder, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: <Type, GestureRecognizerFactory>{
                  _GridPanGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        _GridPanGestureRecognizer
                      >(_GridPanGestureRecognizer.new, (instance) {
                        instance
                          // Report the drag from where the finger actually
                          // landed. The default, DragStartBehavior.start,
                          // reports it from wherever the slop threshold was
                          // crossed instead, which selected a cell or two
                          // along from the one the player touched.
                          ..dragStartBehavior = DragStartBehavior.down
                          ..onStart = (details) {
                            final cell = _cellAt(
                              details.localPosition,
                              cellSize,
                            );
                            if (cell != null) onDragStart(cell.$1, cell.$2);
                          }
                          ..onUpdate = (details) {
                            handlePan(details.localPosition);
                          }
                          ..onEnd = (_) {
                            onDragEnd();
                          }
                          ..onCancel = onDragEnd;
                      }),
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Column(
                      children: List.generate(puzzle.size, (r) {
                        return Expanded(
                          child: Row(
                            children: List.generate(puzzle.size, (c) {
                              final key = '$r,$c';
                              return Expanded(
                                child: _LetterCell(
                                  letter: puzzle.letterAt(r, c),
                                  isFound: foundCells.contains(key),
                                  isSelected: liveSet.contains(key),
                                  isWrong: wrongSelectionCells.contains(key),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _FoundWordLinesPainter(
                          gridSize: puzzle.size,
                          isRtl: _isRtl,
                          placements: puzzle.placements,
                          foundWords: {
                            for (final p in puzzle.placements)
                              if (foundCells.containsAll([
                                for (final c in p.cells) '${c.$1},${c.$2}',
                              ]))
                                p.word,
                          },
                          liveSelection: liveSelection,
                          isWrongSelection: wrongSelectionCells.isNotEmpty,
                          foundLine: colors.foundLine,
                          selectionLine: colors.selectionLine,
                          wrongLine: colors.wrongSelection,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.letter,
    required this.isFound,
    required this.isSelected,
    required this.isWrong,
  });

  final String letter;
  final bool isFound;
  final bool isSelected;
  final bool isWrong;

  @override
  Widget build(BuildContext context) {
    final colors = context.wordSearchColors;

    Color background = colors.cellBackground;
    if (isWrong) {
      background = colors.wrongSelection.withValues(alpha: 0.18);
    } else if (isSelected) {
      background = colors.cellSelected;
    } else if (isFound) {
      background = colors.cellFound;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: colors.cellBorder, width: 0.5),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isFound ? colors.foundLetterText : colors.letterText,
          ),
        ),
      ),
    );
  }
}

/// Draws a capsule line over every found word's cells, plus the live line
/// under the player's finger while dragging.
///
/// A separate paint layer rather than per-cell decoration: a word's line
/// has to visually connect its cells end-to-end (including diagonals),
/// which individual cell borders/backgrounds cannot express.
class _FoundWordLinesPainter extends CustomPainter {
  const _FoundWordLinesPainter({
    required this.gridSize,
    required this.isRtl,
    required this.placements,
    required this.foundWords,
    required this.liveSelection,
    required this.isWrongSelection,
    required this.foundLine,
    required this.selectionLine,
    required this.wrongLine,
  });

  final int gridSize;

  /// A canvas is never flipped by [Directionality] — its origin stays at
  /// the top-left — so a mirrored board has to be mirrored here by hand,
  /// or the line lands opposite the letters it is meant to strike through.
  final bool isRtl;

  final List<WordPlacement> placements;
  final Set<String> foundWords;
  final List<(int, int)> liveSelection;
  final bool isWrongSelection;
  final Color foundLine;
  final Color selectionLine;
  final Color wrongLine;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;
    final strokeWidth = cellSize * 0.34;

    Offset centerOf((int, int) cell) => Offset(
      (WordSearchGridView.mirrorCol(cell.$2, gridSize, isRtl: isRtl) + 0.5) *
          cellSize,
      (cell.$1 + 0.5) * cellSize,
    );

    void drawCapsule(Offset from, Offset to, Color color) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, paint);
    }

    for (final placement in placements) {
      if (!foundWords.contains(placement.word)) continue;
      final cells = placement.cells;
      drawCapsule(centerOf(cells.first), centerOf(cells.last), foundLine);
    }

    if (liveSelection.length >= 2) {
      drawCapsule(
        centerOf(liveSelection.first),
        centerOf(liveSelection.last),
        isWrongSelection ? wrongLine : selectionLine,
      );
    }
  }

  @override
  bool shouldRepaint(_FoundWordLinesPainter oldDelegate) {
    return oldDelegate.foundWords.length != foundWords.length ||
        oldDelegate.liveSelection != liveSelection ||
        oldDelegate.isWrongSelection != isWrongSelection ||
        oldDelegate.isRtl != isRtl;
  }
}
