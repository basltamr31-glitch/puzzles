import 'dart:ui';

import '../../app/app_config.dart';

/// Resolves the app's UI language following spec §10: use the device
/// language if supported, otherwise fall back to English.
class SupportedLocales {
  SupportedLocales._();

  /// Derived from [AppConfig.supportedUILanguageCodes] rather than a
  /// second hardcoded list — two lists that are supposed to always match
  /// are exactly the kind of thing that quietly drifts apart.
  static List<Locale> get all =>
      AppConfig.supportedUILanguageCodes.map(Locale.new).toList();

  static bool isSupported(String languageCode) =>
      AppConfig.supportedUILanguageCodes.contains(languageCode);

  static bool isRtl(String languageCode) =>
      AppConfig.rtlLanguageCodes.contains(languageCode);

  /// Picks the best-matching supported UI locale for the device's
  /// preferred locales, falling back to English.
  static Locale resolveFromDevice(List<Locale> deviceLocales) {
    for (final locale in deviceLocales) {
      if (isSupported(locale.languageCode)) {
        return Locale(locale.languageCode);
      }
    }
    return const Locale(AppConfig.fallbackUILanguageCode);
  }
}
