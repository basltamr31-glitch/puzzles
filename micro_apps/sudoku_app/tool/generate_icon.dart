// Generates the app icon and adaptive-icon layers.
//
//   dart run tool/generate_icon.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// Writes assets/icon/{icon,icon_background,icon_foreground}.png. The
// artwork is code rather than a binary checked into the repo so a brand
// change is a diff you can read, and so the three layers can never drift
// out of alignment with each other.
//
// The mark is a 3x3 Sudoku box with four cells filled — not a 9x9 grid,
// whose lines vanish at 48dp on a launcher, and not a digit, which would
// need a bundled font and would read as a different glyph in every
// locale's rendering.

import 'dart:io';

import 'package:image/image.dart' as img;

const int _size = 1024;

/// Adaptive icons crop to a circle of ~66% of the layer, and Android may
/// mask more aggressively still; the glyph is sized to sit inside that.
const double _foregroundGlyphFraction = 0.46;
const double _iconGlyphFraction = 0.62;

final _tealTop = img.ColorRgb8(0x14, 0x8F, 0x86);
final _tealBottom = img.ColorRgb8(0x0D, 0x5E, 0x59);
final _white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);
final _transparent = img.ColorRgba8(0, 0, 0, 0);

void main() {
  final iconDir = Directory('assets/icon')..createSync(recursive: true);

  final background = _gradientBackground();
  File('${iconDir.path}/icon_background.png')
      .writeAsBytesSync(img.encodePng(background));

  final foreground = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(foreground, color: _transparent);
  _drawMark(foreground, _size * _foregroundGlyphFraction);
  File('${iconDir.path}/icon_foreground.png')
      .writeAsBytesSync(img.encodePng(foreground));

  final icon = _gradientBackground();
  _drawMark(icon, _size * _iconGlyphFraction);
  File('${iconDir.path}/icon.png').writeAsBytesSync(img.encodePng(icon));

  stdout.writeln('Wrote icon.png, icon_background.png, icon_foreground.png '
      'to ${iconDir.path}');
}

img.Image _gradientBackground() {
  final image = img.Image(width: _size, height: _size, numChannels: 4);
  for (var y = 0; y < _size; y++) {
    final t = y / (_size - 1);
    final color = img.ColorRgba8(
      _lerp(_tealTop.r, _tealBottom.r, t),
      _lerp(_tealTop.g, _tealBottom.g, t),
      _lerp(_tealTop.b, _tealBottom.b, t),
      255,
    );
    img.drawLine(image, x1: 0, y1: y, x2: _size - 1, y2: y, color: color);
  }
  return image;
}

int _lerp(num a, num b, double t) => (a + (b - a) * t).round();

/// A 3x3 box, centred, with four cells filled in a pinwheel so the mark
/// is asymmetric — a symmetric fill pattern reads as a checkerboard.
void _drawMark(img.Image image, double glyphSize) {
  final side = glyphSize.round();
  final left = (_size - side) ~/ 2;
  final top = (_size - side) ~/ 2;
  final cell = side / 3;
  final stroke = (side * 0.055).round().clamp(2, _size);

  const filled = [(0, 0), (1, 1), (2, 0), (0, 2)];
  for (final (row, col) in filled) {
    // Inset so the fill sits inside the grid lines rather than under them.
    final inset = stroke * 0.75;
    img.fillRect(
      image,
      x1: (left + col * cell + inset).round(),
      y1: (top + row * cell + inset).round(),
      x2: (left + (col + 1) * cell - inset).round(),
      y2: (top + (row + 1) * cell - inset).round(),
      color: _white,
      radius: (cell * 0.12).round(),
    );
  }

  // Four filled bars rather than drawRect: drawRect's `thickness` is
  // ignored once a corner `radius` is given, which leaves the frame a
  // hairline next to the internal lines drawn at full stroke.
  void bar(int x1, int y1, int x2, int y2) {
    img.fillRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: _white);
  }

  final half = stroke ~/ 2;
  bar(left - half, top - half, left + side + half, top + half);
  bar(left - half, top + side - half, left + side + half, top + side + half);
  bar(left - half, top - half, left + half, top + side + half);
  bar(left + side - half, top - half, left + side + half, top + side + half);

  for (var i = 1; i < 3; i++) {
    final offset = (i * cell).round();
    img.drawLine(
      image,
      x1: left + offset,
      y1: top,
      x2: left + offset,
      y2: top + side,
      color: _white,
      thickness: stroke,
    );
    img.drawLine(
      image,
      x1: left,
      y1: top + offset,
      x2: left + side,
      y2: top + offset,
      color: _white,
      thickness: stroke,
    );
  }
}
