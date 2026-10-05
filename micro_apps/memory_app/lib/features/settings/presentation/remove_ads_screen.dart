import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/promo/partner_unlock_controller.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';

/// "Remove Ads" is the companion-app route: install
/// [AppConfig.partnerAppName] and the banner ads go away.
///
/// **Banners only, by design.** Hints and extra lives are paid for with a
/// rewarded video for every player, and interstitials keep showing — that
/// is the product decision, and the copy says so up front so nobody
/// installs expecting every ad to stop. There is deliberately no paid
/// button here: the download *is* the way to remove banners.
class RemoveAdsScreen extends ConsumerWidget {
  const RemoveAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bannersHidden = ref.watch(areBannersHiddenProvider);

    return AppScaffold(
      title: l10n.removeAdsTitle,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              size: 72,
              color: AppColors.accent,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (bannersHidden)
              Text(
                l10n.partnerUnlockActive(AppConfig.partnerAppName),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              )
            else ...[
              Text(
                l10n.partnerUnlockDescription(AppConfig.partnerAppName),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: l10n.partnerUnlockButton(AppConfig.partnerAppShortName),
                onPressed: () => _openStore(context, l10n),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Opens the companion app's Play listing. `market:` hands straight to
  /// the Play app; the https URL is the fallback for a device without
  /// it. A failure is reported rather than swallowed — a tap that
  /// silently does nothing reads as a broken app.
  ///
  /// The unlock itself is granted on return: the app re-checks for the
  /// companion package on `resumed`.
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
