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

/// 44.1 kHz rather than 22.05 kHz because the tap is now built on a noise
/// transient, and noise is the one thing a low sample rate audibly hurts —
/// the 11 kHz ceiling turned the click into a dull thud. The whole file is
/// still under 4 KB.
const _sfxSampleRate = 44100;

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

/// One-pole lowpass. Takes the fizz off white noise so the transient reads
/// as a soft knock rather than a burst of hiss.
List<double> _lowpass(List<double> input, double cutoffHz) {
  final a = 1 - exp(-2 * pi * cutoffHz / _sfxSampleRate);
  var y = 0.0;
  return [
    for (final x in input) y += a * (x - y),
  ];
}

/// Raised-cosine attack and release.
///
/// Without these the waveform starts and ends on a non-zero sample, and
/// that step is itself an audible click — a harshness with nothing to do
/// with the sound being designed.
void _applyEdges(List<double> samples) {
  final attack = (_sfxSampleRate * 0.0015).round();
  final release = (_sfxSampleRate * 0.004).round();
  for (var i = 0; i < attack && i < samples.length; i++) {
    samples[i] *= 0.5 - 0.5 * cos(pi * i / attack);
  }
  for (var i = 0; i < release && i < samples.length; i++) {
    final index = samples.length - 1 - i;
    samples[index] *= 0.5 - 0.5 * cos(pi * i / release);
  }
}

void _normalize(List<double> samples, double peak) {
  var maximum = 0.0;
  for (final s in samples) {
    maximum = max(maximum, s.abs());
  }
  if (maximum == 0) return;
  final gain = peak / maximum;
  for (var i = 0; i < samples.length; i++) {
    samples[i] *= gain;
  }
}

/// A soft membrane-keyboard tap: a filtered noise transient (plastic
/// meeting plastic) over a short, heavily damped low body.
///
/// This replaced two stacked pure sine waves at 900 Hz and 1800 Hz running
/// for 70 ms. Those are the numbers that matter: a steady pitch held that
/// long is long enough for the ear to resolve it as a musical note, which
/// is exactly why it read as an electronic beep instead of a key. The body
/// here sits at 210 Hz, glides *down* to 150 Hz the way a real key drops
/// as it bottoms out, and is gone inside 38 ms — too short and too low to
/// register as a note at all.
///
/// The noise is seeded so the asset is reproducible: regenerating must not
/// produce a subtly different file on every run.
List<double> _keyTap() {
  const durationSec = 0.038;
  const clickLevel = 0.35;
  const clickCutoffHz = 2200.0;
  const clickDecay = 260.0;
  const bodyLevel = 0.55;
  const bodyStartHz = 210.0;
  const bodyEndHz = 150.0;
  const bodyDecay = 95.0;
  const softenHz = 5000.0;

  final n = (_sfxSampleRate * durationSec).round();
  final random = Random(7);
  final noise = _lowpass(
    List<double>.generate(n, (_) => random.nextDouble() * 2 - 1),
    clickCutoffHz,
  );

  final out = List<double>.filled(n, 0);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / _sfxSampleRate;
    final frequency =
        bodyStartHz + (bodyEndHz - bodyStartHz) * (1 - exp(-t * 60));
    phase += 2 * pi * frequency / _sfxSampleRate;
    out[i] = noise[i] * clickLevel * exp(-t * clickDecay) +
        sin(phase) * bodyLevel * exp(-t * bodyDecay);
  }

  final softened = _lowpass(out, softenHz);
  _applyEdges(softened);
  _normalize(softened, 0.85);
  return softened;
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
