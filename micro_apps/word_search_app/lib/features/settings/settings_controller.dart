import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/sound_service.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import 'domain/app_settings_state.dart';

class SettingsController extends Notifier<AppSettingsState> {
  @override
  AppSettingsState build() {
    final storage = ref.watch(localStorageServiceProvider);
    return AppSettingsState(
      soundEnabled: storage.getBool(StorageKeys.soundEnabled) ?? true,
      vibrationEnabled: storage.getBool(StorageKeys.vibrationEnabled) ?? true,
      musicTrack: MusicTrack.fromId(
        storage.getString(StorageKeys.musicTrack) ?? MusicTrack.off.id,
      ),
    );
  }

  Future<void> setSoundEnabled(bool value) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setBool(StorageKeys.soundEnabled, value);
    state = state.copyWith(soundEnabled: value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setBool(StorageKeys.vibrationEnabled, value);
    state = state.copyWith(vibrationEnabled: value);
  }

  /// Persists the choice and actually starts/stops playback — picking
  /// [MusicTrack.off] is how a player turns music off/removes it, there's
  /// no separate mute switch to keep in sync.
  Future<void> setMusicTrack(MusicTrack track) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setString(StorageKeys.musicTrack, track.id);
    if (track != MusicTrack.off) {
      await storage.setString(StorageKeys.lastMusicTrack, track.id);
    }
    state = state.copyWith(musicTrack: track);
    await ref.read(soundServiceProvider).playMusic(track);
  }

  /// One-tap mute/unmute for the in-game toggle. Turning music back on
  /// restores whichever track the player actually picked rather than
  /// forcing a default, falling back to [MusicTrack.calm] for someone who
  /// has never chosen one.
  Future<void> toggleMusic() async {
    if (state.musicTrack != MusicTrack.off) {
      await setMusicTrack(MusicTrack.off);
      return;
    }
    final storage = ref.read(localStorageServiceProvider);
    final previous = MusicTrack.fromId(
      storage.getString(StorageKeys.lastMusicTrack) ?? MusicTrack.calm.id,
    );
    await setMusicTrack(
      previous == MusicTrack.off ? MusicTrack.calm : previous,
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettingsState>(
      SettingsController.new,
    );
