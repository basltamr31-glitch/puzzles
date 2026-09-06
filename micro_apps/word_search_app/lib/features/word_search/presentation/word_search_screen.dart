import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/ads/ad_policy.dart';
import '../../../core/ads/ad_service.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/audio/sound_service.dart';
import '../../../core/billing/premium_state.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/decorative_art.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../settings/settings_controller.dart';
import 'controllers/word_search_controller.dart';
import 'widgets/word_list_panel.dart';
import 'widgets/word_search_grid_view.dart';

/// The core gameplay screen: grid, word list, hint, and restart.
class WordSearchScreen extends ConsumerStatefulWidget {
  const WordSearchScreen({
    super.key,
    required this.assetPath,
    required this.siblingAssetPaths,
  });

  final String assetPath;
  final List<String> siblingAssetPaths;

  @override
  ConsumerState<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends ConsumerState<WordSearchScreen> {
  bool _completionHandled = false;

  /// Drives pinch-to-zoom on the grid. Pan is only enabled once zoomed in,
  /// so at 1x a vertical drag still scrolls the page instead of being
  /// swallowed by the viewer.
  final _zoomController = TransformationController();
  double _gridScale = 1;

  static const double _minScale = 1;
  static const double _maxScale = 3;

  @override
  void initState() {
    super.initState();
    _zoomController.addListener(_onZoomChanged);
  }

  @override
  void dispose() {
    _zoomController.removeListener(_onZoomChanged);
    _zoomController.dispose();
    super.dispose();
  }

  void _onZoomChanged() {
    final scale = _zoomController.value.getMaxScaleOnAxis();
    if ((scale - _gridScale).abs() > 0.01) {
      setState(() => _gridScale = scale);
    }
  }

  void _zoomBy(double factor) {
    _setZoom((_gridScale * factor).clamp(_minScale, _maxScale));
  }

  void _setZoom(double scale) {
    if (scale <= _minScale) {
      _zoomController.value = Matrix4.identity();
      return;
    }
    _zoomController.value = Matrix4.identity()
      ..scaleByDouble(scale, scale, scale, 1);
  }

  WordSearchController get _notifier =>
      ref.read(wordSearchControllerProvider(widget.assetPath).notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(wordSearchControllerProvider(widget.assetPath));

    ref.listen<WordSearchGameState>(
      wordSearchControllerProvider(widget.assetPath),
      (previous, next) {
        if (next.isCompleted && previous?.isCompleted != true) {
          _onPuzzleCompleted();
        }
      },
    );

    return AppScaffold(
      title: state.puzzle == null
          ? null
          : l10n.puzzleNumberLabel(
              (state.puzzle!.index + 1).toString().padLeft(3, '0'),
            ),
      padHorizontal: false,
      actions: [
        const _MusicToggleButton(),
        if (state.puzzle != null)
          IconButton(
            onPressed: () => _confirmRestart(context, l10n),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.restartPuzzleButton,
          ),
      ],
      body: Column(
        children: [
          Expanded(child: _buildContent(context, l10n, state)),
          _buildBanner(),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    WordSearchGameState state,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _buildContentForState(context, l10n, state),
    );
  }

  Widget _buildContentForState(
    BuildContext context,
    AppLocalizations l10n,
    WordSearchGameState state,
  ) {
    if (state.errorMessage != null) {
      return ErrorState(
        key: const ValueKey('error'),
        message: l10n.errorPuzzleMissing,
      );
    }
    if (state.isLoading || state.puzzle == null) {
      return const LoadingIndicator(key: ValueKey('loading'));
    }

    final puzzle = state.puzzle!;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      key: const ValueKey('content'),
      // A soft wash behind the play area, matching the puzzle-list banner
      // and the sibling apps' own backdrop treatment.
      decoration: isLight
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backdropTopLight,
                  AppColors.backdropBottomLight,
                ],
              ),
            )
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            WordListPanel(
              words: puzzle.words,
              foundWords: state.foundWords,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: isLight
                    ? const [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: ClipRect(
                child: InteractiveViewer(
                  transformationController: _zoomController,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  // Zoomed-in panning must not fight the selection drag,
                  // so panning is only claimed once zoomed in — at 1x
                  // every drag is a word selection.
                  panEnabled: _gridScale > _minScale,
                  child: WordSearchGridView(
                    puzzle: puzzle,
                    foundCells: state.foundCells,
                    liveSelection: state.liveSelection,
                    wrongSelectionCells: state.wrongSelectionCells,
                    onDragStart: (row, col) {
                      ref.read(hapticServiceProvider).play(HapticIntent.light);
                      _notifier.startDrag(row, col);
                    },
                    onDragUpdate: _notifier.updateDrag,
                    onDragEnd: () {
                      final before = ref
                          .read(wordSearchControllerProvider(widget.assetPath))
                          .foundWords
                          .length;
                      _notifier.endDrag();
                      final after = ref
                          .read(wordSearchControllerProvider(widget.assetPath))
                          .foundWords
                          .length;
                      ref
                          .read(hapticServiceProvider)
                          .play(
                            after > before
                                ? HapticIntent.medium
                                : HapticIntent.selection,
                          );
                      if (after > before) {
                        ref.read(soundServiceProvider).playKeyTap();
                      }
                    },
                  ),
                ),
              ),
            ),
            _buildZoomControls(l10n),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: l10n.hintButton,
              icon: Icons.lightbulb_outline_rounded,
              onPressed: state.isCompleted
                  ? null
                  : () => _handleHintTap(context, l10n),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  /// Explicit buttons alongside pinch-to-zoom: the bigger expert grids are
  /// hard to read on a phone, and a discoverable control beats relying on
  /// players guessing that the grid is pinchable.
  Widget _buildZoomControls(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _gridScale > _minScale ? () => _zoomBy(1 / 1.4) : null,
          icon: const Icon(Icons.zoom_out_rounded),
          tooltip: l10n.zoomOutButton,
        ),
        TextButton(
          onPressed: _gridScale > _minScale
              ? () => _setZoom(_minScale)
              : null,
          child: Text('${(_gridScale * 100).round()}%'),
        ),
        IconButton(
          onPressed: _gridScale < _maxScale ? () => _zoomBy(1.4) : null,
          icon: const Icon(Icons.zoom_in_rounded),
          tooltip: l10n.zoomInButton,
        ),
      ],
    );
  }

  Widget _buildBanner() {
    final isAdsRemoved = ref.watch(isAdsRemovedProvider);
    if (isAdsRemoved) return const SizedBox.shrink();
    final adService = ref.watch(adServiceProvider);
    return adService.buildBanner(placementId: 'word_search_bottom');
  }

  Future<void> _confirmRestart(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.restartConfirmTitle),
        content: Text(l10n.restartConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(hapticServiceProvider).play(HapticIntent.light);
      _completionHandled = false;
      await _notifier.restart();
    }
  }

  /// Premium (ads-removed) users get an instant free hint; everyone else
  /// hints via a user-initiated rewarded ad — the reward is only ever
  /// granted after [RewardedAdResult.rewarded], and an unavailable ad
  /// shows a friendly message without penalizing the player.
  Future<void> _handleHintTap(BuildContext context, AppLocalizations l10n) {
    final isAdsRemoved = ref.read(isAdsRemovedProvider);
    return isAdsRemoved
        ? _confirmFreeHint(context, l10n)
        : _confirmWatchAdForHint(context, l10n);
  }

  Future<void> _confirmFreeHint(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.hintConfirmTitle),
        content: Text(l10n.hintConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _notifier.revealHint();
      ref.read(hapticServiceProvider).play(HapticIntent.light);
    }
  }

  Future<void> _confirmWatchAdForHint(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.hintConfirmTitle),
        content: Text(l10n.watchAdForHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.hintButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(adServiceProvider)
        .showRewarded(placementId: 'word_search_hint');
    switch (result) {
      case RewardedAdResult.rewarded:
        await _notifier.revealHint();
        ref.read(hapticServiceProvider).play(HapticIntent.light);
        ref
            .read(analyticsServiceProvider)
            .logEvent(AnalyticsEvents.rewardedAdCompleted);
      case RewardedAdResult.unavailable:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.errorAdUnavailable)),
        );
      case RewardedAdResult.dismissedWithoutReward:
        break;
    }
  }

  Future<void> _onPuzzleCompleted() async {
    if (_completionHandled) return;
    _completionHandled = true;

    ref.read(hapticServiceProvider).play(HapticIntent.heavy);
    await ref.read(adPolicyProvider).recordPuzzleCompleted();
    await ref
        .read(adServiceProvider)
        .maybeShowInterstitial(trigger: 'puzzle_completed');

    if (!mounted) return;
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context);
    final currentIndex = widget.siblingAssetPaths.indexOf(widget.assetPath);
    final hasNext =
        currentIndex != -1 &&
        currentIndex + 1 < widget.siblingAssetPaths.length;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CompletionCelebration(
        l10n: l10n,
        onBackToPuzzles: () {
          Navigator.of(dialogContext).pop();
          context.pop();
        },
        onNextPuzzle: hasNext
            ? () {
                Navigator.of(dialogContext).pop();
                final next = widget.siblingAssetPaths[currentIndex + 1];
                context.pushReplacement(
                  '/play',
                  extra: {
                    'assetPath': next,
                    'siblingAssetPaths': widget.siblingAssetPaths,
                  },
                );
              }
            : null,
      ),
    );
  }
}

/// Mute/unmute background music without leaving the puzzle. Shares the
/// same persisted state as the Settings music picker, so the two never
/// disagree — this is a shortcut to that setting, not a second one.
class _MusicToggleButton extends ConsumerWidget {
  const _MusicToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPlaying =
        ref.watch(settingsControllerProvider).musicTrack != MusicTrack.off;

    return IconButton(
      onPressed: () {
        ref.read(hapticServiceProvider).play(HapticIntent.selection);
        ref.read(settingsControllerProvider.notifier).toggleMusic();
      },
      icon: Icon(
        isPlaying ? Icons.music_note_rounded : Icons.music_off_rounded,
      ),
      tooltip: isPlaying ? l10n.musicToggleOff : l10n.musicToggleOn,
    );
  }
}

/// The puzzle-completion moment gets an actual entrance animation instead
/// of a flat [AlertDialog]. The icon's elastic scale-in is a single
/// implicit [TweenAnimationBuilder], not a hand-rolled controller, because
/// that's all this moment needs.
class _CompletionCelebration extends StatelessWidget {
  const _CompletionCelebration({
    required this.l10n,
    required this.onBackToPuzzles,
    required this.onNextPuzzle,
  });

  final AppLocalizations l10n;
  final VoidCallback onBackToPuzzles;
  final VoidCallback? onNextPuzzle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: ExcludeSemantics(
                        child: CustomPaint(
                          painter: CelebrationBurstPainter(
                            color: AppColors.accent,
                            accent: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.accent, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.puzzleCompletedTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.puzzleCompletedMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (onNextPuzzle != null) ...[
              PrimaryButton(
                label: l10n.nextPuzzleButton,
                onPressed: onNextPuzzle,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SecondaryButton(
              label: l10n.backToPuzzlesButton,
              onPressed: onBackToPuzzles,
            ),
          ],
        ),
      ),
    );
  }
}
