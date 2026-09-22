import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/billing/premium_state.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/promo/partner_unlock_controller.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';

/// The one-time "Remove Ads" purchase screen (spec §22). Purchase state
/// flows entirely through [premiumStateProvider], which the ad decisions
/// in [AdPolicy] also read — so a successful purchase here immediately
/// silences ads everywhere without this screen knowing anything about ads.
class RemoveAdsScreen extends ConsumerWidget {
  const RemoveAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isAdsRemoved = ref.watch(isAdsRemovedProvider);

    return AppScaffold(
      title: l10n.removeAdsTitle,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 72, color: AppColors.accent),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.removeAdsDescription,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (isAdsRemoved)
              Text(
                l10n.removeAdsAlreadyOwned,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              )
            else
              Consumer(
                builder: (context, ref, _) {
                  // Prefer the store's own localized price so the button is
                  // correct in every currency; the bundled string is only a
                  // fallback for when the store can't be reached.
                  final price = ref.watch(removeAdsPriceProvider).value;
                  return PrimaryButton(
                    label: price == null
                        ? l10n.removeAdsPurchaseButton
                        : l10n.removeAdsPurchaseButtonWithPrice(price),
                    onPressed: () => _purchase(context, ref, l10n),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xxl),
            const _PartnerUnlockSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(premiumStateProvider.notifier)
        .purchaseRemoveAds(AppConfig.removeAdsProductId);

    final message = switch (result) {
      PurchaseResult.success || PurchaseResult.alreadyOwned => l10n.removeAdsAlreadyOwned,
      PurchaseResult.pending => l10n.purchasePending,
      PurchaseResult.cancelled => l10n.purchaseCancelled,
      PurchaseResult.storeUnavailable => l10n.purchaseStoreUnavailable,
      PurchaseResult.productUnavailable => l10n.purchaseProductUnavailable,
      PurchaseResult.error => l10n.purchaseError,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The free route to banner-free play: install the companion app.
///
/// Shown alongside the purchase rather than instead of it, and left
/// visible to someone who has already bought Remove Ads — they are not
/// rival offers. The purchase is the whole product; this removes
/// **banners only**, which is why it reads from [partnerUnlockProvider]
/// and never touches the premium flag.
class _PartnerUnlockSection extends ConsumerWidget {
  const _PartnerUnlockSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (ref.watch(partnerUnlockProvider)) {
      return Text(
        l10n.partnerUnlockActive(AppConfig.partnerAppName),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.partnerUnlockTitle,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.partnerUnlockDescription(AppConfig.partnerAppName),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        SecondaryButton(
          label: l10n.partnerUnlockButton(AppConfig.partnerAppShortName),
          onPressed: () => _openStore(context, l10n),
        ),
      ],
    );
  }

  /// Opens the companion app's Play listing. `market:` hands straight to
  /// the Play app; the https URL is the fallback for a device without
  /// it. A failure is reported rather than swallowed — a tap that
  /// silently does nothing reads as a broken app.
  Future<void> _openStore(BuildContext context, AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    for (final url in [
      AppConfig.partnerAppMarketUrl,
      AppConfig.partnerAppStoreUrl,
    ]) {
      try {
        if (await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
          return;
        }
      } catch (_) {
        // Try the next one.
      }
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
  }
}
