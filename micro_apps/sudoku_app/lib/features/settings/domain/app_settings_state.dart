import 'package:equatable/equatable.dart';

import '../../../core/audio/sound_service.dart';

class AppSettingsState extends Equatable {
  const AppSettingsState({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.musicTrack,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final MusicTrack musicTrack;

  AppSettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    MusicTrack? musicTrack,
  }) {
    return AppSettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      musicTrack: musicTrack ?? this.musicTrack,
    );
  }

  @override
  List<Object?> get props => [soundEnabled, vibrationEnabled, musicTrack];
}
