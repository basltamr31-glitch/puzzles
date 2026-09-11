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

Three constraints per tier, all required (`sudokuTiers` in
`sudoku_generator.dart`):

- **A clue-count window.** Each puzzle picks a random target inside it,
  so one tier's grids vary the way a real puzzle book's do.
- **A technique band**, from `SudokuSolver.grade` — the hardest technique
  a logical solver needs: naked single -> hidden single -> locked
  candidates -> naked pair -> hidden pair -> naked triple -> X-Wing.
- **A score window**, from `SudokuSolver.profile(...).score` — how much
  work the whole solve is, counting *every* technique application plus
  the cost of finding each move.

| Tier | Clues | Technique band | Score |
| --- | --- | --- | --- |
| easy | 40-46 | naked singles only | 0-20 |
| medium | 32-38 | hidden singles | 24-65 |
| hard | 28-32 | locked candidates - naked pairs | 70-130 |
| expert | 24-30 | hidden pairs - X-Wing | 140+ |

Measured on the shipped set: easy 2-19, medium 24-64, hard 70-130,
expert 142-290. **The ranges do not overlap**, which is what makes "an
Expert is harder than an Easy" true of every *pair* of puzzles and not
just of the tier medians.

Two rules that are easy to get wrong:

1. **No tier ships a puzzle that needs guessing.** `SudokuTechnique.guess`
   is a failure marker, not a tier. Every bundled grid is finishable by
   the seven implemented techniques, asserted in `bundled_puzzles_test`.
2. **File order is the difficulty curve.** Puzzles unlock sequentially,
   so `tool/generate_puzzles.dart` sorts each tier by ascending score
   before numbering them. Do not reorder a puzzle file by hand.

### Why it used to be inconsistent

Players reported Experts easier than Easies, and they were right. Before
this was fixed, tiers were bounded by clue count and a technique
*ceiling* only. Measured across the old 400 (backtracking nodes needed
once logic stalls):

| Tier | min | median | max |
| --- | --- | --- | --- |
| easy | 38 | 42 | 46 |
| medium | 47 | 62 | 202 |
| hard | 53 | 164 | 1765 |
| expert | 58 | 260 | 2909 |

Every median was correctly ordered; the *ranges* overlapped badly —
hard's easiest puzzle scored below medium's median, and expert's easiest
was barely above it. Three root causes, all now addressed:

1. **`guess` was an unbounded catch-all.** Only four techniques existed,
   so everything past a naked pair graded identically — hidden pairs,
   triples, X-Wings, chains, and real trial-and-error alike. "Expert"
   meant only "harder than a naked pair", a band with no ceiling *and* no
   floor. 95 of the old 100 experts could not be solved by logic at all.
   Fixed by extending the ladder and rejecting unsolvable grids outright.
2. **Grading was categorical, so there was no within-tier order.** The
   hardest step says nothing about whether it happens once or eleven
   times. `SudokuProfile.score` weights every application, so two puzzles
   in the same band can still be ordered — and the files are now sorted
   by it.
3. **Easy's real variable was scanning effort, not technique.** Every
   easy grades the same, so clue count was the only thing separating a
   gentle one from a tedious one — and the window was 36-44, an 8-clue
   swing. The floor moved to 40, and `SudokuProfile.scanLoad` now charges
   for moments when few cells are placeable, which is what "an Easy that
   was extremely difficult" actually felt like.

`SudokuSolver.grade` is kept alongside `profile` on purpose: the
generator calls it once per trial removal, where only the ceiling matters
and a profile's bookkeeping would be pure cost.

The grader is pinned to published puzzles in `sudoku_solver_test.dart`
(the Wikipedia sample grades as naked-single; Inkala's 2012 grid still
defeats the ladder entirely — not one cell falls to any of the seven
techniques). If you change the technique set, those tests are the check
that difficulty still means something.

### Regenerating

```bash
dart run tool/generate_puzzles.dart            # every difficulty, ~15s
dart run tool/generate_puzzles.dart hard       # just one
```

Seeds are fixed per tier, so a regeneration reproduces the same set
rather than silently reshuffling every player's puzzle numbering. Change
a seed only when you intend to replace the content.

Expect it to take a few minutes: expert costs a median of 78 attempts per
puzzle (max ~305 on an unlucky seed) because the score floor rejects most
otherwise-valid grids, which is why `generate`'s default attempt budget is
800. Attempts are only spent on failures, so that budget is free when
generation is going well.

**Regenerating replaces content under players who already have the app.**
Puzzle ids are stable but the grids behind them are not, so a player
mid-way through `easy_007` would have their entries replayed onto a
different grid. `SudokuController._usableProgress` discards saved
progress whose givens no longer match the puzzle, so that swap resets a
puzzle cleanly instead of producing a grid that arrives already broken.

---

## Clash blocking

A digit that would duplicate one the selected cell can already see is
**refused, not written**. The tap costs no undo step, nothing is
persisted, and the player gets three signals at once:

- a rejection buzz (`HapticIntent.rejected` — `HapticFeedback.vibrate`,
  deliberately not an impact, so a refusal never feels like a soft
  success),
- the grid's wrong-answer shake, reusing the controller that an
  unsuccessful Check already drives (skipped under reduced motion),
- a red wash on **both** the refused cell and the cells that refused it,
  via `SudokuGameState.blockedCells`.

Showing both halves is the part that is easy to get wrong. Telling a
player "no" without showing *what* blocked them leaves them stuck, and
the blocker is often one of their own earlier mistakes rather than a
given — so the highlight is what tells them which cell to erase.

**Why it exists.** A player put a 7 in a column that already had one,
several rows away. The grid accepted it and marked it afterwards, but the
only signal was digit colour: the distant clue turned legibly red while
their own mistake sat under the selection highlight at 2.98 contrast. It
read as *"this puzzle contains two 7s"* — a content bug — rather than
*"I slipped"*. Refusing the entry removes the ambiguity at the source,
because the wrong state never exists to be misread.

Two exemptions, both deliberate:

1. **Pencil marks are never blocked.** A note is a hypothesis; the point
   of writing one is to reason about a digit before committing.
2. **Re-tapping a cell's own digit to clear it is not a clash**, and is
   checked before the clash test rather than being caught by it.

`SudokuGameState.conflicts` still exists and still matters: blocking
stops duplicates being *typed*, but every save written before this
feature can already contain them, and those grids must still be marked
when reopened. `sudoku_controller_test.dart` covers that route by loading
such a save — don't "simplify" it back to typing a duplicate, which is
now impossible by design.

---

## The cell-state ramp

Five cell states tint the grid, and the player has to tell them apart at
a glance. `color_contrast_test.dart` asserts two different things about
them, and they are not interchangeable:

- **Contrast** (WCAG) answers *can I read the digit on this fill*.
- **Channel distance** (summed per-channel difference, 0–765) answers
  *is this a different colour from that one*. Two tints at the same
  lightness but different hue score ~1.0 contrast while looking
  obviously different, so contrast is the wrong tool here.

The tints form a strictly increasing ramp away from a plain cell:

| State | Light | Dark | Meaning |
| --- | --- | --- | --- |
| given | 53 | 39 | a whisper — givens are the quiet part |
| peer | 120 | 96 | the row/column/box you are reasoning in |
| same-value | 197 | 174 | every other cell holding your digit |
| selected | 280 | 368 | the one cell you tapped |
| conflict | 108 | 84 | a duplicate digit (red, wins over all) |

**The bug this replaced:** the old ramp was 44 / 56 / 97 / 138 in light
mode, which put a peer cell just **12 steps** from a given cell — the two
were indistinguishable, so the row/column highlight did not exist in
practice. Dark mode was worse: a peer cell sat 29 steps from a plain
cell, invisible on a phone in a lit room. Ordering alone would not have
caught it, which is why the test asserts *adjacent-pair* separation and
not just the ramp order.

Two rules keep this working:

1. **A conflicting cell's fill outranks the selection.** A duplicate
   digit is a mistake the player is actively making; "which cell am I on"
   is something they already know, and the ring still shows it. This is
   also why conflicts get a full red wash and not just red text.
2. **Each digit colour is only guaranteed on the fill it pairs with.**
   The fill and digit `if` chains in `sudoku_grid_view.dart` must stay in
   the same order — `digitOnSelected` is chosen for the selected fill and
   nothing else, and pencil marks on the selected cell use it too.

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

## Mistake limit and rewards

Two mechanics added together, sharing one module: `lib/features/rewards/`.
The module is **identical in all three apps** (relative imports only, no
app-specific colour tokens), so a fix here has to be applied in all three
— the same trade the rest of `core/` makes.

### Three mistakes and the run is over

`maxMistakes` (3) lives in `rewards/domain/solve_reward.dart`. What counts
as a mistake is the one genuinely per-app decision:

A digit that is **legal against every peer the cell can see but still
disagrees with the solution**. Obvious duplicates never reach the
counter — clash blocking refuses them for free, and nothing is written
— so a spent life always means a real deduction error rather than a
slip of the thumb. Pencil marks are exempt, like they are from clash
blocking, for the same reason: a note is a hypothesis.

At the third mistake `state.isFailed` flips and **the board goes
read-only** — entry, undo, erase, check and hint all refuse. That last one
is deliberate: a run that is out of lives is over in both directions, and
a hint that could rescue it would make the limit negotiable. The only ways
on are restart or leave, which is exactly what `OutOfLivesDialog` offers.

Three things are easy to get wrong here:

1. **The counters are persisted per puzzle**, under
   `StorageKeys.puzzleAttempt(id)`, not held in memory. A limit that resets
   when the player backs out to the list and walks straight back in is not
   a limit. They are cleared on restart and on a solve, so a replay always
   starts on a full three lives.
2. **They live in their own key, not in each app's saved progress.** The
   three apps store progress in three different shapes (81 digits, a letter
   map, a found-word set); one small shared record avoided three
   serialization migrations.
3. **The offending entry is marked at the same moment the life is spent.**
   Counting a mistake without showing which entry cost it leaves the player
   hunting for something they cannot see.

Not built, deliberately: **no rewarded ad to continue a failed run.** That
is a monetization change and needs to be asked for, not slipped in
alongside a gameplay one. The hook for it is the one place
`OutOfLivesDialog` is constructed.

### What a solve earns

`RewardsController.recordSolve` is the single entry point, called by each
screen the moment the puzzle completes — **before** the interstitial, so an
ad failing to load cannot cost the player the solve they just earned.

- **Stars, 1-3.** Three for no mistakes and no hints, two for at most one
  mistake and two hints, one otherwise. Never zero: finishing a hard puzzle
  the messy way should not read as failure. Shown in the celebration and on
  the solved rows of the puzzle list.
- **A day streak**, counting *days*, not puzzles — a second solve on a day
  already played extends nothing, or the streak could be farmed in one
  sitting. `PlayerProgress.streakOn(now)` is what the UI must read: the
  stored number can be a day stale, and showing a run the player has
  already lost is worse than showing zero.
- **Six badges**, on `/progress`, reachable from the puzzle list's trophy
  button. Locked ones show how far off they are rather than hiding behind a
  question mark — a target you can see is a reason to play another puzzle.

`recordSolve` is safe to call again for an already-solved puzzle: the star
total moves by the *improvement* on that puzzle's previous best, and the
solved count does not move at all. Replaying for a cleaner result is meant
to be worth something without being a way to grind the totals up on one
easy grid. `test/features/rewards/rewards_test.dart` pins all of that.

**The reward strings use ICU plurals, which fail at render time, not build
time.** `reward_widgets_test.dart` renders every widget in all six locales
across the plural boundaries for exactly that reason — the scoring unit
tests never build a `MaterialApp`, so they would all pass while the
celebration crashed on the player's screen.

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
- **The grid highlights clear WCAG AA everywhere, with no exceptions.**
  This used to be a documented shortfall: the player's teal digit on the
  teal selected/same-value fills measured 4.34/4.35 against AA's 4.50,
  and the compromise looked unavoidable because lightening the selected
  fill to fix the ratio destroyed the very contrast that made selection
  visible. It was a false dilemma — it assumed the fill alone had to
  carry selection. Selection is now signalled by a **2.5px ring** as well
  as a fill, and a ring costs nothing in text contrast, which frees the
  fills to be far bolder. The selected cell also gets its own digit
  colour (`digitOnSelected`) instead of reusing the entered-digit teal.
  See "The cell-state ramp" below.
- **400 puzzles**: 100 per difficulty, every one verified to have exactly
  one solution, to be solvable by logic alone, and to sit inside its
  tier's clue, technique *and* score windows. Each tier's file is sorted
  easiest-first, so sequential unlock is a real difficulty ramp.
- Gameplay: notes/pencil marks, undo, erase, hint (rewarded ad or free
  for premium), explicit check, clash blocking (a duplicate digit is
  refused, with a buzz and a red wash on both cells), live conflict
  highlighting for pre-existing saves, peer and same-digit highlighting,
  elapsed timer that pauses with the app.
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
