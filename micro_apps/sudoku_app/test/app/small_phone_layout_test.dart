import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku_app/app/app.dart';
import 'package:sudoku_app/core/ads/ad_service.dart';
import 'package:sudoku_app/core/billing/billing_service.dart';
import 'package:sudoku_app/core/billing/premium_state.dart';
import 'package:sudoku_app/core/consent/consent_service.dart';
import 'package:sudoku_app/core/storage/local_storage_service.dart';

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
/// 320x568 is a 4-inch iPhone SE / small Android: the tightest case the
/// nine-key number pad and the square grid have to survive together.
///
/// In its own file because go_router's route state leaks between
/// `testWidgets` in one file — see `app_flow_returning_user_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the grid, controls, and number pad fit a 320x568 phone',
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
        child: const SudokuApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Puzzle 001'), findsOneWidget);
    await tester.tap(find.textContaining('Puzzle 001'));
    await tester.pumpAndSettle();

    // Every control the player needs is built. The gameplay column is
    // scrollable by design, so this asserts they exist and that nothing
    // overflowed getting there — not that all of them fit without a
    // scroll on a 4-inch screen.
    for (final label in ['Undo', 'Erase', 'Notes', 'Hint', 'Check']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (var digit = 1; digit <= 9; digit++) {
      expect(find.text('$digit'), findsWidgets, reason: 'digit $digit');
    }
  });
}
