// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Mots mêlés';

  @override
  String get onboardingTitle => 'Mots mêlés';

  @override
  String get onboardingSubtitle =>
      'De petites grilles de mots mêlés à jouer partout, à tout moment — sans compte, sans connexion internet.';

  @override
  String get continueButton => 'Continuer';

  @override
  String get chooseGameLanguageTitle => 'Choisissez votre langue de jeu';

  @override
  String get chooseGameLanguageSubtitle =>
      'C\'est la langue de la liste de mots. Vous pourrez la modifier plus tard dans les paramètres.';

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
  String puzzlesSolvedLabel(int solved, int total) {
    return '$solved sur $total résolues';
  }

  @override
  String get puzzleLockedMessage =>
      'Résolvez la grille précédente pour déverrouiller celle-ci.';

  @override
  String puzzleNumberLabel(String number) {
    return 'Grille $number';
  }

  @override
  String puzzleWordsLabel(int count) {
    return '$count mots';
  }

  @override
  String wordsFoundLabel(int found, int total) {
    return '$found sur $total trouvés';
  }

  @override
  String get noPuzzlesTitle => 'Pas encore de grilles';

  @override
  String get noPuzzlesMessage =>
      'De nouvelles grilles pour ce niveau arrivent bientôt.';

  @override
  String get hintButton => 'Indice';

  @override
  String get hintConfirmTitle => 'Utiliser un indice ?';

  @override
  String get hintConfirmMessage => 'Cela trouvera un mot pour vous.';

  @override
  String get watchAdForHint =>
      'Regardez une courte vidéo pour obtenir un indice';

  @override
  String get restartPuzzleButton => 'Recommencer';

  @override
  String get zoomInButton => 'Zoom avant';

  @override
  String get zoomOutButton => 'Zoom arrière';

  @override
  String get zoomAreaLabel => 'Zone de zoom';

  @override
  String get zoomAreaTopLeft => 'En haut à gauche';

  @override
  String get zoomAreaTopRight => 'En haut à droite';

  @override
  String get zoomAreaBottomLeft => 'En bas à gauche';

  @override
  String get zoomAreaBottomRight => 'En bas à droite';

  @override
  String get restartConfirmTitle => 'Recommencer cette grille ?';

  @override
  String get restartConfirmMessage =>
      'Votre progression sur cette grille sera effacée.';

  @override
  String get exitPuzzleConfirmTitle => 'Quitter la grille ?';

  @override
  String get exitPuzzleConfirmMessage =>
      'Votre progression est enregistrée automatiquement.';

  @override
  String get puzzleCompletedTitle => 'Grille terminée !';

  @override
  String get puzzleCompletedMessage => 'Bien joué. Prêt pour la suivante ?';

  @override
  String get nextPuzzleButton => 'Grille suivante';

  @override
  String get backToPuzzlesButton => 'Retour aux grilles';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsUiLanguage => 'Langue de l\'application';

  @override
  String get settingsGameLanguage => 'Langue des grilles';

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
  String get partnerUnlockTitle => 'Ou supprimez les bannières gratuitement';

  @override
  String partnerUnlockDescription(String app) {
    return 'Installez $app et les bannières disparaissent définitivement. Les indices et les vies supplémentaires utilisent toujours une courte vidéo.';
  }

  @override
  String partnerUnlockButton(String app) {
    return 'Obtenir $app';
  }

  @override
  String partnerUnlockActive(String app) {
    return 'Les bannières sont désactivées — merci d\'avoir installé $app.';
  }

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

  @override
  String get mistakesLabel => 'Erreurs';

  @override
  String livesRemaining(int remaining, int max) {
    return '$remaining vies sur $max restantes';
  }

  @override
  String get outOfLivesTitle => 'Plus de vies';

  @override
  String outOfLivesMessage(int max) {
    return 'Cela fait $max erreurs. Recommencez cette grille pour un nouvel essai.';
  }

  @override
  String get outOfLivesTryAgain => 'Réessayer';

  @override
  String outOfLivesMessageRevive(int max) {
    return 'Cela fait $max erreurs. Vous pouvez gagner une vie supplémentaire ou recommencer cette grille.';
  }

  @override
  String get outOfLivesWatchAd => 'Regarder une vidéo pour une vie de plus';

  @override
  String get outOfLivesExtraLife => 'Obtenir une vie de plus';

  @override
  String get rewardHeadlineFlawless => 'Sans faute !';

  @override
  String get rewardHeadlineGreat => 'Belle résolution !';

  @override
  String get rewardHeadlineSolved => 'Résolu !';

  @override
  String get rewardNoMistakes => 'Aucune erreur';

  @override
  String rewardMistakesMade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erreurs',
      one: '1 erreur',
    );
    return '$_temp0';
  }

  @override
  String rewardStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'série de $days jours',
      one: 'série de 1 jour',
    );
    return '$_temp0';
  }

  @override
  String rewardBestStreak(int days) {
    return 'Nouvelle meilleure série : $days';
  }

  @override
  String rewardBadgeUnlocked(String badge) {
    return 'Nouveau badge : $badge';
  }

  @override
  String rewardStarsEarned(int stars, int max) {
    return '$stars étoiles sur $max';
  }

  @override
  String get achievementsTitle => 'Progression';

  @override
  String get achievementsStreakLabel => 'Jours d\'affilée';

  @override
  String get achievementsSolvedLabel => 'Grilles résolues';

  @override
  String get achievementsStarsLabel => 'Étoiles gagnées';

  @override
  String get achievementsBestStreakLabel => 'Meilleure série';

  @override
  String get achievementsBadgesTitle => 'Badges';

  @override
  String achievementsEarnedSemantics(String badge) {
    return '$badge, obtenu';
  }

  @override
  String achievementsLockedSemantics(String badge) {
    return '$badge, verrouillé';
  }

  @override
  String get achievementFirstSolveTitle => 'Première résolution';

  @override
  String get achievementFirstSolveDescription =>
      'Terminez votre première grille';

  @override
  String get achievementTenSolvesTitle => 'En chauffe';

  @override
  String get achievementTenSolvesDescription => 'Terminez 10 grilles';

  @override
  String get achievementFiftySolvesTitle => 'Habitué';

  @override
  String get achievementFiftySolvesDescription => 'Terminez 50 grilles';

  @override
  String get achievementHundredSolvesTitle => 'Centenaire';

  @override
  String get achievementHundredSolvesDescription => 'Terminez 100 grilles';

  @override
  String get achievementFlawlessFiveTitle => 'Perfectionniste';

  @override
  String get achievementFlawlessFiveDescription =>
      'Obtenez trois étoiles sur 5 grilles';

  @override
  String get achievementWeekStreakTitle => 'Sept jours';

  @override
  String get achievementWeekStreakDescription => 'Jouez 7 jours d\'affilée';
}
