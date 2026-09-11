import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Word Search'**
  String get appName;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Search'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bite-sized word search puzzles you can play anywhere, anytime — no account, no internet required.'**
  String get onboardingSubtitle;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @chooseGameLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your puzzle language'**
  String get chooseGameLanguageTitle;

  /// No description provided for @chooseGameLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This is the language of the word list. You can change it later in Settings.'**
  String get chooseGameLanguageSubtitle;

  /// No description provided for @chooseDifficultyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a difficulty'**
  String get chooseDifficultyTitle;

  /// No description provided for @chooseDifficultySubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can play any difficulty at any time.'**
  String get chooseDifficultySubtitle;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get difficultyExpert;

  /// No description provided for @puzzleListTitle.
  ///
  /// In en, this message translates to:
  /// **'{difficulty} Puzzles'**
  String puzzleListTitle(String difficulty);

  /// No description provided for @puzzleStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get puzzleStatusCompleted;

  /// No description provided for @puzzleStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get puzzleStatusInProgress;

  /// No description provided for @puzzleStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get puzzleStatusNotStarted;

  /// No description provided for @puzzleStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get puzzleStatusLocked;

  /// No description provided for @puzzlesSolvedLabel.
  ///
  /// In en, this message translates to:
  /// **'{solved} of {total} solved'**
  String puzzlesSolvedLabel(int solved, int total);

  /// No description provided for @puzzleLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Solve the previous puzzle to unlock this one.'**
  String get puzzleLockedMessage;

  /// No description provided for @puzzleNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Puzzle {number}'**
  String puzzleNumberLabel(String number);

  /// No description provided for @puzzleWordsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String puzzleWordsLabel(int count);

  /// No description provided for @wordsFoundLabel.
  ///
  /// In en, this message translates to:
  /// **'{found} of {total} found'**
  String wordsFoundLabel(int found, int total);

  /// No description provided for @noPuzzlesTitle.
  ///
  /// In en, this message translates to:
  /// **'No puzzles yet'**
  String get noPuzzlesTitle;

  /// No description provided for @noPuzzlesMessage.
  ///
  /// In en, this message translates to:
  /// **'New puzzles for this difficulty are on the way.'**
  String get noPuzzlesMessage;

  /// No description provided for @hintButton.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hintButton;

  /// No description provided for @hintConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Use a hint?'**
  String get hintConfirmTitle;

  /// No description provided for @hintConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will find one word for you.'**
  String get hintConfirmMessage;

  /// No description provided for @watchAdForHint.
  ///
  /// In en, this message translates to:
  /// **'Watch a short video to get one hint'**
  String get watchAdForHint;

  /// No description provided for @restartPuzzleButton.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restartPuzzleButton;

  /// No description provided for @zoomInButton.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomInButton;

  /// No description provided for @zoomOutButton.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOutButton;

  /// No description provided for @zoomAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Zoom area'**
  String get zoomAreaLabel;

  /// No description provided for @zoomAreaTopLeft.
  ///
  /// In en, this message translates to:
  /// **'Top left'**
  String get zoomAreaTopLeft;

  /// No description provided for @zoomAreaTopRight.
  ///
  /// In en, this message translates to:
  /// **'Top right'**
  String get zoomAreaTopRight;

  /// No description provided for @zoomAreaBottomLeft.
  ///
  /// In en, this message translates to:
  /// **'Bottom left'**
  String get zoomAreaBottomLeft;

  /// No description provided for @zoomAreaBottomRight.
  ///
  /// In en, this message translates to:
  /// **'Bottom right'**
  String get zoomAreaBottomRight;

  /// No description provided for @restartConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart this puzzle?'**
  String get restartConfirmTitle;

  /// No description provided for @restartConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress on this puzzle will be cleared.'**
  String get restartConfirmMessage;

  /// No description provided for @exitPuzzleConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave puzzle?'**
  String get exitPuzzleConfirmTitle;

  /// No description provided for @exitPuzzleConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress is saved automatically.'**
  String get exitPuzzleConfirmMessage;

  /// No description provided for @puzzleCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Puzzle complete!'**
  String get puzzleCompletedTitle;

  /// No description provided for @puzzleCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Nicely done. Ready for the next one?'**
  String get puzzleCompletedMessage;

  /// No description provided for @nextPuzzleButton.
  ///
  /// In en, this message translates to:
  /// **'Next puzzle'**
  String get nextPuzzleButton;

  /// No description provided for @backToPuzzlesButton.
  ///
  /// In en, this message translates to:
  /// **'Back to puzzles'**
  String get backToPuzzlesButton;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsUiLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsUiLanguage;

  /// No description provided for @settingsGameLanguage.
  ///
  /// In en, this message translates to:
  /// **'Puzzle language'**
  String get settingsGameLanguage;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get settingsSound;

  /// No description provided for @settingsVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsVibration;

  /// No description provided for @settingsMusic.
  ///
  /// In en, this message translates to:
  /// **'Background music'**
  String get settingsMusic;

  /// No description provided for @musicTrackOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get musicTrackOff;

  /// No description provided for @musicTrackCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get musicTrackCalm;

  /// No description provided for @musicTrackGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get musicTrackGentle;

  /// No description provided for @musicTrackUplifting.
  ///
  /// In en, this message translates to:
  /// **'Uplifting'**
  String get musicTrackUplifting;

  /// No description provided for @musicTrackFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get musicTrackFocus;

  /// No description provided for @musicTrackBright.
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get musicTrackBright;

  /// No description provided for @musicTrackNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get musicTrackNight;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Play reminders'**
  String get settingsReminders;

  /// No description provided for @remindersPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for this app. You can enable them in your device settings.'**
  String get remindersPermissionDenied;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'A puzzle is waiting'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Take a break and solve one — it only takes a few minutes.'**
  String get reminderBody;

  /// No description provided for @settingsTestSound.
  ///
  /// In en, this message translates to:
  /// **'Test sound'**
  String get settingsTestSound;

  /// No description provided for @soundTestOk.
  ///
  /// In en, this message translates to:
  /// **'Sound played.'**
  String get soundTestOk;

  /// No description provided for @soundTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Sound failed: {error}'**
  String soundTestFailed(String error);

  /// No description provided for @settingsRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get settingsRemoveAds;

  /// No description provided for @settingsRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get settingsRestorePurchases;

  /// No description provided for @settingsAdPrivacyOptions.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy options'**
  String get settingsAdPrivacyOptions;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacy;

  /// No description provided for @privacyPolicyViewOnline.
  ///
  /// In en, this message translates to:
  /// **'View online'**
  String get privacyPolicyViewOnline;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @removeAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get removeAdsTitle;

  /// No description provided for @removeAdsDescription.
  ///
  /// In en, this message translates to:
  /// **'Enjoy every puzzle with no banner or interstitial ads — forever, with one purchase.'**
  String get removeAdsDescription;

  /// No description provided for @removeAdsPrice.
  ///
  /// In en, this message translates to:
  /// **'\$1.00'**
  String get removeAdsPrice;

  /// No description provided for @removeAdsPurchaseButton.
  ///
  /// In en, this message translates to:
  /// **'Purchase — \$1.00'**
  String get removeAdsPurchaseButton;

  /// No description provided for @removeAdsPurchaseButtonWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase — {price}'**
  String removeAdsPurchaseButtonWithPrice(String price);

  /// No description provided for @musicToggleOn.
  ///
  /// In en, this message translates to:
  /// **'Turn music on'**
  String get musicToggleOn;

  /// No description provided for @musicToggleOff.
  ///
  /// In en, this message translates to:
  /// **'Turn music off'**
  String get musicToggleOff;

  /// No description provided for @settingsDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloper;

  /// No description provided for @settingsDeveloperName.
  ///
  /// In en, this message translates to:
  /// **'BT developer'**
  String get settingsDeveloperName;

  /// No description provided for @settingsCopyright.
  ///
  /// In en, this message translates to:
  /// **'© BaLa Dream'**
  String get settingsCopyright;

  /// No description provided for @removeAdsAlreadyOwned.
  ///
  /// In en, this message translates to:
  /// **'You already own Remove Ads. Thank you for your support!'**
  String get removeAdsAlreadyOwned;

  /// No description provided for @purchasePending.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is being processed…'**
  String get purchasePending;

  /// No description provided for @purchaseError.
  ///
  /// In en, this message translates to:
  /// **'The purchase couldn\'t be completed. Please try again.'**
  String get purchaseError;

  /// No description provided for @purchaseStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store isn\'t available right now. Check that you\'re signed in and try again.'**
  String get purchaseStoreUnavailable;

  /// No description provided for @purchaseProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This purchase isn\'t available right now. Please try again later.'**
  String get purchaseProductUnavailable;

  /// No description provided for @purchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled.'**
  String get purchaseCancelled;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your purchases have been restored.'**
  String get restoreSuccess;

  /// No description provided for @restoreNothingFound.
  ///
  /// In en, this message translates to:
  /// **'No previous purchases were found.'**
  String get restoreNothingFound;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. This feature needs an internet connection.'**
  String get errorNoInternet;

  /// No description provided for @errorAdUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No ad is available right now. Please try again later.'**
  String get errorAdUnavailable;

  /// No description provided for @errorPuzzleMissing.
  ///
  /// In en, this message translates to:
  /// **'This puzzle couldn\'t be loaded.'**
  String get errorPuzzleMissing;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @mistakesLabel.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get mistakesLabel;

  /// No description provided for @livesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {max} lives left'**
  String livesRemaining(int remaining, int max);

  /// No description provided for @outOfLivesTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of lives'**
  String get outOfLivesTitle;

  /// No description provided for @outOfLivesMessage.
  ///
  /// In en, this message translates to:
  /// **'That is {max} mistakes. Start this puzzle again to have another go.'**
  String outOfLivesMessage(int max);

  /// No description provided for @outOfLivesTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get outOfLivesTryAgain;

  /// No description provided for @rewardHeadlineFlawless.
  ///
  /// In en, this message translates to:
  /// **'Flawless!'**
  String get rewardHeadlineFlawless;

  /// No description provided for @rewardHeadlineGreat.
  ///
  /// In en, this message translates to:
  /// **'Great solve!'**
  String get rewardHeadlineGreat;

  /// No description provided for @rewardHeadlineSolved.
  ///
  /// In en, this message translates to:
  /// **'Solved!'**
  String get rewardHeadlineSolved;

  /// No description provided for @rewardNoMistakes.
  ///
  /// In en, this message translates to:
  /// **'No mistakes'**
  String get rewardNoMistakes;

  /// No description provided for @rewardMistakesMade.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 mistake} other{{count} mistakes}}'**
  String rewardMistakesMade(int count);

  /// No description provided for @rewardStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1-day streak} other{{days}-day streak}}'**
  String rewardStreakDays(int days);

  /// No description provided for @rewardBestStreak.
  ///
  /// In en, this message translates to:
  /// **'New best streak: {days}'**
  String rewardBestStreak(int days);

  /// No description provided for @rewardBadgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'New badge: {badge}'**
  String rewardBadgeUnlocked(String badge);

  /// No description provided for @rewardStarsEarned.
  ///
  /// In en, this message translates to:
  /// **'{stars} of {max} stars'**
  String rewardStarsEarned(int stars, int max);

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get achievementsTitle;

  /// No description provided for @achievementsStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get achievementsStreakLabel;

  /// No description provided for @achievementsSolvedLabel.
  ///
  /// In en, this message translates to:
  /// **'Puzzles solved'**
  String get achievementsSolvedLabel;

  /// No description provided for @achievementsStarsLabel.
  ///
  /// In en, this message translates to:
  /// **'Stars earned'**
  String get achievementsStarsLabel;

  /// No description provided for @achievementsBestStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get achievementsBestStreakLabel;

  /// No description provided for @achievementsBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get achievementsBadgesTitle;

  /// No description provided for @achievementsEarnedSemantics.
  ///
  /// In en, this message translates to:
  /// **'{badge}, earned'**
  String achievementsEarnedSemantics(String badge);

  /// No description provided for @achievementsLockedSemantics.
  ///
  /// In en, this message translates to:
  /// **'{badge}, locked'**
  String achievementsLockedSemantics(String badge);

  /// No description provided for @achievementFirstSolveTitle.
  ///
  /// In en, this message translates to:
  /// **'First solve'**
  String get achievementFirstSolveTitle;

  /// No description provided for @achievementFirstSolveDescription.
  ///
  /// In en, this message translates to:
  /// **'Finish your first puzzle'**
  String get achievementFirstSolveDescription;

  /// No description provided for @achievementTenSolvesTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting warm'**
  String get achievementTenSolvesTitle;

  /// No description provided for @achievementTenSolvesDescription.
  ///
  /// In en, this message translates to:
  /// **'Finish 10 puzzles'**
  String get achievementTenSolvesDescription;

  /// No description provided for @achievementFiftySolvesTitle.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get achievementFiftySolvesTitle;

  /// No description provided for @achievementFiftySolvesDescription.
  ///
  /// In en, this message translates to:
  /// **'Finish 50 puzzles'**
  String get achievementFiftySolvesDescription;

  /// No description provided for @achievementHundredSolvesTitle.
  ///
  /// In en, this message translates to:
  /// **'Centurion'**
  String get achievementHundredSolvesTitle;

  /// No description provided for @achievementHundredSolvesDescription.
  ///
  /// In en, this message translates to:
  /// **'Finish 100 puzzles'**
  String get achievementHundredSolvesDescription;

  /// No description provided for @achievementFlawlessFiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Perfectionist'**
  String get achievementFlawlessFiveTitle;

  /// No description provided for @achievementFlawlessFiveDescription.
  ///
  /// In en, this message translates to:
  /// **'Earn three stars on 5 puzzles'**
  String get achievementFlawlessFiveDescription;

  /// No description provided for @achievementWeekStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Seven days'**
  String get achievementWeekStreakTitle;

  /// No description provided for @achievementWeekStreakDescription.
  ///
  /// In en, this message translates to:
  /// **'Play 7 days in a row'**
  String get achievementWeekStreakDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'it',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
