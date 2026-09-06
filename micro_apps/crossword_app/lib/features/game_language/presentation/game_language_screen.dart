import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_config.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../shared/models/game_locale.dart';
import '../game_language_controller.dart';

/// Step 2 of onboarding: pick the puzzle content language (spec §11/§12).
/// Only languages with real puzzle content are listed — see
/// [AppConfig.supportedGameLanguageCodes].
class GameLanguageScreen extends ConsumerWidget {
  const GameLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = ref.watch(gameLanguageControllerProvider);

    return AppScaffold(
      showBackButton: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.chooseGameLanguageTitle,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.chooseGameLanguageSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: ListView.separated(
              itemCount: AppConfig.supportedGameLanguageCodes.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final locale = GameLocale.byCode(
                  AppConfig.supportedGameLanguageCodes[index],
                );
                final isSelected = selected == locale.code;
                return AppCard(
                  onTap: () async {
                    ref
                        .read(hapticServiceProvider)
                        .play(HapticIntent.selection);
                    await ref
                        .read(gameLanguageControllerProvider.notifier)
                        .select(locale.code);
                    if (context.mounted) context.go('/difficulty');
                  },
                  child: Row(
                    children: [
                      Text(
                        locale.flagEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          locale.nativeName,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
