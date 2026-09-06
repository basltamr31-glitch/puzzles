import 'package:crossword_app/app/app_config.dart';
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
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('resolves Android test IDs by default', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(AppConfig.bannerAdUnitId, 'ca-app-pub-3940256099942544/6300978111');
      expect(AppConfig.interstitialAdUnitId, 'ca-app-pub-3940256099942544/1033173712');
      expect(AppConfig.rewardedAdUnitId, 'ca-app-pub-3940256099942544/5224354917');
    });

    test('resolves iOS test IDs when the target platform is iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(AppConfig.bannerAdUnitId, 'ca-app-pub-3940256099942544/2934735716');
      expect(AppConfig.interstitialAdUnitId, 'ca-app-pub-3940256099942544/4411468910');
      expect(AppConfig.rewardedAdUnitId, 'ca-app-pub-3940256099942544/1712485313');
    });

    test('never returns an empty ad unit ID while running in debug mode', () {
      expect(AppConfig.bannerAdUnitId, isNotEmpty);
      expect(AppConfig.interstitialAdUnitId, isNotEmpty);
      expect(AppConfig.rewardedAdUnitId, isNotEmpty);
    });
  });
}
