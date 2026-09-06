import 'dart:async';

import 'package:sudoku_app/app/app_config.dart';
import 'package:sudoku_app/core/billing/billing_service.dart';
import 'package:sudoku_app/core/billing/premium_state.dart';
import 'package:sudoku_app/core/storage/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockBillingService extends Mock implements BillingService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockBillingService billing;
  late StreamController<String> updatesController;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferencesStorageService.create();

    billing = _MockBillingService();
    updatesController = StreamController<String>.broadcast();
    when(() => billing.purchaseUpdates).thenAnswer((_) => updatesController.stream);
    when(billing.dispose).thenAnswer((_) {});

    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        billingServiceProvider.overrideWithValue(billing),
      ],
    );
    // addTearDown runs LIFO: disposing the container first cancels the
    // StreamProvider's subscription to updatesController, so closing the
    // controller afterward completes immediately instead of hanging while
    // it waits for a listener that's never cancelled.
    addTearDown(updatesController.close);
    addTearDown(container.dispose);
  });

  test('starts as not purchased when nothing is stored', () {
    expect(container.read(premiumStateProvider), isFalse);
  });

  test('a successful purchase removes ads', () async {
    when(() => billing.purchase(AppConfig.removeAdsProductId))
        .thenAnswer((_) async => PurchaseResult.success);

    final result = await container
        .read(premiumStateProvider.notifier)
        .purchaseRemoveAds(AppConfig.removeAdsProductId);

    expect(result, PurchaseResult.success);
    expect(container.read(premiumStateProvider), isTrue);
  });

  test('a failed purchase leaves ads in place', () async {
    when(() => billing.purchase(AppConfig.removeAdsProductId))
        .thenAnswer((_) async => PurchaseResult.error);

    final result = await container
        .read(premiumStateProvider.notifier)
        .purchaseRemoveAds(AppConfig.removeAdsProductId);

    expect(result, PurchaseResult.error);
    expect(container.read(premiumStateProvider), isFalse);
  });

  test('a pending purchase does not remove ads yet', () async {
    when(() => billing.purchase(AppConfig.removeAdsProductId))
        .thenAnswer((_) async => PurchaseResult.pending);

    final result = await container
        .read(premiumStateProvider.notifier)
        .purchaseRemoveAds(AppConfig.removeAdsProductId);

    expect(result, PurchaseResult.pending);
    expect(container.read(premiumStateProvider), isFalse);
  });

  test('restore finds a previous purchase', () async {
    when(billing.restorePurchases).thenAnswer((_) async => PurchaseResult.alreadyOwned);
    when(() => billing.isPurchased(AppConfig.removeAdsProductId))
        .thenAnswer((_) async => true);

    final result = await container
        .read(premiumStateProvider.notifier)
        .restorePurchases(AppConfig.removeAdsProductId);

    expect(result, PurchaseResult.alreadyOwned);
    expect(container.read(premiumStateProvider), isTrue);
  });

  test('restore finding nothing leaves ads in place', () async {
    when(billing.restorePurchases).thenAnswer((_) async => PurchaseResult.error);
    when(() => billing.isPurchased(AppConfig.removeAdsProductId))
        .thenAnswer((_) async => false);

    final result = await container
        .read(premiumStateProvider.notifier)
        .restorePurchases(AppConfig.removeAdsProductId);

    expect(result, PurchaseResult.error);
    expect(container.read(premiumStateProvider), isFalse);
  });

  test('a platform-replayed purchase update removes ads without an explicit call', () async {
    // Read once so PremiumStateController.build() subscribes to purchaseUpdates.
    expect(container.read(premiumStateProvider), isFalse);

    updatesController.add(AppConfig.removeAdsProductId);
    // The subscription's setAdsRemoved(true) call awaits a storage write
    // before flipping state — give that chain a real event-loop turn.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(premiumStateProvider), isTrue);
  });

  test('a purchase update for a different product ID is ignored', () async {
    expect(container.read(premiumStateProvider), isFalse);

    updatesController.add('some_other_product');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(premiumStateProvider), isFalse);
  });
}
