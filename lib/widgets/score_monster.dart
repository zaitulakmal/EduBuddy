import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The one-eyed monster on the quiz score screen, with swappable colour,
/// body style and reaction. The defaults draw the original orange winged
/// grinning monster.
class ScoreMonster extends StatelessWidget {
  final double size;
  final ScoreMonsterColor color;
  final ScoreMonsterStyle style;
  final ScoreMonsterMood mood;

  const ScoreMonster({
    super.key,
    this.size = 80,
    this.color = ScoreMonsterColor.orange,
    this.style = ScoreMonsterStyle.winged,
    this.mood = ScoreMonsterMood.grin,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ScoreMonsterPainter(color: color, style: style, mood: mood),
      ),
    );
  }
}

enum ScoreMonsterColor { orange, teal, violet, pink, lime, sky, cherry, sunny }

enum ScoreMonsterStyle {
  winged, // round wings + one horn (original)
  bat, // pointed bat wings + one horn
  horned, // two horns, no wings
  furry, // fur tufts all round
  antenna, // bobbly antennae
  tentacle, // wiggly legs instead of feet
}

enum ScoreMonsterMood { grin, cheer, wow, sad, dizzy, sleepy, love, wink }

/// (body, accent) per colour. Accent paints wings, horns and feet highlights.
const Map<ScoreMonsterColor, (Color, Color)> kScoreMonsterPalette = {
  ScoreMonsterColor.orange: (Color(0xFFE8784A), Color(0xFFFF9955)),
  ScoreMonsterColor.teal: (Color(0xFF00A892), Color(0xFF3FD9C2)),
  ScoreMonsterColor.violet: (Color(0xFF7C5CFF), Color(0xFFA68CFF)),
  ScoreMonsterColor.pink: (Color(0xFFF0508F), Color(0xFFFF8CB8)),
  ScoreMonsterColor.lime: (Color(0xFF7FBF1E), Color(0xFFB4E45A)),
  ScoreMonsterColor.sky: (Color(0xFF2E93E6), Color(0xFF6CC0FA)),
  ScoreMonsterColor.cherry: (Color(0xFFD9344A), Color(0xFFFF6B7E)),
  ScoreMonsterColor.sunny: (Color(0xFFF2A516), Color(0xFFFFCF4D)),
};

class ScoreMonsterPainter extends CustomPainter {
  final ScoreMonsterColor color;
  final ScoreMonsterStyle style;
  final ScoreMonsterMood mood;

  const ScoreMonsterPainter({
    this.color = ScoreMonsterColor.orange,
    this.style = ScoreMonsterStyle.winged,
    this.mood = ScoreMonsterMood.grin,
  });

  static const _ink = Color(0xFF222222);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height * 0.52;
    final r = size.shortestSide * 0.42;
    final (bodyColor, accent) = kScoreMonsterPalette[color]!;
    final body = Paint()..color = bodyColor;
    final accentPaint = Paint()..color = accent;

    _paintBehind(canvas, cx, cy, r, body, accentPaint);

    // Body
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 1.6, height: r * 1.8),
        body);

    _paintOnTop(canvas, cx, cy, r, body, accentPaint);
    _paintEye(canvas, cx, cy, r);
    _paintMouth(canvas, cx, cy, r);
    _paintExtras(canvas, cx, cy, r);
  }

  void _paintBehind(Canvas canvas, double cx, double cy, double r, Paint body,
      Paint accent) {
    switch (style) {
      case ScoreMonsterStyle.winged:
        final leftWing = Path()
          ..moveTo(cx - r * 0.6, cy)
          ..cubicTo(cx - r * 1.6, cy - r * 0.5, cx - r * 1.5, cy + r * 0.5, cx - r * 0.6, cy + r * 0.3)
          ..close();
        final rightWing = Path()
          ..moveTo(cx + r * 0.6, cy)
          ..cubicTo(cx + r * 1.6, cy - r * 0.5, cx + r * 1.5, cy + r * 0.5, cx + r * 0.6, cy + r * 0.3)
          ..close();
        canvas.drawPath(leftWing, accent);
        canvas.drawPath(rightWing, accent);
      case ScoreMonsterStyle.bat:
        for (final dir in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(cx + dir * r * 0.6, cy - r * 0.25)
              ..lineTo(cx + dir * r * 1.45, cy - r * 0.55)
              ..lineTo(cx + dir * r * 1.3, cy + r * 0.05)
              ..lineTo(cx + dir * r * 1.1, cy - r * 0.1)
              ..lineTo(cx + dir * r * 0.95, cy + r * 0.3)
              ..lineTo(cx + dir * r * 0.8, cy + r * 0.1)
              ..lineTo(cx + dir * r * 0.6, cy + r * 0.35)
              ..close(),
            accent,
          );
        }
      case ScoreMonsterStyle.furry:
        for (var i = 0; i < 16; i++) {
          final a = i * 2 * math.pi / 16;
          canvas.drawCircle(
              Offset(cx + math.cos(a) * r * 0.78, cy + math.sin(a) * r * 0.88),
              r * 0.16,
              body);
        }
      default:
        break;
    }
  }

  void _paintOnTop(Canvas canvas, double cx, double cy, double r, Paint body,
      Paint accent) {
    switch (style) {
      case ScoreMonsterStyle.winged:
      case ScoreMonsterStyle.bat:
        final horn = Path()
          ..moveTo(cx - r * 0.12, cy - r * 0.85)
          ..lineTo(cx, cy - r * 1.2)
          ..lineTo(cx + r * 0.12, cy - r * 0.85)
          ..close();
        canvas.drawPath(horn, accent);
      case ScoreMonsterStyle.horned:
        for (final dir in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(cx + dir * r * 0.5, cy - r * 0.62)
              ..quadraticBezierTo(cx + dir * r * 0.85, cy - r * 0.9,
                  cx + dir * r * 0.72, cy - r * 1.22)
              ..quadraticBezierTo(cx + dir * r * 0.42, cy - r * 1.0,
                  cx + dir * r * 0.18, cy - r * 0.84)
              ..close(),
            accent,
          );
        }
      case ScoreMonsterStyle.antenna:
        final stalk = Paint()
          ..color = body.color
          ..strokeWidth = r * 0.08
          ..strokeCap = StrokeCap.round;
        for (final dir in [-1.0, 1.0]) {
          final tip = Offset(cx + dir * r * 0.45, cy - r * 1.22);
          canvas.drawLine(Offset(cx + dir * r * 0.22, cy - r * 0.8), tip, stalk);
          canvas.drawCircle(tip, r * 0.12, accent);
        }
      case ScoreMonsterStyle.furry:
        break;
      case ScoreMonsterStyle.tentacle:
        break;
    }

    // Feet
    if (style == ScoreMonsterStyle.tentacle) {
      final leg = Paint()
        ..color = body.color
        ..strokeWidth = r * 0.14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final dx in [-0.45, -0.15, 0.15, 0.45]) {
        final x = cx + dx * r;
        canvas.drawPath(
          Path()
            ..moveTo(x, cy + r * 0.6)
            ..quadraticBezierTo(x + r * 0.14, cy + r * 0.85, x, cy + r * 0.98)
            ..quadraticBezierTo(x - r * 0.1, cy + r * 1.08, x + dx.sign * r * 0.1, cy + r * 1.1),
          leg,
        );
      }
    } else {
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.25, cy + r * 0.94), width: r * 0.28, height: r * 0.2), body);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + r * 0.25, cy + r * 0.94), width: r * 0.28, height: r * 0.2), body);
    }
  }

  void _paintEye(Canvas canvas, double cx, double cy, double r) {
    final c = Offset(cx, cy - r * 0.1);
    final line = Paint()
      ..color = _ink
      ..strokeWidth = r * 0.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case ScoreMonsterMood.cheer:
      case ScoreMonsterMood.wink:
        // Closed happy arc.
        canvas.drawArc(Rect.fromCenter(center: c.translate(0, r * 0.1), width: r * 0.6, height: r * 0.45),
            math.pi, math.pi, false, line);
      case ScoreMonsterMood.sleepy:
        canvas.drawArc(Rect.fromCenter(center: c, width: r * 0.6, height: r * 0.4),
            0, math.pi, false, line);
      case ScoreMonsterMood.dizzy:
        canvas.drawCircle(c, r * 0.38, Paint()..color = Colors.white);
        final spiral = Path()..moveTo(c.dx, c.dy);
        for (var i = 1; i <= 40; i++) {
          final t = i / 40;
          final a = t * 2.4 * 2 * math.pi;
          spiral.lineTo(c.dx + math.cos(a) * r * 0.3 * t, c.dy + math.sin(a) * r * 0.3 * t);
        }
        canvas.drawPath(spiral, line..strokeWidth = r * 0.06);
      case ScoreMonsterMood.love:
        canvas.drawCircle(c, r * 0.38, Paint()..color = Colors.white);
        canvas.drawPath(_heart(c.translate(0, r * 0.02), r * 0.24),
            Paint()..color = const Color(0xFFFF4D6D));
      case ScoreMonsterMood.grin:
      case ScoreMonsterMood.wow:
      case ScoreMonsterMood.sad:
        final pupil = mood == ScoreMonsterMood.wow ? 0.13 : 0.22;
        final dy = mood == ScoreMonsterMood.sad ? r * 0.06 : 0.0;
        canvas.drawCircle(c, r * 0.38, Paint()..color = Colors.white);
        canvas.drawCircle(c.translate(0, dy), r * pupil, Paint()..color = _ink);
        canvas.drawCircle(c.translate(r * 0.08 * pupil / 0.22, -r * 0.08 + dy),
            r * 0.08 * pupil / 0.22, Paint()..color = Colors.white);
        if (mood == ScoreMonsterMood.sad) {
          // Droopy lid in body colour.
          canvas.save();
          canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.38)));
          canvas.drawRect(Rect.fromLTRB(c.dx - r * 0.4, c.dy - r * 0.4, c.dx + r * 0.4, c.dy - r * 0.12),
              Paint()..color = kScoreMonsterPalette[color]!.$1);
          canvas.restore();
        }
    }
  }

  void _paintMouth(Canvas canvas, double cx, double cy, double r) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3, r * 0.09)
      ..strokeCap = StrokeCap.round;
    switch (mood) {
      case ScoreMonsterMood.grin:
      case ScoreMonsterMood.love:
      case ScoreMonsterMood.wink:
        final mp = Path()
          ..moveTo(cx - r * 0.35, cy + r * 0.28)
          ..quadraticBezierTo(cx, cy + r * 0.55, cx + r * 0.35, cy + r * 0.28);
        canvas.drawPath(mp, stroke);
      case ScoreMonsterMood.cheer:
        final open = Path()
          ..moveTo(cx - r * 0.36, cy + r * 0.26)
          ..lineTo(cx + r * 0.36, cy + r * 0.26)
          ..quadraticBezierTo(cx, cy + r * 0.85, cx - r * 0.36, cy + r * 0.26)
          ..close();
        canvas.drawPath(open, Paint()..color = _ink);
        canvas.save();
        canvas.clipPath(open);
        canvas.drawCircle(Offset(cx, cy + r * 0.62), r * 0.18,
            Paint()..color = const Color(0xFFFF6F91));
        canvas.restore();
      case ScoreMonsterMood.wow:
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, cy + r * 0.45), width: r * 0.26, height: r * 0.32),
            Paint()..color = _ink);
      case ScoreMonsterMood.sad:
        canvas.drawPath(
            Path()
              ..moveTo(cx - r * 0.28, cy + r * 0.5)
              ..quadraticBezierTo(cx, cy + r * 0.26, cx + r * 0.28, cy + r * 0.5),
            stroke);
      case ScoreMonsterMood.dizzy:
        final wavy = Path()..moveTo(cx - r * 0.32, cy + r * 0.42);
        for (var i = 0; i < 4; i++) {
          final x0 = cx - r * 0.32 + i * r * 0.16;
          wavy.quadraticBezierTo(x0 + r * 0.08, cy + r * (i.isEven ? 0.34 : 0.5),
              x0 + r * 0.16, cy + r * 0.42);
        }
        canvas.drawPath(wavy, stroke);
      case ScoreMonsterMood.sleepy:
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, cy + r * 0.42), width: r * 0.18, height: r * 0.14),
            stroke);
    }
  }

  void _paintExtras(Canvas canvas, double cx, double cy, double r) {
    switch (mood) {
      case ScoreMonsterMood.cheer:
        final p = Paint()..color = const Color(0xFFFFCC00);
        canvas.drawPath(_sparkle(Offset(cx + r * 0.95, cy - r * 0.75), r * 0.2), p);
        canvas.drawPath(_sparkle(Offset(cx - r * 0.98, cy - r * 0.55), r * 0.14), p);
      case ScoreMonsterMood.sad:
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + r * 0.3, cy + r * 0.22), width: r * 0.12, height: r * 0.2),
            Paint()..color = const Color(0xFF7FD3FF));
      case ScoreMonsterMood.love:
        canvas.drawPath(_heart(Offset(cx + r * 0.95, cy - r * 0.8), r * 0.18),
            Paint()..color = const Color(0xFFFF4D6D));
      case ScoreMonsterMood.wink:
        canvas.drawPath(_sparkle(Offset(cx + r * 0.55, cy - r * 0.55), r * 0.14),
            Paint()..color = Colors.white);
      case ScoreMonsterMood.sleepy:
        // Three rising bubbles instead of text "Zzz".
        final p = Paint()..color = Colors.white.withValues(alpha: 0.9);
        final ring = Paint()
          ..color = const Color(0xFF9AA6B2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.04;
        for (final (dx, dy, s) in [(0.7, -0.7, 0.08), (0.9, -0.95, 0.11), (1.12, -1.25, 0.14)]) {
          final c = Offset(cx + r * dx, cy + r * dy);
          canvas.drawCircle(c, r * s, p);
          canvas.drawCircle(c, r * s, ring);
        }
      default:
        break;
    }
  }

  static Path _heart(Offset c, double s) => Path()
    ..moveTo(c.dx, c.dy + s * 0.75)
    ..cubicTo(c.dx - s * 1.3, c.dy - s * 0.1, c.dx - s * 0.55, c.dy - s * 1.05, c.dx, c.dy - s * 0.35)
    ..cubicTo(c.dx + s * 0.55, c.dy - s * 1.05, c.dx + s * 1.3, c.dy - s * 0.1, c.dx, c.dy + s * 0.75)
    ..close();

  static Path _sparkle(Offset c, double s) => Path()
    ..moveTo(c.dx, c.dy - s)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s)
    ..close();

  @override
  bool shouldRepaint(ScoreMonsterPainter old) =>
      old.color != color || old.style != style || old.mood != mood;
}
