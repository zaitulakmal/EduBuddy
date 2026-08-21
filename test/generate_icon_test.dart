import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import '../tool/icon/owl_icon_painter.dart';

/// Renders the launcher icon to PNG.
///
///   flutter test test/generate_icon_test.dart
///
/// Writes the full-bleed master used for iOS and legacy Android, a separate
/// adaptive foreground, and two small previews for eyeballing legibility.
/// flutter_launcher_icons then generates the per-density sizes.
Future<void> _render(
  String path,
  int px, {
  bool background = true,
  bool cropBody = true,
  double contentScale = 1.0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final side = px.toDouble();

  if (contentScale != 1.0) {
    // Shrink about the centre so the mark survives the adaptive-icon mask.
    final inset = side * (1 - contentScale) / 2;
    canvas.translate(inset, inset);
    canvas.scale(contentScale, contentScale);
  }

  OwlIconPainter(drawBackground: background, cropBody: cropBody)
      .paint(canvas, ui.Size(side, side));
  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  test('renders the launcher icon', () async {
    // Full bleed: iOS and legacy Android.
    await _render('assets/icon/app_icon.png', 1024);

    // Adaptive foreground. Android guarantees only the central 66dp of the
    // 108dp layer is visible, so the artwork is scaled into that safe zone
    // and the ground is left to adaptive_icon_background.
    await _render(
      'assets/icon/app_icon_foreground.png',
      1024,
      background: false,
      cropBody: false,
      contentScale: 0.88,
    );

    await _render('assets/icon/preview_96.png', 96);
    await _render('assets/icon/preview_32.png', 32);

    expect(File('assets/icon/app_icon.png').lengthSync(), greaterThan(0));
    expect(
      File('assets/icon/app_icon_foreground.png').lengthSync(),
      greaterThan(0),
    );
  });
}
