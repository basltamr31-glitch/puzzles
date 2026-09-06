import 'package:sudoku_app/app/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monetization guardrails.
///
/// Per-platform ad unit *resolution* is already covered by
/// `test/app/app_config_test.dart`; this file asserts the things that
/// would silently cost money or break paying customers if they changed.
void main() {
  group('ad unit guardrails', () {
    test('the three placements use distinct ad units', () {
      final ids = {
        AppConfig.bannerAdUnitId,
        AppConfig.interstitialAdUnitId,
        AppConfig.rewardedAdUnitId,
      };
      expect(ids.length, 3,
          reason: 'banner/interstitial/rewarded must not share a unit ID');
    });

    test('no ad unit ID enters from anywhere but a define or the test units', () {
      // The real guardrail: an ID must be traceable to something
      // sanctioned. Either a `--dart-define` supplied it, or it is one of
      // Google's public test units used as the debug fallback. A third
      // value could only have been hardcoded into the source, which would
      // ship a live unit to a debug build (or a test unit to production) —
      // an AdMob policy violation that can get an account suspended.
      //
      // Deliberately *not* asserting the defines are empty: supplying them
      // via `--dart-define-from-file=ad_config.json` is the sanctioned
      // release path, and a guard that fails on the correct build is a
      // guard nobody can run.
      const googleTestPublisher = '3940256099942544';
      const placements = <String, String>{
        'banner': String.fromEnvironment('BANNER_AD_UNIT_ID'),
        'interstitial': String.fromEnvironment('INTERSTITIAL_AD_UNIT_ID'),
        'rewarded': String.fromEnvironment('REWARDED_AD_UNIT_ID'),
      };
      final resolved = <String, String>{
        'banner': AppConfig.bannerAdUnitId,
        'interstitial': AppConfig.interstitialAdUnitId,
        'rewarded': AppConfig.rewardedAdUnitId,
      };

      placements.forEach((name, supplied) {
        if (supplied.isNotEmpty) {
          expect(resolved[name], supplied, reason: '$name ignored its define');
        } else {
          expect(
            resolved[name],
            anyOf(isEmpty, contains(googleTestPublisher)),
            reason: '$name resolved to an ID that came from neither a '
                'define nor the test units — check AppConfig for a hardcoded '
                'value',
          );
        }
      });
    });
  });

  group('monetization config', () {
    test('the Remove Ads product ID is stable', () {
      // Must match the in-app product created in Play Console; changing it
      // silently breaks purchase and restore for existing buyers.
      expect(AppConfig.removeAdsProductId, 'remove_ads');
    });

    test('interstitials are spaced out rather than shown every puzzle', () {
      expect(AppConfig.interstitialMinPuzzlesBetween, greaterThanOrEqualTo(2));
    });
  });
}
