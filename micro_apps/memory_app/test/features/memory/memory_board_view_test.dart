import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memory_app/core/localization/generated/app_localizations.dart';
import 'package:memory_app/core/localization/supported_locales.dart';
import 'package:memory_app/app/theme/app_theme.dart';
import 'package:memory_app/app/theme/memory_colors.dart';
import 'package:memory_app/features/memory/domain/memory_models.dart';
import 'package:memory_app/features/memory/presentation/widgets/memory_board_view.dart';

const _deck = MemoryDeckDef(
  id: 'test_fixture_001',
  difficulty: 'easy',
  index: 0,
  rows: 4,
  cols: 3,
  cards: ['A', 'B', 'C', 'D', 'A', 'B', 'C', 'D', 'E', 'F', 'E', 'F'],
);

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: SupportedLocales.all,
    home: Scaffold(body: Center(child: SizedBox(width: 320, child: child))),
  );
}

MemoryBoardView _board({
  Set<int> matched = const {},
  List<int> faceUp = const [],
  Set<int> mismatched = const {},
  void Function(int index)? onTap,
}) {
  return MemoryBoardView(
    deck: _deck,
    matchedCards: matched,
    faceUpCards: faceUp,
    mismatchedCards: mismatched,
    isCompleted: false,
    onCardTap: onTap ?? (_) {},
  );
}

void main() {
  testWidgets('draws one card per board position', (tester) async {
    await tester.pumpWidget(_wrap(_board()));
    await tester.pumpAndSettle();

    expect(find.byType(MemoryCardView), findsNWidgets(12));
  });

  testWidgets('a face-down card does not render its symbol', (tester) async {
    await tester.pumpWidget(_wrap(_board()));
    await tester.pumpAndSettle();

    // The one thing this game is about is not knowing what is on a card.
    // A symbol painted behind the back — invisible to the eye but present
    // in the tree — would leak the whole board to a screen reader.
    expect(find.text('A'), findsNothing);
  });

  testWidgets('a revealed card shows its symbol once the flip lands',
      (tester) async {
    await tester.pumpWidget(_wrap(_board(faceUp: const [0])));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('a matched pair stays face up', (tester) async {
    await tester.pumpWidget(_wrap(_board(matched: const {0, 4})));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsNWidgets(2));
  });

  testWidgets('tapping a card reports its board position', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(_wrap(_board(onTap: tapped.add)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MemoryCardView).at(5));
    expect(tapped, [5]);
  });

  testWidgets('a face-down card announces its position but not its symbol',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(_board()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Row 1, column 1, face down'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a revealed card announces what it is showing', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(_board(faceUp: const [0])));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Row 1, column 1, showing A'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a matched card says so, rather than just showing a symbol',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(_board(matched: const {0, 4})));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Row 1, column 1, A, matched'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('lays out every tier shape without overflowing', (tester) async {
    // The board sizes itself from the deck's own rows and columns, so
    // each tier shape is a different layout — and an overflow in any of
    // them fails this test, because `testWidgets` fails on any unconsumed
    // Flutter error.
    for (final shape in const [(4, 3), (4, 4), (6, 4), (6, 5)]) {
      final (rows, cols) = shape;
      final cards = [
        for (var i = 0; i < rows * cols ~/ 2; i++) ...['s$i', 's$i'],
      ];
      await tester.pumpWidget(
        _wrap(
          MemoryBoardView(
            deck: MemoryDeckDef(
              id: 'fixture',
              difficulty: 'easy',
              index: 0,
              rows: rows,
              cols: cols,
              cards: cards,
            ),
            matchedCards: const {},
            faceUpCards: const [],
            mismatchedCards: const {},
            isCompleted: false,
            onCardTap: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(MemoryCardView),
        findsNWidgets(rows * cols),
        reason: '${rows}x$cols',
      );
      expect(tester.takeException(), isNull, reason: '${rows}x$cols');
    }
  });

  testWidgets('a finished board stops accepting taps', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      _wrap(
        MemoryBoardView(
          deck: _deck,
          matchedCards: const {},
          faceUpCards: const [],
          mismatchedCards: const {},
          isCompleted: true,
          onCardTap: tapped.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MemoryCardView).first);
    expect(tapped, isEmpty);
  });

  testWidgets('each card state is painted with its own token', (tester) async {
    // The mismatch wash is on screen for well under a second and is the
    // only feedback that a life was spent, so it is the state most likely
    // to be broken without anyone noticing in manual play — and the one a
    // browser screenshot is too slow to catch.
    await tester.pumpWidget(
      _wrap(_board(matched: const {0, 4}, faceUp: const [1, 2],
          mismatched: const {1, 2})),
    );
    await tester.pumpAndSettle();

    Color fillOf(int index) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MemoryCardView).at(index),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).color!;
    }

    expect(fillOf(0), MemoryColors.light.cardMatched);
    expect(fillOf(1), MemoryColors.light.cardMismatch);
    expect(fillOf(3), MemoryColors.light.cardBack);
  });
}
