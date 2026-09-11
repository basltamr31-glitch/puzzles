import '../../../core/localization/generated/app_localizations.dart';
import '../domain/memory_theme.dart';

/// The player-facing name of a deck's theme, in the **UI** language.
///
/// Kept out of [MemoryTheme] itself so the enum stays free of any
/// localization import — it is shared with `tool/`, which runs without a
/// Flutter engine and has no `AppLocalizations` to hand.
String memoryThemeLabel(AppLocalizations l10n, MemoryTheme theme) {
  return switch (theme) {
    MemoryTheme.animals => l10n.themeAnimals,
    MemoryTheme.food => l10n.themeFood,
    MemoryTheme.nature => l10n.themeNature,
    MemoryTheme.travel => l10n.themeTravel,
    MemoryTheme.sports => l10n.themeSports,
    MemoryTheme.faces => l10n.themeFaces,
    MemoryTheme.party => l10n.themeParty,
    MemoryTheme.objects => l10n.themeObjects,
  };
}
