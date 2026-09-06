import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../billing/premium_state.dart';
import '../storage/local_storage_service.dart';
import '../storage/storage_keys.dart';

/// Centralized frequency policy for interstitial ads.
///
/// This is the single place that decides "is now a sustainable moment to
/// show an interstitial", so no screen has to reimplement that judgment
/// call. Kept deliberately conservative per spec: natural breaks only,
/// never after every tiny interaction.
class AdPolicy {
  AdPolicy(this._storage, this._isAdsRemoved);

  final LocalStorageService _storage;
  final bool Function() _isAdsRemoved;

  bool shouldShowInterstitial({required String trigger}) {
    if (_isAdsRemoved()) return false;
    if (trigger != 'puzzle_completed') return false;

    final sinceLast =
        _storage.getInt(StorageKeys.puzzlesCompletedSinceInterstitial) ?? 0;
    return sinceLast + 1 >= AppConfig.interstitialMinPuzzlesBetween;
  }

  Future<void> recordPuzzleCompleted() async {
    final sinceLast =
        _storage.getInt(StorageKeys.puzzlesCompletedSinceInterstitial) ?? 0;
    await _storage.setInt(
      StorageKeys.puzzlesCompletedSinceInterstitial,
      sinceLast + 1,
    );
  }

  Future<void> recordInterstitialShown() async {
    await _storage.setInt(StorageKeys.puzzlesCompletedSinceInterstitial, 0);
  }
}

final adPolicyProvider = Provider<AdPolicy>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final isAdsRemoved = ref.watch(isAdsRemovedProvider);
  return AdPolicy(storage, () => isAdsRemoved);
});
