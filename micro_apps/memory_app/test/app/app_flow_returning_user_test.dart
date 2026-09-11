import 'package:memory_app/app/app.dart';
import 'package:memory_app/core/ads/ad_service.dart';
import 'package:memory_app/core/billing/billing_service.dart';
import 'package:memory_app/core/billing/premium_state.dart';
import 'package:memory_app/core/consent/consent_service.dart';
import 'package:memory_app/core/storage/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kept in its own file/process, separate from `app_flow_test.dart`.
/// `flutter test` runs every `testWidgets` in a file within one shared
/// isolate, and go_router's `GoRouter` ties into platform-level route
/// state (`WidgetsBinding`/route information provider) that isn't fully
/// reset between separate `GoRouter` instances built in sequential tests
/// — a fresh GoRouter built in a *third* test after two prior tests had
/// already navigated deep into the app intermittently picked up a stale
/// route instead of honoring `initialLocation`. Splitting this scenario
/// into its own test file sidesteps that Flutter/go_router-testing
/// interaction entirely, since each test file runs in its own process.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a returning user (onboarding already complete) skips straight to the puzzle list',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.onboarding_complete': true,
    });
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

    expect(find.text('Continue'), findsNothing);
    expect(find.textContaining('Puzzle 001'), findsOneWidget);
  });
}
