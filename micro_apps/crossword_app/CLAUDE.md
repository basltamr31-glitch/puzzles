# Crossword app — working agreement & architecture

**The app is feature-complete.** The owner's default expectation is that
routine work is **adding new languages**, following exactly the structure
below. Do not redesign systems, change gameplay, restyle the UI, or
"improve" architecture unless explicitly asked.

New features are not forbidden — the owner asks for them from time to
time (local play reminders were added this way, after the languages-only
rule was first set). Treat "languages only" as the default assumption for
unprompted work, not a hard ban: if a feature is explicitly requested,
build it, and update this file afterwards so it stays accurate.

Branding: **Developer — BT developer. Copyright — BaLa Dream.**
App/product identity is fixed: `com.baslt.crossword_app`, product ID
`remove_ads`.

---

## Non-negotiable invariants

1. **Puzzle content is generated, never hand-authored.** `tool/` owns
   everything under `assets/puzzles/`. Never hand-edit a puzzle JSON.
2. **Every puzzle is validated through the real parser before shipping.**
   Not by inspection — by running the actual
   `PuzzleRepository` + `CrosswordGridGenerator`.
3. **`assets/test_fixtures/` is off-limits to the generator.** Tests
   assert against it precisely because it never changes.
4. **UI language list and game language list are separate.**
   `supportedUILanguageCodes` (translated chrome) vs
   `supportedGameLanguageCodes` (has puzzle content). They may diverge.
   The *lists* stay separate; the defaults no longer are — an unset UI
   language follows the chosen game language before the device locale.
5. **Ad unit IDs are never committed.** They come from `--dart-define`;
   debug falls back to Google test units, release falls back to empty.
6. **Prices are not hardcoded.** The store reports them; bundled strings
   are only an offline fallback.
7. **The app stays fully offline.** No backend, no database, no accounts —
   all state is SharedPreferences. Notifications are **local only**;
   introducing push (Firebase/FCM) would mean a server, stored device
   tokens, and new privacy-policy disclosures. Don't, unless asked.

---

## Adding a new language — the exact recipe

Nothing here is optional; skipping a step ships a broken language.

### 1. Decide the script conventions first
Write them down in the word-bank file header. Existing precedents:

| Language | Convention | Why |
| --- | --- | --- |
| German | No umlauts or ß in grid answers | ß has no clean single-char uppercase |
| French | Accents dropped in answers, kept in clues | Standard French crossword convention |
| Spanish | Acute accents dropped, **Ñ kept** | Ñ is a distinct letter, not a diacritic — `ano` ≠ `año` |
| Italian | Accents dropped in answers | Same convention as French |
| Arabic | No tashkeel diacritics at all | The grid indexes UTF-16 units; combining marks would break it |

**Scripts needing code changes first** (do not attempt as "just a new
language"): Devanagari/Hindi and other scripts with combining vowel
signs, because `CrosswordGridGenerator` indexes `answer[i]` as plain
UTF-16 code units. Turkish needs an explicit decision on dotted/dotless
İ/I, since Dart's default `toUpperCase()` applies the wrong mapping.

### 2. Create the word bank
`tool/word_banks/<code>_words.dart`, mirroring an existing one:

- `easyWords<Xx>` — short, everyday words
- `mediumWords<Xx>`, `hardWords<Xx>`, `expertWords<Xx>` — progressively
  longer/rarer
- `connectorWords<Xx>` — short common words merged into medium/hard/expert
  so long answers have material to interlock with. **Without these the
  grids come out sparse.**
- `wordBanksByDifficulty<Xx>` map at the bottom

Clues are written in that language. Answers are uppercase and obey the
conventions from step 1.

### 2b. Tag the easy words with clue categories
Add a block to `tool/word_banks/clue_categories.dart` mapping that
language's **easy** answers onto `ClueCategory` values.

The icon must signal the *field* a word belongs to, never depict the word:
a paw print for "animal", not a cat. An icon that shows the answer defeats
the point — these support the clue text, they don't replace solving it.
Categories are language-independent, so one icon set serves every language.

Only the easy tier is categorized; a validation test asserts that no
harder-tier clue carries one. Anything left unlisted simply gets no icon,
which is correct for abstract words.

### 3. Register it
- `tool/generate_puzzles.dart` → import the bank, add a `_LanguageConfig`
  entry with the localized puzzle-title prefix.
- `lib/app/app_config.dart` → add the code to `supportedGameLanguageCodes`
  (and `supportedUILanguageCodes` if the UI is translated too).
- `lib/shared/models/game_locale.dart` → add `GameLocale` with native
  name, `isRtl`, and `flagEmoji`.
- `pubspec.yaml` → add the four asset paths
  (`assets/puzzles/<code>/{easy,medium,hard,expert}/`).
- `lib/core/localization/l10n/app_<code>.arb` → full translation, if the
  UI is being localized. Then run `flutter gen-l10n`.

### 4. Generate
```bash
dart run tool/generate_puzzles.dart <code>
```
Target is 100 per difficulty. Tier sizing lives in `_tierConfigs`;
difficulty scales by **grid size and word count**, not just vocabulary.

### 5. Validate through the real parser — mandatory
Create a temporary `test/_validate_all_puzzles.dart` that loads every
bundled puzzle via `AssetManifest`, parses with `PuzzleRepository`, and
generates with `CrosswordGridGenerator`; assert no failures, no duplicate
IDs, no empty clue sets, that **every easy clue has a category** and that
**no harder-tier clue has one**. Run it, confirm counts, then **delete it**.

A quick way to find words you forgot to categorize: parse the generated
easy puzzles and collect answers whose `category` is null.

### 6. Verify and report honestly
```bash
flutter analyze && flutter test && flutter build apk --release
```
All three must pass. Report real output; never claim console/account
setup that only the owner can perform.

---

## Architecture map

```
lib/
  app/            app_config.dart (all constants), router, theme
  core/
    ads/          AdService abstraction + google_mobile_ads impl
    audio/        SoundService (key tap + background music)
    billing/      BillingService + premium state
    consent/      UMP consent
    notifications/ NotificationService + ReminderController (local only)
    localization/ ARB files + generated
    storage/      LocalStorageService + StorageKeys registry
  features/
    crossword/    gameplay: controller, grid view, hidden text input
    puzzle_list/  list + sequential unlock
    settings/     single settings surface
tool/             puzzle generator + word banks + audio generator
```

Platform-specific plugins (`google_mobile_ads`, `in_app_purchase`,
`audioplayers`, `flutter_local_notifications`) are reached only through
the abstractions above, via conditional-import factories, so web/desktop
builds stay clean.

### Play reminders

Local, on-device only. `ReminderController` owns the preference and keeps
exactly one pending reminder in sync with it.

- **Off by default.** Enabling requests OS permission; if the player
  declines, the switch stays off rather than lying about what will happen.
- Fires `reminderAfterDays` (2) after the last play, at 7pm local.
  `StorageKeys.lastPlayedAt` is written whenever a puzzle is opened, so an
  active player is never nagged.
- Rescheduling **replaces** rather than accumulates, so calling it on every
  launch is safe.
- Notification text is captured at schedule time via
  `reminderStringsProvider` — the OS may fire it when no localized
  `BuildContext` exists, so it cannot be localized at delivery.
- **Inexact scheduling on purpose.** `SCHEDULE_EXACT_ALARM` is restricted
  on Android 12+ and invites review scrutiny; a "come back" nudge does not
  need minute precision. Don't "fix" this to exact.
- Manifest needs `POST_NOTIFICATIONS` (Android 13+ runtime permission),
  `RECEIVE_BOOT_COMPLETED`, and the two `flutter_local_notifications`
  receivers, or pending reminders vanish on reboot.

---

## Traps already hit — do not reintroduce

- **`TextField.onChanged` does not fire for programmatic controller
  changes.** The hidden input uses stateless sentinel decoding
  (`crossword_text_input.dart`); a "suppress next change" flag swallows
  every other keystroke on some IMEs.
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
  initialize the Mobile Ads SDK itself; `adsReadyProvider` does, and only
  after `consentRequestProvider` resolves. `main()` *does* now read
  `adsReadyProvider` so that chain starts at launch instead of waiting for
  the first ad widget to mount — that is not a bypass, because the
  provider still awaits consent internally before `initializeAds()`. Every
  ad call goes through `ConsentGatedAdService`, so a new screen cannot
  bypass it, and **preloading goes through the same gate**: a warm ad is
  still an ad request. Under GDPR an ad request made before a lawful basis
  exists cannot be fixed afterwards — see
  `test/core/ads/consent_gate_test.dart`.
- **A rewarded ad fetched at tap time loses the race.** Loading only once
  the player has tapped "watch an ad for a hint" put a large video
  download on the critical path of a button press, and on mobile data it
  routinely blew through the 8s load timeout — which the player read as
  "no ad is available right now" on a perfectly good connection.
  `GoogleMobileAdsService` keeps one rewarded ad warm from startup and
  refills it the moment it is spent. Two things that are easy to get wrong
  if you touch it: a cached rewarded ad **expires** after about an hour
  (it is binned at 50 minutes, or showing it would fail), and a failed
  load must **retry with backoff** — the banner had no retry at all, so a
  single failure at cold start left the slot dead for the whole session.
  Background retries stop after 5 attempts; a player tap always resets
  that count, because giving up in the background must never mean giving
  up on someone who just asked.
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

- **The board's reading direction comes from the *puzzle*, not the app.**
  `CrosswordGridView` sets its own `Directionality` from
  `grid.language`. Inheriting the ambient one is wrong in both
  directions, because the UI language and the game language are picked
  separately: an Arabic player on an English phone had every across
  answer drawn backwards (first letter on the left), and an English board
  under an Arabic UI would mirror the same way. `crossword_grid_direction_test.dart`
  pins both halves. Clue numbering needs no special case — scanning
  row-major in a mirrored board *is* the Arabic convention.
- **The UI language falls back to the game language.** Resolution order is
  explicit Settings choice > game language (if the UI is translated into
  it) > device locale > English. Going straight to the device locale is
  what left an Arabic player looking at `Hint` and `Check` in English.
  Choosing a language to play in says what you read; a Settings choice is
  still never overwritten.
- **A rewarded ad outlives a 30-second timeout.** `showRewarded` capped
  the *show* phase at 30s, which expires while a normal rewarded video is
  still playing — so the hint came back `unavailable` and was never
  granted no matter how many ads were watched to the end. The timeout is
  a stuck-callback backstop (5 minutes) and never downgrades a reward the
  SDK already said was earned.
- **A hint must visibly do something.** It is paid for with an ad, so
  revealing the selected cell unconditionally was wrong: the caret sits on
  an already-correct cell after typing a word, and the reward rewrote a
  letter that was already there. `revealHintAtSelectedCell` falls forward
  to the first cell that still needs solving — current word first, then
  the grid.
- **`FutureProvider.family` caches and never re-reads storage.**
  Completing/restarting a puzzle must `ref.invalidate(puzzleSummariesProvider)`
  or the unlock state goes stale.
- **`PlayerMode.lowLatency` routes to Android SoundPool** and fails
  silently with a plain `play(AssetSource(...))`. Use the default
  media-player mode.
- **Phone speakers reproduce almost nothing below ~300 Hz.** Music must
  sit at ~350 Hz and above or it's felt as vibration, not heard.
- **Riverpod 3**: `StateNotifier` *and* `StateProvider` come from
  `flutter_riverpod/legacy.dart` — prefer a plain `Notifier` over both.
  Plain `Provider` overrides use `overrideWith`, not `overrideValue`.
- **SharedPreferences test mocks** take plain values, not JSON-encoded
  strings.
- `flutter test` isolates by file; go_router state can leak between
  `testWidgets` in one file.
- Generated `lib/core/localization/generated/` files periodically vanish
  between sessions — rerun `flutter gen-l10n`.

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

**The companion app is named in the UI**: "Couples — A Space for Two" in
the description, "Couples" on the button. Both live in `AppConfig`
(`partnerAppName`, `partnerAppShortName`) and reach the strings through an
`{app}` placeholder, because a brand name is not translated and should not
be spelled out once per locale. The short form exists because
`SecondaryButton` scales its label down inside a `FittedBox` — the full
listing title renders unreadably small on a narrow phone at a large text
scale. The copy also states that hints and extra lives still cost a video,
because a player who installs expecting *all* ads to stop and then meets
an interstitial was misled by the button, not by the ad.

**Owner decision (2026-09-24): Remove Ads *is* the companion download.**
The Remove Ads screen offers only "Get Couples" — there is no paid button
on it any more. Removing ads means banners and nothing else: hints and the
extra life cost a rewarded video for **every** player (the old free-hint /
free-life path for `isAdsRemoved` is gone), and interstitials keep showing.
A legacy `isAdsRemoved` flag still hides banners via
`areBannersHiddenProvider` and still skips interstitials in `AdPolicy`.
Do not reintroduce a purchase or free hints without the owner asking.

**Release builds must go through `micro_apps/build_release.ps1`.** Ad unit
IDs come only from `--dart-define-from-file=ad_config.json`; a plain
`flutter build apk --release` ships an app with *no ads at all* (every unit
ID resolves to empty). The 2026-09-22 APKs were built that way and showed
no banners and no rewarded video. The script builds with the config and
fails unless the real banner ID is found inside `libapp.so`.


---

## Current state

- **6 languages**: en, ar, de, fr, es, it — all with full UI translation
  and 100 puzzles per difficulty (2,400 total).
- Audio, sequential unlock, zoom, dark mode, difficulty switching,
  in-game music toggle, local play reminders, category icons on easy
  clues: done.
- **Music is not bundled.** `assets/audio/music/` takes six MP3 tracks
  supplied by hand — see that folder's README for the filename contract
  and what a track has to meet. Until real files are added the folder
  holds only that README, and every track silently plays nothing: a
  missing file is caught and logged, deliberately, so tracks can be added
  one at a time.
- `tool/generate_audio.dart` **no longer writes music.** It used to
  synthesize placeholders there, which meant re-running it would destroy
  real tracks. It still generates the key-tap SFX — as **WAV**, on
  purpose: MP3 encoder delay and padding would add latency and an audible
  gap to a click this short.
- **The key tap is a noise transient, not a tone.** It used to be two pure
  sine waves (900 Hz + 1800 Hz) held for 70 ms, and that is precisely why
  it read as an electronic beep: a steady pitch held that long is long
  enough for the ear to resolve it as a musical note. It is now a filtered
  noise click over a low body that glides 210 Hz -> 150 Hz and is gone
  inside 38 ms — the downward glide is most of what separates "a key" from
  "a tone". The sample rate went 22 kHz -> 44.1 kHz with it, because noise
  is the one thing a low rate audibly hurts; the file is still under 4 KB.
  The noise is seeded, so regenerating produces identical bytes rather
  than drifting. Memory's card flip plays this same asset.
- Light mode carries per-difficulty accent colours and soft card shadows.
  `test/app/theme/color_contrast_test.dart` enforces WCAG ratios — if you
  change a palette value, that test is what catches an unreadable result.
- Remaining before launch is account configuration only — see
  `store/MONETIZATION_SETUP.md`.

---

## Mistake limit and rewards

Two mechanics added together, sharing one module: `lib/features/rewards/`.
The module is **identical in all three apps** (relative imports only, no
app-specific colour tokens), so a fix here has to be applied in all three
— the same trade the rest of `core/` makes.

### Three mistakes and the run is over

`maxMistakes` (3) lives in `rewards/domain/solve_reward.dart`. What counts
as a mistake is the one genuinely per-app decision:

A **finished word that is wrong**, charged once per distinct guess.
Only finished words are judged: a crossword is typed left to right, so
every partial answer disagrees with the solution at some point, and
charging per keystroke would end the puzzle before the player had
entered a single complete word. Retyping the *same* wrong answer is
free (`_struckClues` keys on clue + letters) — a player who cannot see
why an answer was refused will do exactly that, and draining their
remaining lives for it would be punishing them for the UI's silence.
A *different* wrong answer is a new guess and does cost a life.

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
