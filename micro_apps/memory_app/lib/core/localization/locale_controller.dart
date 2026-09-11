import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../storage/local_storage_service.dart';
import '../storage/storage_keys.dart';
import 'supported_locales.dart';

/// Owns the app's UI language — the only language setting this app has.
/// On first run this resolves from the device locale; once the
/// user (or Settings) sets it explicitly, that choice is persisted and
/// wins over the device locale on every future launch.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final storage = ref.watch(localStorageServiceProvider);
    final saved = storage.getString(StorageKeys.uiLanguageCode);
    if (saved != null && SupportedLocales.isSupported(saved)) {
      return Locale(saved);
    }
    return SupportedLocales.resolveFromDevice(PlatformDispatcher.instance.locales);
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
