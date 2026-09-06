import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/settings_controller.dart';

/// Selectable background music. [assetPath] is null for [off], which is
/// both "no track selected" and the way to stop/remove music entirely —
/// there's no separate mute switch, picking [off] *is* turning it off.
enum MusicTrack {
  off('off', null),
  calm('calm', 'audio/music/calm.mp3'),
  gentle('gentle', 'audio/music/gentle.mp3'),
  uplifting('uplifting', 'audio/music/uplifting.mp3'),
  focus('focus', 'audio/music/focus.mp3'),
  bright('bright', 'audio/music/bright.mp3'),
  night('night', 'audio/music/night.mp3');

  const MusicTrack(this.id, this.assetPath);

  final String id;

  /// Relative to the `assets/` prefix that audioplayers prepends, so this
  /// resolves to `assets/audio/music/<file>` in the bundle.
  final String? assetPath;

  static MusicTrack fromId(String id) {
    return MusicTrack.values.firstWhere(
      (t) => t.id == id,
      orElse: () => MusicTrack.off,
    );
  }
}

/// Thin wrapper around actual audio playback, gated by the user's Settings
/// toggle for the key-tap SFX. Follows the same shape as `HapticService` —
/// feature code asks for an intent/track, never touches the platform APIs.
abstract class SoundService {
  void playKeyTap();

  /// Plays the tap sound and reports the failure reason, or null on
  /// success. Audio failures on Android are frequently silent rather than
  /// throwing where the caller can see them, so Settings exposes this to
  /// turn "I hear nothing" into an actual message.
  Future<String?> testKeyTap();

  Future<void> playMusic(MusicTrack track);
  Future<void> pauseMusic();
  Future<void> resumeMusic();

  /// Most recent playback error, or null. Lets Settings surface a music
  /// failure that would otherwise just sound like silence.
  String? get lastError;

  void dispose();
}

/// Music is supplied as real MP3 files in `assets/audio/music/`, one per
/// [MusicTrack]. The filenames are the contract — see the README in that
/// folder for the exact list and the requirements a track must meet.
/// `tool/generate_audio.dart` no longer writes there; it only produces the
/// key-tap SFX, so regenerating sounds can't clobber licensed music.
///
/// Deliberately uses the default [PlayerMode.mediaPlayer] for both players.
/// An earlier version put the tap sound in [PlayerMode.lowLatency], which
/// routes to Android's SoundPool — a different code path where the source
/// must be preloaded and `seek` is not supported, and which failed without
/// surfacing anything. Slight extra latency on a key tap is a much better
/// trade than silence.
///
/// ## Audio focus
///
/// The two players need *different* audio focus, and this is not a detail:
/// audioplayers defaults every player to [AudioContextConfigFocus.gain],
/// which on Android is a request for **permanent** audio focus. With that
/// default, every key tap announced itself as the sole audio source, the
/// system took focus away from the music player, and the music stopped —
/// permanently, because nothing ever gives it back.
///
/// So the SFX player mixes instead of taking focus, and only the music
/// player asks for focus at all.
class AudioPlayersSoundService implements SoundService {
  AudioPlayersSoundService(this._isSfxEnabled);

  static const String _keyTapAsset = 'audio/sfx/key_tap.wav';
  static const double _musicVolume = 0.5;

  /// A key tap must never interrupt the music. `mixWithOthers` maps to
  /// [AndroidAudioFocus.none] and to `AVAudioSessionOptions.mixWithOthers`
  /// on iOS — the sound plays over whatever is already playing.
  static final AudioContext sfxAudioContext =
      AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build();

  /// Background music is the app's own soundtrack, so it does take focus —
  /// starting it should pause the podcast the player had running, which is
  /// what someone turning on game music expects.
  static final AudioContext musicAudioContext =
      AudioContextConfig(focus: AudioContextConfigFocus.gain).build();

  final bool Function() _isSfxEnabled;
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  MusicTrack _currentTrack = MusicTrack.off;
  bool _disposed = false;
  String? _lastError;

  Future<void>? _sfxLoad;
  bool _tapInFlight = false;
  DateTime _lastTapAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Typing can outrun audio easily; below this gap a tap is dropped rather
  /// than queued, so the sound never becomes a backlog that delays letters.
  static const Duration _minTapGap = Duration(milliseconds: 45);

  @override
  String? get lastError => _lastError;

  /// Loads the sample **once**. Handing `play()` an [AssetSource] on every
  /// keystroke makes the platform copy the asset out of the bundle and build
  /// a fresh player each time — two channel round trips plus file I/O per
  /// letter, which is what made fast typing stutter and lag behind.
  Future<void> _ensureSfxLoaded() {
    return _sfxLoad ??= () async {
      // Set before the source: this is what stops a tap from grabbing
      // audio focus and killing the background music.
      await _sfxPlayer.setAudioContext(sfxAudioContext);
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setSource(AssetSource(_keyTapAsset));
      await _sfxPlayer.setVolume(1);
    }();
  }

  @override
  void playKeyTap() {
    if (!_isSfxEnabled() || _disposed) return;

    // Dropping overlapping taps keeps this strictly fire-and-forget: the
    // input path never waits on audio, and no work piles up behind it.
    final now = DateTime.now();
    if (_tapInFlight || now.difference(_lastTapAt) < _minTapGap) return;
    _lastTapAt = now;
    unawaited(_playKeyTap());
  }

  Future<String?> _playKeyTap() async {
    _tapInFlight = true;
    try {
      await _ensureSfxLoaded();
      if (_disposed) return null;
      // Rewind-and-resume replays the already-loaded sample instead of
      // reloading it.
      await _sfxPlayer.seek(Duration.zero);
      await _sfxPlayer.resume();
      _lastError = null;
      return null;
    } catch (error, stackTrace) {
      // A failed preload must not poison every later tap.
      _sfxLoad = null;
      final message = error.toString();
      _lastError = message;
      debugPrint('SoundService key tap failed: $error\n$stackTrace');
      // Guarantee some audible feedback even if the bundled sample can't
      // be played on this device.
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {
        // Nothing more we can do; the returned message is the diagnosis.
      }
      return message;
    } finally {
      // Must always clear, or a single failure would silence every later tap.
      _tapInFlight = false;
    }
  }

  @override
  Future<String?> testKeyTap() {
    if (_disposed) return Future.value('Sound service was disposed.');
    return _playKeyTap();
  }

  @override
  Future<void> playMusic(MusicTrack track) async {
    _currentTrack = track;
    if (_disposed) return;
    try {
      await _musicPlayer.stop();
      final assetPath = track.assetPath;
      if (assetPath == null) return;
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(
        AssetSource(assetPath),
        volume: _musicVolume,
        ctx: musicAudioContext,
      );
      _lastError = null;
    } catch (error, stackTrace) {
      _lastError = error.toString();
      debugPrint(
        'SoundService music failed for ${track.id}: $error\n$stackTrace',
      );
    }
  }

  @override
  Future<void> pauseMusic() async {
    if (_currentTrack == MusicTrack.off || _disposed) return;
    try {
      await _musicPlayer.pause();
    } catch (error) {
      debugPrint('SoundService pause failed: $error');
    }
  }

  @override
  Future<void> resumeMusic() async {
    if (_currentTrack == MusicTrack.off || _disposed) return;
    try {
      await _musicPlayer.resume();
    } catch (error) {
      debugPrint('SoundService resume failed: $error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = AudioPlayersSoundService(
    () => ref.read(settingsControllerProvider).soundEnabled,
  );
  ref.onDispose(service.dispose);
  return service;
});
