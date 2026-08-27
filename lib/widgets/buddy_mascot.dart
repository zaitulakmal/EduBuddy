import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Original cartoon "Buddy" monster family — round blobs with big eyes, an
/// antenna, and stubby arms. Drawn entirely with CustomPaint (no assets/emoji).
/// Each VARIANT is a different coloured buddy; each ANIMATION is a different
/// motion so every page can show "the monster" but a different one / different
/// move. Fully original — no copying from anywhere.
class BuddyMascot extends StatefulWidget {
  final double size;
  final bool waving;
  final BuddyVariant variant;
  final BuddyAnim animation;
  final Color? bodyColor;
  final Color? cheekColor;

  /// The little ball on the antenna. Defaults to the app yellow, which
  /// disappears on a yellow background - pass something contrasting there.
  final Color? antennaColor;

  const BuddyMascot({
    super.key,
    this.size = 96,
    this.waving = true,
    this.variant = BuddyVariant.buddy,
    this.animation = BuddyAnim.wave,
    this.bodyColor,
    this.cheekColor,
    this.antennaColor,
  });

  @override
  State<BuddyMascot> createState() => _BuddyMascotState();
}

enum BuddyVariant {
  buddy, // violet
  bub, // teal
  pip, // lime
  zuzu, // pink
  tako, // coral
  lumi, // blue
  nova, // indigo
  coco, // butter
}

enum BuddyAnim {
  wave,
  bounce,
  spin,
  cheer,
  hop,
  think,
  idle,
}

/// Stable string ids for persisting a chosen Buddy as a profile avatar.
///
/// The user_profile row stores one of these in its avatar column. Rows written
/// before Buddy replaced the emoji avatars still hold something like '🦁', so
/// every lookup falls back rather than assuming a match.
const Map<String, BuddyVariant> kBuddyVariantIds = {
  'buddy': BuddyVariant.buddy,
  'bub': BuddyVariant.bub,
  'pip': BuddyVariant.pip,
  'zuzu': BuddyVariant.zuzu,
  'tako': BuddyVariant.tako,
  'lumi': BuddyVariant.lumi,
  'nova': BuddyVariant.nova,
  'coco': BuddyVariant.coco,
};

BuddyVariant buddyVariantFromId(String? id) =>
    kBuddyVariantIds[id] ?? BuddyVariant.buddy;

String buddyVariantId(BuddyVariant variant) => kBuddyVariantIds.entries
    .firstWhere((e) => e.value == variant)
    .key;

class _BuddyMascotState extends State<BuddyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  (Color, Color) _colors() {
    switch (widget.variant) {
      case BuddyVariant.buddy:
        return (widget.bodyColor ?? AppColors.mascot, widget.cheekColor ?? AppColors.mascotCheek);
      case BuddyVariant.bub:
        return (AppColors.punchTeal, const Color(0xFFB6F5EC));
      case BuddyVariant.pip:
        return (AppColors.punchLime, const Color(0xFFE9F8A8));
      case BuddyVariant.zuzu:
        return (AppColors.punchPink, const Color(0xFFFFC7DE));
      case BuddyVariant.tako:
        return (AppColors.secondary, const Color(0xFFFFD0B8));
      case BuddyVariant.lumi:
        return (const Color(0xFF3FA7F5), const Color(0xFFBFE3FC));
      case BuddyVariant.nova:
        return (const Color(0xFF5B6EF5), const Color(0xFFC3C9FB));
      case BuddyVariant.coco:
        return (const Color(0xFFFFC93C), const Color(0xFFFFE3A1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (body, cheek) = _colors();
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final t = _ctrl.value;
          double dy = 0, rot = 0, scale = 1;
          double wave = 0;
          switch (widget.animation) {
            case BuddyAnim.wave:
              wave = Curves.easeInOut.transform(t) * 0.5 - 0.25;
              dy = -t * (widget.size * 0.03);
              break;
            case BuddyAnim.bounce:
              dy = -sin01(t) * (widget.size * 0.06);
              break;
            case BuddyAnim.spin:
              rot = (t - 0.5) * 0.5;
              break;
            case BuddyAnim.cheer:
              dy = -sin01(t) * (widget.size * 0.07);
              scale = 1 + sin01(t) * 0.04;
              break;
            case BuddyAnim.hop:
              dy = -((t < 0.5) ? t * 2 : (1 - t) * 2) * (widget.size * 0.08);
              break;
            case BuddyAnim.think:
              rot = (t - 0.5) * 0.12;
              dy = -t * (widget.size * 0.015);
              break;
            case BuddyAnim.idle:
              dy = -t * (widget.size * 0.02);
              break;
          }
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: rot,
              child: Transform.scale(
                scale: scale,
                child: CustomPaint(
                  painter: _BuddyPainter(
                    wave: wave,
                    bodyColor: body,
                    cheekColor: cheek,
                    antennaColor: widget.antennaColor ?? const Color(0xFFFFC93C),
                    variant: widget.variant,
                    animation: widget.animation,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

double sin01(double t) => (1 - (1 - t) * (1 - t)) * (1); // ease-out lift

class _BuddyPainter extends CustomPainter {
  final double wave;
  final Color bodyColor;
  final Color cheekColor;
  final Color antennaColor;
  final BuddyVariant variant;
  final BuddyAnim animation;

  _BuddyPainter({
    required this.wave,
    required this.bodyColor,
    required this.cheekColor,
    required this.antennaColor,
    required this.variant,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.56;
    final r = w * 0.34;

    // Soft shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.92),
        width: r * 1.4,
        height: r * 0.32,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    // Body
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2.05),
        Radius.circular(r),
      ),
      bodyPaint,
    );
    // Belly highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + r * 0.18),
          width: r * 1.25,
          height: r * 1.3,
        ),
        Radius.circular(r * 0.7),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Antenna
    final antPaint = Paint()
      ..color = bodyColor
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy - r),
      Offset(cx + r * 0.18, cy - r * 1.5),
      antPaint,
    );
    canvas.drawCircle(
      Offset(cx + r * 0.18, cy - r * 1.55),
      w * 0.06,
      Paint()..color = antennaColor,
    );

    // Eyes (variant changes where the pupil looks)
    final eyeY = cy - r * 0.25;
    final eyeDx = r * 0.42;
    final look = animation == BuddyAnim.think ? r * 0.12 : 0.0;
    for (final dir in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(cx + dir * eyeDx, eyeY),
        w * 0.105,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(cx + dir * eyeDx + look, eyeY + w * 0.01),
        w * 0.05,
        Paint()..color = const Color(0xFF2B2440),
      );
      canvas.drawCircle(
        Offset(cx + dir * eyeDx - w * 0.02 + look, eyeY - w * 0.02),
        w * 0.018,
        Paint()..color = Colors.white,
      );
    }

    // Cheeks
    final cheekPaint = Paint()..color = cheekColor;
    for (final dir in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(cx + dir * r * 0.66, cy + r * 0.18),
        w * 0.07,
        cheekPaint,
      );
    }

    // Mouth (variant flavour)
    final mouthPaint = Paint()
      ..color = const Color(0xFF2B2440)
      ..strokeWidth = w * 0.035
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (variant == BuddyVariant.zuzu) {
      // open happy "o"
      canvas.drawCircle(Offset(cx, cy + r * 0.34), w * 0.07, mouthPaint);
    } else {
      final smile = Path()
        ..moveTo(cx - r * 0.34, cy + r * 0.28)
        ..quadraticBezierTo(cx, cy + r * 0.62, cx + r * 0.34, cy + r * 0.28);
      canvas.drawPath(smile, mouthPaint);
    }

    // Arms — one waves by `wave`, other rests
    final armPaint = Paint()
      ..color = bodyColor
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - r * 0.95, cy + r * 0.1),
      Offset(cx - r * 1.25, cy + r * 0.35),
      armPaint,
    );
    canvas.save();
    canvas.translate(cx + r * 0.95, cy + r * 0.1);
    canvas.rotate(wave);
    canvas.drawLine(
      Offset(0, 0),
      Offset(r * 0.45, -r * 0.55),
      armPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BuddyPainter old) =>
      old.wave != wave ||
      old.variant != variant ||
      old.antennaColor != antennaColor;
}
