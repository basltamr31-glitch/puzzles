import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'billing_service.dart';

/// The real, `in_app_purchase`-backed implementation of [BillingService]
/// for the "Remove Ads" non-consumable product (spec §22).
///
/// `in_app_purchase` is inherently stream-based: a purchase or restore
/// doesn't return its own result directly, it triggers events on
/// [InAppPurchase.purchaseStream] that this class correlates back to the
/// in-flight request. The stream subscription is created once, in the
/// constructor, so purchases the platform store replays automatically on
/// app start (e.g. an unacknowledged purchase from a killed session) are
/// still picked up even without an explicit user action.
class InAppPurchaseBillingService implements BillingService {
  InAppPurchaseBillingService() {
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {},
    );
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _purchaseUpdatesController = StreamController<String>.broadcast();
  final Set<String> _confirmedProductIds = {};

  String? _pendingProductId;
  Completer<PurchaseResult>? _pendingCompleter;

  @override
  Stream<String> get purchaseUpdates => _purchaseUpdatesController.stream;

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _completePending(purchase.productID, PurchaseResult.pending);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _confirmedProductIds.add(purchase.productID);
          _purchaseUpdatesController.add(purchase.productID);
          _completePending(
            purchase.productID,
            purchase.status == PurchaseStatus.restored
                ? PurchaseResult.alreadyOwned
                : PurchaseResult.success,
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        case PurchaseStatus.error:
          _completePending(purchase.productID, PurchaseResult.error);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        case PurchaseStatus.canceled:
          _completePending(purchase.productID, PurchaseResult.cancelled);
      }
    }
  }

  void _completePending(String productId, PurchaseResult result) {
    if (productId != _pendingProductId) return;
    final completer = _pendingCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  @override
  Future<bool> isPurchased(String productId) async {
    return _confirmedProductIds.contains(productId);
  }

  @override
  Future<String?> localizedPrice(String productId) async {
    try {
      if (!await _iap.isAvailable()) return null;
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return null;
      return response.productDetails.first.price;
    } catch (_) {
      // Price display is cosmetic; never let it break the purchase screen.
      return null;
    }
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    if (!await _iap.isAvailable()) return PurchaseResult.storeUnavailable;

    final response = await _iap.queryProductDetails({productId});
    // `notFoundIDs` is Play telling us the product does not exist for this
    // package — the single most likely reason a first purchase attempt
    // fails, and previously indistinguishable from a network blip.
    if (response.productDetails.isEmpty ||
        response.notFoundIDs.contains(productId)) {
      return PurchaseResult.productUnavailable;
    }

    final completer = Completer<PurchaseResult>();
    _pendingProductId = productId;
    _pendingCompleter = completer;

    final started = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: response.productDetails.first),
    );
    if (!started) {
      _pendingProductId = null;
      _pendingCompleter = null;
      return PurchaseResult.error;
    }

    try {
      return await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => PurchaseResult.error,
      );
    } finally {
      _pendingProductId = null;
      _pendingCompleter = null;
    }
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    if (!await _iap.isAvailable()) return PurchaseResult.error;

    // restorePurchases() only triggers the platform to start emitting
    // restored purchases on purchaseStream — it doesn't itself await
    // completion. A short grace window is the documented workaround for
    // giving the store a moment to deliver those events before we report
    // a result to the user.
    await _iap.restorePurchases();
    await Future<void>.delayed(const Duration(seconds: 2));

    return _confirmedProductIds.isNotEmpty ? PurchaseResult.alreadyOwned : PurchaseResult.error;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _purchaseUpdatesController.close();
  }
}
