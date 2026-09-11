/// Metadata about a language the app's UI can be displayed in.
///
/// Unlike the crossword app there is no second "puzzle language" list to
/// keep this in sync with — a deck holds emoji, not words, so this is the
/// only language concept in the app.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.isRtl,
    required this.flagEmoji,
  });

  final String code;
  final String nativeName;
  final bool isRtl;

  /// Unicode regional-indicator flag representing this language, shown
  /// next to [nativeName] wherever languages are listed. Language-to-flag
  /// is inherently a many-to-one simplification (English isn't one
  /// country) — these pick the conventional representative flag used by
  /// most language pickers (e.g. Google Translate's Arabic → Saudi Arabia).
  final String flagEmoji;

  static const all = <AppLanguage>[
    AppLanguage(code: 'en', nativeName: 'English', isRtl: false, flagEmoji: '🇬🇧'),
    AppLanguage(code: 'ar', nativeName: 'العربية', isRtl: true, flagEmoji: '🇸🇦'),
    AppLanguage(code: 'de', nativeName: 'Deutsch', isRtl: false, flagEmoji: '🇩🇪'),
    AppLanguage(code: 'fr', nativeName: 'Français', isRtl: false, flagEmoji: '🇫🇷'),
    AppLanguage(code: 'es', nativeName: 'Español', isRtl: false, flagEmoji: '🇪🇸'),
    AppLanguage(code: 'it', nativeName: 'Italiano', isRtl: false, flagEmoji: '🇮🇹'),
  ];

  static AppLanguage byCode(String code) {
    return all.firstWhere((l) => l.code == code, orElse: () => all.first);
  }
}
