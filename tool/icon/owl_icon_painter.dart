import 'dart:ui';

/// Source of truth for the EduBuddy launcher icon.
///
/// Deliberately built from a handful of large, blunt shapes so the mark still
/// reads at 32x32. Three colours only: gold body, cream face disc, and the
/// orange ground reused for the facial marks.
class OwlIconPainter {
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
    // Tapered ovals angled outward read as owl tufts where circles read as
    // bear ears. Drawn first so the head overlaps their base.
    _tuft(canvas, goldPaint, const Offset(316, 244), -0.50);
    _tuft(canvas, goldPaint, const Offset(708, 244), 0.50);

    // ── Head and body: one gold egg ─────────────────────────────────────────
    canvas.drawOval(
      Rect.fromLTRB(120, 180, 904, cropBody ? 1150 : 986),
      goldPaint,
    );

    // ── Cream face disc, upper body only ────────────────────────────────────
    // Kept off the belly so the gold still reads as the bird rather than a
    // hood around a pale blob.
    canvas.drawOval(const Rect.fromLTRB(238, 330, 786, 726), creamPaint);

    // ── Facial marks reuse the ground colour ────────────────────────────────
    // Set close together: wide-set eyes read as a mammal.
    canvas.drawCircle(const Offset(412, 508), 94, markPaint);
    canvas.drawCircle(const Offset(612, 508), 94, markPaint);

    // Catchlights, in cream so the palette stays at three colours.
    canvas.drawCircle(const Offset(384, 478), 28, creamPaint);
    canvas.drawCircle(const Offset(584, 478), 28, creamPaint);

    // Blunt beak — an oval, so there is no point anywhere on the mark.
    canvas.drawOval(const Rect.fromLTRB(478, 596, 546, 664), markPaint);

    canvas.restore();
  }

  /// A blunt, tapered ear tuft: a narrow oval rotated about its own centre so
  /// both sides stay symmetric.
  void _tuft(Canvas canvas, Paint paint, Offset center, double radians) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(radians);
    canvas.drawOval(const Rect.fromLTRB(-68, -132, 68, 132), paint);
    canvas.restore();
  }
}
