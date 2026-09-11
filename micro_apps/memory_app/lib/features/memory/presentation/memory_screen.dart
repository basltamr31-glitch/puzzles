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
import '../../../core/utils/motion.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/decorative_art.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../puzzle_list/puzzle_list_providers.dart';
import '../../rewards/domain/solve_reward.dart';
import '../../rewards/presentation/widgets/lives_indicator.dart';
import '../../rewards/presentation/widgets/out_of_lives_dialog.dart';
import '../../rewards/presentation/widgets/reward_summary.dart';
import '../../rewards/rewards_controller.dart';
import '../../settings/settings_controller.dart';
import 'controllers/memory_controller.dart';
import 'widgets/memory_board_view.dart';

/// The core gameplay screen: the board, the two counters a memory player
/// watches (pairs found and moves spent), and a hint.
///
/// There is no control row here of the kind the sudoku app needs. Every
/// action in this game is "turn over that card" — there is nothing to
/// undo (a revealed card cannot be un-seen), nothing to erase, and
/// nothing to check. Adding buttons for them would be inventing
/// mechanics to fill a toolbar.
class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key, required this.difficulty, required this.index});

  final String difficulty;
  final int index;

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen>
    with WidgetsBindingObserver {
  bool _completionHandled = false;
  bool _failureHandled = false;

  /// What the solve earned, captured the moment the board was finished so
  /// the celebration can show it once the interstitial is out of the way.
  SolveReward? _reward;

  MemoryDeckRef get _deckRef => (
    difficulty: widget.difficulty,
    index: widget.index,
  );

  MemoryController get _notifier =>
      ref.read(memoryControllerProvider(_deckRef).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A board left open on a locked phone must not keep accruing time —
  /// the timer is part of the player's score, and inflating it while
  /// they're not looking would make it meaningless.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _notifier.pauseTimer();
      case AppLifecycleState.resumed:
        _notifier.resumeTimer();
      case AppLifecycleState.detached:
        break;
    }
  }

  /// Feedback is chosen from what the tap actually did, read back off the
  /// controller rather than guessed at the call site: the same tap can
  /// reveal a card, complete a pair, or spend a life, and only the
  /// controller knows which.
  void _onCardTap(int index) {
    final before = ref.read(memoryControllerProvider(_deckRef));
    if (before.isFaceUp(index) || before.isCompleted || before.isFailed) return;

    ref.read(soundServiceProvider).playKeyTap();
    _notifier.flipCard(index);
    final after = ref.read(memoryControllerProvider(_deckRef));

    if (after.pairsFound > before.pairsFound) {
      ref.read(hapticServiceProvider).play(HapticIntent.medium);
      return;
    }
    if (after.mistakes > before.mistakes) {
      ref.read(hapticServiceProvider).play(HapticIntent.rejected);
      return;
    }
    ref.read(hapticServiceProvider).play(HapticIntent.selection);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(memoryControllerProvider(_deckRef));

    ref.listen<MemoryGameState>(memoryControllerProvider(_deckRef), (
      previous,
      next,
    ) {
      if (next.isCompleted && previous?.isCompleted != true) {
        _onPuzzleCompleted();
      }
      // Also fires when a failed board is reopened, which is deliberate:
      // the board is locked either way, and a locked board with no
      // explanation on screen is just a game that has stopped responding.
      if (next.isFailed && !_failureHandled) {
        _onOutOfLives();
      }
    });

    return AppScaffold(
      title: l10n.puzzleNumberLabel(
        (widget.index + 1).toString().padLeft(3, '0'),
      ),
      padHorizontal: false,
      actions: [
        if (state.deck != null) _ElapsedLabel(seconds: state.elapsedSeconds),
        const _MusicToggleButton(),
        if (state.deck != null)
          IconButton(
            onPressed: () => _confirmRestart(context, l10n),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.restartPuzzleButton,
          ),
      ],
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildContentForState(context, l10n, state),
            ),
          ),
          _buildBanner(),
        ],
      ),
    );
  }

  Widget _buildContentForState(
    BuildContext context,
    AppLocalizations l10n,
    MemoryGameState state,
  ) {
    if (state.errorMessage != null) {
      return ErrorState(
        key: const ValueKey('error'),
        message: l10n.errorPuzzleMissing,
      );
    }
    final deck = state.deck;
    if (state.isLoading || deck == null) {
      return const LoadingIndicator(key: ValueKey('loading'));
    }

    return SingleChildScrollView(
      key: const ValueKey('content'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      // The board's height follows its own row/column count, so on a
      // tablet or in a browser window it would otherwise grow to fill the
      // screen and push the hint below the fold. Capping the column keeps
      // the playing area a comfortable phone-sized board and centres it.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              _StatsRow(state: state),
              const SizedBox(height: AppSpacing.sm),
              MemoryBoardView(
                deck: deck,
                matchedCards: state.matchedCards,
                faceUpCards: state.faceUpCards,
                mismatchedCards: state.mismatchedCards,
                isCompleted: state.isCompleted || state.isFailed,
                onCardTap: _onCardTap,
              ),
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                label: l10n.hintButton,
                icon: Icons.lightbulb_outline_rounded,
                // A run that is out of lives is over in both directions:
                // no more flips, and no spending a hint to rescue it.
                onPressed: state.isCompleted || state.isFailed
                    ? null
                    : () => _handleHintTap(context, l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final isAdsRemoved = ref.watch(isAdsRemovedProvider);
    if (isAdsRemoved) return const SizedBox.shrink();
    return ref.watch(adServiceProvider).buildBanner(placementId: 'memory_bottom');
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
    final confirmed = await _confirmHintDialog(
      context,
      l10n,
      l10n.hintConfirmMessage,
    );
    if (confirmed != true) return;
    _grantHint();
  }

  Future<void> _confirmWatchAdForHint(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await _confirmHintDialog(
      context,
      l10n,
      l10n.watchAdForHint,
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(adServiceProvider)
        .showRewarded(placementId: 'memory_hint');
    switch (result) {
      case RewardedAdResult.rewarded:
        ref
            .read(analyticsServiceProvider)
            .logEvent(AnalyticsEvents.rewardedAdCompleted);
        _grantHint();
      case RewardedAdResult.unavailable:
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorAdUnavailable)));
      case RewardedAdResult.dismissedWithoutReward:
        break;
    }
  }

  Future<bool?> _confirmHintDialog(
    BuildContext context,
    AppLocalizations l10n,
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.hintConfirmTitle),
        content: Text(message),
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
  }

  void _grantHint() {
    _notifier.revealHint();
    ref.read(hapticServiceProvider).play(HapticIntent.light);
  }

  /// Locks the run down and tells the player why. Restart is offered
  /// right here rather than sending them back to the list first: wanting
  /// another go is the overwhelmingly likely next move.
  void _onOutOfLives() {
    if (_failureHandled) return;
    _failureHandled = true;

    ref.read(hapticServiceProvider).play(HapticIntent.heavy);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => OutOfLivesDialog(
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

  Future<void> _onPuzzleCompleted() async {
    if (_completionHandled) return;
    _completionHandled = true;

    // Banked before the interstitial: an ad failing to load, or the
    // player killing the app while one is on screen, must not be able to
    // cost them the solve they just earned.
    final state = ref.read(memoryControllerProvider(_deckRef));
    final deckId = state.deck?.id;
    if (deckId != null) {
      _reward = ref
          .read(rewardsControllerProvider.notifier)
          .recordSolve(
            puzzleId: deckId,
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
    final state = ref.read(memoryControllerProvider(_deckRef));
    final total = ref
        .read(puzzleSummariesProvider(widget.difficulty))
        .value
        ?.length;
    final hasNext = total != null && widget.index + 1 < total;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CompletionCelebration(
        l10n: l10n,
        elapsedSeconds: state.elapsedSeconds,
        moves: state.moves,
        reward: _reward,
        onBackToPuzzles: () {
          Navigator.of(dialogContext).pop();
          context.pop();
        },
        onNextPuzzle: hasNext
            ? () {
                Navigator.of(dialogContext).pop();
                context.pushReplacement(
                  '/play/${widget.difficulty}/${widget.index + 1}',
                );
              }
            : null,
      ),
    );
  }
}

/// Pairs found, moves spent, and the mistake budget — above the board
/// rather than in the app bar, because three hearts alongside an elapsed
/// timer and two icon buttons is more than a 320dp app bar can hold, and
/// the numbers the player is watching should not be the first thing to
/// get squeezed.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final MemoryGameState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            l10n.pairsFoundLabel('${state.pairsFound}', '${state.totalPairs}'),
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            l10n.movesLabel(state.moves),
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        LivesIndicator(mistakes: state.mistakes),
      ],
    );
  }
}

/// Elapsed time, in the app bar rather than over the board so it informs
/// without nagging. Rendered as `m:ss` up to an hour and `h:mm:ss` after,
/// because a leading `00:` on a two-minute game is just noise.
class _ElapsedLabel extends StatelessWidget {
  const _ElapsedLabel({required this.seconds});

  final int seconds;

  static String format(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    final paddedSeconds = secs.toString().padLeft(2, '0');
    if (hours == 0) return '$minutes:$paddedSeconds';
    return '$hours:${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(
          format(seconds),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Mute/unmute background music without leaving the board. Shares the
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
      icon: Icon(isPlaying ? Icons.music_note_rounded : Icons.music_off_rounded),
      tooltip: isPlaying ? l10n.musicToggleOff : l10n.musicToggleOn,
    );
  }
}

/// The completion moment — the emotional payoff of the whole game — gets
/// an actual entrance animation instead of a flat [AlertDialog], and
/// reports both numbers a memory player competes against: the clock, and
/// the move count that says how well they actually remembered.
class _CompletionCelebration extends StatelessWidget {
  const _CompletionCelebration({
    required this.l10n,
    required this.elapsedSeconds,
    required this.moves,
    required this.reward,
    required this.onBackToPuzzles,
    required this.onNextPuzzle,
  });

  final AppLocalizations l10n;
  final int elapsedSeconds;
  final int moves;

  /// Null only if the board finished before its deck id was known, which
  /// should not happen — the celebration degrades to the time-only layout
  /// rather than throwing on the player's best moment.
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
              // A burst behind the badge, so finishing a board actually
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
              l10n.puzzleCompletedTime(_ElapsedLabel.format(elapsedSeconds)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              l10n.puzzleCompletedMoves(moves),
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
