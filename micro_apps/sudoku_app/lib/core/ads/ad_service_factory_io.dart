import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_policy.dart';
import 'ad_service.dart';
import 'google_mobile_ads_service.dart';

AdService createAdService(AdPolicy policy) => GoogleMobileAdsService(policy);

Future<void> initializeAds() async {
  await MobileAds.instance.initialize();
}
