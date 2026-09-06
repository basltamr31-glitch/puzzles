// Generates the key-tap sound effect.
//
// Music is NOT generated here. assets/audio/music/ holds real licensed MP3
// tracks added by hand; this tool used to synthesize placeholders there,
// which meant re-running it would silently destroy them. See that folder's
// README for the expected filenames.
//
// Run with: dart run tool/generate_audio.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _sfxSampleRate = 22050;

void _writeWav(String path, List<double> samples, int sampleRate) {
  final dataSize = samples.length * 2;
  final builder = BytesBuilder();

  void writeString(String s) => builder.add(s.codeUnits);
  void writeUint32(int v) {
    final b = ByteData(4)..setUint32(0, v, Endian.little);
    builder.add(b.buffer.asUint8List());
  }

  void writeUint16(int v) {
    final b = ByteData(2)..setUint16(0, v, Endian.little);
    builder.add(b.buffer.asUint8List());
  }

  writeString('RIFF');
  writeUint32(36 + dataSize);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);
  writeUint16(1); // PCM
  writeUint16(1); // mono
  writeUint32(sampleRate);
  writeUint32(sampleRate * 2); // byte rate
  writeUint16(2); // block align
  writeUint16(16); // bits per sample
  writeString('data');
  writeUint32(dataSize);

  final sampleBytes = ByteData(dataSize);
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    sampleBytes.setInt16(i * 2, (clamped * 32767).round(), Endian.little);
  }
  builder.add(sampleBytes.buffer.asUint8List());

  File(path).writeAsBytesSync(builder.toBytes());
}

List<double> _keyTap() {
  const duration = 0.07;
  final n = (_sfxSampleRate * duration).round();
  return List.generate(n, (i) {
    final t = i / _sfxSampleRate;
    final envelope = exp(-t * 45);
    final tone = sin(2 * pi * 900 * t) * 0.6 + sin(2 * pi * 1800 * t) * 0.2;
    return tone * envelope;
  });
}

void main() {
  Directory('assets/audio/sfx').createSync(recursive: true);

  _writeWav('assets/audio/sfx/key_tap.wav', _keyTap(), _sfxSampleRate);
  stdout.writeln('Wrote assets/audio/sfx/key_tap.wav');

  stdout.writeln(
    '\nMusic is NOT generated. assets/audio/music/ holds real, licensed MP3\n'
    'tracks supplied by hand — writing synthesized files there would\n'
    'silently destroy them. See that folder\'s README for the expected\n'
    'filenames and what a track needs to meet.',
  );
}
