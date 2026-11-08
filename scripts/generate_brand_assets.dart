import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:image/image.dart' as img;

void main(List<String> args) {
  final source = img.decodePng(File('assets/brand/enogym_foreground.png').readAsBytesSync())!;
  final metadata = {
    ...?source.textData,
    'Software': 'EnoGym scripts/generate_brand_assets.dart; resize and composite only',
  };
  if (args.contains('--stamp-android')) {
    for (final file in Directory('android/app/src/main/res').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('/ic_launcher.png') && !file.path.endsWith('/ic_launcher_foreground.png')) {
        continue;
      }
      final icon = img.decodePng(file.readAsBytesSync())!..textData = metadata;
      file.writeAsBytesSync(img.encodePng(icon));
    }
    return;
  }
  final foreground = img.copyResize(
    source,
    width: 1024,
    height: 1024,
    interpolation: img.Interpolation.average,
  );
  final icon = img.Image(width: 1024, height: 1024, numChannels: 4, textData: metadata);
  img.fill(icon, color: img.ColorRgba8(12, 11, 10, 255));
  img.compositeImage(icon, foreground);
  File('assets/brand/enogym_legacy.png').writeAsBytesSync(img.encodePng(icon));
  File('assets/brand/enogym_icon.png').writeAsBytesSync(
    img.encodePng(img.copyResize(icon, width: 192, height: 192, interpolation: img.Interpolation.average)),
  );
}
