// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Sudoku';

  @override
  String get onboardingTitle => 'Sudoku';

  @override
  String get onboardingSubtitle =>
      'Rompecabezas numéricos clásicos para todos los niveles: 400 cuadrículas para resolver, sin cuenta ni conexión a Internet.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get chooseDifficultyTitle => 'Elige una dificultad';

  @override
  String get chooseDifficultySubtitle =>
      'Puedes jugar cualquier dificultad en cualquier momento.';

  @override
  String get difficultyEasy => 'Fácil';

  @override
  String get difficultyMedium => 'Medio';

  @override
  String get difficultyHard => 'Difícil';

  @override
  String get difficultyExpert => 'Experto';

  @override
  String puzzleListTitle(String difficulty) {
    return 'Crucigramas de nivel $difficulty';
  }

  @override
  String get puzzleStatusCompleted => 'Completado';

  @override
  String get puzzleStatusInProgress => 'En curso';

  @override
  String get puzzleStatusNotStarted => 'Sin empezar';

  @override
  String get puzzleStatusLocked => 'Bloqueado';

  @override
  String get puzzleLockedMessage =>
      'Resuelve el crucigrama anterior para desbloquear este.';

  @override
  String puzzleNumberLabel(String number) {
    return 'Crucigrama $number';
  }

  @override
  String puzzleCluesLabel(int count) {
    return '$count pistas';
  }

  @override
  String puzzlesSolvedLabel(int solved, int total) {
    return '$solved de $total resueltos';
  }

  @override
  String get noPuzzlesTitle => 'Todavía no hay crucigramas';

  @override
  String get noPuzzlesMessage =>
      'Nuevos crucigramas para este nivel están en camino.';

  @override
  String cellSemanticLabel(int row, int column) {
    return 'Fila $row, columna $column';
  }

  @override
  String get cellEmpty => 'Vacía';

  @override
  String numberPadDigitLabel(int digit) {
    return 'Introducir $digit';
  }

  @override
  String numberPadNoteLabel(int digit) {
    return 'Nota $digit';
  }

  @override
  String get undoButton => 'Deshacer';

  @override
  String get eraseButton => 'Borrar';

  @override
  String get notesButton => 'Notas';

  @override
  String get hintButton => 'Pista';

  @override
  String get hintConfirmTitle => '¿Usar una pista?';

  @override
  String get hintConfirmMessage =>
      'Se rellenará el número de la casilla seleccionada.';

  @override
  String get watchAdForHint => 'Mira un video corto para obtener una pista';

  @override
  String get checkButton => 'Comprobar';

  @override
  String get checkNoMistakes => 'Sin errores por ahora.';

  @override
  String get restartPuzzleButton => 'Reiniciar';

  @override
  String get restartConfirmTitle => '¿Reiniciar este crucigrama?';

  @override
  String get restartConfirmMessage =>
      'Se borrará tu progreso en este crucigrama.';

  @override
  String get puzzleCompletedTitle => '¡Crucigrama completado!';

  @override
  String puzzleCompletedTime(String time) {
    return 'Resuelto en $time';
  }

  @override
  String get nextPuzzleButton => 'Siguiente crucigrama';

  @override
  String get backToPuzzlesButton => 'Volver a los crucigramas';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsUiLanguage => 'Idioma de la app';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get settingsSound => 'Efectos de sonido';

  @override
  String get settingsVibration => 'Vibración';

  @override
  String get settingsMusic => 'Música de fondo';

  @override
  String get musicTrackOff => 'Desactivada';

  @override
  String get musicTrackCalm => 'Tranquila';

  @override
  String get musicTrackGentle => 'Suave';

  @override
  String get musicTrackUplifting => 'Animada';

  @override
  String get musicTrackFocus => 'Concentración';

  @override
  String get musicTrackBright => 'Luminosa';

  @override
  String get musicTrackNight => 'Noche';

  @override
  String get settingsReminders => 'Recordatorios de juego';

  @override
  String get remindersPermissionDenied =>
      'Las notificaciones están desactivadas para esta aplicación. Puedes activarlas en los ajustes de tu dispositivo.';

  @override
  String get reminderTitle => 'Un crucigrama te espera';

  @override
  String get reminderBody =>
      'Tómate un descanso y resuelve uno — solo lleva unos minutos.';

  @override
  String get settingsTestSound => 'Probar sonido';

  @override
  String get soundTestOk => 'Sonido reproducido.';

  @override
  String soundTestFailed(String error) {
    return 'Error de sonido: $error';
  }

  @override
  String get settingsRemoveAds => 'Quitar anuncios';

  @override
  String get settingsRestorePurchases => 'Restaurar compras';

  @override
  String get settingsAdPrivacyOptions => 'Opciones de privacidad de anuncios';

  @override
  String get settingsPrivacy => 'Política de privacidad';

  @override
  String get privacyPolicyViewOnline => 'Ver en línea';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String settingsVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get removeAdsTitle => 'Quitar anuncios';

  @override
  String get removeAdsDescription =>
      'Disfruta de cada crucigrama sin anuncios de banner ni de pantalla completa — para siempre, con una sola compra.';

  @override
  String get removeAdsPrice => '1,00 \$';

  @override
  String get removeAdsPurchaseButton => 'Comprar — 1,00 \$';

  @override
  String removeAdsPurchaseButtonWithPrice(String price) {
    return 'Comprar — $price';
  }

  @override
  String get musicToggleOn => 'Activar la música';

  @override
  String get musicToggleOff => 'Desactivar la música';

  @override
  String get settingsDeveloper => 'Desarrollador';

  @override
  String get settingsDeveloperName => 'BT developer';

  @override
  String get settingsCopyright => '© BaLa Dream';

  @override
  String get removeAdsAlreadyOwned =>
      'Ya tienes la opción Quitar anuncios. ¡Gracias por tu apoyo!';

  @override
  String get purchasePending => 'Tu compra se está procesando…';

  @override
  String get purchaseError =>
      'No se pudo completar la compra. Inténtalo de nuevo.';

  @override
  String get purchaseStoreUnavailable =>
      'La tienda no está disponible en este momento. Comprueba que has iniciado sesión e inténtalo de nuevo.';

  @override
  String get purchaseProductUnavailable =>
      'Esta compra no está disponible en este momento. Inténtalo de nuevo más tarde.';

  @override
  String get purchaseCancelled => 'Compra cancelada.';

  @override
  String get restoreSuccess => 'Tus compras se han restaurado.';

  @override
  String get restoreNothingFound => 'No se encontraron compras anteriores.';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get errorNoInternet =>
      'Estás sin conexión. Esta función necesita conexión a internet.';

  @override
  String get errorAdUnavailable =>
      'No hay ningún anuncio disponible en este momento. Inténtalo más tarde.';

  @override
  String get errorPuzzleMissing => 'No se pudo cargar este crucigrama.';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get okButton => 'Aceptar';

  @override
  String get confirmButton => 'Confirmar';
}
