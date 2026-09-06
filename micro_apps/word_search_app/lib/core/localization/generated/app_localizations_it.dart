// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Cerca parole';

  @override
  String get onboardingTitle => 'Cerca parole';

  @override
  String get onboardingSubtitle =>
      'Piccoli giochi di cerca parole da giocare ovunque e in qualsiasi momento — senza account, senza bisogno di internet.';

  @override
  String get continueButton => 'Continua';

  @override
  String get chooseGameLanguageTitle => 'Scegli la lingua dei tuoi cruciverba';

  @override
  String get chooseGameLanguageSubtitle =>
      'Questa è la lingua dell\'elenco di parole. Potrai cambiarla in seguito nelle Impostazioni.';

  @override
  String get chooseDifficultyTitle => 'Scegli una difficoltà';

  @override
  String get chooseDifficultySubtitle =>
      'Puoi giocare a qualsiasi livello di difficoltà in qualsiasi momento.';

  @override
  String get difficultyEasy => 'Facile';

  @override
  String get difficultyMedium => 'Medio';

  @override
  String get difficultyHard => 'Difficile';

  @override
  String get difficultyExpert => 'Esperto';

  @override
  String puzzleListTitle(String difficulty) {
    return 'Cruciverba $difficulty';
  }

  @override
  String get puzzleStatusCompleted => 'Completato';

  @override
  String get puzzleStatusInProgress => 'In corso';

  @override
  String get puzzleStatusNotStarted => 'Non iniziato';

  @override
  String get puzzleStatusLocked => 'Bloccato';

  @override
  String puzzlesSolvedLabel(int solved, int total) {
    return '$solved di $total risolti';
  }

  @override
  String get puzzleLockedMessage =>
      'Risolvi il cruciverba precedente per sbloccare questo.';

  @override
  String puzzleNumberLabel(String number) {
    return 'Cruciverba $number';
  }

  @override
  String puzzleWordsLabel(int count) {
    return '$count parole';
  }

  @override
  String wordsFoundLabel(int found, int total) {
    return '$found su $total trovate';
  }

  @override
  String get noPuzzlesTitle => 'Ancora nessun cruciverba';

  @override
  String get noPuzzlesMessage =>
      'Nuovi cruciverba per questo livello sono in arrivo.';

  @override
  String get hintButton => 'Suggerimento';

  @override
  String get hintConfirmTitle => 'Usare un suggerimento?';

  @override
  String get hintConfirmMessage => 'Questo troverà una parola per te.';

  @override
  String get watchAdForHint =>
      'Guarda un breve video per ottenere un suggerimento';

  @override
  String get restartPuzzleButton => 'Ricomincia';

  @override
  String get zoomInButton => 'Ingrandisci';

  @override
  String get zoomOutButton => 'Riduci';

  @override
  String get restartConfirmTitle => 'Ricominciare questo cruciverba?';

  @override
  String get restartConfirmMessage =>
      'I tuoi progressi in questo cruciverba verranno cancellati.';

  @override
  String get exitPuzzleConfirmTitle => 'Uscire dal cruciverba?';

  @override
  String get exitPuzzleConfirmMessage =>
      'I tuoi progressi vengono salvati automaticamente.';

  @override
  String get puzzleCompletedTitle => 'Cruciverba completato!';

  @override
  String get puzzleCompletedMessage => 'Ben fatto. Pronto per il prossimo?';

  @override
  String get nextPuzzleButton => 'Prossimo cruciverba';

  @override
  String get backToPuzzlesButton => 'Torna ai cruciverba';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsUiLanguage => 'Lingua dell\'app';

  @override
  String get settingsGameLanguage => 'Lingua dei cruciverba';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Chiaro';

  @override
  String get themeModeDark => 'Scuro';

  @override
  String get settingsSound => 'Effetti sonori';

  @override
  String get settingsVibration => 'Vibrazione';

  @override
  String get settingsMusic => 'Musica di sottofondo';

  @override
  String get musicTrackOff => 'Disattivata';

  @override
  String get musicTrackCalm => 'Calma';

  @override
  String get musicTrackGentle => 'Delicata';

  @override
  String get musicTrackUplifting => 'Allegra';

  @override
  String get musicTrackFocus => 'Concentrazione';

  @override
  String get musicTrackBright => 'Luminosa';

  @override
  String get musicTrackNight => 'Notte';

  @override
  String get settingsReminders => 'Promemoria di gioco';

  @override
  String get remindersPermissionDenied =>
      'Le notifiche sono disattivate per questa app. Puoi attivarle nelle impostazioni del dispositivo.';

  @override
  String get reminderTitle => 'Un cruciverba ti aspetta';

  @override
  String get reminderBody =>
      'Prenditi una pausa e risolvine uno — bastano pochi minuti.';

  @override
  String get settingsTestSound => 'Prova suono';

  @override
  String get soundTestOk => 'Suono riprodotto.';

  @override
  String soundTestFailed(String error) {
    return 'Suono non riuscito: $error';
  }

  @override
  String get settingsRemoveAds => 'Rimuovi pubblicità';

  @override
  String get settingsRestorePurchases => 'Ripristina acquisti';

  @override
  String get settingsAdPrivacyOptions => 'Opzioni sulla privacy degli annunci';

  @override
  String get settingsPrivacy => 'Informativa sulla privacy';

  @override
  String get privacyPolicyViewOnline => 'Visualizza online';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String settingsVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get removeAdsTitle => 'Rimuovi pubblicità';

  @override
  String get removeAdsDescription =>
      'Goditi ogni cruciverba senza banner o pubblicità a schermo intero — per sempre, con un solo acquisto.';

  @override
  String get removeAdsPrice => '1,00 \$';

  @override
  String get removeAdsPurchaseButton => 'Acquista — 1,00 \$';

  @override
  String removeAdsPurchaseButtonWithPrice(String price) {
    return 'Acquista — $price';
  }

  @override
  String get musicToggleOn => 'Attiva la musica';

  @override
  String get musicToggleOff => 'Disattiva la musica';

  @override
  String get settingsDeveloper => 'Sviluppatore';

  @override
  String get settingsDeveloperName => 'BT developer';

  @override
  String get settingsCopyright => '© BaLa Dream';

  @override
  String get removeAdsAlreadyOwned =>
      'Possiedi già Rimuovi pubblicità. Grazie per il tuo supporto!';

  @override
  String get purchasePending => 'Il tuo acquisto è in elaborazione…';

  @override
  String get purchaseError =>
      'Non è stato possibile completare l\'acquisto. Riprova.';

  @override
  String get purchaseStoreUnavailable =>
      'Lo store non è disponibile al momento. Verifica di aver effettuato l\'accesso e riprova.';

  @override
  String get purchaseProductUnavailable =>
      'Questo acquisto non è disponibile al momento. Riprova più tardi.';

  @override
  String get purchaseCancelled => 'Acquisto annullato.';

  @override
  String get restoreSuccess => 'I tuoi acquisti sono stati ripristinati.';

  @override
  String get restoreNothingFound => 'Nessun acquisto precedente trovato.';

  @override
  String get errorGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get errorNoInternet =>
      'Sei offline. Questa funzione richiede una connessione a internet.';

  @override
  String get errorAdUnavailable =>
      'Al momento nessuna pubblicità è disponibile. Riprova più tardi.';

  @override
  String get errorPuzzleMissing => 'Impossibile caricare questo cruciverba.';

  @override
  String get cancelButton => 'Annulla';

  @override
  String get okButton => 'OK';

  @override
  String get confirmButton => 'Conferma';
}
