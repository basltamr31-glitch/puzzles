import '../../../core/promo/partner_unlock_controller.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/utils/motion.dart';
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
import '../domain/crossword_models.dart';
import 'controllers/crossword_controller.dart';
import 'input/crossword_text_input.dart';
import 'widgets/clue_bar.dart';
import 'widgets/clue_category_icon.dart';
import 'widgets/crossword_grid_view.dart';

/// The core gameplay screen: grid, current clue, hint/check controls, and
/// a hidden text field that requests the OS software keyboard so typing
/// works correctly for every game language without a hand-built keyboard.
class CrosswordScreen extends ConsumerStatefulWidget {
  const CrosswordScreen({
    super.key,
    required this.assetPath,
    required this.siblingAssetPaths,
  });

  final String assetPath;
  final List<String> siblingAssetPaths;

  @override
  ConsumerState<CrosswordScreen> createState() => _CrosswordScreenState();
}

class _CrosswordScreenState extends ConsumerState<CrosswordScreen>
    with SingleTickerProviderStateMixin {
  final _focusNode = FocusNode();
  final _textController = TextEditingController();
  bool _completionHandled = false;
  bool _failureHandled = false;

  /// What the solve earned, captured the moment the puzzle was finished
  /// so the celebration can show it once the interstitial is out of the
  /// way.
  SolveReward? _reward;

  /// Drives pinch-to-zoom on the grid. Pan is only enabled once zoomed in,
  /// so at 1x a vertical drag still scrolls the page instead of being
  /// swallowed by the viewer.
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

  static const double _minScale = 1;
  static const double _maxScale = 4;

  /// Where a quarter jumps to when it is picked from an unzoomed board.
  /// 2x is exactly "this quarter fills the frame".
  static const double _quadrantScale = 2;

  /// Built eagerly in [initState], not with a `late final` initialiser.
  /// Lazily creating it means a screen the player never shook would first
  /// construct the controller inside `dispose()` — and `createTicker`
  /// looks up `TickerMode` on an element that is already deactivated by
  /// then, which is illegal.
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _resetInputField();
    _zoomController.addListener(_onZoomChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    _zoomController.removeListener(_onZoomChanged);
    _zoomController.dispose();
    _shakeController.dispose();
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

  /// Parks the hidden field on the sentinel so [decodeCrosswordInput] can
  /// tell real typing apart from our own resets.
  void _resetInputField() {
    _textController.value = const TextEditingValue(
      text: inputSentinel,
      selection: TextSelection.collapsed(offset: inputSentinel.length),
    );
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

  CrosswordController get _notifier =>
      ref.read(crosswordControllerProvider(widget.assetPath).notifier);

  /// A short, decaying left-right shake — the classic "wrong answer" tell
  /// used across word games, triggered from [_handleCheck] whenever the
  /// check reveals at least one incorrect letter.
  double _shakeOffset(double t) => math.sin(t * math.pi * 6) * (1 - t) * 8;

  void _onChanged(String value) {
    final input = decodeCrosswordInput(value);
    switch (input) {
      case CrosswordNoInput():
        // Our own reset echoing back. Returning without touching the field
        // is what keeps this from eating the next real keystroke.
        return;
      case CrosswordBackspace():
        _notifier.backspace();
      case CrosswordLetters(:final letters):
        ref.read(soundServiceProvider).playKeyTap();
        for (final character in letters.characters) {
          _notifier.enterLetter(character);
        }
    }
    _resetInputField();
  }

  /// Brings the software keyboard back.
  ///
  /// `requestFocus()` alone is not enough: when the node *already* holds
  /// focus but the IME connection was torn down — which is what happens
  /// when an Android platform view such as the banner ad is inserted or
  /// auto-refreshes — requesting focus is a no-op and the keyboard stays
  /// hidden. That is exactly why tapping a cell appeared dead while
  /// tapping the clue bar first (moving focus away, then back) worked.
  /// Asking the text input channel directly recovers that case.
  void _ensureKeyboard() {
    if (_focusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    } else {
      _focusNode.requestFocus();
    }
  }

  void _onCellTap(int row, int col) {
    ref.read(hapticServiceProvider).play(HapticIntent.selection);
    _notifier.selectCell(row, col);
    _ensureKeyboard();
  }

  void _handleCheck() {
    _notifier.checkAnswers();
    final hasErrors = ref
        .read(crosswordControllerProvider(widget.assetPath))
        .incorrectCells
        .isNotEmpty;
    if (hasErrors) {
      ref.read(hapticServiceProvider).play(HapticIntent.medium);
      // Haptic still fires either way — only the visual shake is skipped,
      // since that's the large positional motion reduced-motion settings
      // exist to avoid.
      if (!isReducedMotion(context)) {
        _shakeController.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(crosswordControllerProvider(widget.assetPath));

    ref.listen<CrosswordGameState>(
      crosswordControllerProvider(widget.assetPath),
      (previous, next) {
        if (next.isCompleted && previous?.isCompleted != true) {
          _onPuzzleCompleted();
        }
        // Also fires when a failed puzzle is reopened, which is
        // deliberate: the grid is locked either way, and a locked grid
        // with no explanation on screen is just a game that has
        // stopped responding.
        if (next.isFailed && !_failureHandled) {
          _onOutOfLives();
        }
      },
    );

    return AppScaffold(
      title: state.grid?.title,
      padHorizontal: false,
      actions: [
        const _MusicToggleButton(),
        if (state.grid != null)
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
          _buildHiddenInput(),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    CrosswordGameState state,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _buildContentForState(context, l10n, state),
    );
  }

  Widget _buildContentForState(
    BuildContext context,
    AppLocalizations l10n,
    CrosswordGameState state,
  ) {
    if (state.errorMessage != null) {
      return ErrorState(
        key: const ValueKey('error'),
        message: l10n.errorPuzzleMissing,
      );
    }
    if (state.isLoading || state.grid == null) {
      return const LoadingIndicator(key: ValueKey('loading'));
    }

    final grid = state.grid!;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      key: const ValueKey('content'),
      // A soft wash behind the play area. Flat cream behind a white grid is
      // what made this screen read as unfinished; dark mode already has
      // enough contrast and keeps its flat background.
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            _MistakesRow(mistakes: state.mistakes),
            const SizedBox(height: AppSpacing.sm),
            ClueBar(
              clue: state.currentClue,
              onTap: () => _showClueList(context, l10n, grid),
              onPrevious: () => _stepClue(grid, state, -1),
              onNext: () => _stepClue(grid, state, 1),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeOffset(_shakeController.value), 0),
                  child: child,
                );
              },
              // Framed and lifted off the backdrop, so the grid reads as the
              // focal object on the page rather than blending into it.
              child: Container(
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
                  key: _viewerKey,
                  child: InteractiveViewer(
                    transformationController: _zoomController,
                    minScale: _minScale,
                    maxScale: _maxScale,
                    // Only claim drags once there is somewhere to pan to,
                    // otherwise the viewer would swallow the page scroll.
                    panEnabled: _gridScale > _minScale,
                    child: CrosswordGridView(
                      grid: grid,
                      letters: state.letters,
                      selectedRow: state.selectedRow,
                      selectedCol: state.selectedCol,
                      direction: state.direction,
                      incorrectCells: state.incorrectCells,
                      isCompleted: state.isCompleted,
                      onCellTap: _onCellTap,
                    ),
                  ),
                ),
              ),
            ),
            _buildZoomControls(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _PuzzleActionButton(
                    label: l10n.hintButton,
                    icon: Icons.lightbulb_outline_rounded,
                    fill: AppColors.hintFillLight,
                    foreground: AppColors.hintForegroundLight,
                    onPressed: state.isCompleted || state.isFailed
                        ? null
                        : () => _handleHintTap(context, l10n),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _PuzzleActionButton(
                    label: l10n.checkButton,
                    icon: Icons.check_circle_outline_rounded,
                    fill: AppColors.checkFillLight,
                    foreground: AppColors.checkForegroundLight,
                    onPressed: state.isCompleted || state.isFailed
                        ? null
                        : _handleCheck,
                  ),
                ),
              ],
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
    return adService.buildBanner(placementId: 'crossword_bottom');
  }

  /// Purely a mechanism for getting the OS software keyboard on screen —
  /// it carries no meaningful content of its own (the grid cells already
  /// have real Semantics labels), so it's excluded from the accessibility
  /// tree rather than left as a confusing, empty focusable element for
  /// screen-reader users to land on.
  Widget _buildHiddenInput() {
    return ExcludeSemantics(
      child: SizedBox(
        width: 1,
        height: 1,
        child: Opacity(
          opacity: 0,
          child: TextField(
            focusNode: _focusNode,
            controller: _textController,
            onChanged: _onChanged,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ),
    );
  }

  void _stepClue(CrosswordGrid grid, CrosswordGameState state, int delta) {
    final currentClue = state.currentClue;
    if (currentClue == null) return;
    final list = currentClue.direction == WordDirection.across
        ? grid.acrossClues
        : grid.downClues;
    final index = list.indexWhere((c) => c.number == currentClue.number);
    if (index == -1) return;
    final nextIndex = (index + delta).clamp(0, list.length - 1);
    _notifier.selectClue(list[nextIndex]);
    // Stepping to another clue should leave the player able to type
    // immediately; without this the keyboard stays hidden until a cell tap.
    _ensureKeyboard();
  }

  void _showClueList(
    BuildContext context,
    AppLocalizations l10n,
    CrosswordGrid grid,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Text(
                  l10n.acrossLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...grid.acrossClues.map(
                  (clue) => _ClueListTile(
                    clue: clue,
                    onTap: () {
                      _notifier.selectClue(clue);
                      Navigator.of(sheetContext).pop();
                      // The sheet took focus on the way in; restore it so
                      // the player can type as soon as it closes.
                      _ensureKeyboard();
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.downLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...grid.downClues.map(
                  (clue) => _ClueListTile(
                    clue: clue,
                    onTap: () {
                      _notifier.selectClue(clue);
                      Navigator.of(sheetContext).pop();
                      // The sheet took focus on the way in; restore it so
                      // the player can type as soon as it closes.
                      _ensureKeyboard();
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            );
          },
        );
      },
    );
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
  /// hints via a user-initiated rewarded ad (spec §21/§22) — the reward is
  /// only ever granted after [RewardedAdResult.rewarded], and an
  /// unavailable ad shows a friendly message without penalizing the player.
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
      _notifier.revealHintAtSelectedCell();
      ref.read(hapticServiceProvider).play(HapticIntent.light);
      ref.read(analyticsServiceProvider).logEvent(AnalyticsEvents.hintUsed);
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
        .showRewarded(placementId: 'crossword_hint');
    switch (result) {
      case RewardedAdResult.rewarded:
        _notifier.revealHintAtSelectedCell();
        ref.read(hapticServiceProvider).play(HapticIntent.light);
        ref
            .read(analyticsServiceProvider)
            .logEvent(AnalyticsEvents.rewardedAdCompleted);
        ref.read(analyticsServiceProvider).logEvent(AnalyticsEvents.hintUsed);
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
    final state = ref.read(crosswordControllerProvider(widget.assetPath));
    final puzzleId = state.grid?.puzzleId;
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
                  '/crossword',
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

/// Hint and Check, each with its own tint in light mode.
///
/// They were two identical grey outlines, which gave the play screen no
/// visual hierarchy at all. Dark mode falls back to the shared outlined
/// button, where the tints would glow against the dark surface.
class _PuzzleActionButton extends StatelessWidget {
  const _PuzzleActionButton({
    required this.label,
    required this.icon,
    required this.fill,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color fill;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return SecondaryButton(label: label, icon: icon, onPressed: onPressed);
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: fill,
        foregroundColor: foreground,
        disabledBackgroundColor: theme.colorScheme.onSurfaceVariant.withValues(
          alpha: 0.10,
        ),
        disabledForegroundColor: theme.colorScheme.onSurfaceVariant.withValues(
          alpha: 0.55,
        ),
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
        textStyle: theme.textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
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

/// The puzzle-completion moment — the emotional payoff of the whole game —
/// gets an actual entrance animation instead of a flat [AlertDialog]. The
/// icon's elastic scale-in is a single implicit [TweenAnimationBuilder]
/// (Lever 1's cheapest, highest-impact technique), not a hand-rolled
/// controller, because that's all this moment needs.
/// The mistake budget, above the grid rather than in the app bar: three
/// hearts alongside a puzzle title and two icon buttons is more than a
/// 320dp app bar can hold, and the number the player is watching should
/// not be the first thing to get squeezed.
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
              duration: motionDuration(
                context,
                const Duration(milliseconds: 400),
              ),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              // A burst behind the badge, so finishing a puzzle actually
              // feels like an event rather than a dialog with an icon.
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

class _ClueListTile extends StatelessWidget {
  const _ClueListTile({required this.clue, required this.onTap});

  final CrosswordClue clue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text('${clue.number}', style: const TextStyle(fontSize: 12)),
      ),
      title: Text(clue.clue),
      // Makes a long clue list far easier to scan by field.
      trailing: clue.category == null
          ? null
          : ClueCategoryIcon(category: clue.category!, size: 16),
      contentPadding: EdgeInsets.zero,
    );
  }
}
