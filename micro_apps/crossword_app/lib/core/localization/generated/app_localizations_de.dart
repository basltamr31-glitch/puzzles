// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Kreuzworträtsel';

  @override
  String get onboardingTitle => 'Kreuzworträtsel';

  @override
  String get onboardingSubtitle =>
      'Kurze Kreuzworträtsel, die du jederzeit und überall spielen kannst — kein Konto, kein Internet erforderlich.';

  @override
  String get continueButton => 'Weiter';

  @override
  String get chooseGameLanguageTitle => 'Wähle deine Rätselsprache';

  @override
  String get chooseGameLanguageSubtitle =>
      'Dies ist die Sprache der Hinweise und Antworten. Du kannst sie später in den Einstellungen ändern.';

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
  String puzzlesSolvedLabel(int solved, int total) {
    return '$solved von $total gelöst';
  }

  @override
  String get puzzleLockedMessage =>
      'Löse zuerst das vorherige Rätsel, um dieses freizuschalten.';

  @override
  String puzzleNumberLabel(String number) {
    return 'Rätsel $number';
  }

  @override
  String get noPuzzlesTitle => 'Noch keine Rätsel';

  @override
  String get noPuzzlesMessage =>
      'Neue Rätsel für diesen Schwierigkeitsgrad sind unterwegs.';

  @override
  String get acrossLabel => 'Waagerecht';

  @override
  String get downLabel => 'Senkrecht';

  @override
  String get previousClueTooltip => 'Vorheriger Hinweis';

  @override
  String get nextClueTooltip => 'Nächster Hinweis';

  @override
  String get hintButton => 'Tipp';

  @override
  String get hintConfirmTitle => 'Tipp verwenden?';

  @override
  String get hintConfirmMessage =>
      'Dadurch wird der Buchstabe in der ausgewählten Zelle aufgedeckt.';

  @override
  String get watchAdForHint =>
      'Schau ein kurzes Video, um einen Tipp zu erhalten';

  @override
  String get checkButton => 'Prüfen';

  @override
  String get restartPuzzleButton => 'Neu starten';

  @override
  String get zoomInButton => 'Vergrößern';

  @override
  String get zoomOutButton => 'Verkleinern';

  @override
  String get restartConfirmTitle => 'Dieses Rätsel neu starten?';

  @override
  String get restartConfirmMessage =>
      'Dein Fortschritt bei diesem Rätsel wird gelöscht.';

  @override
  String get exitPuzzleConfirmTitle => 'Rätsel verlassen?';

  @override
  String get exitPuzzleConfirmMessage =>
      'Dein Fortschritt wird automatisch gespeichert.';

  @override
  String get puzzleCompletedTitle => 'Rätsel gelöst!';

  @override
  String get puzzleCompletedMessage => 'Gut gemacht! Bereit für das nächste?';

  @override
  String get nextPuzzleButton => 'Nächstes Rätsel';

  @override
  String get backToPuzzlesButton => 'Zurück zu den Rätseln';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsUiLanguage => 'App-Sprache';

  @override
  String get settingsGameLanguage => 'Rätselsprache';

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
}
