import 'dart:io';
import 'dart:math' as math;

// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as img;

import 'package:gymmane/app/own_build.dart';

const _sourcePath = 'assets/brand/enogym_pine_source.png';
final _metadata = <String, String>{
  'Title': 'EnoGym - Pine and Cream Runner',
  'Source':
      'GymMane by InlitX; option 04 approved by Enoch on 2026-11-13; foreground refined with built-in image generation',
  'PromptFile': 'assets/brand/enogym_pine_source.prompt.txt',
  'Software':
      'EnoGym scripts/generate_brand_assets.dart; alpha cleanup, palette normalization, layout and resampling',
};

img.ColorRgba8 _color(int argb) => img.ColorRgba8((argb >> 16) & 255, (argb >> 8) & 255, argb & 255, 255);

void _write(String path, img.Image image) {
  image.textData = {...?image.textData, ..._metadata};
  File(path).writeAsBytesSync(img.encodePng(image));
}

img.Image _resize(img.Image image, int size) =>
    img.copyResize(image, width: size, height: size, interpolation: img.Interpolation.average);

img.Image _canvas(int size) => img.Image(width: size, height: size, numChannels: 4);

img.Image _place(img.Image mark, int size, double heightFraction, {bool solid = false}) {
  final canvas = _canvas(size);
  if (solid) img.fill(canvas, color: _color(ownBrandBackground));
  final height = (size * heightFraction).round();
  final figure = img.copyResize(mark, height: height, interpolation: img.Interpolation.average);
  img.compositeImage(
    canvas,
    figure,
    blend: solid ? img.BlendMode.alpha : img.BlendMode.direct,
    dstX: ((size - figure.width) / 2).round(),
    dstY: ((size - height) / 2).round(),
  );
  return canvas;
}

img.Image _round(img.Image source) =>
    img.copyCrop(source, x: 0, y: 0, width: source.width, height: source.height, radius: source.width * 0.24);

void main(List<String> args) {
  if (args.contains('--stamp-platforms') || args.contains('--stamp-android')) {
    // flutter_launcher_icons also rewrites service icons. Preserve the
    // complication's functional glyph instead of turning it into a launcher.
    final manifest = File('android/app/src/main/AndroidManifest.xml');
    manifest.writeAsStringSync(
      manifest.readAsStringSync().replaceAllMapped(
        RegExp(r'(<service\s+android:name="\.GymComplicationService"[^>]*android:icon=")[^"]+("\s)'),
        (match) => '${match[1]}@drawable/ic_complication${match[2]}',
      ),
    );
    for (final directory in ['android/app/src/main/res', 'ios/Runner/Assets.xcassets/AppIcon.appiconset']) {
      for (final file in Directory(directory).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.png')) continue;
        if (directory.startsWith('android') && !file.path.contains('ic_launcher')) continue;
        _write(file.path, img.decodePng(file.readAsBytesSync())!);
      }
    }
    return;
  }

  final source = img.decodePng(File(_sourcePath).readAsBytesSync())!;
  var left = source.width, top = source.height, right = 0, bottom = 0;
  final cream = _color(ownBrandForeground);
  for (final p in source) {
    // Remove near-invisible matte residue without reshaping the generated
    // contour. Keep antialiased edges and use one consistent brand fill.
    final alpha = p.a < 8
        ? 0
        : p.a >= 245
        ? 255
        : p.a.toInt();
    p.setRgba(cream.r, cream.g, cream.b, alpha);
    if (alpha < 32) continue;
    left = math.min(left, p.x);
    top = math.min(top, p.y);
    right = math.max(right, p.x);
    bottom = math.max(bottom, p.y);
  }
  if (right <= left || bottom <= top) throw StateError('Brand source has no visible silhouette.');
  // Leave a tiny gutter so antialiasing is not cut at the extrema.
  left = math.max(0, left - 2);
  top = math.max(0, top - 2);
  right = math.min(source.width - 1, right + 2);
  bottom = math.min(source.height - 1, bottom + 2);
  final mark = img.copyCrop(source, x: left, y: top, width: right - left + 1, height: bottom - top + 1);
  _write(ownBrandMark, img.copyResize(mark, height: 512, interpolation: img.Interpolation.average));

  // Android's 16% foreground inset maps this into the adaptive viewport.
  // PWA maskable icons need a separate, more generous safe area.
  final foreground = _place(mark, 1024, 0.76);
  final square = _place(mark, 1024, 0.76, solid: true);
  final rounded = _round(square);
  _write('assets/brand/enogym_foreground.png', foreground);
  _write('assets/brand/enogym_square.png', square);
  _write('assets/brand/enogym_legacy.png', rounded);
  _write(ownBrandIcon, _resize(rounded, 512));
  _write('assets/img/app_icon.png', _resize(rounded, 192));

  final monochrome = foreground.clone();
  for (final p in monochrome) {
    p.setRgba(255, 255, 255, p.a);
  }
  _write('assets/brand/enogym_monochrome.png', monochrome);

  final whiteMark = mark.clone();
  for (final p in whiteMark) {
    p.setRgba(255, 255, 255, p.a);
  }
  for (final (density, size) in [
    ('mdpi', 24),
    ('hdpi', 36),
    ('xhdpi', 48),
    ('xxhdpi', 72),
    ('xxxhdpi', 96),
  ]) {
    _write(
      'android/app/src/main/res/drawable-$density/ic_stat_gymmane.png',
      _place(whiteMark, size, 20 / 24),
    );
  }
  for (final size in [192, 512]) {
    _write('web/icons/Icon-$size.png', _resize(rounded, size));
    _write('web/icons/Icon-maskable-$size.png', _resize(_place(mark, 1024, 0.66, solid: true), size));
  }
  _write('web/icons/apple-touch-icon.png', _resize(square, 180));
  _write('web/favicon.png', _resize(rounded, 32));
  for (final (scale, size) in [(2, 80), (3, 120)]) {
    _write(
      'ios/GymManeWidgets/Assets.xcassets/LiveIcon.imageset/LiveIcon@${scale}x.png',
      _resize(rounded, size),
    );
  }
  stdout.writeln('Generated pine-and-cream brand, notification, Web and Live Activity assets.');
}
