// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Memory Match';

  @override
  String get onboardingTitle => 'Memory Match';

  @override
  String get onboardingSubtitle =>
      'Turn the cards over and find every pair — 400 boards, no account, no internet required.';

  @override
  String get continueButton => 'Continue';

  @override
  String get chooseDifficultyTitle => 'Choose a difficulty';

  @override
  String get chooseDifficultySubtitle =>
      'You can play any difficulty at any time.';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String puzzleListTitle(String difficulty) {
    return '$difficulty Puzzles';
  }

  @override
  String get puzzleStatusCompleted => 'Completed';

  @override
  String get puzzleStatusInProgress => 'In progress';

  @override
  String get puzzleStatusNotStarted => 'Not started';

  @override
  String get puzzleStatusLocked => 'Locked';

  @override
  String get puzzleLockedMessage =>
      'Solve the previous puzzle to unlock this one.';

  @override
  String puzzleNumberLabel(String number) {
    return 'Puzzle $number';
  }

  @override
  String puzzlesSolvedLabel(int solved, int total) {
    return '$solved of $total solved';
  }

  @override
  String get noPuzzlesTitle => 'No puzzles yet';

  @override
  String get noPuzzlesMessage =>
      'New puzzles for this difficulty are on the way.';

  @override
  String cellSemanticLabel(int row, int column) {
    return 'Row $row, column $column';
  }

  @override
  String get hintButton => 'Hint';

  @override
  String get hintConfirmTitle => 'Use a hint?';

  @override
  String get hintConfirmMessage => 'This will match one pair for you.';

  @override
  String get watchAdForHint => 'Watch a short video to get one hint';

  @override
  String get restartPuzzleButton => 'Restart';

  @override
  String get restartConfirmTitle => 'Restart this puzzle?';

  @override
  String get restartConfirmMessage =>
      'Your progress on this puzzle will be cleared.';

  @override
  String get puzzleCompletedTitle => 'Puzzle complete!';

  @override
  String puzzleCompletedTime(String time) {
    return 'Solved in $time';
  }

  @override
  String get nextPuzzleButton => 'Next puzzle';

  @override
  String get backToPuzzlesButton => 'Back to puzzles';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUiLanguage => 'App language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get settingsSound => 'Sound effects';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsMusic => 'Background music';

  @override
  String get musicTrackOff => 'Off';

  @override
  String get musicTrackCalm => 'Calm';

  @override
  String get musicTrackGentle => 'Gentle';

  @override
  String get musicTrackUplifting => 'Uplifting';

  @override
  String get musicTrackFocus => 'Focus';

  @override
  String get musicTrackBright => 'Bright';

  @override
  String get musicTrackNight => 'Night';

  @override
  String get settingsReminders => 'Play reminders';

  @override
  String get remindersPermissionDenied =>
      'Notifications are turned off for this app. You can enable them in your device settings.';

  @override
  String get reminderTitle => 'A puzzle is waiting';

  @override
  String get reminderBody =>
      'Take a break and solve one — it only takes a few minutes.';

  @override
  String get settingsTestSound => 'Test sound';

  @override
  String get soundTestOk => 'Sound played.';

  @override
  String soundTestFailed(String error) {
    return 'Sound failed: $error';
  }

  @override
  String get settingsRemoveAds => 'Remove ads';

  @override
  String get settingsRestorePurchases => 'Restore purchases';

  @override
  String get settingsAdPrivacyOptions => 'Ad privacy options';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get privacyPolicyViewOnline => 'View online';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get removeAdsTitle => 'Remove Ads';

  @override
  String get removeAdsDescription =>
      'Enjoy every puzzle with no banner or interstitial ads — forever, with one purchase.';

  @override
  String get removeAdsPrice => '\$1.00';

  @override
  String get removeAdsPurchaseButton => 'Purchase — \$1.00';

  @override
  String removeAdsPurchaseButtonWithPrice(String price) {
    return 'Purchase — $price';
  }

  @override
  String get musicToggleOn => 'Turn music on';

  @override
  String get musicToggleOff => 'Turn music off';

  @override
  String get settingsDeveloper => 'Developer';

  @override
  String get settingsDeveloperName => 'BT developer';

  @override
  String get settingsCopyright => '© BaLa Dream';

  @override
  String get removeAdsAlreadyOwned =>
      'You already own Remove Ads. Thank you for your support!';

  @override
  String get partnerUnlockTitle => 'Or remove banners for free';

  @override
  String partnerUnlockDescription(String app) {
    return 'Install $app and banner ads are gone for good. Hints and extra lives still use a short video.';
  }

  @override
  String partnerUnlockButton(String app) {
    return 'Get $app';
  }

  @override
  String partnerUnlockActive(String app) {
    return 'Banner ads are off — thanks for installing $app.';
  }

  @override
  String get purchasePending => 'Your purchase is being processed…';

  @override
  String get purchaseError =>
      'The purchase couldn\'t be completed. Please try again.';

  @override
  String get purchaseStoreUnavailable =>
      'The store isn\'t available right now. Check that you\'re signed in and try again.';

  @override
  String get purchaseProductUnavailable =>
      'This purchase isn\'t available right now. Please try again later.';

  @override
  String get purchaseCancelled => 'Purchase cancelled.';

  @override
  String get restoreSuccess => 'Your purchases have been restored.';

  @override
  String get restoreNothingFound => 'No previous purchases were found.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNoInternet =>
      'You\'re offline. This feature needs an internet connection.';

  @override
  String get errorAdUnavailable =>
      'No ad is available right now. Please try again later.';

  @override
  String get errorPuzzleMissing => 'This puzzle couldn\'t be loaded.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get okButton => 'OK';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get mistakesLabel => 'Mistakes';

  @override
  String livesRemaining(int remaining, int max) {
    return '$remaining of $max lives left';
  }

  @override
  String get outOfLivesTitle => 'Out of lives';

  @override
  String outOfLivesMessage(int max) {
    return 'That is $max mistakes. Start this puzzle again to have another go.';
  }

  @override
  String get outOfLivesTryAgain => 'Try again';

  @override
  String outOfLivesMessageRevive(int max) {
    return 'That is $max mistakes. You can earn one more life, or start this puzzle again.';
  }

  @override
  String get outOfLivesWatchAd => 'Watch a video for one more life';

  @override
  String get outOfLivesExtraLife => 'Get one more life';

  @override
  String get rewardHeadlineFlawless => 'Flawless!';

  @override
  String get rewardHeadlineGreat => 'Great solve!';

  @override
  String get rewardHeadlineSolved => 'Solved!';

  @override
  String get rewardNoMistakes => 'No mistakes';

  @override
  String rewardMistakesMade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mistakes',
      one: '1 mistake',
    );
    return '$_temp0';
  }

  @override
  String rewardStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String rewardBestStreak(int days) {
    return 'New best streak: $days';
  }

  @override
  String rewardBadgeUnlocked(String badge) {
    return 'New badge: $badge';
  }

  @override
  String rewardStarsEarned(int stars, int max) {
    return '$stars of $max stars';
  }

  @override
  String get achievementsTitle => 'Progress';

  @override
  String get achievementsStreakLabel => 'Day streak';

  @override
  String get achievementsSolvedLabel => 'Puzzles solved';

  @override
  String get achievementsStarsLabel => 'Stars earned';

  @override
  String get achievementsBestStreakLabel => 'Best streak';

  @override
  String get achievementsBadgesTitle => 'Badges';

  @override
  String achievementsEarnedSemantics(String badge) {
    return '$badge, earned';
  }

  @override
  String achievementsLockedSemantics(String badge) {
    return '$badge, locked';
  }

  @override
  String get achievementFirstSolveTitle => 'First solve';

  @override
  String get achievementFirstSolveDescription => 'Finish your first puzzle';

  @override
  String get achievementTenSolvesTitle => 'Getting warm';

  @override
  String get achievementTenSolvesDescription => 'Finish 10 puzzles';

  @override
  String get achievementFiftySolvesTitle => 'Regular';

  @override
  String get achievementFiftySolvesDescription => 'Finish 50 puzzles';

  @override
  String get achievementHundredSolvesTitle => 'Centurion';

  @override
  String get achievementHundredSolvesDescription => 'Finish 100 puzzles';

  @override
  String get achievementFlawlessFiveTitle => 'Perfectionist';

  @override
  String get achievementFlawlessFiveDescription =>
      'Earn three stars on 5 puzzles';

  @override
  String get achievementWeekStreakTitle => 'Seven days';

  @override
  String get achievementWeekStreakDescription => 'Play 7 days in a row';

  @override
  String puzzlePairsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pairs',
      one: '1 pair',
    );
    return '$_temp0';
  }

  @override
  String puzzleThemedPairsLabel(String pairs, String theme) {
    return '$pairs · $theme';
  }

  @override
  String pairsFoundLabel(String found, String total) {
    return 'Pairs $found/$total';
  }

  @override
  String movesLabel(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: '$moves moves',
      one: '1 move',
    );
    return '$_temp0';
  }

  @override
  String puzzleCompletedMoves(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: 'In $moves moves',
      one: 'In 1 move',
    );
    return '$_temp0';
  }

  @override
  String get cardFaceDownLabel => 'face down';

  @override
  String cardFaceUpLabel(String symbol) {
    return 'showing $symbol';
  }

  @override
  String cardMatchedLabel(String symbol) {
    return '$symbol, matched';
  }

  @override
  String get themeAnimals => 'Animals';

  @override
  String get themeFood => 'Food';

  @override
  String get themeNature => 'Nature';

  @override
  String get themeTravel => 'Travel';

  @override
  String get themeSports => 'Sports';

  @override
  String get themeFaces => 'Faces';

  @override
  String get themeParty => 'Party';

  @override
  String get themeObjects => 'Objects';
}
