import 'dart:async';

import 'package:sudoku_app/app/app_config.dart';
import 'package:sudoku_app/core/analytics/analytics_events.dart';
import 'package:sudoku_app/core/analytics/analytics_service.dart';
import 'package:sudoku_app/core/billing/billing_service.dart';
import 'package:sudoku_app/core/billing/premium_state.dart';
import 'package:sudoku_app/core/localization/locale_controller.dart';
import 'package:sudoku_app/core/storage/local_storage_service.dart';
import 'package:sudoku_app/features/onboarding/onboarding_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_analytics_service.dart';

class _MockBillingService extends Mock implements BillingService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAnalyticsService analytics;
  late LocalStorageService storage;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await SharedPreferencesStorageService.create();
    analytics = FakeAnalyticsService();

    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
  });

  group('OnboardingController', () {
    test('logs first_launch exactly once on a fresh install', () {
      container.read(onboardingControllerProvider);

      expect(analytics.countOf(AnalyticsEvents.firstLaunch), 1);
    });

    test('does not log first_launch for a returning user', () async {
      await storage.setBool('onboarding_complete', true);

      container.read(onboardingControllerProvider);

      expect(analytics.hasEvent(AnalyticsEvents.firstLaunch), isFalse);
    });
  });

  test('LocaleController.setLanguage logs ui_language_selected', () async {
    await container.read(localeControllerProvider.notifier).setLanguage('ar');

    expect(analytics.countOf(AnalyticsEvents.uiLanguageSelected), 1);
    expect(analytics.events.last.parameters['language_code'], 'ar');
  });

  group('PremiumStateController purchase analytics', () {
    late _MockBillingService billing;

    setUp(() {
      billing = _MockBillingService();
      when(() => billing.purchaseUpdates).thenAnswer((_) => const Stream.empty());
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          analyticsServiceProvider.overrideWithValue(analytics),
          billingServiceProvider.overrideWithValue(billing),
        ],
      );
      addTearDown(container.dispose);
    });

    test('a successful purchase logs started then completed', () async {
      when(() => billing.purchase(AppConfig.removeAdsProductId))
          .thenAnswer((_) async => PurchaseResult.success);

      await container
          .read(premiumStateProvider.notifier)
          .purchaseRemoveAds(AppConfig.removeAdsProductId);

      expect(
        analytics.events.map((e) => e.name),
        [AnalyticsEvents.removeAdsPurchaseStarted, AnalyticsEvents.removeAdsPurchaseCompleted],
      );
    });

    test('a failed purchase logs started but never completed', () async {
      when(() => billing.purchase(AppConfig.removeAdsProductId))
          .thenAnswer((_) async => PurchaseResult.error);

      await container
          .read(premiumStateProvider.notifier)
          .purchaseRemoveAds(AppConfig.removeAdsProductId);

      expect(analytics.countOf(AnalyticsEvents.removeAdsPurchaseStarted), 1);
      expect(analytics.hasEvent(AnalyticsEvents.removeAdsPurchaseCompleted), isFalse);
    });
  });
}
