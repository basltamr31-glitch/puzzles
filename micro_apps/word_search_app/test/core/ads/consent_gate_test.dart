import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_search_app/core/ads/ad_service.dart';

/// GDPR does not let you fix an ad request made before a lawful basis
/// existed, and Google's UMP guidance requires the consent signal before
/// the Mobile Ads SDK starts. [ConsentGatedAdService] is what enforces
/// that, so these tests assert the order rather than trusting a comment.
class _RecordingAdService implements AdService {
  int bannerBuilds = 0;
  int interstitials = 0;
  int rewardeds = 0;

  @override
  Widget buildBanner({required String placementId}) {
    bannerBuilds++;
    return const SizedBox(key: ValueKey('real-banner'), height: 50);
  }

  @override
  Future<void> maybeShowInterstitial({required String trigger}) async {
    interstitials++;
  }

  @override
  Future<RewardedAdResult> showRewarded({required String placementId}) async {
    rewardeds++;
    return RewardedAdResult.rewarded;
  }
}

void main() {
  // Built inside each test, never in `setUp`: a `Completer` created in
  // setUp belongs to the real async zone, and completing it would not be
  // observed inside a `testWidgets` fake-async zone — the widget would
  // sit on its pre-consent branch forever and the test would look like a
  // product bug.
  ({_RecordingAdService inner, Completer<void> consent, ConsentGatedAdService gated})
      makeGate() {
    final inner = _RecordingAdService();
    final consent = Completer<void>();
    return (
      inner: inner,
      consent: consent,
      gated: ConsentGatedAdService(inner, consent.future),
    );
  }

  testWidgets('no banner is built before consent resolves', (tester) async {
    final (:inner, :consent, :gated) = makeGate();
    await tester.pumpWidget(
      MaterialApp(home: gated.buildBanner(placementId: 'test')),
    );
    await tester.pump();

    expect(inner.bannerBuilds, 0, reason: 'an ad was requested pre-consent');
    expect(find.byKey(const ValueKey('real-banner')), findsNothing);
  });

  testWidgets('the banner appears once consent resolves', (tester) async {
    final (:inner, :consent, :gated) = makeGate();
    await tester.pumpWidget(
      MaterialApp(home: gated.buildBanner(placementId: 'test')),
    );
    await tester.pump();

    consent.complete();
    await tester.pumpAndSettle();

    expect(inner.bannerBuilds, greaterThan(0));
    expect(find.byKey(const ValueKey('real-banner')), findsOneWidget);
  });

  test('an interstitial waits for consent rather than being dropped', () async {
    final (:inner, :consent, :gated) = makeGate();
    final pending = gated.maybeShowInterstitial(trigger: 'test');
    await Future<void>.delayed(Duration.zero);
    expect(inner.interstitials, 0, reason: 'shown before consent');

    consent.complete();
    await pending;
    expect(inner.interstitials, 1, reason: 'never shown after consent');
  });

  test('a rewarded ad waits for consent and still returns its reward',
      () async {
    final (:inner, :consent, :gated) = makeGate();
    final pending = gated.showRewarded(placementId: 'test');
    await Future<void>.delayed(Duration.zero);
    expect(inner.rewardeds, 0, reason: 'shown before consent');

    consent.complete();
    expect(await pending, RewardedAdResult.rewarded);
    expect(inner.rewardeds, 1);
  });

  test('a failed consent flow still lets ads run, non-personalized',
      () async {
    final (:inner, consent: _, gated: _) = makeGate();
    // adsReadyProvider swallows errors so this future always completes.
    // If it did not, tapping "watch an ad for a hint" would hang forever.
    final completed = ConsentGatedAdService(inner, Future<void>.value());
    await completed.maybeShowInterstitial(trigger: 'test');
    expect(inner.interstitials, 1);
  });
}
