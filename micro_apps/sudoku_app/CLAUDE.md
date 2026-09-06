# Sudoku app — working agreement & architecture

The second app in the portfolio, built on the crossword app's skeleton.
`app/` and `core/` were **copied**, not extracted into a shared package —
each micro app stays independently shippable and versioned. The cost is
real: a fix to `core/` has to be applied in both apps. Make that trade
deliberately rather than "fixing" it without being asked.

Branding: **Developer — BT developer. Copyright — BaLa Dream.**
App/product identity is fixed: `com.baslt.sudoku_app`, product ID
`remove_ads`.

---

## What is different from the crossword app

Read this before assuming a crossword recipe applies here.

| | Crossword | Sudoku |
| --- | --- | --- |
| Puzzle content | Per-language word banks in `tool/word_banks/` | Generated grids, **no language dimension at all** |
| Assets | One JSON per puzzle, under `<lang>/<difficulty>/` | One JSON per difficulty, 100 puzzles each |
| Language settings | UI language *and* puzzle language | UI language only |
| Onboarding | welcome → language → difficulty | welcome → difficulty |
| Input | Hidden `TextField` + OS keyboard | On-screen number pad, no keyboard |
| Palette | Indigo + amber on cream | Teal + orange on cool white |

The two apps are kept at **visual parity** apart from the palette: the
decorative art, per-tier difficulty accents, card shadows, difficulty
banner, and completion burst are the same design in both. When one app
gains a UI treatment, the other should get it too — with its own colour
tokens, never by copying the other's palette.

"Add a new language" here means **UI translation only** — an ARB file and
an `AppConfig.supportedUILanguageCodes` entry. There is no puzzle content
to generate, and there must never be a `supportedGameLanguageCodes`.

---

## Non-negotiable invariants

1. **Puzzle content is generated, never hand-authored.** `tool/` owns
   everything under `assets/puzzles/`. Never hand-edit a puzzle JSON.
2. **Every bundled puzzle is validated through the real solver**, and
   that validation is a permanent test, not a throwaway script — see
   `test/features/sudoku/bundled_puzzles_test.dart`. It runs in seconds;
   don't delete it to speed up the suite.
3. **The generator and the app share one engine.**
   `lib/features/sudoku/domain/sudoku_solver.dart` is pure Dart with no
   Flutter import precisely so `tool/generate_puzzles.dart` can run it
   under plain `dart run`. Keep it that way — a second, tool-only
   implementation of the rules is how a puzzle ships unsolvable.
4. **Every puzzle has exactly one solution.** Uniqueness is checked
   during generation *and* asserted in tests. A Sudoku with two solutions
   is not a Sudoku.
5. **Ad unit IDs are never committed.** They live in the gitignored
   `ad_config.json` (copy `ad_config.example.json`) and reach the app via
   `--dart-define-from-file`; debug without them falls back to Google test
   units, release falls back to empty. The AdMob **App ID** is different:
   it *is* committed, in `AndroidManifest.xml`, because it is public and
   the ads SDK crashes on launch without it.
6. **Prices are not hardcoded.** The store reports them; bundled strings
   are only an offline fallback.
7. **The app stays fully offline.** No backend, no database, no accounts —
   all state is SharedPreferences. Notifications are **local only**.

---

## How difficulty actually works

Two constraints per tier, both required (`sudokuTiers` in
`sudoku_generator.dart`):

- **A clue-count window.** Each puzzle picks a random target inside it,
  so one tier's grids vary the way a real puzzle book's do.
- **A technique ceiling**, from `SudokuSolver.grade` — the hardest
  technique a logical solver needs: naked single → hidden single →
  locked candidates → naked pair → guess.

Neither alone is enough. Greedy digging under the technique cap *alone*
will strip a naked-singles-only grid down to ~25 clues, which no player
would accept as "Easy". Given count alone is the classic lazy measure and
is wrong often enough to matter.

| Tier | Clues | Needs at most | Needs at least |
| --- | --- | --- | --- |
| easy | 36–44 | naked singles | — |
| medium | 30–35 | hidden singles | hidden singles |
| hard | 26–29 | naked pairs | locked candidates |
| expert | 22–26 | (uncapped) | guessing |

The grader is pinned to published puzzles in `sudoku_solver_test.dart`
(the Wikipedia sample grades as naked-single; Inkala's 2012 grid and
Escargot both grade as `guess`). If you change the technique set, those
tests are the check that difficulty still means something.

### Regenerating

```bash
dart run tool/generate_puzzles.dart            # every difficulty, ~15s
dart run tool/generate_puzzles.dart hard       # just one
```

Seeds are fixed per tier, so a regeneration reproduces the same set
rather than silently reshuffling every player's puzzle numbering. Change
a seed only when you intend to replace the content.

---

## Architecture map

```
lib/
  app/            app_config.dart (all constants), router, theme
  core/           ads, audio, billing, consent, notifications,
                  localization, storage — copied from crossword_app
  features/
    sudoku/
      domain/     models, solver/grader, generator, saved-progress format
      data/       PuzzleRepository (asset bundles + progress)
      presentation/ controller, grid view, number pad, screen
    puzzle_list/  list + sequential unlock
    difficulty/   tier selection
    settings/     single settings surface
tool/             puzzle generator, icon generator, audio generator
```

Platform-specific plugins (`google_mobile_ads`, `in_app_purchase`,
`audioplayers`, `flutter_local_notifications`) are reached only through
the abstractions in `core/`, via conditional-import factories, so
web/desktop builds stay clean.

---

## Traps already hit — do not reintroduce

- **`solve`/`countSolutions` must reject an inconsistent grid up front.**
  Candidate pruning only inspects *empty* cells, so two identical givens
  in one row send the search exhaustively down every branch — it does not
  terminate in any useful time. Both entry points guard with
  `isConsistent` first.
- **`Equatable` compares a `List<Set<int>>` by identity per element.**
  `SudokuGameState.props` flattens the pencil marks into strings; without
  that, toggling a note replaces the list but the UI never rebuilds.
- **The 3x3 box separators are painted over the grid, not drawn as cell
  borders.** A separator that is half on each of two cells comes out
  visibly uneven once the cell size isn't a whole number of pixels.
- **A modal bottom sheet is capped at 9/16 of the screen.** The music
  picker holds one tile per track inside a `SingleChildScrollView` for
  exactly this reason — a bare `Column` overflowed in the crossword app
  once its track count reached seven. `test/features/settings/
  music_picker_overflow_test.dart` guards it, including a case proving a
  plain `Column` really does break.
- **WCAG contrast is the wrong test for "are these two tints
  distinguishable".** Two colours at the same lightness but different hue
  score ~1.0 while looking obviously different. `color_contrast_test.dart`
  uses contrast for text legibility and channel distance for cell-state
  distinctness — don't collapse them into one metric.
- **A stale `GeneratedPluginRegistrant.java` breaks the release build.**
  Running `dart run flutter_native_splash:create` leaves that generated
  file listing `flutter_native_splash` — a *dev* dependency, absent from
  the release classpath — and neither `flutter clean` nor `flutter pub
  get` rewrites it, so `assembleRelease` fails with "package
  net.jonhanson.flutter_native_splash does not exist". Delete
  `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
  and rebuild; the build regenerates it correctly.
- **audioplayers takes *permanent* audio focus by default.** Every player
  defaults to `AudioContextConfigFocus.gain`, which on Android is a
  request for permanent focus — so a key tap stopped the background music
  and nothing ever restored it. The SFX player must use
  `mixWithOthers` (`AndroidAudioFocus.none`); only the music player takes
  focus. `test/core/audio/audio_focus_test.dart` pins both.
- **A `SegmentedButton` splits its width evenly, whatever the words are.**
  The four tier labels run from "Hard" to "Difficile", and at 320dp they
  wrapped down to one character per line. `DifficultySwitcher` drops the
  tier icon to a coloured dot below 96dp per segment, forbids wrapping,
  and scales the label down to fit. Don't reintroduce a bare `Text` there
  — `difficulty_switcher_layout_test.dart` checks every language at 320dp.
- **A `late final AnimationController` is a dispose-time crash.** With a
  lazy initialiser, a screen the player never triggered the animation on
  would first *construct* the controller inside `dispose()`, where
  `createTicker` looks up `TickerMode` on an already-deactivated element.
  Build it in `initState`.
- **A fixed `childAspectRatio` cannot hold text that scales.** The
  difficulty tiles derive their ratio from what they actually contain
  (fixed badge + label at the current text scale); a hardcoded 1.3
  overflowed both at 320dp and at a 1.5x accessibility scale.
- **An unconstrained `Text` inside a button's `Row` overflows sideways.**
  `PrimaryButton`/`SecondaryButton` wrap the label in
  `Flexible(FittedBox(scaleDown))` — a long translated label at a large
  text scale is simply wider than the button.
- **The welcome screen must scroll.** `Spacer`s only absorb *positive*
  free space, so the fixed layout was 124px too tall at 1.5x text on a
  4-inch phone. It is a `SingleChildScrollView` with a viewport-height
  minimum, which keeps the centred look when there is room.
- **Objects created in `setUp` belong to the real async zone.** A
  `Completer`, a `Future`, or a primed `rootBundle` entry made there is
  never observed inside a `testWidgets` fake-async zone — the widget sits
  on its pending branch forever and it reads like a product bug. Build
  them inside the test body.
- **The apps are declared 13+**, in Play Console and in the privacy
  policy, and those two must never disagree — a policy claiming a wider
  audience than the listing is what drags an app into Google Play's
  Families programme by accident. Because of that declaration,
  `tagForChildDirectedTreatment` / `tagForUnderAgeOfConsent` are
  deliberately not set; both force non-personalized ads for every user.
  `MaxAdContentRating.g` *is* set, because the policy promises ads
  "rated suitable for a general audience" — change one and you must
  change the other. `privacy_policy_test.dart` pins the policy half.
- **Ads must not start before consent.** `main()` deliberately does *not*
  initialize the Mobile Ads SDK; `adsReadyProvider` does, and only after
  `consentRequestProvider` resolves. Every ad call goes through
  `ConsentGatedAdService`, so a new screen cannot bypass it. Under GDPR an
  ad request made before a lawful basis exists cannot be fixed afterwards
  — see `test/core/ads/consent_gate_test.dart`.
- **`rootBundle` caches per asset path, across tests.** The cached Future
  is created in whichever `testWidgets` zone asked first, so every later
  test awaits a Future from a dead fake-async zone and hangs on a loading
  spinner. Any test file that pumps a widget reading an asset needs
  `setUp(rootBundle.clear)`.
- **`build/unit_test_assets/` goes stale when assets change.**
  `flutter test` builds its own asset bundle there and does not always
  refresh it, so a newly added asset can fail `rootBundle.load` in tests
  while being present in the APK — the error says "asset does not exist",
  which sends you hunting in `pubspec.yaml` for nothing. Delete that
  folder and re-run.
- **`pumpAndSettle` never returns on a screen with a loading spinner.**
  `CircularProgressIndicator` animates forever, so the layout tests use
  `pumpFrames` (bounded pumps) instead. A test that "times out" on these
  screens is usually this, not a hang in the app.

### The responsive matrix

`test/app/responsive_layout_test.dart` renders every screen across
device size x text scale x text direction x theme. `testWidgets` fails on
any unconsumed Flutter error, and a `RenderFlex overflowed` is exactly
that — so reaching the end of a case *is* the assertion. Every layout bug
listed above was found by it, not by looking at screenshots. Add new
screens to it rather than checking them by eye.

- **`FutureProvider.family` caches and never re-reads storage.**
  Completing/restarting a puzzle must `ref.invalidate(puzzleSummariesProvider)`
  or the unlock state goes stale.
- **`PlayerMode.lowLatency` routes to Android SoundPool** and fails
  silently. Use the default media-player mode.
- **Phone speakers reproduce almost nothing below ~300 Hz.** Music must
  sit at ~350 Hz and above or it's felt as vibration, not heard.
- **Riverpod 3**: `StateNotifier` *and* `StateProvider` come from
  `flutter_riverpod/legacy.dart` — prefer a plain `Notifier` over both.
  `AsyncValue` exposes `.value`, not `.valueOrNull`.
- **The gameplay controller owns a periodic `Timer`.** Tests must dispose
  every controller they create, or it keeps ticking after the container
  is gone.
- **SharedPreferences test mocks** take plain values, not JSON-encoded
  strings.
- `flutter test` isolates by file; go_router state can leak between
  `testWidgets` in one file — hence the separate
  `app_flow_returning_user_test.dart`.
- Generated `lib/core/localization/generated/` files periodically vanish
  between sessions — rerun `flutter gen-l10n`.

---

## Verify before reporting done

```bash
flutter analyze && flutter test && flutter build apk --release
```

All three must pass. Report real output; never claim console/account
setup that only the owner can perform.

---

## Current state

- **6 UI languages**: en, ar, de, fr, es, it — full translation.
- **Music is not bundled.** `assets/audio/music/` takes six MP3 tracks
  supplied by hand — see that folder's README for the filename contract
  and what a track has to meet. Until real files are added the folder
  holds only that README, and every track silently plays nothing: a
  missing file is caught and logged, deliberately, so tracks can be added
  one at a time.
- `tool/generate_audio.dart` **no longer writes music.** It used to
  synthesize placeholders there, which meant re-running it would destroy
  real tracks. It still generates the key-tap SFX — as 22 kHz **WAV**, on
  purpose: MP3 encoder delay and padding would add latency and an audible
  gap to a 70 ms click.
- Light mode carries per-tier difficulty accents, soft card shadows, a
  gradient + cell-scatter backdrop on welcome, and a progress banner at
  the head of the puzzle list. `test/app/theme/color_contrast_test.dart`
  enforces the palette's legibility.
- **Known accessibility shortfall, deliberately not fixed:** the player's
  teal digit on the teal *selected* and *same-value* highlights measures
  4.34 and 4.35 against WCAG AA's 4.50 (and 2.98/2.99 for the red
  incorrect digit against 3.00). Lightening `cellSelectedLight` fixes the
  ratios but drops the selected-vs-peer channel distance from 92 to ~35,
  which is what makes the selection legible at a glance. The contrast test
  pins the current numbers as named exceptions so a *further* regression
  still fails. Revisit with a hue change rather than a lightness change.
- **400 puzzles**: 100 per difficulty, every one verified to have exactly
  one solution and to sit inside its tier.
- Gameplay: notes/pencil marks, undo, erase, hint (rewarded ad or free
  for premium), explicit check, live conflict highlighting, peer and
  same-digit highlighting, elapsed timer that pauses with the app.
- Sequential unlock, difficulty switching, dark mode, audio, local play
  reminders: done, inherited from the crossword skeleton.
- **AdMob is wired up for real.** App ID
  `ca-app-pub-1057967613304012~2137218877` is in the Android manifest; the
  three unit IDs are in the gitignored `ad_config.json`. Ship with:
  `flutter build appbundle --release --dart-define-from-file=ad_config.json`
  — a build without that flag silently falls back to test units (debug) or
  to no ads at all (release). iOS still carries Google's test App ID in
  `ios/Runner/Info.plist`: AdMob issues a *separate* App ID per platform,
  and the Android one must not be pasted there.
- **Register your device in AdMob → Settings → Test devices before opening
  a build with the real IDs.** Tapping your own live ads is invalid traffic
  and is the most common reason new AdMob accounts get suspended.
- Remaining before launch is account configuration only — see
  `store/PLAY_STORE_READINESS.md`.
