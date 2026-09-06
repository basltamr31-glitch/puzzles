# Play Store listing — Word Search

Every claim here was checked against the code. Do not add a feature to
this copy without confirming the app actually has it: a listing that
promises something the app does not do is both a Play policy problem and
the fastest route to one-star reviews.

Deliberately **not** mentioned: Remove Ads. The in-app product is not
created or activated yet, so advertising a purchase users cannot make
would be false. Paste the line at the bottom in once it is live.

---

## Title (max 30 characters)

```
Word Search Puzzles
```

19 characters. "Word Search" alone is the term people search for;
"Puzzles" catches the longer query without keyword-stuffing.

## Short description (max 80 characters)

```
2,400 word search puzzles in 6 languages. Play offline, no account needed.
```

74 characters. Leads with the two things that actually differentiate it:
the volume, and that it works with no network and no sign-up.

## Full description (max 4000 characters)

```
Find every hidden word — 2,400 puzzles across six languages, all playable offline.

Word Search is a calm, uncluttered puzzle game. No account, no sign-up, no internet needed to play. Open it and start.

FOUR DIFFICULTIES THAT ACTUALLY DIFFER
• Easy — 8x8 grid, 6 words, running right and down
• Medium — 10x10 grid, 8 words, diagonals appear
• Hard — 12x12 grid, 10 words, words start running backwards
• Expert — 14x14 grid, 12 words, all eight directions

The grid grows, the word list grows, and the directions open up together. Backwards words arrive at Hard, because that is the point where a word search stops being a scan and starts being a search.

SIX LANGUAGES, CHOSEN SEPARATELY
Play the puzzles in English, Arabic, German, French, Spanish or Italian — and set the app's own language independently. Read the menus in Arabic while solving English word lists, or the reverse. Arabic is fully right-to-left, grid included.

EIGHT THEMES
Animals, food, nature, home, the body, clothes, travel and sports. Every puzzle draws its words from a single theme, so a grid holds a set that belongs together.

BUILT TO BE PLEASANT
• Drag in any of eight directions to select a word
• Stuck? A hint will find one word for you
• Your progress saves itself — close the app mid-puzzle and come back
• Puzzles unlock in order, so there is always a clear next one
• Light and dark themes
• Six background music tracks, or silence — sound and vibration both switch off
• Optional gentle reminders if you want a nudge to play

WORKS WITHOUT A CONNECTION
Every puzzle ships inside the app. There is no server, no account and no login. Nothing you do is uploaded — your progress and settings stay on your device. A connection is only ever used for ads.

2,400 puzzles: 100 per difficulty, in each of six languages. Every one was verified by machine to contain each of its words exactly once — so a word you cannot find is always there.
```

Roughly 1,750 characters, well inside the 4,000 limit.

### Line to add once Remove Ads is live

```
REMOVE ADS
A single one-time purchase removes banner and interstitial ads permanently, and makes hints free. Restore it any time on a new device.
```

---

## Graphics

| Asset | Requirement | Status |
| --- | --- | --- |
| App icon | 512x512 PNG, 32-bit | **Ready** — `store/graphics/play_icon_512.png` |
| Feature graphic | 1024x500 PNG/JPG | **Ready** — `store/graphics/feature_graphic.png` |
| Phone screenshots | 2-8, min 320px, max 3840px per side | **Missing — must be real device captures** |
| Tablet screenshots | Only if declaring tablet support | Optional |

Both ready assets regenerate from the app icon with
`dart run tool/generate_store_graphics.dart`.

### Screenshots to capture during the device test pass

Six is a good number. Capture in this order — it tells a story to
someone scrolling the listing:

1. **A puzzle mid-solve**, with two or three words already struck
   through — the single most useful shot, because it shows the whole
   mechanic at a glance
2. **The moment a word is found**, drag highlight visible
3. **Puzzle list** showing the difficulty banner and progress
4. **Difficulty picker** — communicates depth
5. **An Arabic puzzle** — proves the six-language claim rather than
   asserting it
6. **Dark mode**, on any screen

Do not add marketing text over the first screenshot. Play crops and
scales these heavily, and the shot that reads clearly at thumbnail size
is a clean grid, not a captioned one.
