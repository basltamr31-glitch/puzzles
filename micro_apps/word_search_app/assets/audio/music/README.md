# Background music — drop your MP3 files here

Put six MP3 files in this folder, named **exactly** as below. The names are
the contract: `MusicTrack` in `lib/core/audio/sound_service.dart` looks each
one up by filename, and Settings shows a translated label for it.

| File | Shown in Settings as | Intended mood |
| --- | --- | --- |
| `calm.mp3` | Calm | slow, unobtrusive |
| `gentle.mp3` | Gentle | soft and rounded |
| `uplifting.mp3` | Uplifting | brighter, a little faster |
| `focus.mp3` | Focus | sparse, for concentration |
| `bright.mp3` | Bright | open and cheerful |
| `night.mp3` | Night | low-lit, slow |

A missing file is **not** a crash — that track just plays nothing and the
reason is logged. So you can add them one at a time.

## What a track needs

**Loop seamlessly.** This is the one that ruins otherwise good music: the
player loops each track forever, so any silence at the start or end becomes
an audible gap every time it repeats. Trim both ends to the exact bar.

**Stay in a range phone speakers can reproduce.** Small speakers put out
almost nothing below ~300 Hz. A track carried by deep bass will be *felt*
as a buzz rather than heard — this exact problem made the first version of
this app's music inaudible. Music with content in the mid range works.

**Keep it modest in size.** 96–128 kbps mono is plenty for background
music behind gameplay and keeps each file a few hundred KB. The app is
already ~62 MB; six large tracks would be very noticeable.

**Mind the licence.** If the music is licensed or royalty-free, keep proof
of the licence, and check it permits redistribution *inside an application*
— that is not automatic even for "free" tracks.

## Adding a seventh track

1. Put the file here, e.g. `ocean.mp3`
2. Add an entry to `MusicTrack` in `lib/core/audio/sound_service.dart`
3. Add `musicTrackOcean` to all six `.arb` files, then `flutter gen-l10n`
4. Add the case to `_musicTrackLabel` in `settings_screen.dart`

Step 4 won't compile if you skip it — the switch is exhaustive on purpose,
so a track can't ship without a name.

## Note

`tool/generate_audio.dart` deliberately does **not** write to this folder.
It used to generate synthesized placeholder tracks here; that was removed
so re-running it can never overwrite real music. It still generates the
key-tap sound in `assets/audio/sfx/`.
