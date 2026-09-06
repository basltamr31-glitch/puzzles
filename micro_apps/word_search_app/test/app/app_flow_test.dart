import 'package:word_search_app/app/app.dart';
import 'package:word_search_app/core/ads/ad_service.dart';
import 'package:word_search_app/core/billing/billing_service.dart';
import 'package:word_search_app/core/billing/premium_state.dart';
import 'package:word_search_app/core/consent/consent_service.dart';
import 'package:word_search_app/core/storage/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end widget coverage of the app wired together for real: real
/// router, real screens, real localization delegates, real bundled puzzle
/// assets — only the platform-plugin-backed services (ads/billing/consent)
/// are swapped for no-ops, since their real implementations need platform
/// channels `flutter test` doesn't provide. This is what catches the
/// class of bug pure unit tests structurally can't: a missing
/// localization delegate, a router misconfiguration, a provider that's
/// wired to the wrong override.
///
/// Deliberately just the fresh-install path in this file — see
/// `app_flow_returning_user_test.dart` for why the "already onboarded"
/// scenario lives in its own file/process instead of a third test here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    final storage = await SharedPreferencesStorageService.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          adServiceProvider.overrideWithValue(const NoOpAdService()),
          billingServiceProvider.overrideWithValue(const NoOpBillingService()),
          consentServiceProvider.overrideWithValue(const NoOpConsentService()),
        ],
        child: const WordSearchApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a fresh install lands on the welcome screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('Word Search'), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets(
    'onboarding leads to a real puzzle list, and opening a puzzle renders the grid',
    (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('Easy'), findsOneWidget);
      await tester.tap(find.text('Easy'));
      await tester.pumpAndSettle();

      // The real bundled en/easy puzzles should be listed, not a
      // placeholder/empty state.
      expect(find.textContaining('Puzzle 001'), findsOneWidget);
      expect(find.textContaining('Puzzle 002'), findsOneWidget);

      await tester.tap(find.textContaining('Puzzle 001'));
      await tester.pumpAndSettle();

      // Confirms we actually reached gameplay, not just a route change.
      expect(find.text('Hint'), findsOneWidget);
    },
  );
}
