import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/localization/generated/app_localizations.dart';
import 'difficulty.dart';

/// Shared display mapping for [Difficulty] — label and icon — used by
/// both the onboarding difficulty picker and the in-list difficulty
/// switcher so the two stay visually consistent by construction.
String difficultyLabel(AppLocalizations l10n, Difficulty difficulty) {
  return switch (difficulty) {
    Difficulty.easy => l10n.difficultyEasy,
    Difficulty.medium => l10n.difficultyMedium,
    Difficulty.hard => l10n.difficultyHard,
    Difficulty.expert => l10n.difficultyExpert,
  };
}

const Map<Difficulty, IconData> difficultyIcons = {
  Difficulty.easy: Icons.sentiment_satisfied_rounded,
  Difficulty.medium: Icons.trending_up_rounded,
  Difficulty.hard: Icons.local_fire_department_rounded,
  Difficulty.expert: Icons.emoji_events_rounded,
};

/// The accent hue for a tier. Kept next to the label/icon mapping so every
/// surface showing a difficulty picks up the same colour by construction.
Color difficultyColor(Difficulty difficulty) {
  return switch (difficulty) {
    Difficulty.easy => AppColors.difficultyEasy,
    Difficulty.medium => AppColors.difficultyMedium,
    Difficulty.hard => AppColors.difficultyHard,
    Difficulty.expert => AppColors.difficultyExpert,
  };
}

/// Soft background tint matching [difficultyColor], for badges behind icons.
Color difficultyTint(Difficulty difficulty) {
  return switch (difficulty) {
    Difficulty.easy => AppColors.difficultyEasyTint,
    Difficulty.medium => AppColors.difficultyMediumTint,
    Difficulty.hard => AppColors.difficultyHardTint,
    Difficulty.expert => AppColors.difficultyExpertTint,
  };
}
