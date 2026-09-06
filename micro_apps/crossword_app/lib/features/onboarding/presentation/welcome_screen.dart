import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/widgets/decorative_art.dart';
import '../../../core/widgets/primary_button.dart';

/// The very first screen a new player sees. Deliberately minimal: brand
/// mark, name, one line of value proposition, one action — nothing to
/// decide yet (spec §9). UI language here already follows the device
/// locale automatically via [LocaleController].
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      body: Container(
        // First impression of the app: a plain flat field behind a single
        // logo undersells it. The wash plus the cell motif reads as
        // "crossword" before a word has been shown.
        decoration: isLight
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.puzzleBackdropTopLight,
                    AppColors.puzzleBackdropBottomLight,
                  ],
                ),
              )
            : null,
        child: CellScatterBackdrop(
          color: theme.colorScheme.primary,
          count: 16,
          child: SafeArea(
            // Scrollable, with a minimum height of the viewport: the
            // Spacers still centre the mark when there is room, and the
            // screen scrolls instead of overflowing when there is not. At
            // a 1.5x accessibility text scale on a 4-inch phone the fixed
            // layout was too tall.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        children: [
                          const Spacer(flex: 3),
                          const _LogoMark(),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            l10n.onboardingTitle,
                            style: theme.textTheme.displayMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.onboardingSubtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(flex: 4),
                          PrimaryButton(
                            label: l10n.continueButton,
                            onPressed: () => context.go('/language'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(Icons.grid_3x3_rounded, color: Colors.white, size: 48),
    );
  }
}
