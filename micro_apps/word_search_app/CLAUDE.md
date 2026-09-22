# Word Search app — working agreement & architecture

The third app in the portfolio, built on the crossword app's skeleton
(the same one sudoku used). `app/` and `core/` were **copied**, not
extracted into a shared package — each micro app stays independently
shippable and versioned. The cost is real: a fix to `core/` has to be
applied in all three apps. Make that trade deliberately rather than
"fixing" it without being asked.

Branding: **Developer — BT developer. Copyright — BaLa Dream.**
App/product identity is fixed: `com.baslt.word_search_app`, product ID
`remove_ads`.

---

## What is different from the crossword and sudoku apps

Read this before assuming a recipe from either sibling applies here.

| | Crossword | Sudoku | Word Search |
| --- | --- | --- | --- |
| Puzzle content | Per-language word banks, grid *derived* at load | Generated grids, no language dimension | Per-language word banks, grid *stored* (not derived) |
| Language settings | UI language *and* puzzle language | UI language only | UI language *and* puzzle language |
| Onboarding | welcome → language → difficulty | welcome → difficulty | welcome → language → difficulty |
| Input | Hidden `TextField` + OS keyboard | On-screen number pad | Drag-to-select on the grid, no keyboard |
| Hint | Reveals one letter | Reveals one cell | Finds one whole unfound word |
| Palette | Indigo + amber on cream | Teal + orange on cool white | Violet + lime on tinted white |

The three apps are kept at **visual parity** apart from the palette: the
decorative art, per-tier difficulty accents, card shadows, difficulty
banner, and completion burst are the same design across all of them.
When one app gains a UI treatment, the others should get it too — with
their own colour tokens, never by copying another app's palette.

"Add a new language" here means **both** halves, same as crossword: an
ARB file (UI translation) *and* a new `tool/word_banks/<code>_words.dart`
(puzzle content) plus a `supportedGameLanguageCodes` entry. Adding UI
translation alone is possible (crossword's UI/game language split is
deliberately reused) but is a partial job — flag it if that's genuinely
all that's wanted.

---

## Why the grid is stored, not derived

Crossword's puzzle asset holds the word list and clue text; the grid
(blocked cells, clue numbers) is *derived* from it at load time by
`CrosswordGridGenerator`. Word Search cannot do the same: the filler
letters between words are not derivable from the word list alone — they
are themselves part of what makes a puzzle a specific puzzle. Two
players opening puzzle `en_easy_007` must see the *same* grid, so the
filled grid (`rows`) is generated once, offline, by
`tool/generate_puzzles.dart`, and shipped as-is. The word list
(`placements`) travels alongside it so the app can validate a selection
without re-deriving anything, and so tests can prove the two agree.

---

## Non-negotiable invariants

1. **Puzzle content is generated, never hand-authored.** `tool/` owns
   everything under `assets/puzzles/`. Never hand-edit a puzzle JSON.
2. **Every bundled puzzle is validated through the real scanner**, and
   that validation is a permanent test, not a throwaway script — see
   `test/features/word_search/bundled_puzzles_test.dart`. It runs in
   seconds; don't delete it to speed up the suite.
3. **The generator and the app share one engine.**
   `lib/features/word_search/domain/word_search_scanner.dart` and
   `word_search_generator.dart` are pure Dart with no Flutter import
   precisely so `tool/generate_puzzles.dart` can run them under plain
   `dart run`. Keep it that way — a second, tool-only implementation of
   the placement rules is how a puzzle ships with a word that isn't
   actually where its metadata claims.
4. **Every listed word appears in its grid exactly once.** A word that
   accidentally repeats (once from its real placement, once from filler
   letters lining up by chance) lets a player select the wrong copy and
   be told they're wrong. `WordSearchValidator` checks this at generation
   time *and* the bundled-puzzles test checks it again on the shipped
   asset.
5. **`assets/test_fixtures/` is off-limits to the generator.** Tests
   assert against it precisely because it never changes.
6. **UI language list and game language list are separate.**
   `supportedUILanguageCodes` (translated chrome) vs
   `supportedGameLanguageCodes` (has puzzle content). They may diverge.
7. **Ad unit IDs are never committed.** They live in the gitignored
   `ad_config.json` (copy `ad_config.example.json`) and reach the app via
   `--dart-define-from-file`; debug without them falls back to Google
   test units, release falls back to empty. The AdMob **App ID** is
   different: it *is* committed, in `AndroidManifest.xml`, because it is
   public and the ads SDK crashes on launch without it.
8. **Prices are not hardcoded.** The store reports them; bundled strings
   are only an offline fallback.
9. **The app stays fully offline.** No backend, no database, no accounts
   — all state is SharedPreferences. Notifications are **local only**.

---

## How difficulty actually works

Three levers per tier, not just grid size — see `WordSearchTier` in
`word_search_generator.dart` (`wordSearchTiers`):

| Tier | Grid | Words | Directions |
| --- | --- | --- | --- |
| easy | 8x8 | 6 | right, down |
| medium | 10x10 | 8 | + down-right |
| hard | 12x12 | 10 | + up-right, **backwards** |
| expert | 14x14 | 12 | all eight |

"Backwards" is the real difficulty cliff, which is why it arrives at hard
and not before: a player scanning for a word reads in one direction, and
a reversed word defeats that habit entirely. Word-length windows widen
alongside grid size so a bigger board doesn't just mean "more of the same
short words".

Seeds are fixed per language (`_languageSeeds` in
`tool/generate_puzzles.dart`), so a regeneration reproduces the same set
rather than silently reshuffling every player's puzzle numbering. Change
a seed only when you intend to replace the content.

### Regenerating

```bash
dart run tool/generate_puzzles.dart            # every language
dart run tool/generate_puzzles.dart en         # just one
```

### Word banks

`tool/word_banks/<code>_words.dart` holds one word list per
`PuzzleTheme` (animals, food, nature, home, body, clothes, travel,
sports — see `lib/features/word_search/domain/puzzle_theme.dart`).
European-language banks are written **without diacritics**
(`ARBOL` not `ÁRBOL`, `PAIN` not `PAIN` with any accented cousin) —
matching how printed word-search books set this content, and sidestepping
the question of whether an accented and unaccented letter are "the same"
filler letter. Arabic is written without diacritics (tashkeel) for the
same reason real puzzles are. Multi-word answers are concatenated into
one token (`ARCENCIEL`, not `ARC-EN-CIEL`) since a grid cell holds one
letter, not a space.

`WordSearchGenerator.pickWords` excludes any two words where one
contains the other (`CAT`/`CATS`) — such a pair can never both appear
exactly once — so word banks can be generous without hand-curating for
that case; the generator prunes it per draw.

---

## Architecture map

```
lib/
  app/            app_config.dart (all constants), router, theme
  core/           ads, audio, billing, consent, notifications,
                  localization, storage — copied from crossword_app
  features/
    word_search/
      domain/     models, scanner/validator, generator, tiers, progress
      data/       PuzzleRepository (asset bundles + progress)
      presentation/ controller, grid view (drag selection), word list,
                    gameplay screen
    game_language/  puzzle-language picker (reused shape from crossword)
    puzzle_list/    list + sequential unlock
    difficulty/     tier selection
    settings/       single settings surface
tool/             puzzle generator, word banks, icon/audio generators
```

Platform-specific plugins (`google_mobile_ads`, `in_app_purchase`,
`audioplayers`, `flutter_local_notifications`) are reached only through
the abstractions in `core/`, via conditional-import factories, so
web/desktop builds stay clean.

---

## Traps already hit — do not reintroduce

- **A `GestureDetector(onPanStart:)` inside a scroll view cannot select
  vertically.** `PanGestureRecognizer` waits for `kPanSlop` (~36dp)
  before claiming a gesture; the enclosing `SingleChildScrollView`
  claims a *vertical* drag at `kTouchSlop` (~18dp). The scrollable wins
  that race every time, so the shipped build could select horizontal
  words but no vertical ones — the board just scrolled. The grid uses a
  `RawGestureDetector` with `_GridPanGestureRecognizer`, which accepts on
  the first move event while leaving two-finger gestures on the default
  slop so `InteractiveViewer` keeps pinch-to-zoom.
- **`DragStartBehavior.start` reports the drag from where the slop
  threshold was crossed, not where the finger landed**, which selected a
  cell or two along from the one touched. The grid's recognizer sets
  `DragStartBehavior.down`.
- **A `WidgetTester` drag written with one big `moveTo` cannot reproduce
  either bug.** A single large jump crosses both recognizers' thresholds
  in the same event, and the arena then awards the gesture to the
  innermost one — so the grid wins and the test passes against broken
  code. `grid_drag_gesture_test.dart` moves in 8dp steps for exactly this
  reason. If you touch that gesture code, verify the test still *fails*
  when you undo the fix; a gesture test that cannot fail is worse than
  none.

Everything in the crossword and sudoku apps' own "traps" sections applies
here too (both apps share this skeleton's `core/` and much of `app/`
verbatim) — re-read those before assuming a Flutter/Riverpod/asset-bundle
oddity here is new. Only what's specific to this app is repeated below.

- **The 8 drag directions are 45 degrees apart, so "ambiguous" isn't a
  real case.** `snappedSelection` (in `word_search_controller.dart`)
  picks whichever direction's unit vector has the best cosine similarity
  to the drag — always within 22.5 degrees of *some* direction. An
  earlier version rejected low-confidence drags below a threshold that,
  with only 8 evenly-spaced directions, could never actually be crossed;
  it was dead code that looked like a safety check. Don't re-add a
  similarity floor without checking it can actually fire.
- **Comparing raw dot products across the 8 directions is not cosine
  similarity.** The four diagonal step vectors have magnitude √2, the
  four cardinal ones have magnitude 1 — without dividing each direction's
  score by its own magnitude, every comparison is biased toward
  diagonals, and a mostly-horizontal drag can snap to a diagonal instead.
  `snappedSelection`'s scoring divides by `sqrt(rowStep² + colStep²)` for
  exactly this reason; the test at `word_search_controller_test.dart`'s
  "wobbly, mostly-horizontal drag" case is what catches a regression here.
- **`WordSearchScanner.findAll` assumes a square grid.** It uses
  `rows.length` as both the row bound and the column bound, which is
  correct for every real puzzle (`WordSearchValidator` enforces
  `rows.length == size` and each row's length `== size`) but wrong for a
  non-square `List<String>` — a hand-written test fixture that only
  slices the first few rows of a square puzzle will silently miss matches
  near the clipped edge. Use a full, square grid in scanner tests.
- **A palindrome placed once must count as one occurrence, not two.**
  Reading a palindrome forward from one end is the same cells as reading
  it backward from the other; `findAll` dedupes by the *sorted cell set*,
  not by (start cell, direction), specifically so this doesn't look like
  a duplicate to the one-occurrence-per-word check.
- **Filler letters can accidentally spell a second copy of a listed
  word.** `WordSearchGenerator.tryGenerate` re-fills and re-validates up
  to 40 times rather than patching a single offending cell — patching one
  collision can create the next one, and a full validator pass is the
  only way to know the grid is actually clean.
- **A `FutureProvider.family` caches and never re-reads storage.**
  Completing/restarting a puzzle must
  `ref.invalidate(puzzleSummariesProvider)` or the unlock state goes
  stale — same trap as both sibling apps.
- **`endDrag()` is sync and hands off to an unawaited async chain**
  (persist -> check completion -> invalidate -> analytics), exactly like
  the crossword app's `enterLetter()`. A test that drags a word and
  asserts on post-completion state in the same synchronous breath reads
  `isCompleted` before that chain has run — and if the test ends there,
  `tearDown`'s `container.dispose()` can tear down the Ref out from under
  the still-pending `ref.invalidate` call, surfacing as "Ref already
  disposed" rather than as a timing issue. Give it a turn first, same as
  the crossword controller test does:
  `await Future<void>.delayed(const Duration(milliseconds: 50));`.
- **Objects created in `setUp` belong to the real async zone.** Same
  crossword/sudoku trap: build `Completer`/`Future`/primed `rootBundle`
  reads inside the test body, not `setUp`.
- `rootBundle` caches per asset path across tests — any test file that
  pumps a widget reading an asset needs `setUp(rootBundle.clear)`.
- Generated `lib/core/localization/generated/` files periodically vanish
  between sessions — rerun `flutter gen-l10n`.
- A stale `GeneratedPluginRegistrant.java` breaks the release build after
  running `flutter_native_splash:create` — delete
  `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
  and rebuild.

---

## Mistake limit and rewards

Two mechanics added together, sharing one module: `lib/features/rewards/`.
The module is **identical in all three apps** (relative imports only, no
app-specific colour tokens), so a fix here has to be applied in all three
— the same trade the rest of `core/` makes.

### Three mistakes and the run is over

`maxMistakes` (3) lives in `rewards/domain/solve_reward.dart`. What counts
as a mistake is the one genuinely per-app decision:

A **released drag of two or more cells that spells nothing**. A
one-cell selection is a tap, not a guess — the player brushed the board
or thought better of a drag — and charging for that would make the grid
feel hostile to touch.

At the third mistake `state.isFailed` flips and **the board goes
read-only** — entry, undo, erase, check and hint all refuse. That last one
is deliberate: a run that is out of lives is over in both directions, and
a hint that could rescue it would make the limit negotiable. The ways on are one
bought extra life, restart, or leave — which is exactly what
`OutOfLivesDialog` offers.

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

**One extra life per run, bought with a rewarded ad.** This was parked as
"not built, deliberately — a monetization change needs to be asked for";
it has now been asked for, and it is built. Four things hold the rule
together, and all four matter:

1. **`bonusLives` is its own counter on `PuzzleAttempt`**, not a discount
   on `mistakes`. `starsForSolve` reads the mistake count, so folding the
   two together would let an ad quietly buy a *better result* instead of
   just another go. A revived run still scores what it actually cost.
2. **`maxBonusLives` is 1**, per attempt, resetting with it. A limit you
   can always pay past is not a limit — unlimited continues would turn
   "three mistakes" into "how many ads will you sit through".
3. **`PuzzleAttempt.decode` clamps `mistakes` to `maxMistakes +
   maxBonusLives`, not to `maxMistakes`.** Clamping at three was correct
   until a run could legitimately reach four; afterwards it erased the
   fourth mistake on every reload and handed the player a fresh extra
   life each time they reopened the puzzle. `rewards_test.dart` pins this.
4. **The cap is enforced in `grantExtraLife`, not only in the dialog.**
   The dialog is one caller; the rule belongs with the state, and the
   method also refuses on a run that is not actually failed.

Players who have removed ads get the life free, no video — the same trade
the hint button already makes for them. A rewarded ad that fails to load
costs nothing and **reopens the dialog**: dismissing it would strand the
player on a locked board with no way forward, which reads as a crash
rather than as a policy.

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

## Banner-free play without paying: the companion-app unlock

Installing `com.basel.baladream` removes **banner ads only**, for free,
forever. `lib/core/promo/` owns this and it is duplicated per app like the
rest of `core/`.

**The invariant that matters: this is not premium.** `PartnerUnlockController`
writes its own storage key and never touches `isAdsRemoved`. Merging the
two would hand a free-app installer everything the purchase buys —
interstitial-free play, free hints, free extra lives — and make a
cross-promotion indistinguishable from a sale. Every banner slot reads
`areBannersHiddenProvider`, the one place that knows both routes, so a new
banner cannot honour one and forget the other.
`test/core/promo/partner_unlock_test.dart` asserts the separation directly,
including that interstitials still show for an unlocked player.

Four things that are easy to get wrong:

1. **The `<queries>` entry in AndroidManifest.xml is load-bearing.**
   Android 11+ filters package visibility, so without naming the package
   there `getPackageInfo` throws `NameNotFound` even when the app *is*
   installed — the unlock would simply never fire, silently, on exactly
   the devices most players use. One `<package>` entry grants visibility
   of that one package; the app still cannot enumerate anything else.
2. **The unlock is sticky and is never revoked.** Re-checking each launch
   and taking it back would punish the honest majority — people who
   installed the app and later tidied up their phone — to deter a minority
   who would install-unlock-uninstall. What is being protected is a
   banner. `refresh()` only ever moves false -> true.
3. **Android only.** iOS cannot answer "is this bundle id installed" for
   an app it does not own a URL scheme for, so `PartnerAppService` falls
   back to `NoOpPartnerAppService` and nobody on iOS gets the unlock. If
   iOS ever ships, the route is a deep-link handshake from the companion
   app, not package detection.
4. **The check runs on `resumed`, not just at launch.** That is the moment
   someone comes back from the Play Store having just installed it, and it
   is what makes the unlock feel automatic instead of needing a button.

**The UI copy deliberately does not name the companion app.** Its Play
listing title could not be verified, and inventing a brand name in shipped
UI is worse than a neutral phrase. To name it, add the name to the four
`partnerUnlock*` strings in every ARB. The copy also states that hints and
extra lives still cost a video, because a player who installs expecting
*all* ads to stop and then meets an interstitial was misled by the button,
not by the ad.


---

## Current state

- **6 UI languages, 6 game languages**: en, ar, de, fr, es, it — full UI
  translation and full puzzle content in all six.
- **2,400 puzzles**: 100 per language per difficulty, every one verified
  through the real scanner/validator to have every listed word appear
  exactly once, spelled correctly, inside its own grid.
- Gameplay: drag-to-select in all 8 directions (from either end of a
  word), live wrong-selection feedback, found-word strike-through list,
  hint (rewarded ad or free for premium — finds one whole word), pinch
  zoom, restart, sequential unlock, dark mode, audio, local play
  reminders — inherited from the crossword/sudoku skeleton.
- **Music is not bundled per-app.** `assets/audio/music/` and
  `assets/audio/sfx/` were carried over from the crossword app's real,
  licensed tracks rather than left empty — see that folder's README for
  the filename contract if tracks ever need replacing.
- **AdMob is wired up for real.** App ID
  `ca-app-pub-1057967613304012~1554723382` is in the Android manifest;
  the three unit IDs are in the gitignored `ad_config.json`. Ship with:
  `flutter build appbundle --release --dart-define-from-file=ad_config.json`
  — a build without that flag silently falls back to test units (debug)
  or to no ads at all (release). iOS still carries Google's test App ID
  in `ios/Runner/Info.plist`: AdMob issues a *separate* App ID per
  platform, and the Android one must not be pasted there.
- **Register your device in AdMob → Settings → Test devices before
  opening a build with the real IDs.** Tapping your own live ads is
  invalid traffic and is the most common reason new AdMob accounts get
  suspended.
- **Privacy policy is hosted and wired.**
  `AppConfig.privacyPolicyUrl` points at
  `doc-hosting.flycricket.io/word-search/70ff7ba2-.../privacy`, verified
  live on 2026-09-03, and the bundled `assets/legal/privacy_policy.md`
  names that same URL. The two must stay in step: the in-app screen
  renders the bundled file while the Play listing links the hosted one,
  so editing one without republishing the other ships a contradiction.
  `privacy_policy_test.dart` enforces the mechanical half of that (a
  configured URL means no `[[FILL IN]]` placeholders may remain).
- **Release builds are signed with a real upload key.**
  `C:/Users/baslt/keys/word-search-upload.jks` (JKS, alias `upload`,
  2048-bit RSA, ~27-year validity), credentials in the gitignored
  `android/key.properties`. Same convention as
  `crossword-upload.jks` / `sudoku-upload.jks`, one keystore per app.
  Neither the keystore nor its password exists anywhere but this
  machine — they are the one thing here that cannot be regenerated.
- Everything else remaining before launch is account configuration only
  — see `store/PLAY_STORE_READINESS.md`.
