/// Central registry of local storage keys.
///
/// Keeping every key in one place prevents typo-based bugs and makes it
/// obvious what persisted state the app has when auditing storage.
class StorageKeys {
  StorageKeys._();

  static const String onboardingComplete = 'onboarding_complete';
  static const String uiLanguageCode = 'ui_language_code';
  static const String difficulty = 'difficulty';
  static const String themeMode = 'theme_mode';
  static const String soundEnabled = 'sound_enabled';
  static const String vibrationEnabled = 'vibration_enabled';
  static const String musicTrack = 'music_track';

  /// The last non-off track, so the in-game music toggle can restore the
  /// player's actual choice instead of always resuming a default one.
  static const String lastMusicTrack = 'last_music_track';
  static const String isAdsRemoved = 'is_ads_removed';

  /// Whether the player opted into "come back and play" reminders.
  static const String remindersEnabled = 'reminders_enabled';

  /// Milliseconds since epoch of the last time a puzzle was opened. Drives
  /// the inactivity reminder, so a player who is already playing daily is
  /// never nagged.
  static const String lastPlayedAt = 'last_played_at';
  static const String puzzlesCompletedSinceInterstitial =
      'puzzles_completed_since_interstitial';

  static String puzzleProgress(String puzzleId) => 'puzzle_progress_$puzzleId';
  static String puzzleCompleted(String puzzleId) =>
      'puzzle_completed_$puzzleId';
}
