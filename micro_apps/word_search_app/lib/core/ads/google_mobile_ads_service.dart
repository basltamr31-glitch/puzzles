import 'dart:async';
import 'dart:math';

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
///
/// ## Why the rewarded ad is preloaded
///
/// A rewarded video is a large payload. Fetching one only once the player
/// has already tapped "watch an ad for a hint" puts the whole download on
/// the critical path of a button press, and on mobile data it routinely
/// lost the race against [_loadTimeout] — which the player experienced as
/// "no ad is available right now" on a perfectly good connection. So one
/// ad is kept warm from startup and refilled the moment it is spent, and
/// the tap shows what is already in hand.
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

  /// Google expires a cached rewarded ad roughly an hour after it is
  /// fetched, and showing an expired one fails. Discarding at 50 minutes
  /// keeps a margin instead of racing that deadline — a preloaded ad that
  /// went stale in the player's pocket must look like "no ad yet" and
  /// trigger a fresh fetch, never like a broken hint button.
  static const _rewardedTtl = Duration(minutes: 50);

  static const _retryBaseDelay = Duration(seconds: 2);
  static const _retryMaxDelay = Duration(minutes: 2);

  /// Background retries give up after this many failures so a device that
  /// is simply offline stops asking. A player tap always resets the count
  /// — see [_takeRewarded] — so giving up in the background never means
  /// giving up on someone who just asked for a hint.
  static const _maxRetries = 5;

  RewardedAd? _rewarded;
  DateTime? _rewardedLoadedAt;
  Future<void>? _rewardedLoad;
  int _rewardedAttempt = 0;
  Timer? _rewardedRetry;
  bool _disposed = false;

  @override
  void prewarm() => _fillRewardedCache();

  @override
  void dispose() {
    _disposed = true;
    _rewardedRetry?.cancel();
    _rewardedRetry = null;
    _rewarded?.dispose();
    _rewarded = null;
    _rewardedLoadedAt = null;
  }

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

    try {
      await ad.show();
    } catch (error) {
      debugPrint('Interstitial failed to show: $error');
      ad.dispose();
      return;
    }
    await completer.future.timeout(_showTimeout, onTimeout: () {});

    if (didShow) {
      await _policy.recordInterstitialShown();
    }
  }

  @override
  Future<RewardedAdResult> showRewarded({required String placementId}) async {
    final ad = await _takeRewarded();
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

    try {
      await ad.show(onUserEarnedReward: (ad, reward) => earnedReward = true);
    } catch (error) {
      debugPrint('Rewarded ad failed to show: $error');
      ad.dispose();
      _fillRewardedCache();
      return RewardedAdResult.unavailable;
    }

    // Once the SDK has said the reward was earned it is owed, whatever
    // happens to the dismissal callback afterwards — a reward that was
    // earned is never downgraded by a timeout.
    final result = await completer.future.timeout(
      _showTimeout,
      onTimeout: () => _resultFor(earnedReward),
    );

    // Refill straight away so a second hint is as instant as the first.
    _rewardedAttempt = 0;
    _fillRewardedCache();
    return result;
  }

  static RewardedAdResult _resultFor(bool earnedReward) =>
      earnedReward ? RewardedAdResult.rewarded : RewardedAdResult.unavailable;

  bool get _isRewardedStale {
    final loadedAt = _rewardedLoadedAt;
    return loadedAt == null ||
        DateTime.now().difference(loadedAt) > _rewardedTtl;
  }

  /// Hands over the warm ad if there is a usable one, otherwise waits on a
  /// fetch — the old behavior, now only the fallback rather than the norm.
  Future<RewardedAd?> _takeRewarded() async {
    final cached = _rewarded;
    if (cached != null && !_isRewardedStale) {
      _rewarded = null;
      _rewardedLoadedAt = null;
      return cached;
    }
    if (cached != null) {
      // Expired in the player's pocket. Binning it here is what stops a
      // stale ad from failing at show time.
      cached.dispose();
      _rewarded = null;
      _rewardedLoadedAt = null;
    }

    // Somebody is actively asking, so forget however many times the
    // background gave up.
    _rewardedAttempt = 0;
    _fillRewardedCache();

    final pending = _rewardedLoad;
    if (pending != null) {
      await pending.timeout(_loadTimeout, onTimeout: () {});
    }

    // A load that timed out here is still running and will populate the
    // cache shortly, so the next tap is instant even though this one
    // came up empty.
    final loaded = _rewarded;
    _rewarded = null;
    _rewardedLoadedAt = null;
    return loaded;
  }

  void _fillRewardedCache() {
    if (_disposed) return;
    if (_rewardedLoad != null) return;
    if (_rewarded != null && !_isRewardedStale) return;

    final adUnitId = AppConfig.rewardedAdUnitId;
    if (adUnitId.isEmpty) return;

    _rewardedRetry?.cancel();
    _rewardedRetry = null;

    _rewardedLoad = _fetchRewarded(adUnitId).then((ad) {
      _rewardedLoad = null;
      if (_disposed) {
        ad?.dispose();
        return;
      }
      if (ad == null) {
        _scheduleRewardedRetry();
        return;
      }
      _rewardedAttempt = 0;
      _rewarded?.dispose();
      _rewarded = ad;
      _rewardedLoadedAt = DateTime.now();
    });
  }

  void _scheduleRewardedRetry() {
    if (_disposed || _rewardedAttempt >= _maxRetries) return;
    final delay = _backoffDelay(_rewardedAttempt);
    _rewardedAttempt++;
    _rewardedRetry?.cancel();
    _rewardedRetry = Timer(delay, _fillRewardedCache);
  }

  /// Doubling delay, capped. Retrying a failed ad request in a tight loop
  /// is how an app burns battery and gets throttled for it.
  static Duration _backoffDelay(int attempt) {
    final milliseconds = _retryBaseDelay.inMilliseconds * (1 << attempt);
    return Duration(
      milliseconds: min(milliseconds, _retryMaxDelay.inMilliseconds),
    );
  }

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

  Future<RewardedAd?> _fetchRewarded(String adUnitId) {
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
///
/// Retries on failure, because the first attempt lands at cold start when
/// the network is least likely to be ready: without a retry a single
/// early failure left the slot empty for the entire session.
class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget({required this.adUnitId});

  final String adUnitId;

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  static const _retryBaseDelay = Duration(seconds: 2);
  static const _retryMaxDelay = Duration(minutes: 2);
  static const _maxRetries = 5;

  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int _attempt = 0;
  Timer? _retry;

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
          _attempt = 0;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // Clear the field first: `dispose()` must not reach an ad the
          // listener has already disposed.
          if (identical(_bannerAd, ad)) _bannerAd = null;
          if (!mounted) return;
          _scheduleRetry();
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  void _scheduleRetry() {
    if (_attempt >= _maxRetries) return;
    final milliseconds = _retryBaseDelay.inMilliseconds * (1 << _attempt);
    _attempt++;
    _retry?.cancel();
    _retry = Timer(
      Duration(milliseconds: min(milliseconds, _retryMaxDelay.inMilliseconds)),
      () {
        if (mounted) _load();
      },
    );
  }

  @override
  void dispose() {
    _retry?.cancel();
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
