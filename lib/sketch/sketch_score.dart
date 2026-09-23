import 'dart:ui';

import 'pencil.dart';
import 'sketch_data.dart';

// Port of SketchStep's score.ts.

class StepTargets {
  final StepKind kind;
  final List<Offset> pts;
  StepTargets(this.kind, this.pts);
}

StepTargets stepTargets(SketchStep step) {
  if (step.kind == StepKind.line) {
    // Exported polylines are sampled every 2 units; the web version scores every 4.
    return StepTargets(StepKind.line, [
      for (final shape in step.shapes)
        for (final part in shape.parts)
          for (var i = 0; i < part.length; i += 2) part[i],
    ]);
  }
  const gap = 7.0;
  final pts = <Offset>[];
  for (final shape in step.shapes) {
    final area = shape.path;
    for (var y = 0.0; y < kSketchSpace; y += gap) {
      for (var x = 0.0; x < kSketchSpace; x += gap) {
        if (area.contains(Offset(x, y))) pts.add(Offset(x, y));
      }
    }
  }
  return StepTargets(StepKind.shade, pts);
}

// Fill in gaps between pointer events so fast strokes still count.
List<Offset> _densify(Iterable<PencilStroke> strokes) {
  final out = <Offset>[];
  for (final s in strokes) {
    if (s.tool == PencilTool.eraser) continue;
    for (var i = 0; i < s.pts.length; i++) {
      final b = s.pts[i];
      if (i > 0) {
        final a = s.pts[i - 1];
        final n = ((Offset(b.x, b.y) - Offset(a.x, a.y)).distance / 3).floor();
        for (var j = 1; j < n; j++) {
          out.add(Offset(a.x + (b.x - a.x) * j / n, a.y + (b.y - a.y) * j / n));
        }
      }
      out.add(Offset(b.x, b.y));
    }
  }
  return out;
}

double _share(List<Offset> of, List<Offset> near, double r) {
  if (of.isEmpty) return 0;
  final r2 = r * r;
  var hit = 0;
  for (final a in of) {
    for (final b in near) {
      final dx = a.dx - b.dx;
      final dy = a.dy - b.dy;
      if (dx * dx + dy * dy <= r2) {
        hit++;
        break;
      }
    }
  }
  return hit / of.length;
}

/// 0–100. Lines: mostly "did you cover the guide", a little "did you stay on it".
/// Shading: how much of the area got graphite.
int scoreStep(StepTargets target, Iterable<PencilStroke> strokes, List<Offset> guidesSoFar) {
  final user = _densify(strokes);
  if (user.isEmpty) return 0;
  if (target.kind == StepKind.shade) {
    final v = _share(target.pts, user, 9) * 1.25;
    return (100 * (v > 1 ? 1 : v)).round();
  }
  final coverage = _share(target.pts, user, 14);
  final precision = _share(user, guidesSoFar, 18);
  return (100 * (0.7 * coverage + 0.3 * precision)).round();
}

int starsFor(int score) => score >= 80 ? 3 : score >= 55 ? 2 : score > 0 ? 1 : 0;
