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

  /// The player's cross-puzzle progress — totals, streak, badges — as a
  /// single JSON blob. One key rather than a field per stat so the whole
  /// record is read and written atomically.
  static const String playerProgress = 'player_progress';

  static String puzzleProgress(String puzzleId) => 'puzzle_progress_$puzzleId';
  static String puzzleCompleted(String puzzleId) =>
      'puzzle_completed_$puzzleId';

  /// The best star result (1-3) the player has earned on this puzzle.
  /// Absent means never solved, which is how a first solve is told apart
  /// from a replay.
  static String puzzleStars(String puzzleId) => 'puzzle_stars_$puzzleId';

  /// Mistakes and hints spent on the *current* run at this puzzle, so the
  /// mistake limit survives the player leaving the screen and coming back.
  /// Cleared on restart and on a solve.
  static String puzzleAttempt(String puzzleId) => 'puzzle_attempt_$puzzleId';
}
