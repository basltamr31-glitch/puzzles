import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku_app/core/audio/sound_service.dart';

/// Regression guard for "the key tap kills the background music".
///
/// audioplayers defaults every player to [AudioContextConfigFocus.gain],
/// which on Android requests **permanent** audio focus. Under that
/// default the SFX player took focus on every keystroke, the system
/// stopped the music player, and nothing ever restored it — the music was
/// gone for the rest of the session.
///
/// Actual playback needs a device, so what is asserted here is the thing
/// that caused the bug and the thing a future edit could silently undo:
/// which focus each player asks for.
void main() {
  group('audio focus', () {
    test('the key-tap sound never requests audio focus', () {
      expect(
        AudioPlayersSoundService.sfxAudioContext.android.audioFocus,
        AndroidAudioFocus.none,
        reason: 'a tap that takes focus stops the music, permanently',
      );
    });

    test('background music does take focus', () {
      // The app's own soundtrack should interrupt whatever else was
      // playing — that is what turning game music on means.
      expect(
        AudioPlayersSoundService.musicAudioContext.android.audioFocus,
        AndroidAudioFocus.gain,
      );
    });

    test('the two players do not share one context', () {
      expect(
        AudioPlayersSoundService.sfxAudioContext.android.audioFocus,
        isNot(AudioPlayersSoundService.musicAudioContext.android.audioFocus),
      );
    });

    test('neither player is silenced by the ringer switch', () {
      // respectSilence would mandate USAGE_NOTIFICATION_RINGTONE, which is
      // wrong for both a game soundtrack and a UI tap.
      expect(
        AudioPlayersSoundService.musicAudioContext.android.usageType,
        AndroidUsageType.media,
      );
      expect(
        AudioPlayersSoundService.sfxAudioContext.android.usageType,
        AndroidUsageType.media,
      );
    });
  });
}
