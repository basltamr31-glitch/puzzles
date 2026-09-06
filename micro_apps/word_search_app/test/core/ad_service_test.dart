import 'package:word_search_app/core/ads/ad_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoOpAdService', () {
    test('rewarded ads are always unavailable', () async {
      const service = NoOpAdService();
      expect(
        await service.showRewarded(placementId: 'word search_hint'),
        RewardedAdResult.unavailable,
      );
    });

    test('interstitials and banners never throw when nothing is configured', () async {
      const service = NoOpAdService();
      await service.maybeShowInterstitial(trigger: 'puzzle_completed');
      expect(service.buildBanner(placementId: 'x'), isA<Widget>());
    });
  });
}
