import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'pencil.dart';
import 'sketch_data.dart';

const sketchViolet = Color(0xFF7700FA);

void _drawPolylines(Canvas c, SketchShape shape, Paint paint) => c.drawPath(shape.path, paint);

// Parallel lines at -35°, clipped to the shape: the look of pencil hatching.
void _hatch(Canvas c, Path area, double gap, Paint paint, {bool cross = false}) {
  c.save();
  c.clipPath(area);
  final b = area.getBounds();
  final r = math.sqrt(b.width * b.width + b.height * b.height) / 2 + gap;
  final center = b.center;
  void lines(double deg) {
    final a = deg * math.pi / 180;
    final dx = math.cos(a), dy = math.sin(a);
    for (var off = -r; off <= r; off += gap) {
      final ox = -dy * off, oy = dx * off;
      c.drawLine(center + Offset(ox - dx * r, oy - dy * r), center + Offset(ox + dx * r, oy + dy * r), paint);
    }
  }

  lines(55); // -35° from vertical
  if (cross) lines(-35);
  c.restore();
}

class _Tone {
  final double gap, width, opacity;
  final bool cross;
  const _Tone(this.gap, this.width, this.opacity, this.cross);
}

const _tones = {
  1: _Tone(5, 1.6, 0.28, false),
  2: _Tone(4, 2, 0.5, false),
  3: _Tone(3, 2.2, 0.8, true),
};

/// The finished drawing, as shown on lesson cards and the "what you are drawing" preview.
class SketchPreviewPainter extends CustomPainter {
  final SketchLesson lesson;
  SketchPreviewPainter(this.lesson);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / kSketchSpace, size.height / kSketchSpace);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = graphite.withValues(alpha: 0.9)
      ..strokeWidth = 2.3;
    for (final step in lesson.steps) {
      if (step.kind == StepKind.shade) {
        final tone = _tones[step.tone ?? 2]!;
        final p = Paint()
          ..color = graphite.withValues(alpha: tone.opacity)
          ..strokeWidth = tone.width;
        for (final shape in step.shapes) {
          _hatch(canvas, shape.path, tone.gap, p, cross: tone.cross);
        }
        continue;
      }
      final p = Paint.from(line);
      if (step.weight == 'guide') {
        p
          ..strokeWidth = 1.2
          ..color = graphite.withValues(alpha: 0.22);
      } else if (step.weight == 'fine') {
        p
          ..strokeWidth = 1.3
          ..color = graphite.withValues(alpha: 0.8);
      }
      for (final shape in step.shapes) {
        _drawPolylines(canvas, shape, p);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SketchPreviewPainter old) => old.lesson != lesson;
}

/// Guides over the paper: earlier steps faint, the current step in violet.
/// `progress` animates the current lines drawing themselves in.
class GuidePainter extends CustomPainter {
  final SketchLesson lesson;
  final int step;
  final double progress;
  final bool visible;

  GuidePainter({required this.lesson, required this.step, required this.progress, required this.visible});

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    canvas.save();
    canvas.scale(size.width / kSketchSpace, size.height / kSketchSpace);

    final prev = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4
      ..color = const Color(0xFFB8ACDC).withValues(alpha: 0.55);
    for (final s in lesson.steps.take(step)) {
      if (s.kind == StepKind.shade) continue;
      for (final shape in s.shapes) {
        canvas.drawPath(shape.path, prev);
      }
    }

    final current = lesson.steps[step];
    if (current.kind == StepKind.shade) {
      final hatch = Paint()
        ..color = sketchViolet.withValues(alpha: 0.28)
        ..strokeWidth = 3;
      final edge = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = sketchViolet.withValues(alpha: 0.6);
      for (final shape in current.shapes) {
        _hatch(canvas, shape.path, 8, hatch);
        _dashed(canvas, shape.path, edge);
      }
    } else {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 4
        ..color = sketchViolet.withValues(alpha: 0.45);
      final many = current.shapes.length > 8; // texture steps appear together
      for (var i = 0; i < current.shapes.length; i++) {
        final start = many ? 0.0 : (i * 0.25).clamp(0.0, 0.6);
        final t = ((progress - start) / (1 - start)).clamp(0.0, 1.0);
        _partial(canvas, current.shapes[i].path, t, paint);
      }
    }
    canvas.restore();
  }

  void _partial(Canvas c, Path path, double t, Paint paint) {
    if (t >= 1) {
      c.drawPath(path, paint);
      return;
    }
    if (t <= 0) return;
    for (final m in path.computeMetrics()) {
      c.drawPath(m.extractPath(0, m.length * t), paint);
    }
  }

  void _dashed(Canvas c, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        c.drawPath(m.extractPath(d, math.min(d + 6, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(GuidePainter old) =>
      old.step != step || old.progress != progress || old.visible != visible || old.lesson != lesson;
}
