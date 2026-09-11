import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../storage/local_storage_service.dart';
import '../storage/storage_keys.dart';
import 'supported_locales.dart';

/// Owns the app's UI language (spec §10). Still a separate *setting* from
/// the game (puzzle) language — Settings can point them at different
/// languages and that choice sticks — but the two are no longer resolved
/// independently on first run.
///
/// Precedence: an explicit choice in Settings wins; failing that the
/// chosen game language, if the UI is translated into it; failing that
/// the device locale; failing that English. Falling straight through to
/// the device locale is what put an Arabic player on an English-language
/// phone in front of an Arabic board with `Hint`/`Check` written in
/// English — picking a language to play in is a strong statement about
/// what you read.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final storage = ref.watch(localStorageServiceProvider);
    final saved = storage.getString(StorageKeys.uiLanguageCode);
    if (saved != null && SupportedLocales.isSupported(saved)) {
      return Locale(saved);
    }
    final gameLanguage = storage.getString(StorageKeys.gameLanguageCode);
    if (gameLanguage != null && SupportedLocales.isSupported(gameLanguage)) {
      return Locale(gameLanguage);
    }
    return SupportedLocales.resolveFromDevice(
      PlatformDispatcher.instance.locales,
    );
  }

  /// Called when the player picks a game language. Only a *default* — an
  /// explicit Settings choice is never overwritten, so someone who
  /// deliberately reads the app in one language while solving in another
  /// keeps that.
  void applyGameLanguageDefault(String languageCode) {
    final storage = ref.read(localStorageServiceProvider);
    if (storage.getString(StorageKeys.uiLanguageCode) != null) return;
    if (!SupportedLocales.isSupported(languageCode)) return;
    state = Locale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    if (!SupportedLocales.isSupported(languageCode)) return;
    final storage = ref.read(localStorageServiceProvider);
    await storage.setString(StorageKeys.uiLanguageCode, languageCode);
    state = Locale(languageCode);
    ref.read(analyticsServiceProvider).logEvent(
      AnalyticsEvents.uiLanguageSelected,
      {'language_code': languageCode},
    );
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);
