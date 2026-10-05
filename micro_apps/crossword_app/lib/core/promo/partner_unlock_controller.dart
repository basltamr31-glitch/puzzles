import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../billing/premium_state.dart';
import '../storage/local_storage_service.dart';
import '../storage/storage_keys.dart';
import 'partner_app_service.dart';
import 'partner_app_service_factory.dart';

final partnerAppServiceProvider = Provider<PartnerAppService>(
  (ref) => createPartnerAppService(),
);

/// Banner-free play earned by installing the companion app.
///
/// **This is not premium.** It is kept rigorously separate from
/// [isAdsRemovedProvider] because the two grant different things: the
/// purchase is the full product, while this covers **banners only**.
/// Interstitials still show, hints and extra lives are still paid for
/// with a rewarded video, and a legacy purchase still means more —
/// folding this into the premium flag would hand all of that away for
/// free and make a cross-promotion indistinguishable from a sale.
class PartnerUnlockController extends Notifier<bool> {
  @override
  bool build() {
    final storage = ref.watch(localStorageServiceProvider);
    return storage.getBool(StorageKeys.bannersUnlockedByPartner) ?? false;
  }

  /// Looks for the companion app and grants the unlock if it is there.
  ///
  /// **Sticky once earned, never revoked.** Re-checking on every launch
  /// and taking the unlock back would punish the honest majority — people
  /// who installed the app, did what was asked, and later tidied up their
  /// phone — to deter a minority who would install-unlock-uninstall. The
  /// thing being protected is a banner, and that trade is not worth the
  /// support mail. So this only ever moves false -> true.
  ///
  /// Returns the unlock state, so a caller can tell "already had it" and
  /// "just earned it" apart from "still not installed".
  Future<bool> refresh() async {
    if (state) return true;

    final installed = await ref.read(partnerAppServiceProvider).isInstalled();
    if (!installed) return false;

    await ref
        .read(localStorageServiceProvider)
        .setBool(StorageKeys.bannersUnlockedByPartner, true);
    ref
        .read(analyticsServiceProvider)
        .logEvent(AnalyticsEvents.partnerUnlockGranted);
    state = true;
    return true;
  }
}

final partnerUnlockProvider =
    NotifierProvider<PartnerUnlockController, bool>(
      PartnerUnlockController.new,
    );

/// The single question every banner slot asks.
///
/// Two independent routes to a banner-free screen — the purchase and the
/// companion-app unlock — and exactly one place that knows both, so a new
/// banner cannot honour one and forget the other.
final areBannersHiddenProvider = Provider<bool>(
  (ref) => ref.watch(isAdsRemovedProvider) || ref.watch(partnerUnlockProvider),
);
