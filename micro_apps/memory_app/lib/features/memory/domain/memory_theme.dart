/// The subject a deck's symbols are drawn from.
///
/// Deliberately an **id, not a label**: the theme name a player reads is
/// looked up in the UI language, while the symbols themselves are emoji
/// and belong to no language at all. A deck asset therefore stores
/// `"theme": "animals"` and nothing translatable.
///
/// This is the whole reason Memory Match has no game-language concept the
/// way crossword and word search do: a picture of a dog is a picture of a
/// dog in every locale, so there is exactly one set of decks and the UI
/// language is the only language in the app.
enum MemoryTheme {
  animals('animals'),
  food('food'),
  nature('nature'),
  travel('travel'),
  sports('sports'),
  faces('faces'),
  party('party'),
  objects('objects');

  const MemoryTheme(this.id);

  final String id;

  /// Returns null for an unknown or absent id. A deck whose theme this
  /// build does not know still plays — it simply shows the generic puzzle
  /// title — so shipping new themed content can never hard-fail an older
  /// app version.
  static MemoryTheme? fromId(String? id) {
    if (id == null) return null;
    for (final theme in MemoryTheme.values) {
      if (theme.id == id) return theme;
    }
    return null;
  }
}
