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
  real tracks. It still generates the key-tap SFX — as 22 kHz **WAV**, on
  purpose: MP3 encoder delay and padding would add latency and an audible
  gap to a 70 ms click.
- Light mode carries per-difficulty accent colours and soft card shadows.
  `test/app/theme/color_contrast_test.dart` enforces WCAG ratios — if you
  change a palette value, that test is what catches an unreadable result.
- Remaining before launch is account configuration only — see
  `store/MONETIZATION_SETUP.md`.
