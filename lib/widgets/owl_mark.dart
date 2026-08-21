import 'package:flutter/rendering.dart';

/// Source of truth for the EduBuddy launcher icon.
///
/// Built from a handful of large, blunt shapes so the mark still reads at
/// 32x32. Three colours only: gold body, cream facial discs, and the orange
/// ground reused for the eyes and beak.
///
/// The owl read comes mostly from two things: a pair of overlapping circular
/// facial discs (one wide oval reads as a cat) and a beak that tapers
/// downward between them.
class OwlIconPainter extends CustomPainter {
  const OwlIconPainter({
    this.drawBackground = true,
    this.cropBody = true,
  });

  /// Adaptive-icon foregrounds are drawn over a separate background layer, so
  /// the ground is skipped for that export.
  final bool drawBackground;

  /// The full-bleed icon lets the body run off the bottom edge. The adaptive
  /// foreground is masked to a centre safe zone instead, so there the whole
  /// bird has to fit and the body stops short.
  final bool cropBody;

  static const Color ground = Color(0xFFE8784A);
  static const Color gold = Color(0xFFFFC93F);
  static const Color cream = Color(0xFFFFF4DC);

  @override
  void paint(Canvas canvas, Size size) {
    // Authored against a 1024 grid and scaled to whatever size is requested.
    final s = size.width / 1024.0;
    canvas.save();
    canvas.scale(s, s);

    if (drawBackground) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1024, 1024),
        Paint()..color = ground,
      );
    }

    final goldPaint = Paint()..color = gold;
    final creamPaint = Paint()..color = cream;
    final markPaint = Paint()..color = ground;

    // ── Ear tufts ───────────────────────────────────────────────────────────
    // Tapered with a rounded apex. Drawn first so the head covers their base.
    _tuft(canvas, goldPaint, const Offset(360, 236), -0.42);
    _tuft(canvas, goldPaint, const Offset(664, 236), 0.42);

    // ── Head and body: one gold egg ─────────────────────────────────────────
    canvas.drawOval(
      Rect.fromLTRB(112, 214, 912, cropBody ? 1150 : 1002),
      goldPaint,
    );

    // ── Facial discs ────────────────────────────────────────────────────────
    // Two overlapping circles reading as one goggle-shaped mass. This is the
    // strongest owl cue in the whole mark.
    canvas.drawCircle(const Offset(398, 512), 172, creamPaint);
    canvas.drawCircle(const Offset(626, 512), 172, creamPaint);

    // ── Eyes ────────────────────────────────────────────────────────────────
    canvas.drawCircle(const Offset(398, 512), 92, markPaint);
    canvas.drawCircle(const Offset(626, 512), 92, markPaint);

    // Catchlights, in cream so the palette stays at three colours.
    canvas.drawCircle(const Offset(370, 482), 30, creamPaint);
    canvas.drawCircle(const Offset(598, 482), 30, creamPaint);

    // ── Beak ────────────────────────────────────────────────────────────────
    // Sits in the notch where the two discs meet and tapers downward to a
    // blunt, rounded tip.
    _beak(canvas, markPaint);

    canvas.restore();
  }

  /// A tapered ear tuft with a rounded apex, rotated about its own centre.
  void _tuft(Canvas canvas, Paint paint, Offset center, double radians) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(radians);
    final path = Path()
      ..moveTo(-62, 116)
      ..quadraticBezierTo(-56, -62, 0, -116)
      ..quadraticBezierTo(56, -62, 62, 116)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  /// Downward-tapering beak with a blunt tip — no sharp point anywhere.
  void _beak(Canvas canvas, Paint paint) {
    final path = Path()
      ..moveTo(470, 548)
      ..lineTo(554, 548)
      ..quadraticBezierTo(548, 648, 512, 668)
      ..quadraticBezierTo(476, 648, 470, 548)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant OwlIconPainter old) =>
      old.drawBackground != drawBackground || old.cropBody != cropBody;

}
