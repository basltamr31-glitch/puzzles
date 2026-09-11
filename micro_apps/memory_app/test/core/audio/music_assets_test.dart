import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_app/core/audio/sound_service.dart';

/// Every track named in [MusicTrack] must resolve to a real bundled file.
///
/// This is the one audio failure that is completely silent: `playMusic`
/// deliberately catches a missing asset and only logs, so the app cannot
/// crash while tracks are being added one at a time. The flip side is
/// that a typo in a filename — or a track declared but never supplied —
/// ships as "the music setting does nothing", with nothing to notice in
/// review. That is what this test catches.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tracks = MusicTrack.values.where((t) => t.assetPath != null).toList();

  test('every track except "off" declares an asset path', () {
    expect(tracks.length, MusicTrack.values.length - 1);
    expect(MusicTrack.off.assetPath, isNull);
  });

  for (final track in tracks) {
    test('${track.id} resolves to a bundled file', () async {
      // audioplayers prepends "assets/", so that is the real bundle key.
      final key = 'assets/${track.assetPath}';
      final data = await rootBundle.load(key);
      expect(data.lengthInBytes, greaterThan(0), reason: '$key is empty');
    });
  }

  test('every track is an mp3', () {
    for (final track in tracks) {
      expect(track.assetPath, endsWith('.mp3'), reason: track.id);
    }
  });
}
