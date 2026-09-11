import 'package:flutter/material.dart';

import '../../../core/localization/generated/app_localizations.dart';
import 'player_progress.dart';

/// A badge the player can earn. Ids are persisted, so they are literals
/// that must never be renamed — a rename would silently re-lock a badge
/// somebody has already earned.
enum Achievement {
  firstSolve('first_solve', Icons.flag_rounded),
  tenSolves('ten_solves', Icons.local_fire_department_rounded),
  fiftySolves('fifty_solves', Icons.workspace_premium_rounded),
  hundredSolves('hundred_solves', Icons.military_tech_rounded),
  flawlessFive('flawless_five', Icons.auto_awesome_rounded),
  weekStreak('week_streak', Icons.calendar_month_rounded);

  const Achievement(this.id, this.icon);

  final String id;
  final IconData icon;

  bool isEarnedBy(PlayerProgress progress) => switch (this) {
    Achievement.firstSolve => progress.totalSolved >= 1,
    Achievement.tenSolves => progress.totalSolved >= 10,
    Achievement.fiftySolves => progress.totalSolved >= 50,
    Achievement.hundredSolves => progress.totalSolved >= 100,
    Achievement.flawlessFive => progress.flawlessSolves >= 5,
    Achievement.weekStreak => progress.bestStreak >= 7,
  };

  String title(AppLocalizations l10n) => switch (this) {
    Achievement.firstSolve => l10n.achievementFirstSolveTitle,
    Achievement.tenSolves => l10n.achievementTenSolvesTitle,
    Achievement.fiftySolves => l10n.achievementFiftySolvesTitle,
    Achievement.hundredSolves => l10n.achievementHundredSolvesTitle,
    Achievement.flawlessFive => l10n.achievementFlawlessFiveTitle,
    Achievement.weekStreak => l10n.achievementWeekStreakTitle,
  };

  String description(AppLocalizations l10n) => switch (this) {
    Achievement.firstSolve => l10n.achievementFirstSolveDescription,
    Achievement.tenSolves => l10n.achievementTenSolvesDescription,
    Achievement.fiftySolves => l10n.achievementFiftySolvesDescription,
    Achievement.hundredSolves => l10n.achievementHundredSolvesDescription,
    Achievement.flawlessFive => l10n.achievementFlawlessFiveDescription,
    Achievement.weekStreak => l10n.achievementWeekStreakDescription,
  };

  /// How far along the player is, as a 0..1 fraction, for the progress bar
  /// shown on a badge they have not earned yet.
  double progressToward(PlayerProgress progress) {
    final (have, need) = switch (this) {
      Achievement.firstSolve => (progress.totalSolved, 1),
      Achievement.tenSolves => (progress.totalSolved, 10),
      Achievement.fiftySolves => (progress.totalSolved, 50),
      Achievement.hundredSolves => (progress.totalSolved, 100),
      Achievement.flawlessFive => (progress.flawlessSolves, 5),
      Achievement.weekStreak => (progress.bestStreak, 7),
    };
    return (have / need).clamp(0.0, 1.0);
  }
}
