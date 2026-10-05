# Memory Match app — working agreement & architecture

The fourth app in the portfolio, built on the **sudoku app's** skeleton
(itself the crossword app's). `app/` and `core/` were **copied**, not
extracted into a shared package — each micro app stays independently
shippable and versioned. The cost is real: a fix to `core/` has to be
applied in all four apps. Make that trade deliberately rather than
"fixing" it without being asked.

Branding: **Developer — BT developer. Copyright — BaLa Dream.**
App/product identity is fixed: `com.baslt.memory_app`, product ID
`remove_ads`.

Sudoku was the base rather than word search because this app shares
sudoku's shape: no game-language dimension, one JSON bundle per
difficulty, and a board the player taps rather than drags on.

---

## What is different from the three siblings

Read this before assuming a recipe from any of them applies here.

| | Crossword | Sudoku | Word Search | **Memory Match** |
| --- | --- | --- | --- | --- |
| Puzzle content | Per-language word banks | Generated grids | Per-language word banks | **Emoji decks, no language at all** |
| Language settings | UI + puzzle | UI only | UI + puzzle | **UI only** |
| Onboarding | welcome → language → difficulty | welcome → difficulty | welcome → language → difficulty | **welcome → difficulty** |
| Input | Hidden `TextField` + OS keyboard | On-screen number pad | Drag-to-select | **Tap a card** |
| Hint | Reveals one letter | Reveals one cell | Finds one whole word | **Matches one whole pair** |
| Mistake | Wrong digit | Wrong digit | Drag that spells nothing | **Mismatch of two *already-seen* cards** |
| Palette | Indigo + amber on cream | Teal + orange on cool white | Violet + lime on tinted white | **Rose + gold on warm blush** |

The four apps are kept at **visual parity** apart from the palette: the
decorative art, per-tier difficulty accents, card shadows, difficulty
banner, and completion burst are the same design across all of them.
When one app gains a UI treatment, the others should get it too — with
their own colour tokens, never by copying another app's palette.

**"Add a new language" here means one thing only: an ARB file.** There is
no puzzle content to translate — a picture of a dog is a picture of a dog
in every locale. This is the app where the crossword's UI/game language
split genuinely does not apply; do not reintroduce it.

---

## The one rule that makes this game fair

**A mismatch costs a life only when the player had already been shown
both cards.**

This is the single per-app decision inside the shared three-lives module,
and it is narrow on purpose. A memory game *is* turning over cards you
have not seen: charging a life for every mismatch would end most honest
runs of a 15-pair board before half of it was uncovered, and would punish
the exploration the game is made of. Requiring both cards to be in the
seen set means a life is only ever spent on something the player actually
forgot.

Three consequences that are easy to break:

1. **`seenCards` is persisted.** It lives in the saved progress, not in
   memory. Dropping it on a reopen would hand back lives the player had
   already put at risk, and make backing out to the list the cheapest
   strategy in the game. `memory_controller_test.dart` pins this.
2. **The seen set is read *before* the current reveal is folded in.** A
   card the player is seeing for the first time right now was not
   something they could have remembered.
3. **A hint's two cards join the seen set**, so a hinted pair cannot be
   "forgotten" for free afterwards.

---

## How difficulty actually works

Two levers per tier, not one — see `MemoryTier` in
`memory_deck_generator.dart` (`memoryTiers`):

| Tier | Board | Pairs | Symbols |
| --- | --- | --- | --- |
| easy | 4x3 | 6 | mixed themes |
| medium | 4x4 | 8 | mixed themes |
| hard | 6x4 | 12 | one theme |
| expert | 6x5 | 15 | one theme |

Pair count alone is the lazy measure. A 15-pair board of a dog, a plane,
a pizza and a trumpet is easier to hold in your head than an 8-pair board
of eight different birds — so **symbol similarity is the second lever**.
The gentle tiers spread their symbols across themes, at most two per
theme; the hard tiers draw every symbol from one family, which is what
makes twelve cards genuinely hard rather than merely numerous.

Boards are taller than they are wide because phones are. A 5x6 board laid
out landscape would shrink every card to a thumbnail on the device almost
everyone plays on.

Seeds are fixed per tier (`MemoryTier.seed`), so a regeneration
reproduces the same set rather than silently reshuffling every player's
deck numbering. Change a seed only when you intend to replace the
content — and see "saved progress" below for what that costs.

### Regenerating

```bash
dart run tool/generate_puzzles.dart          # every difficulty
dart run tool/generate_puzzles.dart hard     # just one
```

---

## Non-negotiable invariants

1. **Deck content is generated, never hand-authored.** `tool/` owns
   everything under `assets/puzzles/`. Never hand-edit a deck JSON.
2. **Every bundled deck is validated through the real validator**, and
   that validation is a permanent test, not a throwaway script — see
   `test/features/memory/bundled_decks_test.dart`. It runs in seconds;
   don't delete it to speed up the suite.
3. **The generator and the app share one engine.**
   `lib/features/memory/domain/memory_deck_generator.dart` is pure Dart
   with no Flutter import precisely so `tool/generate_puzzles.dart` can
   run it under plain `dart run`. Keep it that way — a second, tool-only
   implementation of the layout rules is how a deck ships with a pair
   that isn't where its metadata claims.
4. **Every symbol appears exactly twice.** Checked at generation time
   *and* refused at load time by `MemoryDeckDef.fromJson`: a deck with an
   odd symbol out can never be completed, and a player would only find
   out after matching everything else.
5. **No pair is dealt into two adjacent cells.** A pair sitting side by
   side is found by accident on the first two taps — on a six-pair board
   that is a third of the game gone before it started.
6. **The symbol banks stay inside Unicode 9.0, with no variation
   selectors, ZWJ sequences or skin tones.** Android renders emoji from
   the system font, so a newer codepoint is a blank rectangle on the
   phones `minSdk 21` invites in — and a card showing a rectangle can
   still be *matched*, so it ships as a puzzle that merely looks broken
   rather than as anything that would crash in testing.
   `bundled_decks_test.dart` enforces both rules on the written asset.
7. **The layout is stored, not shuffled at load.** Two players opening
   `easy_007` must see the same board, and a player who backs out
   mid-game must find their cards where they left them.
8. **Ad unit IDs are never committed.** They live in the gitignored
   `ad_config.json` (copy `ad_config.example.json`) and reach the app via
   `--dart-define-from-file`; debug without them falls back to Google
   test units, release falls back to empty. The AdMob **App ID** is
   different: it *is* committed, in `AndroidManifest.xml`, because it is
   public and the ads SDK crashes on launch without it.
9. **Prices are not hardcoded.** The store reports them; bundled strings
   are only an offline fallback.
10. **The app stays fully offline.** No backend, no database, no accounts
    — all state is SharedPreferences. Notifications are **local only**.

---

## Saved progress is keyed to a *deal*, not just an id

Progress here is a set of **board positions** — which cards are matched,
which have been seen. Positions only mean anything against the exact deal
they were recorded on, and deck ids are stable across releases while the
layouts behind them are regenerated content. So every save carries
`deckFingerprint(deck.cards)`, and progress whose fingerprint no longer
matches is discarded rather than replayed onto a different board.

Without that check, a player mid-way through the old `easy_007` would
come back to find "matched" cards sitting on symbols that no longer pair
up — a board that cannot be finished and cannot be repaired.

The fingerprint is FNV-1a over the joined symbols, not
`Object.hashCode`: Dart's string hash is only promised to be stable
within one process, and this value is written to disk and read back by a
later build. The symbols are joined **with a separator**, because
`["ab","c"]` and `["a","bc"]` would otherwise hash identically and emoji
really do vary in code-unit length.

---

## Architecture map

```
lib/
  app/            app_config.dart (all constants), router, theme
  core/           ads, audio, billing, consent, notifications,
                  localization, storage — copied from sudoku_app
  features/
    memory/
      domain/     deck model, tiers, generator + validator, progress
      data/       DeckRepository (asset bundles + progress)
      presentation/ controller, board view (card flip), game screen
    puzzle_list/    list + sequential unlock
    difficulty/     tier selection
    rewards/        lives, stars, streak, badges
    settings/       single settings surface
tool/             deck generator, symbol banks, icon/audio generators
```

Platform-specific plugins (`google_mobile_ads`, `in_app_purchase`,
`audioplayers`, `flutter_local_notifications`) are reached only through
the abstractions in `core/`, via conditional-import factories, so
web/desktop builds stay clean.

---

## Traps already hit — do not reintroduce

Everything in the three siblings' own "traps" sections applies here too
(all four apps share this skeleton's `core/` and much of `app/`
verbatim) — re-read those before assuming a Flutter/Riverpod/asset-bundle
oddity here is new. Only what is specific to this app is listed below.

- **A `Text` inside a card merges into the card's `Semantics` node.** The
  board's own label already names the symbol *and* says whether it is
  showing or matched, so every card was read out as "…showing A, A". The
  glyph is wrapped in `ExcludeSemantics` for exactly this reason; the
  three semantics tests in `memory_board_view_test.dart` are what catch a
  regression.
- **A face-down card must not render its symbol at all**, not even
  invisibly behind the back. A `Text` hidden under an opaque box is still
  in the tree, and hands the whole board to a screen reader — which is
  the one thing this game is about not knowing.
- **`pumpAndSettle` never returns on any screen showing a spinner.** The
  deck list renders a `CircularProgressIndicator` while its bundle
  loads, and a spinner keeps a frame scheduled forever. Pump frame by
  frame instead.
- **Inside a widget test's fake-async zone, `rootBundle` loads started
  after the first settle never complete on `pump` alone.** Switching
  difficulty mid-test needs `tester.runAsync(...)` between pumps to let
  the real file read finish — see `small_phone_layout_test.dart`. Without
  it the list sits on its spinner until the test times out, which looks
  like a hang rather than a missing await.
- **The `AnimatedSwitcher` on the list keeps the *outgoing* difficulty on
  screen for 250ms.** A test that waits for "Puzzle 001" after switching
  tiers finds the old tier's row and taps into the wrong board. Wait for
  something only the new tier renders (a "15 pairs" row, say).
- **`flipCard` hands off to an unawaited async chain** (persist → check
  completion → invalidate → analytics), like the crossword app's
  `enterLetter()`. A test that matches the last pair and asserts on
  post-completion state in the same synchronous breath reads
  `isCompleted` before that chain has run — and if the test ends there,
  `tearDown`'s dispose can tear down the Ref out from under the pending
  `ref.invalidate`. Give it a turn first.
- **Disposing a controller twice throws.** One test disposes its own
  controller to simulate leaving the screen; the shared `tearDown` must
  check `mounted` first, or the exception aborts the teardown and leaks
  every later test's controllers into the list.
- **A mismatch resolves on a timer *and* on the next tap.** Both paths
  must be safe to run twice — they race each other by design, because
  making the player wait out an animation they have already finished
  reading is the fastest way to make a board feel unresponsive.
- **`fillRect` with a transparent colour composites, it does not erase.**
  The icon generator punches the gap between its two cards by *setting*
  pixels; filling with transparent left the card underneath untouched and
  shipped the icon as a white square.
- Generated `lib/core/localization/generated/` files periodically vanish
  between sessions — rerun `flutter gen-l10n`.
- A stale `GeneratedPluginRegistrant.java` breaks the release build after
  running `flutter_native_splash:create` — delete
  `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
  and rebuild.

---

## Mistake limit and rewards

Two mechanics sharing one module: `lib/features/rewards/`. The module is
**identical in all four apps** (relative imports only, no app-specific
colour tokens), so a fix here has to be applied in all four — the same
trade the rest of `core/` makes.

`maxMistakes` (3) lives in `rewards/domain/solve_reward.dart`. What
counts as a mistake is the per-app decision, and this app's answer is at
the top of this file.

At the third mistake `state.isFailed` flips and **the board goes
read-only** — flips and hints both refuse. That last one is deliberate: a
run that is out of lives is over in both directions, and a hint that
could rescue it would make the limit negotiable. The ways on are one bought
extra life, restart, or leave — which is what `OutOfLivesDialog`
offers.

Stars, the day streak and the six badges work exactly as they do in the
siblings; `rewards_test.dart` pins the scoring. `RewardsController
.recordSolve` is called the moment the board completes, **before** the
interstitial, so an ad failing to load cannot cost the player the solve
they just earned.

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

- **6 UI languages**: en, ar, de, fr, es, it — full translation,
  including the eight theme names.
- **400 decks**: 100 per difficulty, every one verified to hold each
  symbol exactly twice, to fill its tier's board, and to have no pair in
  adjacent cells.
- Gameplay: tap to flip, matched pairs stay up, a mismatch shows for
  900ms (or until the next tap) before turning back, three lives on
  *remembered* mistakes only, hint (rewarded ad or free for premium —
  matches one pair), move counter, elapsed timer, restart, sequential
  unlock, dark mode, audio, local play reminders — inherited from the
  crossword/sudoku skeleton.
- **Music is not bundled per-app.** `assets/audio/music/` and
  `assets/audio/sfx/` were carried over from the crossword app's real,
  licensed tracks rather than left empty — see that folder's README for
  the filename contract if tracks ever need replacing.
- **Icon and splash are this app's own**, generated by
  `tool/generate_icon.dart` (two cards, one tilted, gold star) on the
  rose gradient.

### Not done yet — everything here is account setup, not code

- **AdMob**: wired. Real App ID `ca-app-pub-1057967613304012~8346757209`
  is in `AndroidManifest.xml`; the three real unit IDs are in the
  gitignored `ad_config.json`. Ship with:
  `flutter build appbundle --release --dart-define-from-file=ad_config.json`
  — a build without that flag silently falls back to test units (debug)
  or to no ads at all (release). Still owner action: register your device
  as a test device in AdMob before opening a build with real IDs; tapping
  your own live ads is invalid traffic and the most common reason new
  AdMob accounts get suspended.
- **Privacy policy**: done. Bundled at `assets/legal/privacy_policy.md`
  and hosted on doc-hosting.flycricket.io (one document per app, as with
  the three siblings), with the URL in `AppConfig.privacyPolicyUrl`.
  `privacy_policy_test.dart` enforces the pairing in both directions, so
  the two cannot drift apart. Still owner action: paste that URL into the
  Play Console listing.
- **Signing**: no keystore and no `android/key.properties` yet. The
  siblings use one keystore per app in `C:/Users/baslt/keys/`, alias
  `upload`, JKS, 2048-bit RSA. Release builds are debug-signed until
  that exists.
- **Store listing**: see `store/PLAY_STORE_READINESS.md`.
