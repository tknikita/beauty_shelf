// Generates launcher icon assets from assets/icon/source.png:
//   - assets/icon/app_icon.png            (legacy / fallback square icon)
//   - assets/icon/app_icon_foreground.png (adaptive icon foreground layer)
//
// Run:  dart run tool/generate_icons.dart
// Then: dart run flutter_launcher_icons
//
// The script removes the "Полочка" caption by filling the text rows with the
// surrounding background colour, keeping the product artwork intact.
import 'dart:io';

import 'package:image/image.dart' as img;

const _sourcePath = 'assets/icon/source.png';
const _legacyPath = 'assets/icon/app_icon.png';
const _foregroundPath = 'assets/icon/app_icon_foreground.png';

// Text detection region (below the shelf) and darkness threshold.
const _scanTop = 505;
const _darkThreshold = 160; // luminance below this = text pixel
const _fillMargin = 8;

void main() {
  final src = img.decodeImage(File(_sourcePath).readAsBytesSync());
  if (src == null) {
    stderr.writeln('Cannot decode $_sourcePath');
    exit(1);
  }

  _removeCaption(src);

  // Legacy icon: content fills most of the square (no mask applied).
  final legacy = _square(src, cx: 645, cy: 340, side: 620, out: 1024);
  File(_legacyPath).writeAsBytesSync(img.encodePng(legacy));

  // Adaptive foreground: full-height square, content kept in the safe zone.
  final foreground = _square(src, cx: 640, cy: 356, side: 713, out: 1024);
  File(_foregroundPath).writeAsBytesSync(img.encodePng(foreground));

  // Background colour (top-left area) for adaptive background layer.
  final bg = src.getPixel(8, 8);
  final hex = '${_hex(bg.r)}${_hex(bg.g)}${_hex(bg.b)}';
  stdout.writeln('Wrote $_legacyPath (${legacy.width}x${legacy.height})');
  stdout.writeln(
      'Wrote $_foregroundPath (${foreground.width}x${foreground.height})');
  stdout.writeln('Suggested adaptive_icon_background: #$hex');
}

/// Fill the caption rows with the surrounding background colour.
void _removeCaption(img.Image im) {
  int minX = im.width, maxX = 0, minY = im.height, maxY = 0;
  for (var y = _scanTop; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      final p = im.getPixel(x, y);
      final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      if (lum < _darkThreshold) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < minX) {
    stdout.writeln('No caption detected; nothing to remove.');
    return;
  }

  final x0 = (minX - _fillMargin).clamp(0, im.width - 1);
  final x1 = (maxX + _fillMargin).clamp(0, im.width - 1);
  final y0 = (minY - _fillMargin).clamp(0, im.height - 1);
  final y1 = (maxY + _fillMargin).clamp(0, im.height - 1);
  final sampleX = (x0 - 12).clamp(0, im.width - 1);

  for (var y = y0; y <= y1; y++) {
    final bg = im.getPixel(sampleX, y);
    for (var x = x0; x <= x1; x++) {
      im.setPixelRgb(x, y, bg.r, bg.g, bg.b);
    }
  }
  stdout.writeln(
      'Removed caption bbox x[$minX..$maxX] y[$minY..$maxY] -> filled x[$x0..$x1] y[$y0..$y1]');
}

/// Crop a centered square and resize it to [out] x [out].
img.Image _square(img.Image im, {
  required int cx,
  required int cy,
  required int side,
  required int out,
}) {
  var x = cx - side ~/ 2;
  var y = cy - side ~/ 2;
  x = x.clamp(0, im.width - side).toInt();
  y = y.clamp(0, im.height - side).toInt();
  final crop = img.copyCrop(im, x: x, y: y, width: side, height: side);
  return img.copyResize(crop,
      width: out, height: out, interpolation: img.Interpolation.cubic);
}

String _hex(num v) => v.toInt().clamp(0, 255).toRadixString(16).padLeft(2, '0');
