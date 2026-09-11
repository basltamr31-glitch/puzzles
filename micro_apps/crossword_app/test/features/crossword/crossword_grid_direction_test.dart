import 'package:crossword_app/app/theme/app_theme.dart';
import 'package:crossword_app/features/crossword/domain/crossword_grid_generator.dart';
import 'package:crossword_app/features/crossword/domain/crossword_models.dart';
import 'package:crossword_app/features/crossword/presentation/widgets/crossword_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The board must be laid out in the *puzzle's* reading direction, never
/// the app's. An Arabic player on an English-language phone reported every
/// across answer reading backwards: the grid inherited the UI's
/// left-to-right Directionality, so the first letter of a right-to-left
/// answer was drawn on the left.
CrosswordGrid _gridIn(String language) {
  return CrosswordGridGenerator.generate(
    CrosswordPuzzleDef(
      id: '${language}_dir_001',
      language: language,
      difficulty: 'easy',
      title: 'Direction fixture',
      rows: 1,
      cols: 3,
      words: const [
        CrosswordWordDef(
          direction: WordDirection.across,
          row: 0,
          col: 0,
          answer: 'ABC',
          clue: 'first three',
        ),
      ],
    ),
  );
}

Widget _harness(CrosswordGrid grid) {
  return MaterialApp(
    theme: AppTheme.light,
    // Deliberately the *opposite* of what an Arabic board needs, and what
    // an English board needs anyway: the grid must not take its direction
    // from here.
    home: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 300,
          child: CrosswordGridView(
            grid: grid,
            letters: const {'0,0': 'A', '0,1': 'B', '0,2': 'C'},
            selectedRow: 0,
            selectedCol: 0,
            direction: WordDirection.across,
            incorrectCells: const {},
            isCompleted: false,
            onCellTap: (_, _) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('an Arabic board puts column 0 on the right', (tester) async {
    await tester.pumpWidget(_harness(_gridIn('ar')));

    final first = tester.getCenter(find.text('A')).dx;
    final last = tester.getCenter(find.text('C')).dx;
    expect(
      first,
      greaterThan(last),
      reason: 'the first letter of an Arabic answer belongs on the right',
    );
  });

  testWidgets('an English board keeps column 0 on the left', (tester) async {
    await tester.pumpWidget(_harness(_gridIn('en')));

    final first = tester.getCenter(find.text('A')).dx;
    final last = tester.getCenter(find.text('C')).dx;
    expect(first, lessThan(last));
  });

  testWidgets('an English board stays left-to-right under an RTL app', (
    tester,
  ) async {
    // The mirror image of the reported bug, and the reason the direction
    // is read from the puzzle rather than simply flipped for Arabic UIs.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SizedBox(
              width: 300,
              child: CrosswordGridView(
                grid: _gridIn('en'),
                letters: const {'0,0': 'A', '0,1': 'B', '0,2': 'C'},
                selectedRow: 0,
                selectedCol: 0,
                direction: WordDirection.across,
                incorrectCells: const {},
                isCompleted: false,
                onCellTap: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getCenter(find.text('A')).dx,
      lessThan(tester.getCenter(find.text('C')).dx),
    );
  });
}
