import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:edubuddy/widgets/owl_mark.dart';

/// Renders a contact sheet showing the icon the way launchers present it:
/// square, circle-masked, squircle-masked, and at real small sizes.
///
///   flutter test test/icon_preview_test.dart

void _drawIcon(ui.Canvas canvas, ui.Rect box, {ui.Path? clip}) {
  canvas.save();
  if (clip != null) canvas.clipPath(clip);
  canvas.translate(box.left, box.top);
  const painter = OwlIconPainter();
  painter.paint(canvas, ui.Size(box.width, box.height));
  canvas.restore();
}

/// What Android 8+ actually composites: the flat background colour, then the
/// foreground scaled into the 66dp safe zone, then the launcher's mask.
void _drawAdaptive(ui.Canvas canvas, ui.Rect box, ui.Path clip) {
  canvas.save();
  canvas.clipPath(clip);
  canvas.drawRect(box, ui.Paint()..color = OwlIconPainter.ground);
  const scale = 0.88;
  final inset = box.width * (1 - scale) / 2;
  canvas.translate(box.left + inset, box.top + inset);
  canvas.scale(scale, scale);
  const OwlIconPainter(drawBackground: false, cropBody: false)
      .paint(canvas, ui.Size(box.width, box.height));
  canvas.restore();
}

void main() {
  test('renders the launcher preview sheet', () async {
    const w = 1200.0;
    const h = 520.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Neutral sheet background so masked edges are visible.
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, w, h),
      ui.Paint()..color = const ui.Color(0xFFF2F2F2),
    );

    const big = 240.0;
    const y = 90.0;

    // 1. Full square (iOS / legacy Android). Clipped to the box, since the
    // body deliberately runs off the bottom of the exported canvas.
    final square = ui.Path()
      ..addRect(const ui.Rect.fromLTWH(70, y, big, big));
    _drawIcon(canvas, const ui.Rect.fromLTWH(70, y, big, big), clip: square);

    // 2. Adaptive under a circle mask (Pixel launcher) — what ships on
    // Android 8+.
    const circleBox = ui.Rect.fromLTWH(390, y, big, big);
    _drawAdaptive(canvas, circleBox, ui.Path()..addOval(circleBox));

    // 3. Adaptive under a squircle mask (Samsung / One UI).
    const squircleBox = ui.Rect.fromLTWH(710, y, big, big);
    _drawAdaptive(
      canvas,
      squircleBox,
      ui.Path()
        ..addRRect(ui.RRect.fromRectAndRadius(
          squircleBox,
          const ui.Radius.circular(62),
        )),
    );

    // 4. Real small sizes, adaptive + circle-masked.
    const sizes = <double>[96, 64, 48, 32];
    const x = 1010.0;
    var sy = y;
    for (final s in sizes) {
      final box = ui.Rect.fromLTWH(x, sy, s, s);
      _drawAdaptive(canvas, box, ui.Path()..addOval(box));
      sy += s + 14;
    }

    final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('assets/icon/preview_sheet.png')
        .writeAsBytesSync(data!.buffer.asUint8List());

    expect(File('assets/icon/preview_sheet.png').lengthSync(), greaterThan(0));
  });
}
