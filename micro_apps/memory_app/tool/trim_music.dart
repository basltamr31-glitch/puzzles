// Shortens the bundled music tracks by cutting whole MP3 frames.
//
//   dart run tool/trim_music.dart              # trim to the default length
//   dart run tool/trim_music.dart 210          # trim to 3:30 instead
//
// Reads from ../../music_originals/ and writes to assets/audio/music/.
// The originals are never modified, so a different length is always one
// re-run away.
//
// ## Why frame-cutting rather than re-encoding
//
// The tracks are already 64 kbps — near the bottom of what MP3 does
// acceptably. Decoding and re-encoding them would add a second
// generation of lossy compression to audio that has no quality to spare,
// and would need an encoder this machine does not have. An MP3 file is a
// sequence of self-contained frames, so keeping the first N frames and
// discarding the rest is a byte-level operation: the audio that remains
// is bit-identical to the original. Nothing is re-compressed.
//
// ## The trade-off this cannot solve
//
// A frame cut lands wherever it lands musically. The player loops each
// track forever, so if the end of the trimmed file does not flow into its
// beginning you will hear it every time it wraps. Fixing that properly
// needs a crossfade, which needs decoding, which costs a generation of
// quality. So: listen to each track before shipping. If one seams badly,
// re-run with a different length — it is instant and lossless — before
// reaching for a re-encode.

import 'dart:io';
import 'dart:typed_data';

/// Default loop length. Long enough not to feel repetitive, short enough
/// that six tracks cost a few MB rather than 31.
const int defaultSeconds = 150;

const String originalsDir = '../../music_originals';
const String outputDir = 'assets/audio/music';

/// MPEG-1 Layer III bitrates, indexed by the header's bitrate field.
const List<int> _bitratesV1L3 = [
  0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0,
];
const List<int> _sampleRatesV1 = [44100, 48000, 32000, 0];

/// Every MPEG-1 Layer III frame carries 1152 samples, whatever its size.
const int _samplesPerFrame = 1152;

class _Frame {
  const _Frame(this.offset, this.length, this.sampleRate);
  final int offset;
  final int length;
  final int sampleRate;
}

/// Byte offset of the first MP3 frame, skipping any ID3v2 tag.
///
/// The tag is preserved in the output: it may carry the licence and
/// attribution for the track, which would be careless to throw away.
int _audioStart(Uint8List bytes) {
  if (bytes.length < 10) return 0;
  final isId3 = bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33;
  if (!isId3) return 0;
  // ID3v2 size is four 7-bit bytes.
  final size = (bytes[6] & 0x7F) << 21 |
      (bytes[7] & 0x7F) << 14 |
      (bytes[8] & 0x7F) << 7 |
      (bytes[9] & 0x7F);
  return 10 + size;
}

_Frame? _frameAt(Uint8List bytes, int offset) {
  if (offset + 4 > bytes.length) return null;
  if (bytes[offset] != 0xFF || (bytes[offset + 1] & 0xE0) != 0xE0) return null;

  final version = (bytes[offset + 1] >> 3) & 3; // 3 == MPEG-1
  final layer = (bytes[offset + 1] >> 1) & 3; //   1 == Layer III
  final bitrate = _bitratesV1L3[(bytes[offset + 2] >> 4) & 0xF];
  final sampleRate = _sampleRatesV1[(bytes[offset + 2] >> 2) & 3];
  final padding = (bytes[offset + 2] >> 1) & 1;

  if (version != 3 || layer != 1 || bitrate == 0 || sampleRate == 0) {
    return null;
  }
  final length = (144 * bitrate * 1000) ~/ sampleRate + padding;
  if (length <= 4 || offset + length > bytes.length) return null;
  return _Frame(offset, length, sampleRate);
}

/// True if this frame is a Xing/Info header rather than audio.
///
/// It describes the *original* duration. Carried into a trimmed file it
/// would tell the player the track is three times longer than it is,
/// which is exactly the sort of thing that makes a loop hesitate.
bool _isXingHeader(Uint8List bytes, _Frame frame) {
  for (var i = frame.offset + 4; i < frame.offset + frame.length - 4; i++) {
    final tag = String.fromCharCodes(bytes.sublist(i, i + 4));
    if (tag == 'Xing' || tag == 'Info') return true;
  }
  return false;
}

void main(List<String> args) {
  final seconds = args.isEmpty ? defaultSeconds : int.parse(args.first);

  final source = Directory(originalsDir);
  if (!source.existsSync()) {
    stderr.writeln('No originals at ${source.path}.\n'
        'Copy the untrimmed MP3s there first — this tool never reads its '
        'own output, so it can always be re-run at a different length.');
    exitCode = 1;
    return;
  }

  final files = source
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.mp3'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stderr.writeln('No .mp3 files in ${source.path}.');
    exitCode = 1;
    return;
  }

  var totalBefore = 0;
  var totalAfter = 0;

  for (final file in files) {
    final bytes = file.readAsBytesSync();
    final name = file.uri.pathSegments.last;
    final start = _audioStart(bytes);

    final kept = <_Frame>[];
    var samples = 0;
    var targetSamples = 0;
    var offset = start;
    var skippedXing = false;

    while (offset < bytes.length) {
      final frame = _frameAt(bytes, offset);
      if (frame == null) {
        // Not a frame header: step a byte and resync. Trailing tags and
        // the occasional stray byte are normal at the end of a file.
        offset++;
        continue;
      }
      if (!skippedXing && _isXingHeader(bytes, frame)) {
        skippedXing = true;
        offset += frame.length;
        continue;
      }
      if (targetSamples == 0) targetSamples = seconds * frame.sampleRate;
      if (samples >= targetSamples) break;

      kept.add(frame);
      samples += _samplesPerFrame;
      offset += frame.length;
    }

    if (kept.isEmpty) {
      stderr.writeln('$name: no MPEG-1 Layer III frames found, skipped.');
      continue;
    }

    final out = BytesBuilder();
    out.add(bytes.sublist(0, start)); // ID3v2 tag, if any.
    for (final frame in kept) {
      out.add(bytes.sublist(frame.offset, frame.offset + frame.length));
    }
    final data = out.toBytes();

    Directory(outputDir).createSync(recursive: true);
    File('$outputDir/$name').writeAsBytesSync(data);

    final duration = samples / kept.first.sampleRate;
    totalBefore += bytes.length;
    totalAfter += data.length;
    stdout.writeln('${name.padRight(16)} '
        '${(bytes.length / 1048576).toStringAsFixed(1)} MB -> '
        '${(data.length / 1048576).toStringAsFixed(1)} MB   '
        '${(duration ~/ 60)}:${(duration % 60).floor().toString().padLeft(2, '0')}');
  }

  stdout.writeln('\ntotal ${(totalBefore / 1048576).toStringAsFixed(1)} MB -> '
      '${(totalAfter / 1048576).toStringAsFixed(1)} MB '
      '(saved ${((totalBefore - totalAfter) / 1048576).toStringAsFixed(1)} MB)');
  stdout.writeln('\nListen to each track before shipping: a frame cut does '
      'not know where the music phrases, so a loop may audibly seam. '
      'Re-run with a different length if one does.');
}
