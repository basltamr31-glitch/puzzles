import 'package:flutter/material.dart';

import '../../../../app/theme/crossword_colors.dart';
import '../../domain/crossword_models.dart';
import '../controllers/crossword_controller.dart';

/// Renders the playable grid. Sized responsively via [AspectRatio] so
/// cells stay perfectly square across phone sizes and aspect ratios
/// (spec §27) without any hardcoded dimensions.
class CrosswordGridView extends StatelessWidget {
  const CrosswordGridView({
    super.key,
    required this.grid,
    required this.letters,
    required this.selectedRow,
    required this.selectedCol,
    required this.direction,
    required this.incorrectCells,
    required this.isCompleted,
    required this.onCellTap,
  });

  final CrosswordGrid grid;
  final Map<String, String> letters;
  final int? selectedRow;
  final int? selectedCol;
  final WordDirection direction;
  final Set<String> incorrectCells;
  final bool isCompleted;
  final void Function(int row, int col) onCellTap;

  Set<String> get _currentClueCells {
    if (selectedRow == null || selectedCol == null) return const {};
    final clue = clueAt(grid, selectedRow!, selectedCol!, direction);
    if (clue == null) return const {};
    return clue.cells.map((c) => '${c.$1},${c.$2}').toSet();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.crosswordColors;
    final currentClueCells = _currentClueCells;

    return AspectRatio(
      aspectRatio: grid.cols / grid.rows,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.cellBorder, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(grid.rows, (r) {
            return Expanded(
              child: Row(
                children: List.generate(grid.cols, (c) {
                  return Expanded(
                    child: _CrosswordCellView(
                      cell: grid.cellAt(r, c),
                      letter: letters['$r,$c'],
                      isSelected: r == selectedRow && c == selectedCol,
                      isInCurrentWord: currentClueCells.contains('$r,$c'),
                      isIncorrect: incorrectCells.contains('$r,$c'),
                      isCompleted: isCompleted,
                      onTap: () => onCellTap(r, c),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _CrosswordCellView extends StatelessWidget {
  const _CrosswordCellView({
    required this.cell,
    required this.letter,
    required this.isSelected,
    required this.isInCurrentWord,
    required this.isIncorrect,
    required this.isCompleted,
    required this.onTap,
  });

  final CrosswordCell cell;
  final String? letter;
  final bool isSelected;
  final bool isInCurrentWord;
  final bool isIncorrect;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.crosswordColors;

    if (cell.isBlocked) {
      return ColoredBox(color: colors.cellBlocked);
    }

    Color background = colors.cellBackground;
    if (isSelected) {
      background = colors.cellActiveCell;
    } else if (isInCurrentWord) {
      background = colors.cellActiveWord;
    }

    Color textColor = Theme.of(context).colorScheme.onSurface;
    if (isCompleted) {
      textColor = colors.cellTextCorrect;
    } else if (isIncorrect) {
      textColor = colors.cellTextIncorrect;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: cell.clueNumber != null ? 'Cell, clue ${cell.clueNumber}' : 'Cell',
      value: letter,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: colors.cellBorder, width: 0.5),
          ),
          child: Stack(
            children: [
              if (cell.clueNumber != null)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Text(
                    '${cell.clueNumber}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    letter ?? '',
                    key: ValueKey(letter ?? ''),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
