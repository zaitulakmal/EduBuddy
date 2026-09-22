import 'dart:convert';

import 'package:edubuddy/sketch/pencil.dart';
import 'package:edubuddy/sketch/sketch_data.dart';
import 'package:edubuddy/sketch/sketch_score.dart';
import 'package:flutter_test/flutter_test.dart';

// Traces a step's guide exactly, the way a perfect student would.
List<PencilStroke> trace(SketchStep step, int index) => [
      for (final shape in step.shapes)
        for (final part in shape.parts)
          PencilStroke(PencilTool.b2, index, [for (var i = 0; i < part.length; i++) PencilPoint(part[i].dx, part[i].dy, 0.5)]),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SketchLibrary lib;
  setUpAll(() async => lib = await SketchLibrary.load());

  test('all 75 lessons load, 15 per path, every step has something to draw', () {
    expect(lib.paths.map((p) => p.id), ['animals', 'anime', 'characters', 'objects', 'nature']);
    for (final p in lib.paths) {
      expect(p.lessons.length, 15, reason: p.id);
    }
    for (final l in lib.lessons) {
      expect(l.steps, isNotEmpty, reason: l.id);
      for (final s in l.steps) {
        expect(s.shapes.expand((sh) => sh.parts).any((part) => part.length > 1), isTrue, reason: '${l.id} ${s.tip.en}');
      }
    }
  });

  test('tracing a line step exactly scores 100, a scribble elsewhere scores 0', () {
    final step = lib.lesson('apple')!.steps.first;
    final target = stepTargets(step);
    expect(scoreStep(target, trace(step, 0), target.pts), 100);

    final scribble = [PencilStroke(PencilTool.b2, 0, [for (var i = 0; i < 20; i++) PencilPoint(5 + i * 1.0, 395, 0.5)])];
    expect(scoreStep(target, scribble, target.pts), 0);
  });

  test('tracing half a line scores in between', () {
    final step = lib.lesson('cat')!.steps.first;
    final target = stepTargets(step);
    final part = step.shapes.first.parts.first;
    final half = [PencilStroke(PencilTool.b2, 0, [for (var i = 0; i < part.length ~/ 2; i++) PencilPoint(part[i].dx, part[i].dy, 0.5)])];
    final score = scoreStep(target, half, target.pts);
    expect(score, inInclusiveRange(40, 75));
  });

  test('shading fills count toward shade steps', () {
    final lesson = lib.lesson('apple')!;
    final i = lesson.steps.indexWhere((s) => s.kind == StepKind.shade);
    final target = stepTargets(lesson.steps[i]);
    expect(target.pts, isNotEmpty);
    // Zig-zag across every target point, like hatching.
    final strokes = [PencilStroke(PencilTool.b6, i, [for (final p in target.pts) PencilPoint(p.dx, p.dy, 0.8)])];
    expect(scoreStep(target, strokes, const []), 100);
  });

  test('eraser strokes never count as drawing', () {
    final step = lib.lesson('apple')!.steps.first;
    final target = stepTargets(step);
    final erased = [for (final s in trace(step, 0)) PencilStroke(PencilTool.eraser, 0, s.pts)];
    expect(scoreStep(target, erased, target.pts), 0);
  });

  test('strokes survive the draft round trip', () {
    final s = PencilStroke(PencilTool.b6, 3, const [PencilPoint(12.34, 56.78, 0.42), PencilPoint(100, 200.5, 1)]);
    final back = PencilStroke.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect(back.tool, PencilTool.b6);
    expect(back.step, 3);
    expect(back.pts.length, 2);
    expect(back.pts.first.x, closeTo(12.3, 0.05));
    expect(back.pts.first.y, closeTo(56.8, 0.05));
    expect(back.pts.first.p, closeTo(0.42, 0.005));
  });

  test('stars follow the web thresholds', () {
    expect([starsFor(0), starsFor(1), starsFor(55), starsFor(79), starsFor(80), starsFor(100)], [0, 1, 2, 2, 3, 3]);
  });
}
