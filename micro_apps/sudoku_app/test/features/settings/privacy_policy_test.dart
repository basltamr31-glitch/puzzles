import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/app/app_config.dart';
import 'package:sudoku_app/features/settings/presentation/privacy_policy_screen.dart';

import '../../support/responsive_harness.dart';

/// Google Play will reject a listing whose privacy policy link is broken,
/// and a policy that is bundled but unreachable from the app is no better
/// than not having one. These check both halves: the document ships, and
/// the screen that shows it renders.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `rootBundle` caches the Future it returns, keyed by asset path, and
  // that cache outlives a single `testWidgets`. Without clearing it the
  // second test onwards awaits a Future created inside the *first*
  // test's fake-async zone, which never completes — every screen but the
  // first would sit on a loading spinner forever.
  setUp(rootBundle.clear);

  group('the policy document', () {
    // Read from disk, not through `rootBundle`: the bundle caches the
    // Future it hands back, and one primed here — outside a widget
    // test's fake-async zone — never completes inside one, which silently
    // wedged every screen test below on a loading spinner.
    final policy = File(PrivacyPolicyScreen.assetPath).readAsStringSync();

    test('is bundled and substantial', () {
      expect(policy.length, greaterThan(2000));
      expect(policy, startsWith('# Privacy Policy'));
    });

    test('names this app, not the other one in the portfolio', () {
      // A copy-paste slip here would publish the wrong app's policy.
      expect(policy, contains('Sudoku'));
      expect(policy, isNot(contains('Crossword')));
    });

    test('covers every practice the app actually has', () {
      // Each of these is something the code really does. If a section
      // gets dropped in an edit, the policy silently stops matching the
      // app — which is the failure mode that matters here.
      for (final topic in [
        'AdMob',
        'User Messaging Platform',
        'Google Play Billing',
        'Analytics',
        'Notifications',
        'Age requirement',
        'Contact',
      ]) {
        expect(policy, contains(topic), reason: 'missing section: $topic');
      }
    });

    test('states the 13+ audience the Play listing declares', () {
      // These must agree. A policy claiming a broader audience than the
      // Play Console declaration is the mismatch that pulls an app into
      // the Families programme by accident.
      expect(policy, contains('aged 13 and over'));
      expect(policy, isNot(contains('all ages')));
    });

    test('is not publishable while blanks remain', () {
      // The gate: as soon as a URL is configured the policy is live, so
      // every [[FILL IN]] must be gone by then. Until then this test
      // documents that the document is deliberately incomplete.
      final blanks = RegExp(r'\[\[FILL IN').allMatches(policy).length;
      if (AppConfig.privacyPolicyUrl.isEmpty) {
        expect(
          blanks,
          greaterThan(0),
          reason: 'blanks were filled but no URL was configured — set '
              'AppConfig.privacyPolicyUrl to the hosted address',
        );
      } else {
        expect(
          blanks,
          0,
          reason: 'the policy is published at ${AppConfig.privacyPolicyUrl} '
              'but still contains $blanks unfilled placeholder(s)',
        );
      }
    });
  });

  group('the policy screen', () {
    for (final layoutCase in responsiveCases) {
      testWidgets('renders on $layoutCase', (tester) async {
        await pumpAtViewport(
          tester,
          layoutCase,
          child: const PrivacyPolicyScreen(),
        );
        await pumpFrames(tester);

        expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
        // Headings are rendered as their own Text widgets, so finding one
        // proves the document was parsed rather than dumped as one blob.
        expect(find.text('Summary'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('is selectable so the contact address can be copied',
        (tester) async {
      await pumpAtViewport(
        tester,
        responsiveCases.first,
        child: const PrivacyPolicyScreen(),
      );
      await pumpFrames(tester);
      expect(find.byType(SelectionArea), findsOneWidget);
    });
  });
}
