import 'package:sudoku_app/app/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // `flutter test` always runs in debug mode (kDebugMode is a compile-time
  // constant we can't override here), so these tests exercise the debug
  // test-ad-ID fallback path — the `--dart-define` override and the
  // release-mode "empty until configured" path aren't reachable from a
  // normal test run without invasive refactoring, so they're not asserted
  // here; that's a real, acknowledged coverage gap, not an oversight.
  group('AppConfig ad unit ID resolution (debug fallback)', () {
    // The fallback only applies when nothing is supplied, so this whole
    // group is meaningless under `--dart-define-from-file=ad_config.json`
    // — the override group below covers that run instead. The two are
    // mutually exclusive by construction, not flaky.
    const suppliedBanner = String.fromEnvironment('BANNER_AD_UNIT_ID');
    final skipReason = suppliedBanner.isEmpty
        ? null
        : 'real ad unit IDs supplied; the test fallback is not in play';

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('resolves Android test IDs by default', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(AppConfig.bannerAdUnitId, 'ca-app-pub-3940256099942544/6300978111');
      expect(AppConfig.interstitialAdUnitId, 'ca-app-pub-3940256099942544/1033173712');
      expect(AppConfig.rewardedAdUnitId, 'ca-app-pub-3940256099942544/5224354917');
    }, skip: skipReason);

    test('resolves iOS test IDs when the target platform is iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(AppConfig.bannerAdUnitId, 'ca-app-pub-3940256099942544/2934735716');
      expect(AppConfig.interstitialAdUnitId, 'ca-app-pub-3940256099942544/4411468910');
      expect(AppConfig.rewardedAdUnitId, 'ca-app-pub-3940256099942544/1712485313');
    }, skip: skipReason);

    test('never returns an empty ad unit ID while running in debug mode', () {
      expect(AppConfig.bannerAdUnitId, isNotEmpty);
      expect(AppConfig.interstitialAdUnitId, isNotEmpty);
      expect(AppConfig.rewardedAdUnitId, isNotEmpty);
    });
  });

  /// Exercises the `--dart-define` override that the group above cannot
  /// reach, without ever putting a real ad unit ID in source control.
  ///
  /// Run with the real IDs to actually assert something:
  ///   flutter test --dart-define-from-file=ad_config.json
  /// Without that file the defines are empty and these skip, so a plain
  /// `flutter test` (and CI, which has no ad_config.json) still passes.
  group('AppConfig ad unit ID resolution (--dart-define override)', () {
    const banner = String.fromEnvironment('BANNER_AD_UNIT_ID');
    const interstitial = String.fromEnvironment('INTERSTITIAL_AD_UNIT_ID');
    const rewarded = String.fromEnvironment('REWARDED_AD_UNIT_ID');

    /// Google's public test publisher. A real build resolving to one of
    /// these would silently serve test ads and earn nothing.
    const googleTestPublisher = '3940256099942544';

    test('a supplied banner ID wins over the debug test fallback', () {
      expect(AppConfig.bannerAdUnitId, banner);
      expect(AppConfig.bannerAdUnitId, isNot(contains(googleTestPublisher)));
    }, skip: banner.isEmpty ? 'no BANNER_AD_UNIT_ID supplied' : null);

    test('a supplied interstitial ID wins over the debug test fallback', () {
      expect(AppConfig.interstitialAdUnitId, interstitial);
      expect(
        AppConfig.interstitialAdUnitId,
        isNot(contains(googleTestPublisher)),
      );
    }, skip: interstitial.isEmpty ? 'no INTERSTITIAL_AD_UNIT_ID supplied' : null);

    test('a supplied rewarded ID wins over the debug test fallback', () {
      expect(AppConfig.rewardedAdUnitId, rewarded);
      expect(AppConfig.rewardedAdUnitId, isNot(contains(googleTestPublisher)));
    }, skip: rewarded.isEmpty ? 'no REWARDED_AD_UNIT_ID supplied' : null);

    test('the three units are distinct', () {
      // Built at runtime, not as a set literal: with no defines all three
      // are the empty string, and the analyzer rejects a *const* set whose
      // elements it can see are equal.
      final ids = <String>[banner, interstitial, rewarded];
      expect(ids.toSet().length, 3, reason: 'a unit ID is reused: $ids');
    }, skip: banner.isEmpty ? 'no ad_config.json supplied' : null);

    test('every supplied unit ID belongs to one publisher account', () {
      // A unit pasted from the wrong AdMob app is the classic copy/paste
      // slip, and it fails as "no fill" rather than as an error.
      final publishers = [banner, interstitial, rewarded]
          .map((id) => id.split('/').first)
          .toSet();
      expect(publishers.length, 1, reason: 'mixed AdMob accounts: $publishers');
    }, skip: banner.isEmpty ? 'no ad_config.json supplied' : null);
  });
}
