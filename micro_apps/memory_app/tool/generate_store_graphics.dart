// Generates the Google Play store listing graphics.
//
//   dart run tool/generate_store_graphics.dart
//
// Writes to store/graphics/:
//   * play_icon_512.png    — the launcher icon, resized to Play's 512x512
//   * feature_graphic.png  — the 1024x500 banner at the top of the listing
//
// Both derive from assets/icon/, so the listing and the installed app
// always show the same mark. Regenerate after any icon change.
//
// Screenshots are NOT generated here — Play wants real ones, and a
// fabricated screenshot of a screen the app does not have is a listing
// violation as well as a lie.

import 'dart:io';

import 'package:image/image.dart' as img;

const String outputDir = 'store/graphics';

/// Play's fixed sizes. Not configurable: an upload of any other size is
/// rejected outright.
const int iconSize = 512;
const int featureWidth = 1024;
const int featureHeight = 500;

void main(List<String> args) {
  final source = File('assets/icon/icon.png');
  if (!source.existsSync()) {
    stderr.writeln('Missing ${source.path}. Run tool/generate_icon.dart first.');
    exitCode = 1;
    return;
  }

  final icon = img.decodePng(source.readAsBytesSync());
  if (icon == null) {
    stderr.writeln('Could not decode ${source.path}.');
    exitCode = 1;
    return;
  }

  Directory(outputDir).createSync(recursive: true);

  // --- Play icon: a plain high-quality downscale of the launcher icon.
  final playIcon = img.copyResize(
    icon,
    width: iconSize,
    height: iconSize,
    interpolation: img.Interpolation.cubic,
  );
  final iconPath = '$outputDir/play_icon_512.png';
  File(iconPath).writeAsBytesSync(img.encodePng(playIcon));
  stdout.writeln('$iconPath  ${iconSize}x$iconSize');

  // --- Feature graphic: the mark on the brand gradient.
  //
  // Deliberately no text. The feature graphic is shown at wildly
  // different sizes and is often cropped, and Play's own guidance warns
  // that text near an edge gets cut. The app name sits directly beneath
  // it in the listing anyway, so repeating it adds nothing and risks
  // looking broken.
  final feature = img.Image(
    width: featureWidth,
    height: featureHeight,
    numChannels: 4,
  );

  final topLeft = _sampleBrand(icon, 0.12);
  final bottomRight = _sampleBrand(icon, 0.88);

  for (var y = 0; y < featureHeight; y++) {
    for (var x = 0; x < featureWidth; x++) {
      // Diagonal blend, so the banner echoes the icon's own gradient
      // direction rather than sitting flat behind it.
      final t = (x / featureWidth * 0.5) + (y / featureHeight * 0.5);
      feature.setPixelRgba(
        x,
        y,
        _lerp(topLeft.$1, bottomRight.$1, t),
        _lerp(topLeft.$2, bottomRight.$2, t),
        _lerp(topLeft.$3, bottomRight.$3, t),
        255,
      );
    }
  }

  // The *foreground* glyph, not the full icon: icon.png carries its own
  // gradient background, and compositing that over the banner leaves a
  // visible square seam where the two gradients meet. icon_foreground.png
  // is the transparent-background mark, which floats cleanly.
  final glyphFile = File('assets/icon/icon_foreground.png');
  final glyph = glyphFile.existsSync()
      ? img.decodePng(glyphFile.readAsBytesSync()) ?? icon
      : icon;

  // Centred, at a size that survives Play cropping the banner's left and
  // right edges on narrow screens.
  final markSize = (featureHeight * 0.72).round();
  final mark = img.copyResize(
    glyph,
    width: markSize,
    height: markSize,
    interpolation: img.Interpolation.cubic,
  );
  img.compositeImage(
    feature,
    mark,
    dstX: (featureWidth - markSize) ~/ 2,
    dstY: (featureHeight - markSize) ~/ 2,
  );

  final featurePath = '$outputDir/feature_graphic.png';
  File(featurePath).writeAsBytesSync(img.encodePng(feature));
  stdout.writeln('$featurePath  ${featureWidth}x$featureHeight');

  stdout.writeln('\nUpload both in Play Console > Store listing > Graphics.');
  stdout.writeln('Screenshots still have to come from a real device.');
}

/// Reads a brand colour out of the icon itself, along its diagonal, so
/// the banner cannot drift away from whatever the icon currently is.
(int, int, int) _sampleBrand(img.Image icon, double position) {
  final p = icon.getPixel(
    (icon.width * position).round().clamp(0, icon.width - 1),
    (icon.height * position).round().clamp(0, icon.height - 1),
  );
  return (p.r.toInt(), p.g.toInt(), p.b.toInt());
}

int _lerp(int a, int b, double t) => (a + (b - a) * t).round().clamp(0, 255);
