import 'ad_policy.dart';
import 'ad_service.dart';

/// Web/desktop fallback — `google_mobile_ads` doesn't support these
/// targets, so ads are simply absent rather than attempted.
AdService createAdService(AdPolicy policy) => const NoOpAdService();

Future<void> initializeAds() async {}
