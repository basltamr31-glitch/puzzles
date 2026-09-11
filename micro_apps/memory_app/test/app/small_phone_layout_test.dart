import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memory_app/app/app.dart';
import 'package:memory_app/core/ads/ad_service.dart';
import 'package:memory_app/core/billing/billing_service.dart';
import 'package:memory_app/core/billing/premium_state.dart';
import 'package:memory_app/core/consent/consent_service.dart';
import 'package:memory_app/core/storage/local_storage_service.dart';
import 'package:memory_app/features/memory/presentation/widgets/memory_board_view.dart';

/// Walks to the gameplay screen on the smallest phone the app targets and
/// asserts nothing overflows.
///
/// This is the check the browser preview cannot provide here: the pane
/// renders into a fixed ~144x311 surface regardless of the requested
/// viewport, so every overflow it reports is an artifact of that surface
/// rather than of the layout. `testWidgets` fails on any unconsumed
/// Flutter error, and a `RenderFlex overflowed by N pixels` is exactly
/// that — so reaching the end of this test *is* the assertion.
///
/// 320x568 is a 4-inch iPhone SE / small Android: the tightest case a
/// 6x5 expert board and the counters above it have to survive together.
/// Expert rather than easy on purpose — 30 cards is where the board runs
/// out of room first, and it is reachable in a test because the tap goes
/// straight to the route.
///
/// In its own file because go_router's route state leaks between
/// `testWidgets` in one file — see `app_flow_returning_user_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the board and its counters fit a 320x568 phone',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 568 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({'flutter.onboarding_complete': true});
    final storage = await SharedPreferencesStorageService.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          adServiceProvider.overrideWithValue(const NoOpAdService()),
          billingServiceProvider.overrideWithValue(const NoOpBillingService()),
          consentServiceProvider.overrideWithValue(const NoOpConsentService()),
        ],
        child: const MemoryApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Straight to expert: 30 cards is where the board runs out of room
    // first, so testing easy here would prove almost nothing.
    await tester.tap(find.text('Expert').first);
    // Pumped frame by frame rather than with `pumpAndSettle`, which never
    // returns here: the list shows a `CircularProgressIndicator` while
    // the deck bundle loads, and a spinner keeps a frame scheduled
    // forever. Waiting for a 15-pair row rather than for "Puzzle 001"
    // matters too — the AnimatedSwitcher holds the outgoing *easy* list
    // on screen through the transition, and its rows say "6 pairs".
    for (var i = 0; i < 20; i++) {
      // `runAsync` is what lets the deck bundle's real file read finish:
      // inside the test's fake-async zone the load is started but never
      // completes, so a plain `pump` loop waits on a Future that cannot
      // resolve.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.textContaining('15 pairs').evaluate().isNotEmpty) break;
    }
    // Long enough for the switcher to drop the outgoing list, so the
    // "Puzzle 001" tapped below is unambiguously the expert one.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Puzzle 001'), findsOneWidget);
    await tester.tap(find.textContaining('Puzzle 001'));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(MemoryBoardView).evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 400));

    // Everything the player needs is built. The gameplay column is
    // scrollable by design, so this asserts they exist and that nothing
    // overflowed getting there — not that all of it fits without a
    // scroll on a 4-inch screen.
    expect(find.byType(MemoryBoardView), findsOneWidget);
    expect(find.byType(MemoryCardView), findsNWidgets(30));
    expect(find.text('Pairs 0/15'), findsOneWidget);
    expect(find.text('0 moves'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
  });
}
