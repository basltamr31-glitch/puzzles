// Produces the shipped music tracks from the originals: trimmed to a loop
// length, crossfaded so the loop is seamless, and re-encoded small.
//
//   dart run tool/encode_music.dart                  # defaults
//   dart run tool/encode_music.dart --seconds 120    # shorter loop
//   dart run tool/encode_music.dart --bitrate 128k --stereo
//
// Reads ../../music_originals/, writes assets/audio/music/. The originals
// are never modified, so any setting can be reconsidered by re-running.
//
// Requires ffmpeg on PATH (or FFMPEG set to its full path).
//
// ## Why this exists alongside trim_music.dart
//
// `trim_music.dart` cuts MP3 frames without decoding: lossless, no tools
// needed, but it cannot crossfade — the cut lands wherever it lands, and
// a loop whose end does not flow into its start is audible every time it
// wraps. This tool decodes, so it can wrap the track's own tail back over
// its head and make the seam disappear. The cost is one generation of
// lossy re-encoding, which is why it always works from the originals and
// never from its own output.
//
// ## The crossfade
//
// Given loop length L and crossfade X, the output is L seconds long and
// contains:
//   * the source from 0..L, fading *in* over the first X seconds
//   * the source from L..L+X, fading *out*, mixed on top of that same
//     opening X seconds
// So when the player wraps from L back to 0, the music the listener hears
// at the start is the natural continuation of what was playing at the
// end. Equal-power (`qsin`) curves keep the loudness steady through the
// overlap instead of dipping in the middle.

import 'dart:io';

const String originalsDir = '../../music_originals';
const String outputDir = 'assets/audio/music';

/// Mono at 96 kbps. Background music sits under gameplay and is heard on
/// phone speakers or one earbud; stereo imaging buys nothing there, and
/// mono halves the size outright.
const String defaultBitrate = '96k';
const int defaultSeconds = 150;

/// Long enough to hide the join, short enough not to swallow a phrase.
const double crossfadeSeconds = 5;

String _ffmpeg() => Platform.environment['FFMPEG'] ?? 'ffmpeg';

String _ffprobe() {
  final ffmpeg = _ffmpeg();
  if (ffmpeg == 'ffmpeg') return 'ffprobe';
  // ffprobe sits beside ffmpeg in every distribution, so derive one from
  // the other rather than asking for a second path.
  return ffmpeg.replaceAllMapped(
    RegExp(r'ffmpeg(\.exe)?$'),
    (m) => m[1] == null ? 'ffprobe' : 'ffprobe.exe',
  );
}

double? _durationOf(String path) {
  final result = Process.runSync(_ffprobe(), [
    '-v', 'error',
    '-show_entries', 'format=duration',
    '-of', 'default=noprint_wrappers=1:nokey=1',
    path,
  ]);
  if (result.exitCode != 0) return null;
  return double.tryParse((result.stdout as String).trim());
}

void main(List<String> args) {
  var seconds = defaultSeconds;
  var bitrate = defaultBitrate;
  var channels = 1;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--seconds':
        seconds = int.parse(args[++i]);
      case '--bitrate':
        bitrate = args[++i];
      case '--stereo':
        channels = 2;
    }
  }

  final source = Directory(originalsDir);
  if (!source.existsSync()) {
    stderr.writeln('No originals at ${source.path}. Put the full-length '
        'tracks there; this tool never reads its own output.');
    exitCode = 1;
    return;
  }

  final probe = Process.runSync(_ffmpeg(), ['-hide_banner', '-version']);
  if (probe.exitCode != 0) {
    stderr.writeln('ffmpeg not found. Install it, or set FFMPEG to its '
        'full path. (trim_music.dart needs no tools, but cannot crossfade.)');
    exitCode = 1;
    return;
  }

  final files = source
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.mp3'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  Directory(outputDir).createSync(recursive: true);
  var before = 0;
  var after = 0;

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final target = '$outputDir/$name';
    final duration = _durationOf(file.path);

    if (duration == null) {
      stderr.writeln('$name: could not read duration, skipped.');
      continue;
    }

    // A track shorter than the requested loop still gets crossfaded, using
    // whatever tail it has; one shorter than two crossfades has nothing to
    // overlap and is simply re-encoded.
    final loop = duration > seconds + crossfadeSeconds
        ? seconds.toDouble()
        : duration - crossfadeSeconds;
    final canCrossfade = loop > crossfadeSeconds * 2;

    final List<String> ffmpegArgs;
    if (canCrossfade) {
      final filter = '[0:a]atrim=0:$loop,asetpts=PTS-STARTPTS,'
          'afade=t=in:st=0:d=$crossfadeSeconds:curve=qsin[main];'
          '[0:a]atrim=$loop:${loop + crossfadeSeconds},asetpts=PTS-STARTPTS,'
          'afade=t=out:st=0:d=$crossfadeSeconds:curve=qsin[tail];'
          '[main][tail]amix=inputs=2:duration=first:dropout_transition=0:'
          'normalize=0[out]';
      ffmpegArgs = [
        '-hide_banner', '-loglevel', 'error', '-y',
        '-i', file.path,
        '-filter_complex', filter,
        '-map', '[out]',
        '-ac', '$channels', '-c:a', 'libmp3lame', '-b:a', bitrate,
        target,
      ];
    } else {
      ffmpegArgs = [
        '-hide_banner', '-loglevel', 'error', '-y',
        '-i', file.path,
        '-ac', '$channels', '-c:a', 'libmp3lame', '-b:a', bitrate,
        target,
      ];
    }

    final result = Process.runSync(_ffmpeg(), ffmpegArgs);
    if (result.exitCode != 0) {
      stderr.writeln('$name: ffmpeg failed\n${result.stderr}');
      exitCode = 1;
      continue;
    }

    final inSize = file.lengthSync();
    final outSize = File(target).lengthSync();
    before += inSize;
    after += outSize;
    final outDuration = _durationOf(target) ?? 0;
    stdout.writeln('${name.padRight(16)} '
        '${(inSize / 1048576).toStringAsFixed(1)} MB -> '
        '${(outSize / 1048576).toStringAsFixed(1)} MB   '
        '${outDuration ~/ 60}:${(outDuration % 60).floor().toString().padLeft(2, '0')}'
        '${canCrossfade ? '  crossfaded' : '  (too short to crossfade)'}');
  }

  stdout.writeln('\ntotal ${(before / 1048576).toStringAsFixed(1)} MB -> '
      '${(after / 1048576).toStringAsFixed(1)} MB '
      '(saved ${((before - after) / 1048576).toStringAsFixed(1)} MB)');
}
