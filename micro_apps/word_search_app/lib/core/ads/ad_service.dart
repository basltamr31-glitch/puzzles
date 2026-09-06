import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../consent/consent_service.dart';
import 'ad_policy.dart';
import 'ad_service_factory.dart';

/// Result of requesting a rewarded ad, so callers can react without the
/// ad SDK's types leaking into feature code.
enum RewardedAdResult { rewarded, dismissedWithoutReward, unavailable }

/// Abstraction over all advertising concerns.
///
/// No screen or feature talks to an ad SDK directly. This interface is the
/// only surface they see. [GoogleMobileAdsService] is the real
/// implementation on Android/iOS; [NoOpAdService] backs everything else
/// (web/desktop, and premium is handled by [AdPolicy] rather than here).
abstract class AdService {
  /// Builds a banner ad widget for the given placement, or an empty
  /// [SizedBox] if none is available / the user is premium. Must never
  /// throw and must never cover gameplay-critical UI — placement is the
  /// caller's responsibility, sizing behavior is this service's.
  Widget buildBanner({required String placementId});

  /// Shows an interstitial if the current [AdPolicy] allows it at this
  /// natural break point. Safe to call unconditionally; it is a no-op for
  /// premium users or when policy/availability disallows it.
  Future<void> maybeShowInterstitial({required String trigger});

  /// Shows a rewarded ad. The caller must only invoke this from a user
  /// action (e.g. tapping "Watch ad for a hint"), never automatically.
  Future<RewardedAdResult> showRewarded({required String placementId});
}

class NoOpAdService implements AdService {
  const NoOpAdService();

  @override
  Widget buildBanner({required String placementId}) => const SizedBox.shrink();

  @override
  Future<void> maybeShowInterstitial({required String trigger}) async {}

  @override
  Future<RewardedAdResult> showRewarded({required String placementId}) async {
    return RewardedAdResult.unavailable;
  }
}

/// Wraps an [AdService] so nothing reaches an ad SDK before the user's
/// consent choice exists.
///
/// Google's UMP guidance is explicit that consent must be gathered
/// *before* the Mobile Ads SDK is initialized, and under GDPR an ad
/// request made before a lawful basis exists is not fixable after the
/// fact. Gating here rather than at each call site means a new screen
/// cannot forget to do it.
class ConsentGatedAdService implements AdService {
  const ConsentGatedAdService(this._inner, this._ready);

  final AdService _inner;
  final Future<void> _ready;

  @override
  Widget buildBanner({required String placementId}) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        // Empty, not a placeholder box: the banner already collapses to
        // nothing while loading, so waiting for consent looks identical
        // and never reserves dead space.
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        return _inner.buildBanner(placementId: placementId);
      },
    );
  }

  @override
  Future<void> maybeShowInterstitial({required String trigger}) async {
    await _ready;
    return _inner.maybeShowInterstitial(trigger: trigger);
  }

  @override
  Future<RewardedAdResult> showRewarded({required String placementId}) async {
    await _ready;
    return _inner.showRewarded(placementId: placementId);
  }
}

/// Consent first, then the ads SDK — in that order, always.
///
/// Errors are swallowed deliberately: if the consent flow or SDK startup
/// fails, this future must still complete or the rewarded-ad hint would
/// hang forever on a tap. A failed consent flow leaves the SDK's stored
/// consent absent, and Google serves non-personalized ads in that state,
/// which is the safe direction to fail in.
final adsReadyProvider = FutureProvider<void>((ref) async {
  try {
    await ref.watch(consentRequestProvider.future);
    await initializeAds();
  } catch (error) {
    debugPrint('Ads could not be initialized after consent: $error');
  }
});

final adServiceProvider = Provider<AdService>((ref) {
  return ConsentGatedAdService(
    createAdService(ref.watch(adPolicyProvider)),
    ref.watch(adsReadyProvider.future),
  );
});
