import 'package:flutter/material.dart';

import 'sketch_data.dart';
import 'sketch_painters.dart';

const _pencilYellow = Color(0xFFFFD220);
const _pencilEdge = Color(0xFFE0B400);
const _wood = Color(0xFFE8C9A0);

/// A sharpened pencil pointing down; the lead gets darker with the grade.
class PencilIcon extends StatelessWidget {
  final Color lead;
  const PencilIcon({super.key, required this.lead});

  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(14, 34), painter: _PencilPainter(lead));
}

class _PencilPainter extends CustomPainter {
  final Color lead;
  _PencilPainter(this.lead);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final body = h * 0.65;
    c.drawRect(Rect.fromLTWH(0, 0, w, body), Paint()..color = _pencilYellow);
    final edge = Paint()
      ..color = _pencilEdge
      ..strokeWidth = 1;
    c.drawLine(Offset(w / 3, 0), Offset(w / 3, body), edge);
    c.drawLine(Offset(w * 2 / 3, 0), Offset(w * 2 / 3, body), edge);
    c.drawPath(Path()..moveTo(0, body)..lineTo(w, body)..lineTo(w / 2, h)..close(), Paint()..color = _wood);
    final tip = body + (h - body) * 0.55;
    c.drawPath(
      Path()
        ..moveTo(w / 2 - w * 0.2, tip)
        ..lineTo(w / 2 + w * 0.2, tip)
        ..lineTo(w / 2, h)
        ..close(),
      Paint()..color = lead,
    );
  }

  @override
  bool shouldRepaint(_PencilPainter old) => old.lead != lead;
}

/// A two-tone block eraser, tilted.
class EraserIcon extends StatelessWidget {
  const EraserIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          width: 26,
          height: 12,
          child: Row(children: [
            Expanded(flex: 3, child: Container(color: const Color(0xFFFF8FA3))),
            Expanded(flex: 2, child: Container(color: const Color(0xFFC9C2D6))),
          ]),
        ),
      ),
    );
  }
}

class SketchStars extends StatelessWidget {
  final int count;
  final double size;
  final bool animate;
  final Color emptyColor;

  const SketchStars({super.key, required this.count, this.size = 18, this.animate = false, this.emptyColor = const Color(0x2E2D2D2D)});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count / 3',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            animate
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 450 + 300 + i * 180),
                    curve: Interval((300 + i * 180) / (750 + i * 180), 1, curve: Curves.easeOutBack),
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: _star(i),
                  )
                : _star(i),
        ],
      ),
    );
  }

  Widget _star(int i) => Icon(Icons.star_rounded, size: size, color: i < count ? _pencilYellow : emptyColor);
}

/// A lesson's finished drawing on a small sheet of paper.
class SketchThumb extends StatelessWidget {
  final SketchLesson lesson;
  final double radius;
  const SketchThumb({super.key, required this.lesson, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFF4F1DE), borderRadius: BorderRadius.circular(radius)),
        padding: const EdgeInsets.all(10),
        child: RepaintBoundary(child: CustomPaint(painter: SketchPreviewPainter(lesson))),
      ),
    );
  }
}
