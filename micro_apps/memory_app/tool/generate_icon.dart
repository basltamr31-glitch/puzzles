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
// The mark is two cards — one face down and tilted, one face up in front
// carrying the same gold star the real card backs use. Not a grid of
// cards, whose gaps close up at 48dp on a launcher, and not an emoji,
// which would render as a different picture on every Android version.

import 'dart:io';

import 'package:image/image.dart' as img;

const int _size = 1024;

/// Adaptive icons crop to a circle of ~66% of the layer, and Android may
/// mask more aggressively still; the glyph is sized to sit inside that.
const double _foregroundGlyphFraction = 0.52;
const double _iconGlyphFraction = 0.68;

final _roseTop = img.ColorRgb8(0xD3, 0x1B, 0x4A);
final _roseBottom = img.ColorRgb8(0x8E, 0x0E, 0x2D);
final _white = img.ColorRgba8(0xFF, 0xFF, 0xFF, 0xFF);
final _gold = img.ColorRgba8(0xF6, 0xCE, 0x55, 0xFF);
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
      _lerp(_roseTop.r, _roseBottom.r, t),
      _lerp(_roseTop.g, _roseBottom.g, t),
      _lerp(_roseTop.b, _roseBottom.b, t),
      255,
    );
    img.drawLine(image, x1: 0, y1: y, x2: _size - 1, y2: y, color: color);
  }
  return image;
}

int _lerp(num a, num b, double t) => (a + (b - a) * t).round();

/// Two cards, the back one tilted behind the front one.
///
/// Built in its own transparent layer and composited in one go. The gap
/// between the two cards is *punched* out of that layer rather than
/// painted in the background colour, so the same code produces a correct
/// opaque icon and a correct transparent adaptive-icon foreground.
void _drawMark(img.Image image, double glyphSize) {
  final cardWidth = (glyphSize * 0.56).round();
  final cardHeight = (glyphSize * 0.82).round();
  final radius = (cardWidth * 0.17).round();
  final centerX = _size ~/ 2;
  final centerY = _size ~/ 2;
  final frontX = centerX + (cardWidth * 0.26).round();

  final layer = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(layer, color: _transparent);

  // The back card, tilted and peeking out to the left. Drawn on its own
  // canvas and rotated, because the `image` package can fill a rounded
  // rectangle or rotate a whole image but cannot draw a rotated rounded
  // rectangle directly.
  final tilted = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(tilted, color: _transparent);
  _roundedCard(
    tilted,
    centerX: centerX,
    centerY: centerY,
    width: cardWidth,
    height: cardHeight,
    radius: radius,
    fill: _white,
  );
  final rotated = img.copyRotate(tilted, angle: -15);
  // copyRotate grows the canvas to fit the rotated content, so the offset
  // is measured from the centre of the *result*, not of the original.
  img.compositeImage(
    layer,
    rotated,
    dstX: -(rotated.width - _size) ~/ 2 - (cardWidth * 0.34).round(),
    dstY: -(rotated.height - _size) ~/ 2,
  );

  // A gap around the front card so the two read as two cards rather than
  // one wide blob at launcher size.
  _punchRoundedRect(
    layer,
    centerX: frontX,
    centerY: centerY,
    width: (cardWidth * 1.14).round(),
    height: (cardHeight * 1.10).round(),
    radius: (radius * 1.3).round(),
  );

  _roundedCard(
    layer,
    centerX: frontX,
    centerY: centerY,
    width: cardWidth,
    height: cardHeight,
    radius: radius,
    fill: _white,
  );
  _star(layer, centerX: frontX, centerY: centerY, radius: cardWidth * 0.30);

  img.compositeImage(image, layer);
}

void _roundedCard(
  img.Image image, {
  required int centerX,
  required int centerY,
  required int width,
  required int height,
  required int radius,
  required img.Color fill,
}) {
  final x1 = centerX - width ~/ 2;
  final y1 = centerY - height ~/ 2;
  img.fillRect(
    image,
    x1: x1,
    y1: y1,
    x2: x1 + width,
    y2: y1 + height,
    radius: radius,
    color: fill,
  );
}

/// Clears a rounded rectangle to fully transparent.
///
/// Pixels are *set*, not composited: filling with a transparent colour
/// blends nothing and leaves the card underneath untouched, which is the
/// bug that first shipped this icon as a white square.
void _punchRoundedRect(
  img.Image image, {
  required int centerX,
  required int centerY,
  required int width,
  required int height,
  required int radius,
}) {
  final left = centerX - width / 2;
  final top = centerY - height / 2;
  final right = left + width;
  final bottom = top + height;

  for (var y = top.floor(); y < bottom.ceil(); y++) {
    for (var x = left.floor(); x < right.ceil(); x++) {
      if (x < 0 || y < 0 || x >= _size || y >= _size) continue;
      if (!_insideRoundedRect(
        x.toDouble(),
        y.toDouble(),
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        radius: radius.toDouble(),
      )) {
        continue;
      }
      image.setPixel(x, y, _transparent);
    }
  }
}

bool _insideRoundedRect(
  double x,
  double y, {
  required double left,
  required double top,
  required double right,
  required double bottom,
  required double radius,
}) {
  if (x < left || x > right || y < top || y > bottom) return false;
  final cornerX = x < left + radius
      ? left + radius
      : (x > right - radius ? right - radius : x);
  final cornerY = y < top + radius
      ? top + radius
      : (y > bottom - radius ? bottom - radius : y);
  final dx = x - cornerX;
  final dy = y - cornerY;
  return dx * dx + dy * dy <= radius * radius;
}

/// The same four-point star the card backs carry in the app, so the icon
/// and the board are recognisably the same product.
void _star(
  img.Image image, {
  required int centerX,
  required int centerY,
  required double radius,
}) {
  final points = <int>[];
  for (var i = 0; i < 8; i++) {
    final r = i.isEven ? radius : radius * 0.30;
    final angle = (3.14159265 / 4) * i - 3.14159265 / 2;
    points
      ..add((centerX + _cos(angle) * r).round())
      ..add((centerY + _sin(angle) * r).round());
  }
  img.fillPolygon(
    image,
    vertices: [
      for (var i = 0; i < points.length; i += 2)
        img.Point(points[i], points[i + 1]),
    ],
    color: _gold,
  );
}

// dart:math would do, but the icon tool deliberately imports as little as
// possible so it keeps running under a bare `dart run`.
double _cos(double a) => _sin(a + 3.14159265 / 2);

double _sin(double a) {
  // Taylor series about 0, reduced into [-pi, pi] first — plenty for the
  // eight fixed angles this file asks for.
  const pi = 3.14159265358979;
  var x = a % (2 * pi);
  if (x > pi) x -= 2 * pi;
  if (x < -pi) x += 2 * pi;
  final x2 = x * x;
  return x *
      (1 - x2 / 6 * (1 - x2 / 20 * (1 - x2 / 42 * (1 - x2 / 72))));
}
