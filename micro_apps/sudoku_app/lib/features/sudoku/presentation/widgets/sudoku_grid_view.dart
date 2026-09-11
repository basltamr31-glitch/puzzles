import 'package:flutter/material.dart';

import '../../../../app/theme/sudoku_colors.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../domain/sudoku_models.dart';

/// Renders the playable 9x9 grid.
///
/// Sized via [AspectRatio] so cells stay perfectly square across phone
/// sizes without any hardcoded dimensions, and every font size is derived
/// from the measured cell size rather than fixed — a Sudoku cell has to
/// hold either one large digit or nine tiny ones, and both have to stay
/// legible on a 320pt-wide phone and a tablet alike.
class SudokuGridView extends StatelessWidget {
  const SudokuGridView({
    super.key,
    required this.puzzle,
    required this.values,
    required this.notes,
    required this.selectedIndex,
    required this.incorrectCells,
    required this.conflicts,
    required this.blockedCells,
    required this.isCompleted,
    required this.onCellTap,
  });

  final SudokuPuzzleDef puzzle;
  final List<int> values;
  final List<Set<int>> notes;
  final int? selectedIndex;
  final Set<int> incorrectCells;
  final Set<int> conflicts;

  /// The refused entry and what refused it, shown until the next action.
  final Set<int> blockedCells;

  final bool isCompleted;
  final void Function(int index) onCellTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sudokuColors;
    final l10n = AppLocalizations.of(context);

    final selected = selectedIndex;
    final selectedValue = selected == null ? 0 : values[selected];

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = constraints.maxWidth / sudokuSize;
          return Container(
            decoration: BoxDecoration(
              color: colors.cellBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  children: List.generate(sudokuSize, (row) {
                    return Expanded(
                      child: Row(
                        children: List.generate(sudokuSize, (col) {
                          final index = indexOf(row, col);
                          return Expanded(
                            child: _SudokuCellView(
                              l10n: l10n,
                              row: row,
                              col: col,
                              value: values[index],
                              notes: notes[index],
                              isGiven: puzzle.isGiven(index),
                              isSelected: index == selected,
                              isPeer: selected != null &&
                                  sudokuPeers[selected].contains(index),
                              // "Same value" deliberately excludes the
                              // selected cell itself, which already has
                              // its own stronger highlight.
                              isSameValue: selectedValue != 0 &&
                                  values[index] == selectedValue &&
                                  index != selected,
                              isIncorrect: incorrectCells.contains(index),
                              isConflicting: conflicts.contains(index) ||
                                  blockedCells.contains(index),
                              isCompleted: isCompleted,
                              cellSize: cellSize,
                              onTap: () => onCellTap(index),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
                // Painted over the cells rather than drawn as per-cell
                // borders: box separators that are half on one cell and
                // half on its neighbour end up visibly uneven once the
                // cell size isn't a whole number of pixels.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _BoxLinePainter(color: colors.gridBorder),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SudokuCellView extends StatelessWidget {
  const _SudokuCellView({
    required this.l10n,
    required this.row,
    required this.col,
    required this.value,
    required this.notes,
    required this.isGiven,
    required this.isSelected,
    required this.isPeer,
    required this.isSameValue,
    required this.isIncorrect,
    required this.isConflicting,
    required this.isCompleted,
    required this.cellSize,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final int row;
  final int col;
  final int value;
  final Set<int> notes;
  final bool isGiven;
  final bool isSelected;
  final bool isPeer;
  final bool isSameValue;
  final bool isIncorrect;
  final bool isConflicting;
  final bool isCompleted;
  final double cellSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sudokuColors;

    // Ordered by how much the player needs to see it. A mistake outranks
    // everything — including the selection, whose ring still marks the
    // cell — because a duplicate digit is the one thing in the grid that
    // must never be missable. Below that: their own selection, then
    // digit-matching, then the row/column/box tint, then the flat "this
    // is a clue" shading.
    final isMistake = isIncorrect || isConflicting;
    final Color background;
    if (isMistake) {
      background = colors.cellConflict;
    } else if (isSelected) {
      background = colors.cellSelected;
    } else if (isSameValue) {
      background = colors.cellSameValue;
    } else if (isPeer) {
      background = colors.cellPeer;
    } else if (isGiven) {
      background = colors.cellGiven;
    } else {
      background = colors.cellBackground;
    }

    // Must follow the same order as the fill above: each of these colours
    // is only guaranteed to be readable on the fill it pairs with.
    final Color digitColor;
    if (isMistake) {
      digitColor = colors.digitIncorrect;
    } else if (isSelected) {
      digitColor = colors.digitOnSelected;
    } else if (isGiven) {
      digitColor = colors.digitGiven;
    } else {
      digitColor = colors.digitEntered;
    }

    // The selection ring. Drawn as a border rather than only a fill so
    // that selection survives the red mistake wash taking the fill over,
    // and so the fill never has to be dark enough to hurt the digit.
    final Border border = isSelected
        ? Border.all(color: colors.cellSelectedBorder, width: 2.5)
        : Border.all(color: colors.cellBorder, width: 0.5);

    return Semantics(
      button: true,
      selected: isSelected,
      label: l10n.cellSemanticLabel(row + 1, col + 1),
      value: value == 0 ? l10n.cellEmpty : '$value',
      child: GestureDetector(
        onTap: onTap,
        // Transparent rather than absent: without a hit-test-opaque
        // child, taps on an empty cell fall through to the grid.
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: background,
            border: border,
          ),
          child: Center(
            child: value != 0
                ? Text(
                    '$value',
                    style: TextStyle(
                      fontSize: cellSize * 0.56,
                      // Givens are heavier than the player's own entries,
                      // reinforcing the color difference for anyone who
                      // can't rely on it.
                      fontWeight: isGiven ? FontWeight.w700 : FontWeight.w500,
                      color: digitColor,
                      height: 1,
                    ),
                  )
                : _NoteMarks(
                    notes: notes,
                    cellSize: cellSize,
                    // Pencil marks on the selected cell sit on its strong
                    // fill, where the ordinary note colour would vanish.
                    color: isSelected
                        ? colors.digitOnSelected
                        : colors.noteText,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Pencil marks, laid out on a fixed 3x3 so a given digit always sits in
/// the same spot — the point of notes is scanning them, which only works
/// if 7 is always bottom-left.
class _NoteMarks extends StatelessWidget {
  const _NoteMarks({
    required this.notes,
    required this.cellSize,
    required this.color,
  });

  final Set<int> notes;
  final double cellSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(cellSize * 0.06),
      child: Column(
        children: List.generate(sudokuBoxSize, (noteRow) {
          return Expanded(
            child: Row(
              children: List.generate(sudokuBoxSize, (noteCol) {
                final digit = noteRow * sudokuBoxSize + noteCol + 1;
                return Expanded(
                  child: Center(
                    child: Text(
                      notes.contains(digit) ? '$digit' : '',
                      style: TextStyle(
                        fontSize: cellSize * 0.24,
                        fontWeight: FontWeight.w600,
                        color: color,
                        height: 1,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

/// The two heavy horizontal and two heavy vertical lines that separate
/// the nine 3x3 boxes, plus the outer frame.
class _BoxLinePainter extends CustomPainter {
  const _BoxLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;

    final cell = size.width / sudokuSize;
    for (var i = sudokuBoxSize; i < sudokuSize; i += sudokuBoxSize) {
      final offset = cell * i;
      canvas.drawLine(Offset(offset, 0), Offset(offset, size.height), paint);
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), paint);
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_BoxLinePainter oldDelegate) => oldDelegate.color != color;
}
