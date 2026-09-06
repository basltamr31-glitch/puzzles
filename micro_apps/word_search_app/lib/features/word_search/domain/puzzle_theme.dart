/// The subject a puzzle's word list is drawn from.
///
/// Deliberately an **id, not a label**: the theme name a player reads is
/// looked up in the UI language, while the words themselves are in the
/// game language. A puzzle asset therefore stores `"theme": "animals"`
/// and nothing translatable — the same content file reads correctly with
/// an Arabic UI and a French word list.
///
/// Themes are shared across every game language; each language's word
/// bank in `tool/word_banks/` fills the same set of ids with its own
/// words. Adding a theme means adding it here, in every bank, and in
/// every ARB file.
enum PuzzleTheme {
  animals('animals'),
  food('food'),
  nature('nature'),
  home('home'),
  body('body'),
  clothes('clothes'),
  travel('travel'),
  sports('sports');

  const PuzzleTheme(this.id);

  final String id;

  /// Returns null for an unknown or absent id. A puzzle whose theme this
  /// build does not know still plays — it simply shows the generic
  /// puzzle title — so shipping new themed content can never hard-fail an
  /// older app version.
  static PuzzleTheme? fromId(String? id) {
    if (id == null) return null;
    for (final theme in PuzzleTheme.values) {
      if (theme.id == id) return theme;
    }
    return null;
  }
}
