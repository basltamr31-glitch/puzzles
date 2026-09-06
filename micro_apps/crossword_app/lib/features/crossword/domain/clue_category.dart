/// A broad semantic category for a clue, shown as a small icon beside the
/// clue text on easy puzzles.
///
/// Deliberately **category, not depiction**. An icon of a cat next to
/// "Common household pet that meows" would simply be the answer; a generic
/// paw print tells the player they're looking for an animal without giving
/// the word away. That constraint is what makes this a support for the
/// text rather than a replacement for solving it.
///
/// Categories are language-independent, so a single set of icons serves
/// every game language — the word banks in `tool/` map their own words
/// onto these shared ids.
enum ClueCategory {
  animal('animal'),
  nature('nature'),
  food('food'),
  home('home'),
  people('people'),
  body('body'),
  time('time'),
  place('place'),
  object('object'),
  color('color'),
  action('action');

  const ClueCategory(this.id);

  final String id;

  /// Returns null for an unknown or absent id — a clue simply shows no
  /// icon, which is the correct outcome for abstract words that can't be
  /// meaningfully categorized.
  static ClueCategory? fromId(String? id) {
    if (id == null) return null;
    for (final category in ClueCategory.values) {
      if (category.id == id) return category;
    }
    return null;
  }
}
