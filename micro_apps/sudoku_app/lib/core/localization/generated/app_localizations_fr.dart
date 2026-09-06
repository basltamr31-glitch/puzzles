// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Sudoku';

  @override
  String get onboardingTitle => 'Sudoku';

  @override
  String get onboardingSubtitle =>
      'Des grilles de chiffres classiques pour tous les niveaux — 400 grilles à résoudre, sans compte ni connexion Internet.';

  @override
  String get continueButton => 'Continuer';

  @override
  String get chooseDifficultyTitle => 'Choisissez une difficulté';

  @override
  String get chooseDifficultySubtitle =>
      'Vous pouvez jouer à n\'importe quelle difficulté à tout moment.';

  @override
  String get difficultyEasy => 'Facile';

  @override
  String get difficultyMedium => 'Moyen';

  @override
  String get difficultyHard => 'Difficile';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String puzzleListTitle(String difficulty) {
    return 'Grilles $difficulty';
  }

  @override
  String get puzzleStatusCompleted => 'Terminée';

  @override
  String get puzzleStatusInProgress => 'En cours';

  @override
  String get puzzleStatusNotStarted => 'Non commencée';

  @override
  String get puzzleStatusLocked => 'Verrouillée';

  @override
  String get puzzleLockedMessage =>
      'Résolvez la grille précédente pour déverrouiller celle-ci.';

  @override
  String puzzleNumberLabel(String number) {
    return 'Grille $number';
  }

  @override
  String puzzleCluesLabel(int count) {
    return '$count indices';
  }

  @override
  String puzzlesSolvedLabel(int solved, int total) {
    return '$solved sur $total résolues';
  }

  @override
  String get noPuzzlesTitle => 'Pas encore de grilles';

  @override
  String get noPuzzlesMessage =>
      'De nouvelles grilles pour ce niveau arrivent bientôt.';

  @override
  String cellSemanticLabel(int row, int column) {
    return 'Ligne $row, colonne $column';
  }

  @override
  String get cellEmpty => 'Vide';

  @override
  String numberPadDigitLabel(int digit) {
    return 'Saisir $digit';
  }

  @override
  String numberPadNoteLabel(int digit) {
    return 'Note $digit';
  }

  @override
  String get undoButton => 'Annuler';

  @override
  String get eraseButton => 'Effacer';

  @override
  String get notesButton => 'Notes';

  @override
  String get hintButton => 'Indice';

  @override
  String get hintConfirmTitle => 'Utiliser un indice ?';

  @override
  String get hintConfirmMessage =>
      'Le chiffre de la case sélectionnée sera rempli.';

  @override
  String get watchAdForHint =>
      'Regardez une courte vidéo pour obtenir un indice';

  @override
  String get checkButton => 'Vérifier';

  @override
  String get checkNoMistakes => 'Aucune erreur pour l\'instant.';

  @override
  String get restartPuzzleButton => 'Recommencer';

  @override
  String get restartConfirmTitle => 'Recommencer cette grille ?';

  @override
  String get restartConfirmMessage =>
      'Votre progression sur cette grille sera effacée.';

  @override
  String get puzzleCompletedTitle => 'Grille terminée !';

  @override
  String puzzleCompletedTime(String time) {
    return 'Résolu en $time';
  }

  @override
  String get nextPuzzleButton => 'Grille suivante';

  @override
  String get backToPuzzlesButton => 'Retour aux grilles';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsUiLanguage => 'Langue de l\'application';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get themeModeSystem => 'Système';

  @override
  String get themeModeLight => 'Clair';

  @override
  String get themeModeDark => 'Sombre';

  @override
  String get settingsSound => 'Effets sonores';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsMusic => 'Musique de fond';

  @override
  String get musicTrackOff => 'Désactivée';

  @override
  String get musicTrackCalm => 'Calme';

  @override
  String get musicTrackGentle => 'Douce';

  @override
  String get musicTrackUplifting => 'Entraînante';

  @override
  String get musicTrackFocus => 'Concentration';

  @override
  String get musicTrackBright => 'Lumineuse';

  @override
  String get musicTrackNight => 'Nuit';

  @override
  String get settingsReminders => 'Rappels de jeu';

  @override
  String get remindersPermissionDenied =>
      'Les notifications sont désactivées pour cette application. Vous pouvez les activer dans les réglages de votre appareil.';

  @override
  String get reminderTitle => 'Une grille vous attend';

  @override
  String get reminderBody =>
      'Faites une pause et résolvez-en une — cela ne prend que quelques minutes.';

  @override
  String get settingsTestSound => 'Tester le son';

  @override
  String get soundTestOk => 'Son joué.';

  @override
  String soundTestFailed(String error) {
    return 'Échec du son : $error';
  }

  @override
  String get settingsRemoveAds => 'Supprimer les publicités';

  @override
  String get settingsRestorePurchases => 'Restaurer les achats';

  @override
  String get settingsAdPrivacyOptions =>
      'Options de confidentialité des annonces';

  @override
  String get settingsPrivacy => 'Politique de confidentialité';

  @override
  String get privacyPolicyViewOnline => 'Voir en ligne';

  @override
  String get settingsAbout => 'À propos';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get removeAdsTitle => 'Supprimer les publicités';

  @override
  String get removeAdsDescription =>
      'Profitez de chaque grille sans bannière ni publicité plein écran — pour toujours, avec un seul achat.';

  @override
  String get removeAdsPrice => '1,00 \$';

  @override
  String get removeAdsPurchaseButton => 'Acheter — 1,00 \$';

  @override
  String removeAdsPurchaseButtonWithPrice(String price) {
    return 'Acheter — $price';
  }

  @override
  String get musicToggleOn => 'Activer la musique';

  @override
  String get musicToggleOff => 'Désactiver la musique';

  @override
  String get settingsDeveloper => 'Développeur';

  @override
  String get settingsDeveloperName => 'BT developer';

  @override
  String get settingsCopyright => '© BaLa Dream';

  @override
  String get removeAdsAlreadyOwned =>
      'Vous possédez déjà l\'option Supprimer les publicités. Merci pour votre soutien !';

  @override
  String get purchasePending => 'Votre achat est en cours de traitement…';

  @override
  String get purchaseError =>
      'L\'achat n\'a pas pu être finalisé. Veuillez réessayer.';

  @override
  String get purchaseStoreUnavailable =>
      'La boutique n\'est pas disponible pour le moment. Vérifiez que vous êtes connecté, puis réessayez.';

  @override
  String get purchaseProductUnavailable =>
      'Cet achat n\'est pas disponible pour le moment. Veuillez réessayer plus tard.';

  @override
  String get purchaseCancelled => 'Achat annulé.';

  @override
  String get restoreSuccess => 'Vos achats ont été restaurés.';

  @override
  String get restoreNothingFound => 'Aucun achat précédent trouvé.';

  @override
  String get errorGeneric => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get errorNoInternet =>
      'Vous êtes hors ligne. Cette fonctionnalité nécessite une connexion internet.';

  @override
  String get errorAdUnavailable =>
      'Aucune publicité n\'est disponible pour le moment. Veuillez réessayer plus tard.';

  @override
  String get errorPuzzleMissing => 'Cette grille n\'a pas pu être chargée.';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get okButton => 'OK';

  @override
  String get confirmButton => 'Confirmer';
}
