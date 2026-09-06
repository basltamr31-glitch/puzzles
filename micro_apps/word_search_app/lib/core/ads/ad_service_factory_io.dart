import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_policy.dart';
import 'ad_service.dart';
import 'google_mobile_ads_service.dart';

AdService createAdService(AdPolicy policy) => GoogleMobileAdsService(policy);

Future<void> initializeAds() async {
  // The apps are declared 13+ in Play Console, so the Families policy
  // does not apply and neither `tagForChildDirectedTreatment` nor
  // `tagForUnderAgeOfConsent` is set — both would force non-personalized
  // ads for every user and cut revenue for no compliance benefit here.
  //
  // `MaxAdContentRating.g` is kept anyway: the privacy policy promises
  // ads "rated suitable for a general audience", and a casual puzzle game
  // has nothing to gain from mature ad inventory. Raising it to `pg` or
  // `t` is a one-line revenue-vs-brand-safety change if that is ever
  // wanted — but the policy sentence has to move with it.
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
  );
  await MobileAds.instance.initialize();
}
