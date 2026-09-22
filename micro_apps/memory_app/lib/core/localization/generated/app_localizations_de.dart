// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Memory Match';

  @override
  String get onboardingTitle => 'Memory Match';

  @override
  String get onboardingSubtitle =>
      'Karten umdrehen und alle Paare finden — 400 Spielfelder, ohne Konto, ohne Internet.';

  @override
  String get continueButton => 'Weiter';

  @override
  String get chooseDifficultyTitle => 'Wähle einen Schwierigkeitsgrad';

  @override
  String get chooseDifficultySubtitle =>
      'Du kannst jederzeit jeden Schwierigkeitsgrad spielen.';

  @override
  String get difficultyEasy => 'Leicht';

  @override
  String get difficultyMedium => 'Mittel';

  @override
  String get difficultyHard => 'Schwer';

  @override
  String get difficultyExpert => 'Experte';

  @override
  String puzzleListTitle(String difficulty) {
    return '$difficulty-Rätsel';
  }

  @override
  String get puzzleStatusCompleted => 'Abgeschlossen';

  @override
  String get puzzleStatusInProgress => 'In Bearbeitung';

  @override
  String get puzzleStatusNotStarted => 'Nicht begonnen';

  @override
  String get puzzleStatusLocked => 'Gesperrt';

  @override
  String get puzzleLockedMessage =>
      'Löse zuerst das vorherige Rätsel, um dieses freizuschalten.';

  @override
  String puzzleNumberLabel(String number) {
    return 'Rätsel $number';
  }

  @override
  String puzzlesSolvedLabel(int solved, int total) {
    return '$solved von $total gelöst';
  }

  @override
  String get noPuzzlesTitle => 'Noch keine Rätsel';

  @override
  String get noPuzzlesMessage =>
      'Neue Rätsel für diesen Schwierigkeitsgrad sind unterwegs.';

  @override
  String cellSemanticLabel(int row, int column) {
    return 'Zeile $row, Spalte $column';
  }

  @override
  String get hintButton => 'Tipp';

  @override
  String get hintConfirmTitle => 'Tipp verwenden?';

  @override
  String get hintConfirmMessage => 'Damit wird ein Paar für dich aufgedeckt.';

  @override
  String get watchAdForHint =>
      'Schau ein kurzes Video, um einen Tipp zu erhalten';

  @override
  String get restartPuzzleButton => 'Neu starten';

  @override
  String get restartConfirmTitle => 'Dieses Rätsel neu starten?';

  @override
  String get restartConfirmMessage =>
      'Dein Fortschritt bei diesem Rätsel wird gelöscht.';

  @override
  String get puzzleCompletedTitle => 'Rätsel gelöst!';

  @override
  String puzzleCompletedTime(String time) {
    return 'Gelöst in $time';
  }

  @override
  String get nextPuzzleButton => 'Nächstes Rätsel';

  @override
  String get backToPuzzlesButton => 'Zurück zu den Rätseln';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsUiLanguage => 'App-Sprache';

  @override
  String get settingsAppearance => 'Erscheinungsbild';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Hell';

  @override
  String get themeModeDark => 'Dunkel';

  @override
  String get settingsSound => 'Soundeffekte';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsMusic => 'Hintergrundmusik';

  @override
  String get musicTrackOff => 'Aus';

  @override
  String get musicTrackCalm => 'Ruhig';

  @override
  String get musicTrackGentle => 'Sanft';

  @override
  String get musicTrackUplifting => 'Beschwingt';

  @override
  String get musicTrackFocus => 'Konzentration';

  @override
  String get musicTrackBright => 'Hell';

  @override
  String get musicTrackNight => 'Nacht';

  @override
  String get settingsReminders => 'Spiel-Erinnerungen';

  @override
  String get remindersPermissionDenied =>
      'Benachrichtigungen sind für diese App deaktiviert. Du kannst sie in den Geräteeinstellungen aktivieren.';

  @override
  String get reminderTitle => 'Ein Rätsel wartet auf dich';

  @override
  String get reminderBody =>
      'Gönn dir eine Pause und löse eins — es dauert nur ein paar Minuten.';

  @override
  String get settingsTestSound => 'Ton testen';

  @override
  String get soundTestOk => 'Ton wurde abgespielt.';

  @override
  String soundTestFailed(String error) {
    return 'Ton fehlgeschlagen: $error';
  }

  @override
  String get settingsRemoveAds => 'Werbung entfernen';

  @override
  String get settingsRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get settingsAdPrivacyOptions => 'Anzeigen-Datenschutzoptionen';

  @override
  String get settingsPrivacy => 'Datenschutzrichtlinie';

  @override
  String get privacyPolicyViewOnline => 'Online ansehen';

  @override
  String get settingsAbout => 'Über';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get removeAdsTitle => 'Werbung entfernen';

  @override
  String get removeAdsDescription =>
      'Genieße jedes Rätsel ohne Banner- oder Vollbildwerbung — für immer, mit einem einmaligen Kauf.';

  @override
  String get removeAdsPrice => '1,00 \$';

  @override
  String get removeAdsPurchaseButton => 'Kaufen — 1,00 \$';

  @override
  String removeAdsPurchaseButtonWithPrice(String price) {
    return 'Kaufen — $price';
  }

  @override
  String get musicToggleOn => 'Musik einschalten';

  @override
  String get musicToggleOff => 'Musik ausschalten';

  @override
  String get settingsDeveloper => 'Entwickler';

  @override
  String get settingsDeveloperName => 'BT developer';

  @override
  String get settingsCopyright => '© BaLa Dream';

  @override
  String get removeAdsAlreadyOwned =>
      'Du besitzt bereits „Werbung entfernen“. Danke für deine Unterstützung!';

  @override
  String get partnerUnlockTitle => 'Oder Banner kostenlos entfernen';

  @override
  String partnerUnlockDescription(String app) {
    return 'Installiere $app und Bannerwerbung ist dauerhaft weg. Tipps und Extraleben nutzen weiterhin ein kurzes Video.';
  }

  @override
  String partnerUnlockButton(String app) {
    return '$app holen';
  }

  @override
  String partnerUnlockActive(String app) {
    return 'Bannerwerbung ist aus — danke, dass du $app installiert hast.';
  }

  @override
  String get purchasePending => 'Dein Kauf wird bearbeitet …';

  @override
  String get purchaseError =>
      'Der Kauf konnte nicht abgeschlossen werden. Bitte versuche es erneut.';

  @override
  String get purchaseStoreUnavailable =>
      'Der Store ist derzeit nicht verfügbar. Prüfe, ob du angemeldet bist, und versuche es erneut.';

  @override
  String get purchaseProductUnavailable =>
      'Dieser Kauf ist derzeit nicht verfügbar. Bitte versuche es später erneut.';

  @override
  String get purchaseCancelled => 'Kauf abgebrochen.';

  @override
  String get restoreSuccess => 'Deine Käufe wurden wiederhergestellt.';

  @override
  String get restoreNothingFound => 'Keine früheren Käufe gefunden.';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get errorNoInternet =>
      'Du bist offline. Diese Funktion benötigt eine Internetverbindung.';

  @override
  String get errorAdUnavailable =>
      'Momentan ist keine Werbung verfügbar. Bitte versuche es später erneut.';

  @override
  String get errorPuzzleMissing => 'Dieses Rätsel konnte nicht geladen werden.';

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get okButton => 'OK';

  @override
  String get confirmButton => 'Bestätigen';

  @override
  String get mistakesLabel => 'Fehler';

  @override
  String livesRemaining(int remaining, int max) {
    return '$remaining von $max Leben übrig';
  }

  @override
  String get outOfLivesTitle => 'Keine Leben mehr';

  @override
  String outOfLivesMessage(int max) {
    return 'Das waren $max Fehler. Starte dieses Rätsel neu für einen weiteren Versuch.';
  }

  @override
  String get outOfLivesTryAgain => 'Erneut versuchen';

  @override
  String outOfLivesMessageRevive(int max) {
    return 'Das waren $max Fehler. Du kannst ein weiteres Leben verdienen oder dieses Rätsel neu starten.';
  }

  @override
  String get outOfLivesWatchAd => 'Video ansehen für ein weiteres Leben';

  @override
  String get outOfLivesExtraLife => 'Ein weiteres Leben holen';

  @override
  String get rewardHeadlineFlawless => 'Fehlerfrei!';

  @override
  String get rewardHeadlineGreat => 'Starke Lösung!';

  @override
  String get rewardHeadlineSolved => 'Gelöst!';

  @override
  String get rewardNoMistakes => 'Keine Fehler';

  @override
  String rewardMistakesMade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fehler',
      one: '1 Fehler',
    );
    return '$_temp0';
  }

  @override
  String rewardStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage in Folge',
      one: '1 Tag in Folge',
    );
    return '$_temp0';
  }

  @override
  String rewardBestStreak(int days) {
    return 'Neue Bestserie: $days';
  }

  @override
  String rewardBadgeUnlocked(String badge) {
    return 'Neues Abzeichen: $badge';
  }

  @override
  String rewardStarsEarned(int stars, int max) {
    return '$stars von $max Sternen';
  }

  @override
  String get achievementsTitle => 'Fortschritt';

  @override
  String get achievementsStreakLabel => 'Tage in Folge';

  @override
  String get achievementsSolvedLabel => 'Gelöste Rätsel';

  @override
  String get achievementsStarsLabel => 'Verdiente Sterne';

  @override
  String get achievementsBestStreakLabel => 'Beste Serie';

  @override
  String get achievementsBadgesTitle => 'Abzeichen';

  @override
  String achievementsEarnedSemantics(String badge) {
    return '$badge, erhalten';
  }

  @override
  String achievementsLockedSemantics(String badge) {
    return '$badge, gesperrt';
  }

  @override
  String get achievementFirstSolveTitle => 'Erster Erfolg';

  @override
  String get achievementFirstSolveDescription => 'Löse dein erstes Rätsel';

  @override
  String get achievementTenSolvesTitle => 'Warm geworden';

  @override
  String get achievementTenSolvesDescription => 'Löse 10 Rätsel';

  @override
  String get achievementFiftySolvesTitle => 'Stammspieler';

  @override
  String get achievementFiftySolvesDescription => 'Löse 50 Rätsel';

  @override
  String get achievementHundredSolvesTitle => 'Hundert geschafft';

  @override
  String get achievementHundredSolvesDescription => 'Löse 100 Rätsel';

  @override
  String get achievementFlawlessFiveTitle => 'Perfektionist';

  @override
  String get achievementFlawlessFiveDescription =>
      'Hole dir bei 5 Rätseln drei Sterne';

  @override
  String get achievementWeekStreakTitle => 'Sieben Tage';

  @override
  String get achievementWeekStreakDescription => 'Spiele 7 Tage in Folge';

  @override
  String puzzlePairsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Paare',
      one: '1 Paar',
    );
    return '$_temp0';
  }

  @override
  String puzzleThemedPairsLabel(String pairs, String theme) {
    return '$pairs · $theme';
  }

  @override
  String pairsFoundLabel(String found, String total) {
    return 'Paare $found/$total';
  }

  @override
  String movesLabel(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: '$moves Züge',
      one: '1 Zug',
    );
    return '$_temp0';
  }

  @override
  String puzzleCompletedMoves(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: 'In $moves Zügen',
      one: 'In 1 Zug',
    );
    return '$_temp0';
  }

  @override
  String get cardFaceDownLabel => 'verdeckt';

  @override
  String cardFaceUpLabel(String symbol) {
    return 'zeigt $symbol';
  }

  @override
  String cardMatchedLabel(String symbol) {
    return '$symbol, Paar gefunden';
  }

  @override
  String get themeAnimals => 'Tiere';

  @override
  String get themeFood => 'Essen';

  @override
  String get themeNature => 'Natur';

  @override
  String get themeTravel => 'Reisen';

  @override
  String get themeSports => 'Sport';

  @override
  String get themeFaces => 'Gesichter';

  @override
  String get themeParty => 'Party';

  @override
  String get themeObjects => 'Gegenstände';
}
