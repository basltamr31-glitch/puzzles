/// The four puzzle difficulty tiers. Deliberately a plain enum rather than
/// something hardcoded per-screen — screens read [Difficulty.values] so
/// adding a fifth tier later is a one-line change here.
enum Difficulty {
  easy,
  medium,
  hard,
  expert;

  String get storageValue => name;

  static Difficulty fromStorageValue(String value) {
    return Difficulty.values.firstWhere(
      (d) => d.name == value,
      orElse: () => Difficulty.easy,
    );
  }
}
