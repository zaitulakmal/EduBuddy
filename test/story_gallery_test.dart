import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edubuddy/models/story_library.dart';
import 'package:edubuddy/widgets/story_stage.dart';

/// Renders every library page as a contact sheet, with the reader's dark text
/// band painted over the bottom so hidden actors are easy to spot.
///
///   flutter test test/story_gallery_test.dart
///
/// Sheets land in build/story_gallery/.
void main() {
  for (final story in kStoryLibrary) {
    test('story sheet: ${story.key}', () async {
      const pw = 240.0, ph = 340.0, gap = 8.0, cols = 5;
      final rows = (story.pages.length / cols).ceil();
      final w = cols * (pw + gap) + gap;
      final h = rows * (ph + gap) + gap;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF222222));

      for (var i = 0; i < story.pages.length; i++) {
        final x = gap + (i % cols) * (pw + gap);
        final y = gap + (i ~/ cols) * (ph + gap);
        canvas.save();
        canvas.translate(x, y);
        StoryStagePainter(story.pages[i].shot, null, fixedT: 0.13).paint(canvas, const Size(pw, ph));
        // Approximate reader text band.
        final band = Rect.fromLTWH(0, ph * 0.74, pw, ph * 0.26);
        canvas.drawRect(
          band,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0xC0000000)],
            ).createShader(band),
        );
        canvas.restore();
      }

      final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/story_gallery/${story.key}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data!.buffer.asUint8List());
      expect(file.lengthSync(), greaterThan(0));
    });
  }
}
