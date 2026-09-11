import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/app_config.dart';
import 'ad_policy.dart';
import 'ad_service.dart';

/// The real, `google_mobile_ads`-backed implementation of [AdService].
///
/// Only ever constructed on Android/iOS — see `ad_service_factory.dart`,
/// which picks this on mobile and [NoOpAdService] everywhere else (the
/// plugin doesn't support web/desktop). Every entry point here is
/// defensive: a missing ad unit ID, a failed load, or a failed show all
/// resolve to "no ad" rather than throwing, per spec §21/§30.
class GoogleMobileAdsService implements AdService {
  GoogleMobileAdsService(this._policy);

  final AdPolicy _policy;

  static const _loadTimeout = Duration(seconds: 8);

  /// Deliberately far longer than any ad. This is a stuck-callback
  /// backstop, *not* a limit on how long the player may watch: at 30
  /// seconds it expired while a normal rewarded video was still playing,
  /// so the hint was reported unavailable and never granted no matter how
  /// many ads were watched to the end.
  static const _showTimeout = Duration(minutes: 5);

  @override
  Widget buildBanner({required String placementId}) {
    return _BannerAdWidget(adUnitId: AppConfig.bannerAdUnitId);
  }

  @override
  Future<void> maybeShowInterstitial({required String trigger}) async {
    if (!_policy.shouldShowInterstitial(trigger: trigger)) return;

    final adUnitId = AppConfig.interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    final ad = await _loadInterstitial(adUnitId);
    if (ad == null) return;

    var didShow = false;
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        didShow = true;
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
    );

    await ad.show();
    await completer.future.timeout(_showTimeout, onTimeout: () {});

    if (didShow) {
      await _policy.recordInterstitialShown();
    }
  }

  @override
  Future<RewardedAdResult> showRewarded({required String placementId}) async {
    final adUnitId = AppConfig.rewardedAdUnitId;
    if (adUnitId.isEmpty) return RewardedAdResult.unavailable;

    final ad = await _loadRewarded(adUnitId);
    if (ad == null) return RewardedAdResult.unavailable;

    var earnedReward = false;
    final completer = Completer<RewardedAdResult>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(
            earnedReward
                ? RewardedAdResult.rewarded
                : RewardedAdResult.dismissedWithoutReward,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) {
          completer.complete(_resultFor(earnedReward));
        }
      },
    );

    await ad.show(onUserEarnedReward: (ad, reward) => earnedReward = true);

    // Once the SDK has said the reward was earned it is owed, whatever
    // happens to the dismissal callback afterwards — a reward that was
    // earned is never downgraded by a timeout.
    return completer.future.timeout(
      _showTimeout,
      onTimeout: () => _resultFor(earnedReward),
    );
  }

  static RewardedAdResult _resultFor(bool earnedReward) =>
      earnedReward ? RewardedAdResult.rewarded : RewardedAdResult.unavailable;

  Future<InterstitialAd?> _loadInterstitial(String adUnitId) {
    final completer = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future.timeout(_loadTimeout, onTimeout: () => null);
  }

  Future<RewardedAd?> _loadRewarded(String adUnitId) {
    final completer = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future.timeout(_loadTimeout, onTimeout: () => null);
  }
}

/// Loads a banner lazily and renders nothing until it succeeds, so a slow
/// or failed load never leaves a broken placeholder in the layout —
/// spec §19: the layout must adapt, never show a blank ad box.
class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget({required this.adUnitId});

  final String adUnitId;

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (widget.adUnitId.isEmpty) return;
    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
