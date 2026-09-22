import 'package:sudoku_app/core/ads/ad_policy.dart';
import 'package:sudoku_app/core/billing/billing_service.dart';
import 'package:sudoku_app/core/billing/premium_state.dart';
import 'package:sudoku_app/core/promo/partner_app_service.dart';
import 'package:sudoku_app/core/promo/partner_unlock_controller.dart';
import 'package:sudoku_app/core/storage/local_storage_service.dart';
import 'package:sudoku_app/core/storage/storage_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The companion-app unlock removes **banners only**. It is one flag away
/// from being indistinguishable from the Remove Ads purchase, and if it
/// ever merges with it the app silently gives away interstitial-free
/// play, free hints and free extra lives to anyone who installs a free
/// app. These tests are what stop that.
class _FakePartnerApp implements PartnerAppService {
  _FakePartnerApp(this.installed);

  bool installed;
  int calls = 0;

  @override
  Future<bool> isInstalled() async {
    calls++;
    return installed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, _FakePartnerApp)> harness({
    bool installed = false,
    Map<String, Object> seed = const {},
  }) async {
    SharedPreferences.setMockInitialValues(seed);
    final storage = await SharedPreferencesStorageService.create();
    final partner = _FakePartnerApp(installed);
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        partnerAppServiceProvider.overrideWithValue(partner),
        // The real billing service reaches for the Play plugin, which is
        // not there under `flutter test`. Premium state itself is covered
        // by premium_state_test; what matters here is only that the two
        // flags stay independent.
        billingServiceProvider.overrideWithValue(const NoOpBillingService()),
      ],
    );
    addTearDown(container.dispose);
    return (container, partner);
  }

  test('no unlock when the companion app is not installed', () async {
    final (container, _) = await harness();
    expect(await container.read(partnerUnlockProvider.notifier).refresh(),
        isFalse);
    expect(container.read(partnerUnlockProvider), isFalse);
    expect(container.read(areBannersHiddenProvider), isFalse);
  });

  test('installing the companion app hides banners', () async {
    final (container, _) = await harness(installed: true);
    expect(
        await container.read(partnerUnlockProvider.notifier).refresh(), isTrue);
    expect(container.read(partnerUnlockProvider), isTrue);
    expect(container.read(areBannersHiddenProvider), isTrue);
  });

  test('the unlock does NOT make the player premium', () async {
    final (container, _) = await harness(installed: true);
    await container.read(partnerUnlockProvider.notifier).refresh();

    // Banners: gone. Everything the purchase buys: untouched.
    expect(container.read(areBannersHiddenProvider), isTrue);
    expect(container.read(isAdsRemovedProvider), isFalse,
        reason: 'a cross-promotion must never read as a purchase');

    // Interstitials still show — AdPolicy asks about the premium flag,
    // and that is still false.
    final policy = container.read(adPolicyProvider);
    await policy.recordPuzzleCompleted();
    await policy.recordPuzzleCompleted();
    expect(policy.shouldShowInterstitial(trigger: 'puzzle_completed'), isTrue);
  });

  test('a purchase hides banners on its own, with no companion app',
      () async {
    final (container, _) = await harness();
    await container.read(premiumStateProvider.notifier).setAdsRemoved(true);
    expect(container.read(areBannersHiddenProvider), isTrue);
    expect(container.read(partnerUnlockProvider), isFalse);
  });

  test('the unlock survives a restart', () async {
    final (container, _) = await harness(
      seed: {StorageKeys.bannersUnlockedByPartner: true},
    );
    expect(container.read(partnerUnlockProvider), isTrue);
  });

  test('once earned it is never taken back, even if the app is removed',
      () async {
    final (container, partner) = await harness(installed: true);
    await container.read(partnerUnlockProvider.notifier).refresh();
    expect(container.read(partnerUnlockProvider), isTrue);

    // The player uninstalled the companion app. Revoking here would
    // punish the honest majority to deter a minority, over a banner.
    partner.installed = false;
    await container.read(partnerUnlockProvider.notifier).refresh();
    expect(container.read(partnerUnlockProvider), isTrue);
  });

  test('an unlocked player stops being asked', () async {
    final (container, partner) = await harness(installed: true);
    await container.read(partnerUnlockProvider.notifier).refresh();
    final after = partner.calls;
    await container.read(partnerUnlockProvider.notifier).refresh();
    expect(partner.calls, after,
        reason: 'refresh should short-circuit once unlocked');
  });

  test('a service that fails simply means no unlock', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferencesStorageService.create();
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        partnerAppServiceProvider
            .overrideWithValue(const NoOpPartnerAppService()),
        billingServiceProvider.overrideWithValue(const NoOpBillingService()),
      ],
    );
    addTearDown(container.dispose);
    expect(await container.read(partnerUnlockProvider.notifier).refresh(),
        isFalse);
  });
}
