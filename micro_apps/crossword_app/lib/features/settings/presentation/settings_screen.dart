import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../core/app_info/app_info_provider.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/billing/billing_service.dart';
import '../../../core/billing/premium_state.dart';
import '../../../core/consent/consent_service.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/notifications/reminder_controller.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../shared/models/game_locale.dart';
import '../../game_language/game_language_controller.dart';
import '../settings_controller.dart';

/// The single settings surface for the whole app (spec §25) — deliberately
/// grouped and short: language, gameplay feel, monetization, legal/about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final uiLocale = ref.watch(localeControllerProvider);
    final gameLanguage =
        ref.watch(gameLanguageControllerProvider) ??
        AppConfig.fallbackUILanguageCode;
    final isAdsRemoved = ref.watch(isAdsRemovedProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final consentService = ref.watch(consentServiceProvider);
    final consentAsync = ref.watch(consentRequestProvider);

    return AppScaffold(
      title: l10n.settingsTitle,
      padHorizontal: false,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _SettingsSection(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsAppearance,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: const Icon(
                              Icons.brightness_auto_rounded,
                              size: 16,
                            ),
                            label: Text(l10n.themeModeSystem),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: const Icon(
                              Icons.light_mode_rounded,
                              size: 16,
                            ),
                            label: Text(l10n.themeModeLight),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: const Icon(Icons.dark_mode_rounded, size: 16),
                            label: Text(l10n.themeModeDark),
                          ),
                        ],
                        selected: {themeMode},
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                        ),
                        onSelectionChanged: (selected) => ref
                            .read(themeModeControllerProvider.notifier)
                            .select(selected.first),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                title: l10n.settingsUiLanguage,
                trailing: Text(
                  '${GameLocale.byCode(uiLocale.languageCode).flagEmoji} '
                  '${GameLocale.byCode(uiLocale.languageCode).nativeName}',
                ),
                onTap: () => _pickLanguage(
                  context: context,
                  codes: AppConfig.supportedUILanguageCodes,
                  onSelected: (code) => ref
                      .read(localeControllerProvider.notifier)
                      .setLanguage(code),
                ),
              ),
              _SettingsTile(
                icon: Icons.extension_rounded,
                title: l10n.settingsGameLanguage,
                trailing: Text(
                  '${GameLocale.byCode(gameLanguage).flagEmoji} '
                  '${GameLocale.byCode(gameLanguage).nativeName}',
                ),
                onTap: () => _pickLanguage(
                  context: context,
                  codes: AppConfig.supportedGameLanguageCodes,
                  onSelected: (code) => ref
                      .read(gameLanguageControllerProvider.notifier)
                      .select(code),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            children: [
              _SettingsSwitchTile(
                icon: Icons.volume_up_rounded,
                title: l10n.settingsSound,
                value: settings.soundEnabled,
                onChanged: (value) => ref
                    .read(settingsControllerProvider.notifier)
                    .setSoundEnabled(value),
              ),
              _SettingsSwitchTile(
                icon: Icons.vibration_rounded,
                title: l10n.settingsVibration,
                value: settings.vibrationEnabled,
                onChanged: (value) => ref
                    .read(settingsControllerProvider.notifier)
                    .setVibrationEnabled(value),
              ),
              _SettingsTile(
                icon: Icons.music_note_rounded,
                title: l10n.settingsMusic,
                trailing: Text(_musicTrackLabel(l10n, settings.musicTrack)),
                onTap: () => _pickMusicTrack(context, ref, l10n),
              ),
              _SettingsTile(
                icon: Icons.play_circle_outline_rounded,
                title: l10n.settingsTestSound,
                onTap: () => _testSound(context, ref, l10n),
              ),
              _SettingsSwitchTile(
                icon: Icons.notifications_active_rounded,
                title: l10n.settingsReminders,
                value: ref.watch(reminderControllerProvider),
                onChanged: (value) => _setReminders(context, ref, l10n, value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            children: [
              if (!isAdsRemoved)
                _SettingsTile(
                  icon: Icons.block_rounded,
                  title: l10n.settingsRemoveAds,
                  onTap: () => context.push('/remove-ads'),
                ),
              _SettingsTile(
                icon: Icons.restore_rounded,
                title: l10n.settingsRestorePurchases,
                onTap: () => _restorePurchases(context, ref, l10n),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSection(
            children: [
              if (consentAsync.hasValue &&
                  consentService.isPrivacyOptionsFormAvailable)
                _SettingsTile(
                  icon: Icons.shield_rounded,
                  title: l10n.settingsAdPrivacyOptions,
                  onTap: consentService.showPrivacyOptionsForm,
                ),
              _SettingsTile(
                icon: Icons.privacy_tip_rounded,
                title: l10n.settingsPrivacy,
                onTap: () => context.push('/privacy'),
              ),
              _SettingsTile(
                icon: Icons.info_rounded,
                title: l10n.settingsAbout,
                trailing: Text(
                  l10n.settingsVersion(packageInfoAsync.value?.version ?? '—'),
                ),
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.code_rounded,
                title: l10n.settingsDeveloper,
                trailing: Text(l10n.settingsDeveloperName),
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              l10n.settingsCopyright,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// Turning reminders on requires OS permission. If the player declines,
  /// the switch stays off and says so, rather than sitting in an "on"
  /// state that would never actually deliver anything.
  Future<void> _setReminders(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool value,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final granted = await ref
        .read(reminderControllerProvider.notifier)
        .setEnabled(value);
    if (value && !granted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.remindersPermissionDenied)));
    }
  }

  /// Plays the tap sound on demand and reports the outcome. Android audio
  /// failures are usually silent rather than thrown somewhere visible, so
  /// without this an inaudible sound is indistinguishable from a broken
  /// one and there is nothing to act on.
  Future<void> _testSound(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref.read(soundServiceProvider).testKeyTap();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null ? l10n.soundTestOk : l10n.soundTestFailed(error),
          ),
          duration: Duration(seconds: error == null ? 2 : 8),
        ),
      );
  }

  String _musicTrackLabel(AppLocalizations l10n, MusicTrack track) {
    return switch (track) {
      MusicTrack.off => l10n.musicTrackOff,
      MusicTrack.calm => l10n.musicTrackCalm,
      MusicTrack.gentle => l10n.musicTrackGentle,
      MusicTrack.uplifting => l10n.musicTrackUplifting,
      MusicTrack.focus => l10n.musicTrackFocus,
      MusicTrack.bright => l10n.musicTrackBright,
      MusicTrack.night => l10n.musicTrackNight,
    };
  }

  Future<void> _pickMusicTrack(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final current = ref.read(settingsControllerProvider).musicTrack;
    final selected = await showModalBottomSheet<MusicTrack>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          // Scrollable, not a bare Column: a modal sheet is capped at 9/16
          // of the screen, and a fixed Column of options overflows once the
          // list grows (or the user has large text scaling). That overflow
          // is what made opening this picker throw after the track count
          // went from four to seven.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: MusicTrack.values.map((track) {
                return ListTile(
                  leading: Icon(
                    track == MusicTrack.off
                        ? Icons.music_off_rounded
                        : Icons.music_note_rounded,
                  ),
                  title: Text(_musicTrackLabel(l10n, track)),
                  trailing: track == current
                      ? Icon(
                          Icons.check_rounded,
                          color: Theme.of(sheetContext).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(track),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
    if (selected != null) {
      await ref
          .read(settingsControllerProvider.notifier)
          .setMusicTrack(selected);
    }
  }

  Future<void> _pickLanguage({
    required BuildContext context,
    required List<String> codes,
    required Future<void> Function(String code) onSelected,
  }) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          // Same overflow hazard as the music picker — six languages fit
          // today, but not at large text scale, and not once a seventh is
          // added.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: codes.map((code) {
                final locale = GameLocale.byCode(code);
                return ListTile(
                  leading: Text(
                    locale.flagEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(locale.nativeName),
                  onTap: () => Navigator.of(sheetContext).pop(code),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
    if (selected != null) {
      await onSelected(selected);
    }
  }

  Future<void> _restorePurchases(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(premiumStateProvider.notifier)
        .restorePurchases(AppConfig.removeAdsProductId);
    final succeeded =
        result == PurchaseResult.success ||
        result == PurchaseResult.alreadyOwned;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          succeeded ? l10n.restoreSuccess : l10n.restoreNothingFound,
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(icon),
      title: Text(title),
      trailing:
          trailing ??
          (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      visualDensity: VisualDensity.compact,
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
