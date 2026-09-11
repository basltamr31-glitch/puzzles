import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/app/theme/app_theme.dart';
import 'package:word_search_app/features/word_search/domain/word_search_models.dart';
import 'package:word_search_app/features/word_search/presentation/widgets/word_search_grid_view.dart';

/// The grid lives inside a [SingleChildScrollView] on the real screen, and
/// that is the whole point of these tests.
///
/// A plain `GestureDetector(onPanStart: ...)` loses the gesture arena to an
/// enclosing vertical scrollable: pan waits for ~36dp of travel while the
/// scroll view claims a vertical drag at ~18dp. Shipped that way, the app
/// could select horizontal words but *no* vertical ones — the board just
/// scrolled under the finger. Every case here drags inside a scroll view
/// for that reason; testing the grid on its own passes even when the app
/// is broken.
void main() {
  const puzzle = WordSearchPuzzleDef(
    id: 'test_001',
    language: 'en',
    difficulty: 'easy',
    index: 0,
    size: 4,
    // CAT reads down column 0; DOG reads across row 3.
    rows: ['CXXX', 'AXXX', 'TXXX', 'DOGX'],
    placements: [
      WordPlacement(
        word: 'CAT',
        row: 0,
        col: 0,
        direction: WordDirection.south,
      ),
      WordPlacement(word: 'DOG', row: 3, col: 0, direction: WordDirection.east),
    ],
  );

  /// Mirrors the real screen: a scrollable tall enough to actually scroll,
  /// with the grid inside it.
  Widget harness({
    required void Function(int row, int col) onDragStart,
    required void Function(int row, int col) onDragUpdate,
    required VoidCallback onDragEnd,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 100),
              SizedBox(
                width: 400,
                height: 400,
                child: WordSearchGridView(
                  puzzle: puzzle,
                  foundCells: const {},
                  liveSelection: const [],
                  wrongSelectionCells: const {},
                  onDragStart: onDragStart,
                  onDragUpdate: onDragUpdate,
                  onDragEnd: onDragEnd,
                ),
              ),
              const SizedBox(height: 800),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('a vertical drag selects cells instead of scrolling', (
    tester,
  ) async {
    final started = <(int, int)>[];
    final updated = <(int, int)>[];
    var ended = 0;

    await tester.pumpWidget(
      harness(
        onDragStart: (r, c) => started.add((r, c)),
        onDragUpdate: (r, c) => updated.add((r, c)),
        onDragEnd: () => ended++,
      ),
    );

    final gridBefore = tester.getTopLeft(find.byType(WordSearchGridView));

    // Cells are 100x100 in this harness. Drag down column 0, from the
    // middle of (0,0) to the middle of (2,0).
    //
    // Deliberately in small steps, not one moveTo. A single large jump
    // crosses both the scroll view's ~18dp threshold and the pan's ~36dp
    // one in the *same* event, and the arena then awards the gesture to
    // the innermost recognizer - so the grid wins and the bug hides. A
    // real finger delivers a stream of small moves, which is exactly what
    // lets the scrollable claim the drag first. Reproducing that is the
    // whole point of this test.
    final topLeft = tester.getTopLeft(find.byType(WordSearchGridView));
    final gesture = await tester.startGesture(topLeft + const Offset(50, 50));
    await tester.pump();
    for (var i = 0; i < 25; i++) {
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      started,
      isNotEmpty,
      reason: 'the vertical drag never reached the grid — the scroll view '
          'swallowed it, which is the bug this test exists for',
    );
    expect(started.first, (0, 0), reason: 'drag must start where it touched');
    expect(
      updated,
      contains((2, 0)),
      reason: 'the drag should have tracked down to row 2',
    );
    expect(ended, 1);

    expect(
      tester.getTopLeft(find.byType(WordSearchGridView)),
      gridBefore,
      reason: 'the page must not scroll while a word is being selected - if '
          'the grid moved, the scroll view stole the drag again',
    );
  });

  testWidgets('a horizontal drag still selects', (tester) async {
    final started = <(int, int)>[];
    final updated = <(int, int)>[];

    await tester.pumpWidget(
      harness(
        onDragStart: (r, c) => started.add((r, c)),
        onDragUpdate: (r, c) => updated.add((r, c)),
        onDragEnd: () {},
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(WordSearchGridView));
    final gesture = await tester.startGesture(topLeft + const Offset(50, 350));
    await tester.pump();
    await gesture.moveTo(topLeft + const Offset(250, 350));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(started.first, (3, 0));
    expect(updated, contains((3, 2)));
  });

  testWidgets('the first selected cell is the one under the finger', (
    tester,
  ) async {
    // DragStartBehavior.start would report the drag from wherever the slop
    // threshold was crossed, landing a cell or two along from the touch.
    final started = <(int, int)>[];

    await tester.pumpWidget(
      harness(
        onDragStart: (r, c) => started.add((r, c)),
        onDragUpdate: (_, _) {},
        onDragEnd: () {},
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(WordSearchGridView));
    final gesture = await tester.startGesture(topLeft + const Offset(150, 50));
    await tester.pump();
    await gesture.moveTo(topLeft + const Offset(350, 50));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(started.single, (0, 1));
  });

  // The tests above omit the InteractiveViewer that sits between the scroll
  // view and the grid on the real screen. That matters: InteractiveViewer
  // installs a ScaleGestureRecognizer unconditionally - panEnabled: false
  // only makes it *ignore* the result, it still competes in the arena - so
  // the real tree has three recognizers fighting over one drag, not two.
  // This case mirrors word_search_screen.dart. If it disagrees with the
  // screen, fix the harness, not the assertion.
  testWidgets('vertical drag works with InteractiveViewer in the tree', (
    tester,
  ) async {
    final started = <(int, int)>[];
    final updated = <(int, int)>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                SizedBox(
                  width: 400,
                  height: 400,
                  child: ClipRect(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      panEnabled: false,
                      child: WordSearchGridView(
                        puzzle: puzzle,
                        foundCells: const {},
                        liveSelection: const [],
                        wrongSelectionCells: const {},
                        onDragStart: (r, c) => started.add((r, c)),
                        onDragUpdate: (r, c) => updated.add((r, c)),
                        onDragEnd: () {},
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 800),
              ],
            ),
          ),
        ),
      ),
    );

    final topLeft = tester.getTopLeft(find.byType(WordSearchGridView));
    final gesture = await tester.startGesture(topLeft + const Offset(50, 50));
    await tester.pump();
    for (var i = 0; i < 25; i++) {
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      started,
      isNotEmpty,
      reason: 'a vertical drag was swallowed before it reached the grid',
    );
    expect(updated, contains((2, 0)));
  });
}
