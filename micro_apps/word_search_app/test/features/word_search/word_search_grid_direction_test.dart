import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/app/theme/app_theme.dart';
import 'package:word_search_app/features/word_search/domain/word_search_models.dart';
import 'package:word_search_app/features/word_search/presentation/widgets/word_search_grid_view.dart';

/// The board's reading direction comes from the **puzzle**, not the app.
///
/// The bug these pin: the grid used to inherit the ambient direction, so
/// an Arabic UI mirrored the `Row` of cells while `_cellAt` kept doing
/// left-to-right arithmetic on the pointer position. Dragging across a
/// word then selected the cells opposite the finger — the letters did not
/// spell anything, so a correct drag was rejected *and charged a life*.
///
/// The letters here are Latin on purpose. What is under test is which
/// column a coordinate maps to, and distinct ASCII letters make the
/// assertions readable; the `language` field is what drives direction.
void main() {
  WordSearchPuzzleDef puzzleIn(String language) => WordSearchPuzzleDef(
    id: 'test_001',
    language: language,
    difficulty: 'easy',
    index: 0,
    size: 4,
    // Row 0 is A B C D in *logical* column order 0..3.
    rows: const ['ABCD', 'EFGH', 'IJKL', 'MNOP'],
    placements: const [
      WordPlacement(
        word: 'ABCD',
        row: 0,
        col: 0,
        direction: WordDirection.east,
      ),
    ],
  );

  /// Mirrors the real screen closely enough to matter: the grid sits in a
  /// scrollable, which is what the custom pan recognizer exists to beat.
  Widget harness(
    WordSearchPuzzleDef puzzle, {
    required void Function(int row, int col) onDragStart,
    TextDirection? ambient,
  }) {
    final grid = SizedBox(
      width: 400,
      height: 400,
      child: WordSearchGridView(
        puzzle: puzzle,
        foundCells: const {},
        liveSelection: const [],
        wrongSelectionCells: const {},
        onDragStart: onDragStart,
        onDragUpdate: (_, _) {},
        onDragEnd: () {},
      ),
    );

    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              if (ambient == null)
                grid
              else
                Directionality(textDirection: ambient, child: grid),
              const SizedBox(height: 800),
            ],
          ),
        ),
      ),
    );
  }

  /// Presses at [at] and moves just enough for the recognizer to accept.
  Future<void> dragFrom(WidgetTester tester, Offset at) async {
    final gesture = await tester.startGesture(at);
    await tester.pump();
    await gesture.moveBy(const Offset(4, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }

  group('mirrorCol', () {
    test('is the identity left-to-right', () {
      for (var c = 0; c < 4; c++) {
        expect(WordSearchGridView.mirrorCol(c, 4, isRtl: false), c);
      }
    });

    test('flips the column right-to-left, and is its own inverse', () {
      expect(WordSearchGridView.mirrorCol(0, 4, isRtl: true), 3);
      expect(WordSearchGridView.mirrorCol(3, 4, isRtl: true), 0);
      for (var c = 0; c < 4; c++) {
        final there = WordSearchGridView.mirrorCol(c, 4, isRtl: true);
        expect(WordSearchGridView.mirrorCol(there, 4, isRtl: true), c);
      }
    });
  });

  testWidgets('an Arabic board draws logical column 0 on the right', (
    tester,
  ) async {
    await tester.pumpWidget(harness(puzzleIn('ar'), onDragStart: (_, _) {}));
    await tester.pump();

    // 'A' is logical (0,0); mirrored, it belongs at the right-hand edge.
    expect(
      tester.getCenter(find.text('A')).dx,
      greaterThan(tester.getCenter(find.text('D')).dx),
      reason: 'an Arabic board should render mirrored',
    );
  });

  testWidgets('dragging an Arabic board selects the cell under the finger', (
    tester,
  ) async {
    final started = <(int, int)>[];
    await tester.pumpWidget(
      harness(puzzleIn('ar'), onDragStart: (r, c) => started.add((r, c))),
    );
    await tester.pump();

    // Press on the letter 'A' itself, wherever it is drawn.
    await dragFrom(tester, tester.getCenter(find.text('A')));

    expect(
      started,
      [(0, 0)],
      reason: 'touching A must select A — before the fix this reported (0, 3), '
          'so the drag spelled nothing and cost a life',
    );
  });

  testWidgets('an English board is unmirrored and still maps left to zero', (
    tester,
  ) async {
    final started = <(int, int)>[];
    await tester.pumpWidget(
      harness(puzzleIn('en'), onDragStart: (r, c) => started.add((r, c))),
    );
    await tester.pump();

    expect(
      tester.getCenter(find.text('A')).dx,
      lessThan(tester.getCenter(find.text('D')).dx),
    );
    await dragFrom(tester, tester.getCenter(find.text('A')));
    expect(started, [(0, 0)]);
  });

  testWidgets('an English board is unaffected by an Arabic UI', (tester) async {
    final started = <(int, int)>[];
    await tester.pumpWidget(
      harness(
        puzzleIn('en'),
        onDragStart: (r, c) => started.add((r, c)),
        ambient: TextDirection.rtl,
      ),
    );
    await tester.pump();

    // The whole point of reading direction off the puzzle: an English
    // board under an Arabic UI used to mirror, which is nobody's intent.
    expect(
      tester.getCenter(find.text('A')).dx,
      lessThan(tester.getCenter(find.text('D')).dx),
      reason: 'the UI language must not mirror an English board',
    );
    await dragFrom(tester, tester.getCenter(find.text('A')));
    expect(started, [(0, 0)]);
  });

  testWidgets('an Arabic board is mirrored even under an English UI', (
    tester,
  ) async {
    final started = <(int, int)>[];
    await tester.pumpWidget(
      harness(
        puzzleIn('ar'),
        onDragStart: (r, c) => started.add((r, c)),
        ambient: TextDirection.ltr,
      ),
    );
    await tester.pump();

    expect(
      tester.getCenter(find.text('A')).dx,
      greaterThan(tester.getCenter(find.text('D')).dx),
      reason: 'the UI language must not un-mirror an Arabic board',
    );
    await dragFrom(tester, tester.getCenter(find.text('A')));
    expect(started, [(0, 0)]);
  });
}
