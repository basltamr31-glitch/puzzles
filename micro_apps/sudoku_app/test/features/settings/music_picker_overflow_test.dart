import 'package:sudoku_app/core/audio/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression: the music picker is a modal bottom sheet, which Flutter caps
/// at 9/16 of the screen height. It held a fixed [Column], so once the track
/// list grew from four to seven entries the content no longer fit and
/// opening the picker threw a RenderFlex overflow. That bug was found in
/// the crossword app; this app inherited the same picker, so it is
/// guarded here before it can be hit rather than after.
///
/// These tests exercise the sheet's *layout shape* rather than the real
/// Settings screen, which would drag in storage, billing, ads and audio
/// providers. What matters is that the list scrolls instead of overflowing.
void main() {
  Widget harness({required Size size, required Widget sheetBody}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => sheetBody,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Mirrors the shipped picker: a scrollable column of one tile per track.
  Widget scrollableTrackList() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final track in MusicTrack.values)
              ListTile(
                leading: const Icon(Icons.music_note_rounded),
                title: Text(track.id),
              ),
          ],
        ),
      ),
    );
  }

  testWidgets('every track fits without overflowing on a short screen',
      (tester) async {
    // Deliberately cramped: 9/16 of 640 leaves ~360dp for seven ~56dp tiles
    // plus a drag handle, which is exactly the case that used to throw.
    await tester.pumpWidget(
      harness(size: const Size(360, 640), sheetBody: scrollableTrackList()),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the picker scrolls rather than clipping its last option',
      (tester) async {
    await tester.pumpWidget(
      harness(size: const Size(360, 640), sheetBody: scrollableTrackList()),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // A scrollable is what lets the overflowing content stay reachable.
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // The last track must be reachable, not cut off below the fold.
    expect(find.text(MusicTrack.values.last.id), findsOneWidget);
  });

  testWidgets('a bare Column of the same options does overflow',
      (tester) async {
    // Guards the fix itself: if someone reverts to a non-scrolling Column,
    // this documents that it genuinely breaks rather than being cosmetic.
    await tester.pumpWidget(
      harness(
        size: const Size(360, 640),
        sheetBody: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final track in MusicTrack.values)
                ListTile(
                  leading: const Icon(Icons.music_note_rounded),
                  title: Text(track.id),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      isA<FlutterError>(),
      reason: 'a fixed Column of every track must not fit — that is the bug',
    );
  });
}
