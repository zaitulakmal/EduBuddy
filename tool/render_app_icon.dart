// Renders the Buddy mascot straight out of lib/widgets/buddy_mascot.dart into
// a transparent 1024 PNG, so the launcher icon is the exact same character the
// app draws rather than a redrawn copy that can drift.
//
//   flutter test tool/render_app_icon.dart
//
// Writes assets/icon/app_icon_foreground.png. The opaque app_icon.png is
// composited from it (see tool/compose_app_icon.py), then:
//
//   dart run flutter_launcher_icons

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubuddy/widgets/buddy_mascot.dart';

/// Launcher assets are authored at 1024 and downscaled per platform.
const double _canvas = 1024;

/// Matches the 69% the previous owl foreground occupied, which is what keeps
/// the mark inside the Android adaptive mask instead of being cropped.
const double _markScale = 0.72;

void main() {
  testWidgets('render launcher mark', (tester) async {
    await tester.binding.setSurfaceSize(const Size(_canvas, _canvas));

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: SizedBox(
          width: _canvas,
          height: _canvas,
          // A single still frame: no wave, and idle sits at zero on the first
          // pump, so the pose is symmetric and reads at 32x32.
          child: Center(
            child: BuddyMascot(
              size: _canvas * _markScale,
              // Same Buddy the splash paints, so the launcher icon and the
              // first screen are one identity rather than two.
              animation: BuddyAnim.idle,
              bodyColor: const Color(0xFFE8453C),
              cheekColor: const Color(0xFFFFB3AD),
              antennaColor: const Color(0xFF23348C),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    // PNG encoding is real async work on the engine, so it has to run outside
    // the fake-async zone or the future never completes and the run hangs.
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('assets/icon/app_icon_foreground.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });

    // Tear the mascot down before the test ends: its controller repeats, and a
    // live ticker keeps the binding from finishing.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });
}
