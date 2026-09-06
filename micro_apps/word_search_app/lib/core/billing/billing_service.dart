/// Outcome of a purchase attempt, kept SDK-agnostic.
/// Outcome of a purchase attempt, kept SDK-agnostic.
///
/// [storeUnavailable] and [productUnavailable] used to be folded into
/// [error]. They are the two failures that actually happen while setting
/// monetization up, and they need different actions from the developer —
/// "this build cannot reach Play" versus "Play has no such product" — so
/// collapsing them into "please try again" made the flow untestable.
enum PurchaseResult {
  success,
  alreadyOwned,
  pending,
  cancelled,

  /// The billing service itself is unreachable: no Play Store on the
  /// device, not signed in, or the build was not installed through Play.
  storeUnavailable,

  /// Play answered, but has no active product with this ID for this
  /// package — not created, not activated, or the app has never been
  /// uploaded to a track.
  productUnavailable,

  /// A genuine failure: the store reported an error, the purchase flow
  /// refused to start, or it never came back.
  error,
}

/// Abstraction over Google Play Billing / StoreKit for the single
/// "Remove Ads" non-consumable product. No screen touches
/// `in_app_purchase` directly — [InAppPurchaseBillingService] is the real
/// implementation on Android/iOS; [NoOpBillingService] backs everything
/// else and lets the app be built and tested against a stable interface.
abstract class BillingService {
  Future<bool> isPurchased(String productId);

  /// The store's own localized price string for [productId] (e.g. "$1.00",
  /// "0,89 €"), or null if the store is unreachable or the product isn't
  /// configured yet.
  ///
  /// The real charged amount lives in Play Console / App Store Connect, not
  /// in this app. Displaying the store's string is what keeps the UI honest
  /// across every currency and region instead of promising one hardcoded
  /// figure that only happens to be right in one country.
  Future<String?> localizedPrice(String productId);

  Future<PurchaseResult> purchase(String productId);

  Future<PurchaseResult> restorePurchases();

  /// Emits a product ID whenever a purchase for it is confirmed —
  /// including ones the platform store replays on startup without any
  /// explicit purchase/restore call (e.g. an unacknowledged purchase from
  /// a previous session). [PremiumStateController] listens to this so
  /// premium state stays correct even outside the user-initiated flows.
  Stream<String> get purchaseUpdates;

  void dispose();
}

class NoOpBillingService implements BillingService {
  const NoOpBillingService();

  @override
  Future<bool> isPurchased(String productId) async => false;

  @override
  Future<String?> localizedPrice(String productId) async => null;

  @override
  Future<PurchaseResult> purchase(String productId) async =>
      PurchaseResult.error;

  @override
  Future<PurchaseResult> restorePurchases() async => PurchaseResult.error;

  @override
  Stream<String> get purchaseUpdates => const Stream.empty();

  @override
  void dispose() {}
}
