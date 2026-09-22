import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'sketch_data.dart';

// Port of SketchStep's pencil.ts: strokes are kept in lesson space (400×400)
// so they can be replayed at any size, for thumbnails and the PNG export.

enum PencilTool { hb, b2, b6, eraser }

class PencilPoint {
  final double x, y, p;
  const PencilPoint(this.x, this.y, this.p);
}

class PencilStroke {
  final PencilTool tool;
  final int step;
  final List<PencilPoint> pts;
  PencilStroke(this.tool, this.step, this.pts);

  Map<String, dynamic> toJson() => {
        't': tool.index,
        's': step,
        // x, y, pressure ×10 as integers keeps drafts small.
        'p': [for (final q in pts) ...[(q.x * 10).round(), (q.y * 10).round(), (q.p * 100).round()]],
      };

  factory PencilStroke.fromJson(Map<String, dynamic> j) {
    final raw = (j['p'] as List).cast<int>();
    return PencilStroke(PencilTool.values[j['t'] as int], j['s'] as int, [
      for (var i = 0; i + 2 < raw.length; i += 3) PencilPoint(raw[i] / 10, raw[i + 1] / 10, raw[i + 2] / 100),
    ]);
  }
}

const paperColor = Color(0xFFF4F1DE);
const graphite = Color(0xFF2E2A3A);

class _ToolSpec {
  final double width, alpha;
  const _ToolSpec(this.width, this.alpha);
}

const _specs = {
  PencilTool.hb: _ToolSpec(1.5, 0.5),
  PencilTool.b2: _ToolSpec(2.6, 0.72),
  PencilTool.b6: _ToolSpec(5, 0.95),
  PencilTool.eraser: _ToolSpec(16, 1),
};

/// Graphite on toothy paper: every pixel of the texture has its own opacity,
/// so overlapping strokes build up darker the way a real pencil does.
class PencilTexture {
  static final Map<PencilTool, ui.Image> _grain = {};
  static Future<void>? _loading;

  static Future<void> ensure() => _loading ??= _build();

  static bool get ready => _grain.length == 3;

  static Future<void> _build() async {
    const size = 128;
    final rand = math.Random(42);
    final base = List.generate(size * size, (_) => 0.25 + 0.75 * math.pow(rand.nextDouble(), 0.7));
    for (final tool in [PencilTool.hb, PencilTool.b2, PencilTool.b6]) {
      final alpha = _specs[tool]!.alpha;
      final px = Uint8List(size * size * 4);
      for (var i = 0; i < size * size; i++) {
        px[i * 4] = 46;
        px[i * 4 + 1] = 42;
        px[i * 4 + 2] = 58;
        px[i * 4 + 3] = (255 * base[i] * alpha).round();
      }
      final c = Completer<ui.Image>();
      ui.decodeImageFromPixels(px, size, size, ui.PixelFormat.rgba8888, c.complete);
      _grain[tool] = await c.future;
    }
  }

  static ui.Image? of(PencilTool tool) => _grain[tool];
}

class PencilPainter {
  /// `unitPx` is how many logical pixels one lesson unit covers; the grain stays at ~1 logical px.
  PencilPainter(double unitPx)
      : _grainMatrix = Float64List.fromList([1 / unitPx, 0, 0, 0, 0, 1 / unitPx, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

  final Float64List _grainMatrix;
  final Map<PencilTool, Paint> _paints = {};

  Paint _paint(PencilTool tool) => _paints[tool] ??= () {
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        if (tool == PencilTool.eraser) {
          p.blendMode = BlendMode.clear;
        } else {
          final grain = PencilTexture.of(tool);
          if (grain != null) {
            p.shader = ImageShader(grain, TileMode.repeated, TileMode.repeated, _grainMatrix);
          } else {
            p.color = graphite.withValues(alpha: _specs[tool]!.alpha);
          }
        }
        return p;
      }();

  Paint _brush(PencilTool tool, double pressure) {
    final spec = _specs[tool]!;
    return _paint(tool)..strokeWidth = tool == PencilTool.eraser ? spec.width : spec.width * (0.55 + 0.9 * pressure);
  }

  static Offset _mid(PencilPoint a, PencilPoint b) => Offset((a.x + b.x) / 2, (a.y + b.y) / 2);

  /// The piece of the stroke that ends at point i, smoothed through midpoints.
  void segment(Canvas c, PencilStroke s, int i) {
    if (i < 1) return;
    final a = s.pts[i - 1];
    final path = Path();
    if (i == 1) {
      path.moveTo(a.x, a.y);
      final m = _mid(a, s.pts[1]);
      path.lineTo(m.dx, m.dy);
    } else {
      final m0 = _mid(s.pts[i - 2], a);
      final m1 = _mid(a, s.pts[i]);
      path.moveTo(m0.dx, m0.dy);
      path.quadraticBezierTo(a.x, a.y, m1.dx, m1.dy);
    }
    c.drawPath(path, _brush(s.tool, a.p));
  }

  void end(Canvas c, PencilStroke s) {
    final last = s.pts.last;
    final path = Path();
    if (s.pts.length == 1) {
      path.moveTo(last.x, last.y);
      path.lineTo(last.x + 0.01, last.y);
    } else {
      final m = _mid(s.pts[s.pts.length - 2], last);
      path.moveTo(m.dx, m.dy);
      path.lineTo(last.x, last.y);
    }
    c.drawPath(path, _brush(s.tool, last.p));
  }

  void stroke(Canvas c, PencilStroke s) {
    for (var i = 1; i < s.pts.length; i++) {
      segment(c, s, i);
    }
    end(c, s);
  }

  /// Strokes go on their own layer so the eraser only removes graphite, not the paper.
  void all(Canvas c, Iterable<PencilStroke> strokes, {PencilStroke? live}) {
    c.saveLayer(const Rect.fromLTWH(0, 0, kSketchSpace, kSketchSpace), Paint());
    for (final s in strokes) {
      stroke(c, s);
    }
    if (live != null) stroke(c, live);
    c.restore();
  }
}

/// Rasterises committed strokes once, so live drawing only repaints the new stroke.
ui.Image renderStrokes(List<PencilStroke> strokes, double sizePx, double unitPx) {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.scale(sizePx / kSketchSpace);
  PencilPainter(unitPx).all(c, strokes);
  final px = sizePx.round();
  return rec.endRecording().toImageSync(px, px);
}

/// Flattens the drawing onto paper as a PNG.
Future<Uint8List> exportPng(List<PencilStroke> strokes, {int size = 1200}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), Paint()..color = paperColor);
  c.scale(size / kSketchSpace);
  PencilPainter(size / kSketchSpace / 2).all(c, strokes);
  final img = await rec.endRecording().toImage(size, size);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return data!.buffer.asUint8List();
}
