import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../storage/local_storage_service.dart';
import '../storage/storage_keys.dart';
import 'billing_service.dart';
import 'billing_service_factory.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  final service = createBillingService();
  ref.onDispose(service.dispose);
  return service;
});

/// The single source of truth every ad/monetization decision reads from.
///
/// Backed by local storage so the premium flag survives restarts, and is
/// kept in sync with [BillingService] three ways: explicit purchase,
/// explicit restore, and passively via a direct subscription to
/// [BillingService.purchaseUpdates] — which catches purchases the
/// platform store replays on its own (e.g. an unacknowledged purchase
/// from a session that was killed mid-flow).
class PremiumStateController extends Notifier<bool> {
  StreamSubscription<String>? _purchaseUpdatesSubscription;

  @override
  bool build() {
    final storage = ref.watch(localStorageServiceProvider);
    final billing = ref.watch(billingServiceProvider);

    _purchaseUpdatesSubscription?.cancel();
    _purchaseUpdatesSubscription = billing.purchaseUpdates.listen((productId) {
      if (productId == AppConfig.removeAdsProductId) {
        setAdsRemoved(true);
      }
    });
    ref.onDispose(() => _purchaseUpdatesSubscription?.cancel());

    return storage.getBool(StorageKeys.isAdsRemoved) ?? false;
  }

  Future<void> setAdsRemoved(bool value) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setBool(StorageKeys.isAdsRemoved, value);
    state = value;
  }

  Future<PurchaseResult> purchaseRemoveAds(String productId) async {
    final analytics = ref.read(analyticsServiceProvider);
    analytics.logEvent(AnalyticsEvents.removeAdsPurchaseStarted);

    final billing = ref.read(billingServiceProvider);
    final result = await billing.purchase(productId);
    if (result == PurchaseResult.success || result == PurchaseResult.alreadyOwned) {
      await setAdsRemoved(true);
      analytics.logEvent(AnalyticsEvents.removeAdsPurchaseCompleted);
    }
    return result;
  }

  Future<PurchaseResult> restorePurchases(String productId) async {
    final billing = ref.read(billingServiceProvider);
    final result = await billing.restorePurchases();
    final isPurchased = await billing.isPurchased(productId);
    if (isPurchased) {
      await setAdsRemoved(true);
    }
    return result;
  }
}

final premiumStateProvider = NotifierProvider<PremiumStateController, bool>(
  PremiumStateController.new,
);

/// Convenience read-only accessor used by ad decisions.
final isAdsRemovedProvider = Provider<bool>(
  (ref) => ref.watch(premiumStateProvider),
);

/// The store's localized price for the Remove Ads product, or null while
/// loading / when the store is unreachable. Callers fall back to the
/// bundled price string in that case.
final removeAdsPriceProvider = FutureProvider<String?>((ref) {
  return ref.watch(billingServiceProvider).localizedPrice(
        AppConfig.removeAdsProductId,
      );
});
