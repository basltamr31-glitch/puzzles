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
import '../../../core/promo/partner_unlock_controller.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/board_zoom_controls.dart';
import '../../../core/widgets/decorative_art.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../rewards/domain/solve_reward.dart';
import '../../rewards/presentation/widgets/lives_indicator.dart';
import '../../rewards/presentation/widgets/out_of_lives_dialog.dart';
import '../../rewards/presentation/widgets/reward_summary.dart';
import '../../rewards/rewards_controller.dart';
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
  bool _failureHandled = false;

  /// What the solve earned, captured the moment the puzzle was finished
  /// so the celebration can show it once the interstitial is out of the
  /// way.
  SolveReward? _reward;

  /// Drives pinch-to-zoom on the grid. Panning the *viewer* is only
  /// enabled once zoomed in, so at 1x every drag on the board is a word
  /// selection rather than a pan.
  final _zoomController = TransformationController();
  double _gridScale = 1;

  /// Measures the viewer so [_applyZoom] can work out where the middle of
  /// the board is. Sits on the [ClipRect], whose size is the viewport's.
  final _viewerKey = GlobalKey();

  /// The quarter of the board the zoom buttons are aimed at, or null when
  /// the board is unzoomed or the player has panned it by hand.
  BoardQuadrant? _quadrant;

  /// The last transform this screen set itself, used by [_onZoomChanged]
  /// to tell our own zooming apart from a pinch or a pan.
  Matrix4? _appliedMatrix;

  /// True while a finger is down anywhere on the board.
  ///
  /// While it is, the page stops being scrollable. The grid's own
  /// recognizer is written to out-race the scroll view's (see
  /// `_GridPanGestureRecognizer`), but *winning a race* is a weaker
  /// guarantee than there being no competitor at all: this takes the
  /// scroll view out of the gesture arena for the duration of the touch,
  /// so a vertical drag on the board cannot be stolen no matter how the
  /// arena resolves on a given device.
  ///
  /// Set from a [Listener], not a gesture recognizer, because a Listener
  /// sees raw pointer events without joining the arena — it cannot itself
  /// be beaten to the gesture it is trying to protect.
  bool _boardTouched = false;

  void _setBoardTouched(bool touched) {
    if (_boardTouched == touched) return;
    setState(() => _boardTouched = touched);
  }

  static const double _minScale = 1;
  static const double _maxScale = 3;

  /// Where a quarter jumps to when it is picked from an unzoomed board.
  /// 2x is exactly "this quarter fills the frame".
  static const double _quadrantScale = 2;

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
    final matrix = _zoomController.value;
    final scale = matrix.getMaxScaleOnAxis();
    // A pinch or a pan moves the view off whichever quarter the picker is
    // pointing at, so drop the highlight instead of leaving it claiming
    // something that is no longer true.
    final quadrant = matrix == _appliedMatrix ? _quadrant : null;
    if ((scale - _gridScale).abs() <= 0.01 && quadrant == _quadrant) return;
    setState(() {
      _gridScale = scale;
      _quadrant = quadrant;
    });
  }

  /// The viewport, which is also the board: [InteractiveViewer] sizes its
  /// child to the viewer, so the two are the same box.
  Size? get _viewportSize {
    final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) return null;
    return box.size;
  }

  /// Aims the magnifier at [quadrant]. Picking a quarter of an unzoomed
  /// board zooms straight in on it — arming a button and showing nothing
  /// would read as a dead tap.
  void _selectQuadrant(BoardQuadrant quadrant) {
    _applyZoom(
      _gridScale > _minScale ? _gridScale : _quadrantScale,
      quadrant,
    );
  }

  void _zoomBy(double factor) {
    _applyZoom((_gridScale * factor).clamp(_minScale, _maxScale), _quadrant);
  }

  /// Scales the board to [scale] with [quadrant] centred in the frame.
  /// See [boardZoomMatrix] for why the translation matters.
  void _applyZoom(double scale, BoardQuadrant? quadrant) {
    final size = _viewportSize;
    if (scale <= _minScale || size == null) {
      _setMatrix(Matrix4.identity(), null);
      return;
    }

    final Offset focal;
    if (quadrant != null) {
      focal = Offset(
        size.width * quadrant.fractionX,
        size.height * quadrant.fractionY,
      );
    } else {
      // No quarter aimed at — the player panned here by hand, so hold
      // whatever they parked in the middle and only change the
      // magnification around it.
      final current = _zoomController.value;
      final currentScale = current.getMaxScaleOnAxis();
      final translation = current.getTranslation();
      focal = Offset(
        (size.width / 2 - translation.x) / currentScale,
        (size.height / 2 - translation.y) / currentScale,
      );
    }

    _setMatrix(
      boardZoomMatrix(viewport: size, scale: scale, focal: focal),
      quadrant,
    );
  }

  /// Records the transform as ours before handing it to the controller,
  /// so the listener it wakes up can recognise it.
  void _setMatrix(Matrix4 matrix, BoardQuadrant? quadrant) {
    setState(() {
      _appliedMatrix = matrix;
      _quadrant = quadrant;
      _zoomController.value = matrix;
      _gridScale = matrix.getMaxScaleOnAxis();
    });
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
        // Also fires when a failed puzzle is reopened, which is
        // deliberate: the board is locked either way, and a locked
        // board with no explanation on screen is just a game that has
        // stopped responding.
        if (next.isFailed && !_failureHandled) {
          _onOutOfLives();
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
        physics: _boardTouched ? const NeverScrollableScrollPhysics() : null,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            _MistakesRow(mistakes: state.mistakes),
            const SizedBox(height: AppSpacing.sm),
            WordListPanel(words: puzzle.words, foundWords: state.foundWords),
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
              child: Listener(
                // Raw pointer events: this fires on touch-down, before any
                // recognizer has resolved, which is what makes the scroll
                // lock above take effect for the very gesture it protects.
                onPointerDown: (_) => _setBoardTouched(true),
                onPointerUp: (_) => _setBoardTouched(false),
                onPointerCancel: (_) => _setBoardTouched(false),
                child: ClipRect(
                  key: _viewerKey,
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
                        ref
                            .read(hapticServiceProvider)
                            .play(HapticIntent.light);
                        _notifier.startDrag(row, col);
                      },
                      onDragUpdate: _notifier.updateDrag,
                      onDragEnd: () {
                        final before = ref
                            .read(
                              wordSearchControllerProvider(widget.assetPath),
                            )
                            .foundWords
                            .length;
                        _notifier.endDrag();
                        final after = ref
                            .read(
                              wordSearchControllerProvider(widget.assetPath),
                            )
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
            ),
            _buildZoomControls(),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: l10n.hintButton,
              icon: Icons.lightbulb_outline_rounded,
              onPressed: state.isCompleted || state.isFailed
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
  ///
  /// The quarter picker beside them decides *where* the buttons magnify.
  /// Without it they could only ever enlarge one fixed corner of the
  /// board, leaving the other three reachable only by panning.
  Widget _buildZoomControls() {
    return BoardZoomControls(
      scale: _gridScale,
      minScale: _minScale,
      maxScale: _maxScale,
      selectedQuadrant: _quadrant,
      onQuadrantSelected: _selectQuadrant,
      onZoomIn: () => _zoomBy(1.4),
      onZoomOut: () => _zoomBy(1 / 1.4),
      onReset: () => _applyZoom(_minScale, null),
    );
  }

  Widget _buildBanner() {
    // Either route to banner-free play: the purchase, or the companion
    // app. One provider knows both so a banner cannot honour one and
    // forget the other.
    if (ref.watch(areBannersHiddenProvider)) return const SizedBox.shrink();
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

  /// Locks the run down and tells the player why. Restart is offered
  /// right here rather than sending them back to the list first:
  /// wanting another go is the overwhelmingly likely next move.
  void _onOutOfLives() {
    if (_failureHandled) return;
    _failureHandled = true;

    ref.read(hapticServiceProvider).play(HapticIntent.heavy);
    // Read before the dialog is built: a player who has removed ads gets
    // the life without watching anything, the same trade the hint button
    // already makes for them.
    final isAdsRemoved = ref.read(isAdsRemovedProvider);
    final canRevive = _notifier.canEarnBonusLife;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => OutOfLivesDialog(
        extraLifeCostsAd: !isAdsRemoved,
        onExtraLife: canRevive
            ? () {
                Navigator.of(dialogContext).pop();
                _handleExtraLife(isAdsRemoved);
              }
            : null,
        onRestart: () {
          Navigator.of(dialogContext).pop();
          _failureHandled = false;
          _notifier.restart();
        },
        onBackToPuzzles: () {
          Navigator.of(dialogContext).pop();
          context.pop();
        },
      ),
    );
  }

  /// Grants the extra life, after an ad where one is owed.
  ///
  /// The life is only ever handed over on [RewardedAdResult.rewarded].
  /// An ad that fails to load costs the player nothing and says so — and
  /// crucially puts the dialog back, because dismissing it would leave
  /// them staring at a locked board with no way forward.
  Future<void> _handleExtraLife(bool isAdsRemoved) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!isAdsRemoved) {
      final result = await ref
          .read(adServiceProvider)
          .showRewarded(placementId: 'extra_life');
      if (result != RewardedAdResult.rewarded) {
        if (result == RewardedAdResult.unavailable) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.errorAdUnavailable)),
          );
        }
        _failureHandled = false;
        if (mounted) _onOutOfLives();
        return;
      }
      ref
          .read(analyticsServiceProvider)
          .logEvent(AnalyticsEvents.rewardedAdCompleted);
    }

    await _notifier.grantExtraLife();
    if (!mounted) return;
    // Cleared last: the board is playable again, so the next genuine
    // failure has to be able to raise this dialog afresh.
    _failureHandled = false;
    ref.read(hapticServiceProvider).play(HapticIntent.light);
  }

  Future<void> _onPuzzleCompleted() async {
    if (_completionHandled) return;
    _completionHandled = true;

    // Banked before the interstitial: an ad failing to load, or the
    // player killing the app while one is on screen, must not be able
    // to cost them the solve they just earned.
    final state = ref.read(wordSearchControllerProvider(widget.assetPath));
    final puzzleId = state.puzzle?.id;
    if (puzzleId != null) {
      _reward = ref
          .read(rewardsControllerProvider.notifier)
          .recordSolve(
            puzzleId: puzzleId,
            mistakes: state.mistakes,
            hintsUsed: state.hintsUsed,
          );
    }

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
        reward: _reward,
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

/// The mistake budget, above the board rather than in the app bar:
/// three hearts alongside two icon buttons and a puzzle number is more
/// than a 320dp app bar can hold, and the number the player is watching
/// should not be the first thing to get squeezed.
class _MistakesRow extends StatelessWidget {
  const _MistakesRow({required this.mistakes});

  final int mistakes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.mistakesLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        LivesIndicator(mistakes: mistakes),
      ],
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
    required this.reward,
    required this.onBackToPuzzles,
    required this.onNextPuzzle,
  });

  final AppLocalizations l10n;

  /// Null only if the puzzle finished before its id was known, which
  /// should not happen — the celebration degrades to the plain
  /// congratulation rather than throwing on the player's best moment.
  final SolveReward? reward;

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
            if (reward != null)
              RewardSummary(reward: reward!)
            else
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
