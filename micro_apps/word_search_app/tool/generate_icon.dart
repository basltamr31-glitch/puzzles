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
// The mark is a 3x3 grid of letter tiles with a lime diagonal stroke
// crossing three of them — the exact "found word" selection line the
// gameplay screen draws — rather than a magnifying glass, which is
// generic to every word-finding app and not specific to this one.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int _size = 1024;

/// Adaptive icons crop to a circle of ~66% of the layer, and Android may
/// mask more aggressively still; the glyph is sized to sit inside that.
const double _foregroundGlyphFraction = 0.52;
const double _iconGlyphFraction = 0.68;

final _violetTop = img.ColorRgb8(0x8B, 0x5C, 0xF0);
final _violetBottom = img.ColorRgb8(0x5B, 0x21, 0xB6);
final _white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);
final _lime = img.ColorRgba8(0xBE, 0xF2, 0x64, 0xFF);
final _transparent = img.ColorRgba8(0, 0, 0, 0);

void main() {
  final iconDir = Directory('assets/icon')..createSync(recursive: true);

  final background = _gradientBackground();
  File(
    '${iconDir.path}/icon_background.png',
  ).writeAsBytesSync(img.encodePng(background));

  final foreground = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(foreground, color: _transparent);
  _drawMark(foreground, _size * _foregroundGlyphFraction);
  File(
    '${iconDir.path}/icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(foreground));

  final icon = _gradientBackground();
  _drawMark(icon, _size * _iconGlyphFraction);
  File('${iconDir.path}/icon.png').writeAsBytesSync(img.encodePng(icon));

  stdout.writeln(
    'Wrote icon.png, icon_background.png, icon_foreground.png '
    'to ${iconDir.path}',
  );
}

img.Image _gradientBackground() {
  final image = img.Image(width: _size, height: _size, numChannels: 4);
  for (var y = 0; y < _size; y++) {
    final t = y / (_size - 1);
    final color = img.ColorRgba8(
      _lerp(_violetTop.r, _violetBottom.r, t),
      _lerp(_violetTop.g, _violetBottom.g, t),
      _lerp(_violetTop.b, _violetBottom.b, t),
      255,
    );
    img.drawLine(image, x1: 0, y1: y, x2: _size - 1, y2: y, color: color);
  }
  return image;
}

int _lerp(num a, num b, double t) => (a + (b - a) * t).round();

/// A 3x3 grid of white letter tiles with a lime diagonal capsule crossing
/// the top-left, centre, and bottom-right tiles — a "found word" stroke,
/// the same visual the gameplay grid draws over a solved word.
void _drawMark(img.Image image, double glyphSize) {
  final side = glyphSize.round();
  final left = (_size - side) ~/ 2;
  final top = (_size - side) ~/ 2;
  final cell = side / 3;
  final gap = cell * 0.14;

  for (var row = 0; row < 3; row++) {
    for (var col = 0; col < 3; col++) {
      img.fillRect(
        image,
        x1: (left + col * cell + gap).round(),
        y1: (top + row * cell + gap).round(),
        x2: (left + (col + 1) * cell - gap).round(),
        y2: (top + (row + 1) * cell - gap).round(),
        color: _white,
        radius: (cell * 0.16).round(),
      );
    }
  }

  (int, int) center(int row, int col) => (
    (left + (col + 0.5) * cell).round(),
    (top + (row + 0.5) * cell).round(),
  );
  final start = center(0, 0);
  final end = center(2, 2);
  final strokeWidth = cell * 0.34;
  _drawCapsule(image, start, end, strokeWidth, _lime);
}

/// A rounded-cap line: a rectangle along the segment plus a filled circle
/// at each end, so the stroke reads as a highlighter mark rather than a
/// hard-edged bar.
void _drawCapsule(
  img.Image image,
  (int, int) from,
  (int, int) to,
  double width,
  img.Color color,
) {
  final dx = (to.$1 - from.$1).toDouble();
  final dy = (to.$2 - from.$2).toDouble();
  final length = math.sqrt(dx * dx + dy * dy);
  final nx = -dy / length * (width / 2);
  final ny = dx / length * (width / 2);

  final poly = [
    (from.$1 + nx, from.$2 + ny),
    (to.$1 + nx, to.$2 + ny),
    (to.$1 - nx, to.$2 - ny),
    (from.$1 - nx, from.$2 - ny),
  ];
  img.fillPolygon(
    image,
    vertices: [
      for (final (x, y) in poly) img.Point(x, y),
    ],
    color: color,
  );

  for (final point in [from, to]) {
    img.fillCircle(
      image,
      x: point.$1,
      y: point.$2,
      radius: (width / 2).round(),
      color: color,
    );
  }
}
