# memory_app

Offline Memory Match — the fourth app in the puzzle portfolio, built on
the sudoku app's skeleton.

400 bundled decks (100 each across easy/medium/hard/expert), six UI
languages, no account and no network required to play. The cards are
emoji, so unlike the crossword and word search apps there is no puzzle
language at all — the same decks serve every locale.

```bash
flutter pub get
flutter run

dart run tool/generate_puzzles.dart   # regenerate assets/puzzles/
dart run tool/generate_icon.dart      # regenerate assets/icon/
flutter analyze && flutter test
```

See [CLAUDE.md](CLAUDE.md) for the architecture, how the difficulty tiers
work, why a mismatch only sometimes costs a life, and the traps worth not
rediscovering.
