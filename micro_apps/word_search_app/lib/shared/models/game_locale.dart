/// Metadata about a language the word search's puzzle *content* is available
/// in. Deliberately separate from the app's UI language — spec §11/§12:
/// the UI can be Arabic while puzzles are played in English.
class GameLocale {
  const GameLocale({
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

  static const all = <GameLocale>[
    GameLocale(
      code: 'en',
      nativeName: 'English',
      isRtl: false,
      flagEmoji: '🇬🇧',
    ),
    GameLocale(
      code: 'ar',
      nativeName: 'العربية',
      isRtl: true,
      flagEmoji: '🇸🇦',
    ),
    GameLocale(
      code: 'de',
      nativeName: 'Deutsch',
      isRtl: false,
      flagEmoji: '🇩🇪',
    ),
    GameLocale(
      code: 'fr',
      nativeName: 'Français',
      isRtl: false,
      flagEmoji: '🇫🇷',
    ),
    GameLocale(
      code: 'es',
      nativeName: 'Español',
      isRtl: false,
      flagEmoji: '🇪🇸',
    ),
    GameLocale(
      code: 'it',
      nativeName: 'Italiano',
      isRtl: false,
      flagEmoji: '🇮🇹',
    ),
  ];

  static GameLocale byCode(String code) {
    return all.firstWhere((l) => l.code == code, orElse: () => all.first);
  }
}
