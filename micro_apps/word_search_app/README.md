# word_search_app

Offline Word Search — the third app in the puzzle portfolio, built on the
crossword and sudoku apps' shared skeleton.

2,400 bundled puzzles (100 each across easy/medium/hard/expert, in six
game languages), six UI languages, no account and no network required to
play.

```bash
flutter pub get
flutter run

dart run tool/generate_puzzles.dart   # regenerate assets/puzzles/
flutter analyze && flutter test
```

See [CLAUDE.md](CLAUDE.md) for the architecture, how difficulty tiers are
defined, and the traps worth not rediscovering.
