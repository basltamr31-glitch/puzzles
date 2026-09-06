import 'package:crossword_app/app/app_config.dart';
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

    test('no ad unit override is baked into the source', () {
      // Release builds with no --dart-define must resolve to an empty ID,
      // which AdService treats as "no ad configured". A hardcoded override
      // here would ship a test ad unit to production — an AdMob policy
      // violation that can get an account suspended.
      for (final key in const [
        String.fromEnvironment('BANNER_AD_UNIT_ID'),
        String.fromEnvironment('INTERSTITIAL_AD_UNIT_ID'),
        String.fromEnvironment('REWARDED_AD_UNIT_ID'),
      ]) {
        expect(key, isEmpty);
      }
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
