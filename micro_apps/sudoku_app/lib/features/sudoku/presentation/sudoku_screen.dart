import 'dart:math' as math;

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
import 'controllers/sudoku_controller.dart';
import 'widgets/sudoku_grid_view.dart';
import 'widgets/sudoku_number_pad.dart';

/// The core gameplay screen: grid, number pad, and the four controls a
/// Sudoku player actually reaches for (undo, erase, notes, hint).
///
/// Unlike the crossword screen there is no hidden text field here — every
/// entry goes through the on-screen pad, so the OS keyboard never covers
/// the grid and the same layout works identically in every language.
class SudokuScreen extends ConsumerStatefulWidget {
  const SudokuScreen({super.key, required this.difficulty, required this.index});

  final String difficulty;
  final int index;

  @override
  ConsumerState<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends ConsumerState<SudokuScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _completionHandled = false;
  bool _failureHandled = false;

  /// What the solve earned, captured the moment the puzzle was finished so
  /// the celebration can show it once the interstitial is out of the way.
  SolveReward? _reward;

  /// Built eagerly in [initState], not with a `late final` initialiser.
  /// Lazily creating it means a screen the player never shook would first
  /// construct the controller inside `dispose()` — and `createTicker`
  /// looks up `TickerMode` on an element that is already deactivated by
  /// then, which is illegal.
  late final AnimationController _shakeController;

  SudokuPuzzleRef get _puzzleRef => (difficulty: widget.difficulty, index: widget.index);

  SudokuController get _notifier =>
      ref.read(sudokuControllerProvider(_puzzleRef).notifier);

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeController.dispose();
    super.dispose();
  }

  /// A puzzle left open on a locked phone must not keep accruing time —
  /// the timer is the player's score, and inflating it while they're not
  /// looking would make it meaningless.
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

  /// A short, decaying left-right shake — the classic "wrong answer" tell,
  /// triggered whenever an explicit Check finds a mistake.
  double _shakeOffset(double t) => math.sin(t * math.pi * 6) * (1 - t) * 8;

  void _onCellTap(int index) {
    ref.read(hapticServiceProvider).play(HapticIntent.selection);
    _notifier.selectCell(index);
  }

  void _onDigit(int digit) {
    ref.read(soundServiceProvider).playKeyTap();
    _notifier.enterDigit(digit);

    // Read back rather than trusting the tap: only the controller knows
    // whether the digit was actually written, refused as a clash, or
    // ignored outright (a given, a finished puzzle).
    final blocked = ref
        .read(sudokuControllerProvider(_puzzleRef))
        .blockedCells
        .isNotEmpty;
    if (!blocked) {
      ref.read(hapticServiceProvider).play(HapticIntent.light);
      return;
    }

    ref.read(hapticServiceProvider).play(HapticIntent.rejected);
    // Same treatment a failed Check gets: the buzz always fires, the
    // large positional motion is what reduced-motion settings exist to
    // suppress.
    if (!isReducedMotion(context)) {
      _shakeController.forward(from: 0);
    }
  }

  void _handleCheck() {
    _notifier.checkAnswers();
    final hasErrors = ref
        .read(sudokuControllerProvider(_puzzleRef))
        .incorrectCells
        .isNotEmpty;
    if (!hasErrors) {
      ref.read(hapticServiceProvider).play(HapticIntent.light);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.checkNoMistakes)));
      return;
    }
    ref.read(hapticServiceProvider).play(HapticIntent.medium);
    // Haptic still fires either way — only the visual shake is skipped,
    // since that's the large positional motion reduced-motion settings
    // exist to avoid.
    if (!isReducedMotion(context)) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(sudokuControllerProvider(_puzzleRef));

    ref.listen<SudokuGameState>(sudokuControllerProvider(_puzzleRef), (previous, next) {
      if (next.isCompleted && previous?.isCompleted != true) {
        _onPuzzleCompleted();
      }
      // Also fires when a failed puzzle is reopened, which is deliberate:
      // the board is locked either way, and a locked board with no
      // explanation on screen is just a game that has stopped responding.
      if (next.isFailed && !_failureHandled) {
        _onOutOfLives();
      }
    });

    return AppScaffold(
      title: l10n.puzzleNumberLabel((widget.index + 1).toString().padLeft(3, '0')),
      padHorizontal: false,
      actions: [
        if (state.puzzle != null) _ElapsedLabel(seconds: state.elapsedSeconds),
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
    SudokuGameState state,
  ) {
    if (state.errorMessage != null) {
      return ErrorState(key: const ValueKey('error'), message: l10n.errorPuzzleMissing);
    }
    final puzzle = state.puzzle;
    if (state.isLoading || puzzle == null) {
      return const LoadingIndicator(key: ValueKey('loading'));
    }

    return SingleChildScrollView(
      key: const ValueKey('content'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      // The grid is square and sized off the available width, so on a
      // tablet or in a browser window it would otherwise grow to fill the
      // screen and push the number pad below the fold. Capping the column
      // keeps the playing area a comfortable phone-sized square and
      // centres it instead.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              _MistakesRow(mistakes: state.mistakes),
              const SizedBox(height: AppSpacing.sm),
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeOffset(_shakeController.value), 0),
                    child: child,
                  );
                },
                child: SudokuGridView(
                  puzzle: puzzle,
                  values: state.values,
                  notes: state.notes,
                  selectedIndex: state.selectedIndex,
                  incorrectCells: state.incorrectCells,
                  conflicts: state.conflicts,
                  blockedCells: state.blockedCells,
                  isCompleted: state.isCompleted,
                  onCellTap: _onCellTap,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ControlRow(
                state: state,
                canUndo: _notifier.canUndo,
                onUndo: () {
                  ref.read(hapticServiceProvider).play(HapticIntent.light);
                  _notifier.undo();
                },
                onErase: () {
                  ref.read(hapticServiceProvider).play(HapticIntent.light);
                  _notifier.eraseSelectedCell();
                },
                onToggleNotes: () {
                  ref.read(hapticServiceProvider).play(HapticIntent.selection);
                  _notifier.toggleNotesMode();
                },
                onHint: () => _handleHintTap(context, l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              SudokuNumberPad(
                remainingByDigit: state.remainingByDigit,
                notesMode: state.notesMode,
                // A failed board is read-only, and a pad that still
                // lights up on tap would suggest otherwise.
                enabled: !state.isCompleted && !state.isFailed,
                onDigit: _onDigit,
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: l10n.checkButton,
                icon: Icons.check_circle_outline_rounded,
                onPressed: state.isCompleted || state.isFailed
                    ? null
                    : _handleCheck,
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
    return ref.watch(adServiceProvider).buildBanner(placementId: 'sudoku_bottom');
  }

  Future<void> _confirmRestart(BuildContext context, AppLocalizations l10n) async {
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

  Future<void> _confirmFreeHint(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await _confirmHintDialog(context, l10n, l10n.hintConfirmMessage);
    if (confirmed != true) return;
    _grantHint();
  }

  Future<void> _confirmWatchAdForHint(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await _confirmHintDialog(context, l10n, l10n.watchAdForHint);
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(adServiceProvider)
        .showRewarded(placementId: 'sudoku_hint');
    switch (result) {
      case RewardedAdResult.rewarded:
        ref.read(analyticsServiceProvider).logEvent(AnalyticsEvents.rewardedAdCompleted);
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
    _notifier.revealHintAtSelectedCell();
    ref.read(hapticServiceProvider).play(HapticIntent.light);
    ref.read(analyticsServiceProvider).logEvent(AnalyticsEvents.hintUsed);
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
    final state = ref.read(sudokuControllerProvider(_puzzleRef));
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
    await ref.read(adServiceProvider).maybeShowInterstitial(trigger: 'puzzle_completed');

    if (!mounted) return;
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final l10n = AppLocalizations.of(context);
    final state = ref.read(sudokuControllerProvider(_puzzleRef));
    final total = ref.read(puzzleSummariesProvider(widget.difficulty)).value?.length;
    final hasNext = total != null && widget.index + 1 < total;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CompletionCelebration(
        l10n: l10n,
        elapsedSeconds: state.elapsedSeconds,
        reward: _reward,
        onBackToPuzzles: () {
          Navigator.of(dialogContext).pop();
          context.pop();
        },
        onNextPuzzle: hasNext
            ? () {
                Navigator.of(dialogContext).pop();
                context.pushReplacement(
                  '/sudoku/${widget.difficulty}/${widget.index + 1}',
                );
              }
            : null,
      ),
    );
  }
}

/// The mistake budget, above the grid rather than in the app bar: three
/// hearts alongside an elapsed timer and two icon buttons is more than a
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

/// Undo / erase / notes / hint. Notes is a *toggle* rather than a
/// momentary action, so it gets a filled state — a player who can't tell
/// whether notes are on will write pencil marks they meant as answers.
class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.state,
    required this.canUndo,
    required this.onUndo,
    required this.onErase,
    required this.onToggleNotes,
    required this.onHint,
  });

  final SudokuGameState state;
  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onErase;
  final VoidCallback onToggleNotes;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A run that is out of lives is over in both directions: no more
    // entries, and no spending a hint to rescue it either.
    final enabled = !state.isCompleted && !state.isFailed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ControlButton(
          icon: Icons.undo_rounded,
          label: l10n.undoButton,
          onPressed: enabled && canUndo ? onUndo : null,
        ),
        _ControlButton(
          icon: Icons.backspace_outlined,
          label: l10n.eraseButton,
          onPressed: enabled ? onErase : null,
        ),
        _ControlButton(
          icon: Icons.edit_note_rounded,
          label: l10n.notesButton,
          isActive: state.notesMode,
          onPressed: enabled ? onToggleNotes : null,
        ),
        _ControlButton(
          icon: Icons.lightbulb_outline_rounded,
          label: l10n.hintButton,
          onPressed: enabled ? onHint : null,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final color = !enabled
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
        : isActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    return Semantics(
      button: true,
      enabled: enabled,
      toggled: isActive,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: isActive ? theme.colorScheme.primary : Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: onPressed,
              icon: Icon(icon, color: color),
              tooltip: label,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Elapsed time, in the app bar rather than over the grid so it informs
/// without nagging. Rendered as `m:ss` up to an hour and `h:mm:ss` after,
/// because a leading `00:` on a two-minute puzzle is just noise.
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

/// Mute/unmute background music without leaving the puzzle. Shares the
/// same persisted state as the Settings music picker, so the two never
/// disagree — this is a shortcut to that setting, not a second one.
class _MusicToggleButton extends ConsumerWidget {
  const _MusicToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPlaying = ref.watch(settingsControllerProvider).musicTrack != MusicTrack.off;

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

/// The puzzle-completion moment — the emotional payoff of the whole game —
/// gets an actual entrance animation instead of a flat [AlertDialog], and
/// reports the solve time, which is the number Sudoku players care about.
class _CompletionCelebration extends StatelessWidget {
  const _CompletionCelebration({
    required this.l10n,
    required this.elapsedSeconds,
    required this.reward,
    required this.onBackToPuzzles,
    required this.onNextPuzzle,
  });

  final AppLocalizations l10n;
  final int elapsedSeconds;

  /// Null only if the puzzle finished before its id was known, which
  /// should not happen — the celebration degrades to the old
  /// time-only layout rather than throwing on the player's best moment.
  final SolveReward? reward;
  final VoidCallback onBackToPuzzles;
  final VoidCallback? onNextPuzzle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: motionDuration(context, const Duration(milliseconds: 400)),
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
              l10n.puzzleCompletedTime(_ElapsedLabel.format(elapsedSeconds)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (onNextPuzzle != null) ...[
              PrimaryButton(label: l10n.nextPuzzleButton, onPressed: onNextPuzzle),
              const SizedBox(height: AppSpacing.sm),
            ],
            SecondaryButton(label: l10n.backToPuzzlesButton, onPressed: onBackToPuzzles),
          ],
        ),
      ),
    );
  }
}
