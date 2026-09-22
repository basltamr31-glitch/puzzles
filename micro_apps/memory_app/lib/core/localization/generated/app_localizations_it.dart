// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Memory Match';

  @override
  String get onboardingTitle => 'Memory Match';

  @override
  String get onboardingSubtitle =>
      'Gira le carte e trova tutte le coppie — 400 tavoli, senza account e senza Internet.';

  @override
  String get continueButton => 'Continua';

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
  String get puzzleLockedMessage =>
      'Risolvi il cruciverba precedente per sbloccare questo.';

  @override
  String puzzleNumberLabel(String number) {
    return 'Cruciverba $number';
  }

  @override
  String puzzlesSolvedLabel(int solved, int total) {
    return '$solved di $total risolti';
  }

  @override
  String get noPuzzlesTitle => 'Ancora nessun cruciverba';

  @override
  String get noPuzzlesMessage =>
      'Nuovi cruciverba per questo livello sono in arrivo.';

  @override
  String cellSemanticLabel(int row, int column) {
    return 'Riga $row, colonna $column';
  }

  @override
  String get hintButton => 'Suggerimento';

  @override
  String get hintConfirmTitle => 'Usare un suggerimento?';

  @override
  String get hintConfirmMessage => 'Una coppia verrà abbinata per te.';

  @override
  String get watchAdForHint =>
      'Guarda un breve video per ottenere un suggerimento';

  @override
  String get restartPuzzleButton => 'Ricomincia';

  @override
  String get restartConfirmTitle => 'Ricominciare questo cruciverba?';

  @override
  String get restartConfirmMessage =>
      'I tuoi progressi in questo cruciverba verranno cancellati.';

  @override
  String get puzzleCompletedTitle => 'Cruciverba completato!';

  @override
  String puzzleCompletedTime(String time) {
    return 'Risolto in $time';
  }

  @override
  String get nextPuzzleButton => 'Prossimo cruciverba';

  @override
  String get backToPuzzlesButton => 'Torna ai cruciverba';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsUiLanguage => 'Lingua dell\'app';

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
  String get partnerUnlockTitle => 'Oppure togli i banner gratis';

  @override
  String partnerUnlockDescription(String app) {
    return 'Installa $app e i banner spariscono per sempre. Suggerimenti e vite extra usano ancora un breve video.';
  }

  @override
  String partnerUnlockButton(String app) {
    return 'Scarica $app';
  }

  @override
  String partnerUnlockActive(String app) {
    return 'I banner sono disattivati — grazie per aver installato $app.';
  }

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

  @override
  String get mistakesLabel => 'Errori';

  @override
  String livesRemaining(int remaining, int max) {
    return '$remaining di $max vite rimaste';
  }

  @override
  String get outOfLivesTitle => 'Vite esaurite';

  @override
  String outOfLivesMessage(int max) {
    return 'Sono $max errori. Ricomincia questo puzzle per riprovare.';
  }

  @override
  String get outOfLivesTryAgain => 'Riprova';

  @override
  String outOfLivesMessageRevive(int max) {
    return 'Sono $max errori. Puoi guadagnare una vita in più o ricominciare questo puzzle.';
  }

  @override
  String get outOfLivesWatchAd => 'Guarda un video per una vita in più';

  @override
  String get outOfLivesExtraLife => 'Ottieni una vita in più';

  @override
  String get rewardHeadlineFlawless => 'Impeccabile!';

  @override
  String get rewardHeadlineGreat => 'Ottima soluzione!';

  @override
  String get rewardHeadlineSolved => 'Risolto!';

  @override
  String get rewardNoMistakes => 'Nessun errore';

  @override
  String rewardMistakesMade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errori',
      one: '1 errore',
    );
    return '$_temp0';
  }

  @override
  String rewardStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'serie di $days giorni',
      one: 'serie di 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String rewardBestStreak(int days) {
    return 'Nuova serie record: $days';
  }

  @override
  String rewardBadgeUnlocked(String badge) {
    return 'Nuovo distintivo: $badge';
  }

  @override
  String rewardStarsEarned(int stars, int max) {
    return '$stars di $max stelle';
  }

  @override
  String get achievementsTitle => 'Progressi';

  @override
  String get achievementsStreakLabel => 'Giorni di fila';

  @override
  String get achievementsSolvedLabel => 'Puzzle risolti';

  @override
  String get achievementsStarsLabel => 'Stelle guadagnate';

  @override
  String get achievementsBestStreakLabel => 'Serie record';

  @override
  String get achievementsBadgesTitle => 'Distintivi';

  @override
  String achievementsEarnedSemantics(String badge) {
    return '$badge, ottenuto';
  }

  @override
  String achievementsLockedSemantics(String badge) {
    return '$badge, bloccato';
  }

  @override
  String get achievementFirstSolveTitle => 'Prima soluzione';

  @override
  String get achievementFirstSolveDescription => 'Completa il tuo primo puzzle';

  @override
  String get achievementTenSolvesTitle => 'Si scalda';

  @override
  String get achievementTenSolvesDescription => 'Completa 10 puzzle';

  @override
  String get achievementFiftySolvesTitle => 'Assiduo';

  @override
  String get achievementFiftySolvesDescription => 'Completa 50 puzzle';

  @override
  String get achievementHundredSolvesTitle => 'Centinaio';

  @override
  String get achievementHundredSolvesDescription => 'Completa 100 puzzle';

  @override
  String get achievementFlawlessFiveTitle => 'Perfezionista';

  @override
  String get achievementFlawlessFiveDescription =>
      'Ottieni tre stelle in 5 puzzle';

  @override
  String get achievementWeekStreakTitle => 'Sette giorni';

  @override
  String get achievementWeekStreakDescription => 'Gioca 7 giorni di fila';

  @override
  String puzzlePairsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coppie',
      one: '1 coppia',
    );
    return '$_temp0';
  }

  @override
  String puzzleThemedPairsLabel(String pairs, String theme) {
    return '$pairs · $theme';
  }

  @override
  String pairsFoundLabel(String found, String total) {
    return 'Coppie $found/$total';
  }

  @override
  String movesLabel(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: '$moves mosse',
      one: '1 mossa',
    );
    return '$_temp0';
  }

  @override
  String puzzleCompletedMoves(int moves) {
    String _temp0 = intl.Intl.pluralLogic(
      moves,
      locale: localeName,
      other: 'In $moves mosse',
      one: 'In 1 mossa',
    );
    return '$_temp0';
  }

  @override
  String get cardFaceDownLabel => 'coperta';

  @override
  String cardFaceUpLabel(String symbol) {
    return 'mostra $symbol';
  }

  @override
  String cardMatchedLabel(String symbol) {
    return '$symbol, coppia trovata';
  }

  @override
  String get themeAnimals => 'Animali';

  @override
  String get themeFood => 'Cibo';

  @override
  String get themeNature => 'Natura';

  @override
  String get themeTravel => 'Viaggi';

  @override
  String get themeSports => 'Sport';

  @override
  String get themeFaces => 'Facce';

  @override
  String get themeParty => 'Festa';

  @override
  String get themeObjects => 'Oggetti';
}
