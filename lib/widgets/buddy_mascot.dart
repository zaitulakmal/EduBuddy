import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/progression.dart';
import '../theme/app_theme.dart';

/// Original cartoon "Buddy" monster family — round blobs with big eyes, an
/// antenna, and stubby arms. Drawn entirely with CustomPaint (no assets/emoji).
/// Each VARIANT is a different coloured buddy; each ANIMATION is a different
/// motion so every page can show "the monster" but a different one / different
/// move. Fully original — no copying from anywhere.
///
/// On top of the variant, a Buddy can be dressed up along four independent
/// axes: [BuddyStyle] (body shape — horns, ears, one eye...), [BuddyExpression]
/// (a one-off reaction that overrides the progression [BuddyMood]), [BuddyHat]
/// and [BuddyAccessory].
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

  /// A bought hat, or none. Cosmetics from the star shop.
  final BuddyHat hat;

  /// How Buddy feels. Changes the eyes and mouth so the companion visibly
  /// reacts to how recently the child came back.
  final BuddyMood mood;

  /// A momentary reaction (surprised, laughing, crying...). When set it wins
  /// over [mood], so a screen can react to a right/wrong answer without
  /// touching the progression mood.
  final BuddyExpression? expression;

  /// Body shape. Null uses the variant's own default ([defaultBuddyStyle]),
  /// which is [BuddyStyle.classic] for the original eight Buddies.
  final BuddyStyle? style;

  /// Glasses, scarf, medal... worn alongside the hat.
  final BuddyAccessory accessory;

  const BuddyMascot({
    super.key,
    this.size = 96,
    this.waving = true,
    this.variant = BuddyVariant.buddy,
    this.animation = BuddyAnim.wave,
    this.bodyColor,
    this.cheekColor,
    this.antennaColor,
    this.hat = BuddyHat.none,
    this.mood = BuddyMood.happy,
    this.expression,
    this.style,
    this.accessory = BuddyAccessory.none,
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
  kiki, // cherry red, horns
  momo, // peach, bunny ears
  rio, // leaf green, spiky
  boba, // cocoa, cat ears
  yuki, // frost, fluffy
  gigi, // magenta, fangs
  zap, // cyan, one eye
  onyx, // charcoal, ghost
}

/// Body shape of a Buddy, independent of its colour.
enum BuddyStyle {
  classic, // antenna
  horns,
  bunny,
  cat,
  cyclops, // one big eye
  fangs,
  fluffy,
  spiky,
  ghost, // wavy hem instead of a round bottom
}

/// One-off reactions. Unlike [BuddyMood] these are not derived from
/// progression; screens pick one for the moment (a right answer, a wrong
/// answer, a finished story...).
enum BuddyExpression {
  surprised,
  sad,
  crying,
  angry,
  laughing,
  confused,
  proud,
  love,
  dizzy,
  wink,
  scared,
  silly,
}

/// Hats sold in the star shop. [BuddyHat.none] is what everyone starts with.
enum BuddyHat {
  none,
  bow,
  cap,
  party,
  crown,
  wizard,
  beanie,
  flower,
  headphones,
  pirate,
  halo,
}

/// Worn items that are not hats.
enum BuddyAccessory { none, glasses, sunglasses, bowtie, scarf, medal, cape }

/// Stable string ids so a worn hat can be persisted on the profile row.
const Map<String, BuddyHat> kBuddyHatIds = {
  'none': BuddyHat.none,
  'bow': BuddyHat.bow,
  'cap': BuddyHat.cap,
  'party': BuddyHat.party,
  'crown': BuddyHat.crown,
  'wizard': BuddyHat.wizard,
  'beanie': BuddyHat.beanie,
  'flower': BuddyHat.flower,
  'headphones': BuddyHat.headphones,
  'pirate': BuddyHat.pirate,
  'halo': BuddyHat.halo,
};

BuddyHat buddyHatFromId(String? id) => kBuddyHatIds[id] ?? BuddyHat.none;

String buddyHatId(BuddyHat hat) =>
    kBuddyHatIds.entries.firstWhere((e) => e.value == hat).key;

/// Stable string ids for [BuddyStyle], for when a style gets persisted.
const Map<String, BuddyStyle> kBuddyStyleIds = {
  'classic': BuddyStyle.classic,
  'horns': BuddyStyle.horns,
  'bunny': BuddyStyle.bunny,
  'cat': BuddyStyle.cat,
  'cyclops': BuddyStyle.cyclops,
  'fangs': BuddyStyle.fangs,
  'fluffy': BuddyStyle.fluffy,
  'spiky': BuddyStyle.spiky,
  'ghost': BuddyStyle.ghost,
};

/// Stable string ids for [BuddyAccessory], for when one gets persisted.
const Map<String, BuddyAccessory> kBuddyAccessoryIds = {
  'none': BuddyAccessory.none,
  'glasses': BuddyAccessory.glasses,
  'sunglasses': BuddyAccessory.sunglasses,
  'bowtie': BuddyAccessory.bowtie,
  'scarf': BuddyAccessory.scarf,
  'medal': BuddyAccessory.medal,
  'cape': BuddyAccessory.cape,
};

BuddyAccessory buddyAccessoryFromId(String? id) =>
    kBuddyAccessoryIds[id] ?? BuddyAccessory.none;

String buddyAccessoryId(BuddyAccessory accessory) =>
    kBuddyAccessoryIds.entries.firstWhere((e) => e.value == accessory).key;

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
  'kiki': BuddyVariant.kiki,
  'momo': BuddyVariant.momo,
  'rio': BuddyVariant.rio,
  'boba': BuddyVariant.boba,
  'yuki': BuddyVariant.yuki,
  'gigi': BuddyVariant.gigi,
  'zap': BuddyVariant.zap,
  'onyx': BuddyVariant.onyx,
};

BuddyVariant buddyVariantFromId(String? id) =>
    kBuddyVariantIds[id] ?? BuddyVariant.buddy;

String buddyVariantId(BuddyVariant variant) => kBuddyVariantIds.entries
    .firstWhere((e) => e.value == variant)
    .key;

/// The shape a variant has when no explicit [BuddyStyle] is given. The
/// original eight stay classic so nothing already on screen changes.
BuddyStyle defaultBuddyStyle(BuddyVariant variant) => switch (variant) {
      BuddyVariant.kiki => BuddyStyle.horns,
      BuddyVariant.momo => BuddyStyle.bunny,
      BuddyVariant.rio => BuddyStyle.spiky,
      BuddyVariant.boba => BuddyStyle.cat,
      BuddyVariant.yuki => BuddyStyle.fluffy,
      BuddyVariant.gigi => BuddyStyle.fangs,
      BuddyVariant.zap => BuddyStyle.cyclops,
      BuddyVariant.onyx => BuddyStyle.ghost,
      _ => BuddyStyle.classic,
    };

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
      case BuddyVariant.kiki:
        return (const Color(0xFFF2435A), const Color(0xFFFFB3BE));
      case BuddyVariant.momo:
        return (const Color(0xFFFFA07A), const Color(0xFFFF7F9E));
      case BuddyVariant.rio:
        return (const Color(0xFF3FB36B), const Color(0xFFB9EFC9));
      case BuddyVariant.boba:
        return (const Color(0xFFA0704F), const Color(0xFFF0B9A0));
      case BuddyVariant.yuki:
        return (const Color(0xFFBFE6F7), const Color(0xFFFFB8D1));
      case BuddyVariant.gigi:
        return (const Color(0xFFD13FD6), const Color(0xFFF7B8F2));
      case BuddyVariant.zap:
        return (const Color(0xFF22D3EE), const Color(0xFFB5F3FB));
      case BuddyVariant.onyx:
        return (const Color(0xFF4A4A68), const Color(0xFFB08CD9));
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
                    hat: widget.hat,
                    mood: widget.mood,
                    expression: widget.expression,
                    style: widget.style ?? defaultBuddyStyle(widget.variant),
                    accessory: widget.accessory,
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

const Color _ink = Color(0xFF2B2440);
const Color _tearBlue = Color(0xFF7FD3FF);
const Color _heartPink = Color(0xFFFF4D6D);
const Color _gold = Color(0xFFFFC93C);

enum _Eye { open, happyArc, sleepyArc, squeeze, heart, spiral, wink }

enum _Brow { none, angry, sad, raised }

enum _Mouth { smile, smallSmile, o, frown, grin, gasp, grit, wavy, tongue, smirk }

/// Everything the face needs, resolved once from mood / expression / variant.
class _Face {
  final _Eye eye;
  final double eyeScale;
  final double pupilScale;
  final double pupilDy;
  final _Brow brow;
  final _Mouth mouth;

  const _Face(
    this.eye,
    this.mouth, {
    this.eyeScale = 1.0,
    this.pupilScale = 1.0,
    this.pupilDy = 0.0,
    this.brow = _Brow.none,
  });
}

class _BuddyPainter extends CustomPainter {
  final double wave;
  final Color bodyColor;
  final Color cheekColor;
  final Color antennaColor;
  final BuddyVariant variant;
  final BuddyAnim animation;
  final BuddyHat hat;
  final BuddyMood mood;
  final BuddyExpression? expression;
  final BuddyStyle style;
  final BuddyAccessory accessory;

  _BuddyPainter({
    required this.wave,
    required this.bodyColor,
    required this.cheekColor,
    required this.antennaColor,
    required this.variant,
    required this.animation,
    this.hat = BuddyHat.none,
    this.mood = BuddyMood.happy,
    this.expression,
    this.style = BuddyStyle.classic,
    this.accessory = BuddyAccessory.none,
  });

  Color get _shade => Color.lerp(bodyColor, Colors.black, 0.22)!;

  _Face get _face {
    switch (expression) {
      case null:
        break;
      case BuddyExpression.surprised:
        return const _Face(_Eye.open, _Mouth.gasp,
            eyeScale: 1.2, pupilScale: 0.6, brow: _Brow.raised);
      case BuddyExpression.sad:
        return const _Face(_Eye.open, _Mouth.frown,
            eyeScale: 0.95, pupilDy: 0.02, brow: _Brow.sad);
      case BuddyExpression.crying:
        return const _Face(_Eye.squeeze, _Mouth.frown, brow: _Brow.sad);
      case BuddyExpression.angry:
        return const _Face(_Eye.open, _Mouth.grit, brow: _Brow.angry);
      case BuddyExpression.laughing:
        return const _Face(_Eye.happyArc, _Mouth.grin);
      case BuddyExpression.confused:
        return const _Face(_Eye.open, _Mouth.wavy,
            pupilDy: -0.025, brow: _Brow.sad);
      case BuddyExpression.proud:
        return const _Face(_Eye.happyArc, _Mouth.smirk);
      case BuddyExpression.love:
        return const _Face(_Eye.heart, _Mouth.smile);
      case BuddyExpression.dizzy:
        return const _Face(_Eye.spiral, _Mouth.wavy);
      case BuddyExpression.wink:
        return const _Face(_Eye.wink, _Mouth.smile);
      case BuddyExpression.scared:
        return const _Face(_Eye.open, _Mouth.wavy,
            eyeScale: 1.15, pupilScale: 0.5, brow: _Brow.sad);
      case BuddyExpression.silly:
        return const _Face(_Eye.wink, _Mouth.tongue);
    }
    return switch (mood) {
      BuddyMood.excited => const _Face(_Eye.open, _Mouth.o, eyeScale: 1.15),
      BuddyMood.happy => _Face(_Eye.open,
          variant == BuddyVariant.zuzu ? _Mouth.o : _Mouth.smile),
      BuddyMood.sleepy => const _Face(_Eye.sleepyArc, _Mouth.smallSmile),
      BuddyMood.missing =>
        const _Face(_Eye.open, _Mouth.frown, eyeScale: 0.85),
    };
  }

  /// The body silhouette. Also used to clip anything that wraps the body.
  Path _bodyPath(double cx, double cy, double r) {
    if (style != BuddyStyle.ghost) {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2.05),
          Radius.circular(r),
        ));
    }
    final bottom = cy + r * 1.02;
    final path = Path()
      ..moveTo(cx - r, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), math.pi,
          math.pi, false)
      ..lineTo(cx + r, bottom);
    // Four scallops along the hem, right to left.
    const n = 4;
    final step = 2 * r / n;
    for (var i = 0; i < n; i++) {
      final x0 = cx + r - step * i;
      path.quadraticBezierTo(
          x0 - step / 2, bottom - r * 0.28, x0 - step, bottom);
    }
    return path..close();
  }

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
        width: r * (style == BuddyStyle.ghost ? 1.0 : 1.4),
        height: r * 0.32,
      ),
      Paint()
        ..color = Colors.black
            .withValues(alpha: style == BuddyStyle.ghost ? 0.06 : 0.10),
    );

    if (accessory == BuddyAccessory.cape) _paintCape(canvas, cx, cy, r);
    _paintStyleBehind(canvas, cx, cy, r, w);

    // Body
    final body = _bodyPath(cx, cy, r);
    canvas.drawPath(body, Paint()..color = bodyColor);
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

    _paintStyleFront(canvas, cx, cy, r, w);

    final face = _face;
    final eyeY = cy - r * 0.25;
    _paintEyes(canvas, face, cx, eyeY, r, w);

    // Cheeks
    final love = expression == BuddyExpression.love;
    final cheekPaint = Paint()
      ..color = love ? const Color(0xFFFF7FA8) : cheekColor;
    for (final dir in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(cx + dir * r * 0.66, cy + r * 0.18),
        w * (love ? 0.085 : 0.07),
        cheekPaint,
      );
    }

    _paintMouth(canvas, face.mouth, cx, cy, r, w);
    if (style == BuddyStyle.fangs) _paintFangs(canvas, face.mouth, cx, cy, r);

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

    _paintAccessory(canvas, body, cx, cy, eyeY, r, w);
    _paintHat(canvas, cx, cy, r, w);
    _paintReactionExtras(canvas, cx, cy, eyeY, r, w);
  }

  // ── Style ────────────────────────────────────────────────────────────────

  /// Parts that sit behind the body: ears, fur, spikes.
  void _paintStyleBehind(Canvas canvas, double cx, double cy, double r, double w) {
    switch (style) {
      case BuddyStyle.bunny:
        for (final dir in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(cx + dir * r * 0.42, cy - r * 1.2);
          canvas.rotate(dir * 0.22);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: r * 0.46, height: r * 1.15),
            Paint()..color = bodyColor,
          );
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(0, -r * 0.04), width: r * 0.24, height: r * 0.8),
            Paint()..color = cheekColor,
          );
          canvas.restore();
        }
      case BuddyStyle.cat:
        for (final dir in [-1.0, 1.0]) {
          final outer = Path()
            ..moveTo(cx + dir * r * 0.92, cy - r * 0.35)
            ..lineTo(cx + dir * r * 0.72, cy - r * 1.38)
            ..lineTo(cx + dir * r * 0.1, cy - r * 0.9)
            ..close();
          canvas.drawPath(outer, Paint()..color = bodyColor);
          final inner = Path()
            ..moveTo(cx + dir * r * 0.78, cy - r * 0.7)
            ..lineTo(cx + dir * r * 0.7, cy - r * 1.18)
            ..lineTo(cx + dir * r * 0.36, cy - r * 0.92)
            ..close();
          canvas.drawPath(inner, Paint()..color = cheekColor);
        }
      case BuddyStyle.fluffy:
        final fur = Paint()..color = bodyColor;
        for (var i = 0; i < 14; i++) {
          final a = i * 2 * math.pi / 14;
          canvas.drawCircle(
            Offset(cx + math.cos(a) * r * 0.96, cy + math.sin(a) * r * 0.98),
            r * 0.2,
            fur,
          );
        }
        // Tuft on top instead of an antenna.
        for (final dx in [-0.2, 0.0, 0.2]) {
          canvas.drawCircle(
              Offset(cx + dx * r, cy - r * (1.12 + (dx == 0 ? 0.08 : 0))),
              r * 0.17,
              fur);
        }
      case BuddyStyle.spiky:
        final spike = Paint()..color = _shade;
        for (var i = 0; i < 5; i++) {
          final a = -math.pi * (0.82 - i * 0.16);
          final tip = Offset(cx + math.cos(a) * r * 1.38, cy + math.sin(a) * r * 1.4);
          final left = a - 0.26, right = a + 0.26;
          canvas.drawPath(
            Path()
              ..moveTo(cx + math.cos(left) * r * 0.9, cy + math.sin(left) * r * 0.92)
              ..lineTo(tip.dx, tip.dy)
              ..lineTo(cx + math.cos(right) * r * 0.9, cy + math.sin(right) * r * 0.92)
              ..close(),
            spike,
          );
        }
      default:
        break;
    }
  }

  /// Parts that sit on top of the body: antenna, horns.
  void _paintStyleFront(Canvas canvas, double cx, double cy, double r, double w) {
    switch (style) {
      case BuddyStyle.classic:
      case BuddyStyle.cyclops:
      case BuddyStyle.fangs:
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
      case BuddyStyle.horns:
        final horn = Paint()..color = const Color(0xFFFFDFA3);
        for (final dir in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(cx + dir * r * 0.62, cy - r * 0.72)
              ..quadraticBezierTo(cx + dir * r * 0.98, cy - r * 1.05,
                  cx + dir * r * 0.86, cy - r * 1.46)
              ..quadraticBezierTo(cx + dir * r * 0.5, cy - r * 1.2,
                  cx + dir * r * 0.26, cy - r * 0.94)
              ..close(),
            horn,
          );
        }
      default:
        break;
    }
  }

  void _paintFangs(Canvas canvas, _Mouth mouth, double cx, double cy, double r) {
    // Hang from wherever the mouth's top edge sits.
    final y = switch (mouth) {
      _Mouth.grin => cy + r * 0.27,
      _Mouth.frown => cy + r * 0.44,
      _Mouth.o || _Mouth.gasp => cy + r * 0.5,
      _ => cy + r * 0.4,
    };
    final fang = Paint()..color = Colors.white;
    for (final dir in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(cx + dir * r * 0.1, y)
          ..lineTo(cx + dir * r * 0.28, y)
          ..lineTo(cx + dir * r * 0.19, y + r * 0.2)
          ..close(),
        fang,
      );
    }
  }

  // ── Face ─────────────────────────────────────────────────────────────────

  void _paintEyes(
      Canvas canvas, _Face face, double cx, double eyeY, double r, double w) {
    final cyclops = style == BuddyStyle.cyclops;
    final eyes = cyclops ? [0.0] : [-1.0, 1.0];
    final eyeDx = r * 0.42;
    final look = animation == BuddyAnim.think ? r * 0.12 : 0.0;
    final big = cyclops ? 1.55 : 1.0;
    final stroke = Paint()
      ..color = _ink
      ..strokeWidth = w * 0.03 * (cyclops ? 1.3 : 1)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final dir in eyes) {
      final c = Offset(cx + dir * eyeDx, eyeY);
      final radius = w * 0.105 * face.eyeScale * big;
      var kind = face.eye;
      // Winks close the right eye; a cyclops winks with its only eye.
      if (kind == _Eye.wink) kind = (dir > 0 || cyclops) ? _Eye.happyArc : _Eye.open;

      switch (kind) {
        case _Eye.sleepyArc:
          // Half-lidded: a closed arc reads as sleepy at any size, where a
          // shrunken circle just reads as a smaller eye.
          canvas.drawArc(
            Rect.fromCenter(center: c, width: w * 0.21 * big, height: w * 0.21 * big),
            0,
            math.pi,
            false,
            stroke,
          );
        case _Eye.happyArc:
          canvas.drawArc(
            Rect.fromCenter(
                center: c.translate(0, radius * 0.35),
                width: radius * 1.9,
                height: radius * 1.6),
            math.pi,
            math.pi,
            false,
            stroke,
          );
        case _Eye.squeeze:
          // ">" and "<", pointing at the nose.
          final s = cyclops ? 1.0 : -dir;
          canvas.drawPath(
            Path()
              ..moveTo(c.dx - s * radius * 0.8, c.dy - radius * 0.6)
              ..lineTo(c.dx + s * radius * 0.6, c.dy)
              ..lineTo(c.dx - s * radius * 0.8, c.dy + radius * 0.6),
            stroke,
          );
        case _Eye.heart:
          canvas.drawPath(_heart(c, radius * 1.15), Paint()..color = _heartPink);
          canvas.drawCircle(c.translate(-radius * 0.35, -radius * 0.3),
              radius * 0.16, Paint()..color = Colors.white);
        case _Eye.spiral:
          final spiral = Path()..moveTo(c.dx, c.dy);
          const turns = 2.3;
          for (var i = 1; i <= 40; i++) {
            final t = i / 40;
            final a = t * turns * 2 * math.pi;
            spiral.lineTo(c.dx + math.cos(a) * radius * t,
                c.dy + math.sin(a) * radius * t);
          }
          canvas.drawPath(spiral, stroke..strokeWidth = w * 0.022);
        case _Eye.open:
        case _Eye.wink:
          canvas.drawCircle(c, radius, Paint()..color = Colors.white);
          canvas.drawCircle(
            c.translate(look, w * 0.01 + face.pupilDy * w),
            w * 0.05 * face.eyeScale * face.pupilScale * big,
            Paint()..color = _ink,
          );
          canvas.drawCircle(
            c.translate(-w * 0.02 * big + look, -w * 0.02 * big + face.pupilDy * w),
            w * 0.018 * big,
            Paint()..color = Colors.white,
          );
          if (face.brow == _Brow.angry) {
            // A body-coloured lid slanting down toward the nose.
            final inner = cyclops ? 0.0 : -dir;
            canvas.save();
            canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: radius)));
            final lid = cyclops
                ? (Path()
                  ..addRect(Rect.fromLTRB(c.dx - radius, c.dy - radius,
                      c.dx + radius, c.dy - radius * 0.35)))
                : (Path()
                  ..moveTo(c.dx + inner * radius, c.dy - radius * 1.2)
                  ..lineTo(c.dx - inner * radius, c.dy - radius * 1.2)
                  ..lineTo(c.dx - inner * radius, c.dy - radius * 0.75)
                  ..lineTo(c.dx + inner * radius, c.dy - radius * 0.05)
                  ..close());
            canvas.drawPath(lid, Paint()..color = bodyColor);
            canvas.restore();
          }
      }
      _paintBrow(canvas, face.brow, c, dir, radius, stroke);
    }
  }

  void _paintBrow(Canvas canvas, _Brow brow, Offset c, double dir,
      double radius, Paint stroke) {
    if (brow == _Brow.none) return;
    // Toward the nose; a cyclops has one brow drawn as if it were a left eye.
    final inner = dir == 0 ? 1.0 : -dir;
    final innerX = c.dx + inner * radius * 0.75;
    final outerX = c.dx - inner * radius * 0.95;
    final base = c.dy - radius * 1.3;
    switch (brow) {
      case _Brow.none:
        return;
      case _Brow.angry:
        if (dir == 0) {
          canvas.drawLine(Offset(c.dx - radius, base + radius * 0.15),
              Offset(c.dx + radius, base + radius * 0.15), stroke);
          return;
        }
        canvas.drawLine(Offset(innerX, base + radius * 0.45),
            Offset(outerX, base), stroke);
      case _Brow.sad:
        if (dir == 0) {
          canvas.drawArc(
              Rect.fromCenter(
                  center: Offset(c.dx, base + radius * 0.3),
                  width: radius * 1.8,
                  height: radius * 0.6),
              math.pi,
              math.pi,
              false,
              stroke);
          return;
        }
        canvas.drawLine(Offset(innerX, base - radius * 0.15),
            Offset(outerX, base + radius * 0.3), stroke);
      case _Brow.raised:
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(c.dx, base), width: radius * 1.5, height: radius * 0.6),
            math.pi * 1.15,
            math.pi * 0.7,
            false,
            stroke);
    }
  }

  void _paintMouth(
      Canvas canvas, _Mouth mouth, double cx, double cy, double r, double w) {
    final mouthPaint = Paint()
      ..color = _ink
      ..strokeWidth = w * 0.035
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (mouth) {
      case _Mouth.smile:
        canvas.drawPath(
          Path()
            ..moveTo(cx - r * 0.34, cy + r * 0.28)
            ..quadraticBezierTo(cx, cy + r * 0.62, cx + r * 0.34, cy + r * 0.28),
          mouthPaint,
        );
      case _Mouth.smallSmile:
        canvas.drawPath(
          Path()
            ..moveTo(cx - r * 0.14, cy + r * 0.36)
            ..quadraticBezierTo(cx, cy + r * 0.48, cx + r * 0.14, cy + r * 0.36),
          mouthPaint,
        );
      case _Mouth.o:
        // open happy "o"
        canvas.drawCircle(Offset(cx, cy + r * 0.34), w * 0.07, mouthPaint);
      case _Mouth.frown:
        // Turned down, so being away actually looks like something.
        canvas.drawPath(
          Path()
            ..moveTo(cx - r * 0.28, cy + r * 0.46)
            ..quadraticBezierTo(cx, cy + r * 0.20, cx + r * 0.28, cy + r * 0.46),
          mouthPaint,
        );
      case _Mouth.grin:
        final grin = Path()
          ..moveTo(cx - r * 0.38, cy + r * 0.26)
          ..lineTo(cx + r * 0.38, cy + r * 0.26)
          ..quadraticBezierTo(cx, cy + r * 0.9, cx - r * 0.38, cy + r * 0.26)
          ..close();
        canvas.drawPath(grin, Paint()..color = _ink);
        canvas.save();
        canvas.clipPath(grin);
        canvas.drawCircle(Offset(cx, cy + r * 0.64), r * 0.2,
            Paint()..color = const Color(0xFFFF6F91));
        canvas.restore();
      case _Mouth.gasp:
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, cy + r * 0.4), width: r * 0.28, height: r * 0.36),
          Paint()..color = _ink,
        );
      case _Mouth.grit:
        final teeth = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy + r * 0.42), width: r * 0.62, height: r * 0.24),
          Radius.circular(r * 0.08),
        );
        canvas.drawRRect(teeth, Paint()..color = Colors.white);
        final thin = Paint()
          ..color = _ink
          ..strokeWidth = w * 0.02
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(cx - r * 0.31, cy + r * 0.42),
            Offset(cx + r * 0.31, cy + r * 0.42), thin);
        for (final dx in [-0.1, 0.1]) {
          canvas.drawLine(Offset(cx + dx * r, cy + r * 0.3),
              Offset(cx + dx * r, cy + r * 0.54), thin);
        }
        canvas.drawRRect(teeth, mouthPaint..strokeWidth = w * 0.025);
      case _Mouth.wavy:
        final wavy = Path()..moveTo(cx - r * 0.32, cy + r * 0.42);
        for (var i = 0; i < 4; i++) {
          final x0 = cx - r * 0.32 + i * r * 0.16;
          wavy.quadraticBezierTo(x0 + r * 0.08,
              cy + r * (i.isEven ? 0.33 : 0.51), x0 + r * 0.16, cy + r * 0.42);
        }
        canvas.drawPath(wavy, mouthPaint);
      case _Mouth.tongue:
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + r * 0.08, cy + r * 0.52),
              width: r * 0.24,
              height: r * 0.3),
          Paint()..color = const Color(0xFFFF6F91),
        );
        canvas.drawLine(Offset(cx + r * 0.08, cy + r * 0.44),
            Offset(cx + r * 0.08, cy + r * 0.58),
            Paint()
              ..color = const Color(0xFFD6406A)
              ..strokeWidth = w * 0.015
              ..strokeCap = StrokeCap.round);
        canvas.drawPath(
          Path()
            ..moveTo(cx - r * 0.34, cy + r * 0.28)
            ..quadraticBezierTo(cx, cy + r * 0.56, cx + r * 0.34, cy + r * 0.28),
          mouthPaint,
        );
      case _Mouth.smirk:
        canvas.drawPath(
          Path()
            ..moveTo(cx - r * 0.3, cy + r * 0.38)
            ..quadraticBezierTo(cx + r * 0.05, cy + r * 0.54, cx + r * 0.34, cy + r * 0.24),
          mouthPaint,
        );
    }
  }

  /// Tears, sweat, hearts and the like floating around the head.
  void _paintReactionExtras(
      Canvas canvas, double cx, double cy, double eyeY, double r, double w) {
    switch (expression) {
      case BuddyExpression.crying:
        final tear = Paint()..color = _tearBlue.withValues(alpha: 0.9);
        final xs = style == BuddyStyle.cyclops ? [-0.3, 0.3] : [-0.5, 0.5];
        for (final dx in xs) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(cx + dx * r - r * 0.07, eyeY + r * 0.12,
                  cx + dx * r + r * 0.07, cy + r * 0.62),
              Radius.circular(r * 0.07),
            ),
            tear,
          );
        }
      case BuddyExpression.scared:
      case BuddyExpression.confused:
        canvas.drawPath(
            _drop(Offset(cx + r * 0.88, cy - r * 0.62), r * 0.2),
            Paint()..color = _tearBlue);
        if (expression == BuddyExpression.confused) {
          _paintQuestionMark(canvas, Offset(cx - r * 1.1, cy - r * 1.05), r * 0.36, w);
        }
      case BuddyExpression.love:
        final p = Paint()..color = _heartPink;
        canvas.drawPath(_heart(Offset(cx + r * 1.1, cy - r * 0.95), r * 0.22), p);
        canvas.drawPath(_heart(Offset(cx - r * 1.12, cy - r * 0.62), r * 0.15), p);
      case BuddyExpression.proud:
      case BuddyExpression.laughing:
        final p = Paint()..color = _gold;
        canvas.drawPath(_sparkle(Offset(cx + r * 1.12, cy - r * 0.9), r * 0.24), p);
        canvas.drawPath(_sparkle(Offset(cx - r * 1.14, cy - r * 0.5), r * 0.15), p);
      case BuddyExpression.angry:
        // Little cross-popping vein.
        final vein = Paint()
          ..color = const Color(0xFFFF3B3B)
          ..strokeWidth = w * 0.025
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final c = Offset(cx + r * 0.95, cy - r * 0.9);
        final s = r * 0.13;
        for (final q in [
          (-1.0, -1.0),
          (1.0, -1.0),
          (1.0, 1.0),
          (-1.0, 1.0),
        ]) {
          canvas.drawArc(
            Rect.fromCircle(
                center: c.translate(q.$1 * s * 1.3, q.$2 * s * 1.3), radius: s),
            math.atan2(-q.$2, -q.$1) - math.pi / 4,
            math.pi / 2,
            false,
            vein,
          );
        }
      case BuddyExpression.dizzy:
        final p = Paint()..color = _gold;
        for (var i = 0; i < 3; i++) {
          final a = math.pi * (1.15 + i * 0.35);
          canvas.drawPath(
            _sparkle(
                Offset(cx + math.cos(a) * r * 0.9, cy - r * 1.05 + math.sin(a) * r * 0.25),
                r * 0.14),
            p,
          );
        }
      case BuddyExpression.surprised:
        final lines = Paint()
          ..color = _ink
          ..strokeWidth = w * 0.022
          ..strokeCap = StrokeCap.round;
        for (final a in [-0.35, 0.0, 0.35]) {
          final dirA = -math.pi / 2 + a;
          final base = Offset(cx + r * 1.0, cy - r * 0.9);
          canvas.drawLine(
            base.translate(math.cos(dirA) * r * 0.1, math.sin(dirA) * r * 0.1),
            base.translate(math.cos(dirA) * r * 0.32, math.sin(dirA) * r * 0.32),
            lines,
          );
        }
      default:
        break;
    }
  }

  void _paintQuestionMark(Canvas canvas, Offset c, double s, double w) {
    final p = Paint()
      ..color = _ink
      ..strokeWidth = w * 0.03
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..addArc(Rect.fromCircle(center: c.translate(0, -s * 0.3), radius: s * 0.35),
            math.pi, math.pi * 1.4)
        ..lineTo(c.dx, c.dy + s * 0.25),
      p,
    );
    canvas.drawCircle(c.translate(0, s * 0.55), w * 0.02, Paint()..color = _ink);
  }

  // ── Accessories & hats ───────────────────────────────────────────────────

  void _paintCape(Canvas canvas, double cx, double cy, double r) {
    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.8, cy - r * 0.3)
        ..quadraticBezierTo(cx - r * 1.3, cy + r * 0.5, cx - r * 1.22, cy + r * 1.08)
        ..lineTo(cx + r * 1.22, cy + r * 1.08)
        ..quadraticBezierTo(cx + r * 1.3, cy + r * 0.5, cx + r * 0.8, cy - r * 0.3)
        ..close(),
      Paint()..color = const Color(0xFFE63946),
    );
  }

  void _paintAccessory(Canvas canvas, Path body, double cx, double cy,
      double eyeY, double r, double w) {
    final cyclops = style == BuddyStyle.cyclops;
    final eyeXs = cyclops ? [cx] : [cx - r * 0.42, cx + r * 0.42];
    final lensR = w * 0.105 * (cyclops ? 1.55 : 1.0) * 1.3;

    switch (accessory) {
      case BuddyAccessory.none:
      case BuddyAccessory.cape: // painted behind the body
        return;
      case BuddyAccessory.glasses:
        final frame = Paint()
          ..color = _ink
          ..strokeWidth = w * 0.028
          ..style = PaintingStyle.stroke;
        for (final x in eyeXs) {
          canvas.drawCircle(Offset(x, eyeY), lensR,
              Paint()..color = Colors.white.withValues(alpha: 0.18));
          canvas.drawCircle(Offset(x, eyeY), lensR, frame);
        }
        if (!cyclops) {
          canvas.drawLine(Offset(eyeXs[0] + lensR, eyeY),
              Offset(eyeXs[1] - lensR, eyeY), frame);
        }
      case BuddyAccessory.sunglasses:
        final lens = Paint()..color = const Color(0xFF1E1A2E);
        for (final x in eyeXs) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(x, eyeY + lensR * 0.1),
                  width: lensR * 2.1,
                  height: lensR * 1.5),
              Radius.circular(lensR * 0.55),
            ),
            lens,
          );
          canvas.drawLine(
            Offset(x - lensR * 0.55, eyeY - lensR * 0.25),
            Offset(x - lensR * 0.1, eyeY - lensR * 0.45),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.7)
              ..strokeWidth = w * 0.018
              ..strokeCap = StrokeCap.round,
          );
        }
        if (!cyclops) {
          canvas.drawLine(
            Offset(eyeXs[0], eyeY - lensR * 0.35),
            Offset(eyeXs[1], eyeY - lensR * 0.35),
            Paint()
              ..color = const Color(0xFF1E1A2E)
              ..strokeWidth = w * 0.03,
          );
        }
      case BuddyAccessory.bowtie:
        final c = Offset(cx, cy + r * 0.8);
        final tie = Paint()..color = _heartPink;
        for (final dir in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(c.dx, c.dy)
              ..lineTo(c.dx + dir * r * 0.32, c.dy - r * 0.16)
              ..lineTo(c.dx + dir * r * 0.32, c.dy + r * 0.16)
              ..close(),
            tie,
          );
        }
        canvas.drawCircle(c, r * 0.08, Paint()..color = const Color(0xFFD6334F));
      case BuddyAccessory.scarf:
        const scarfColor = Color(0xFFFF6B35);
        final stripe = Paint()..color = Colors.white.withValues(alpha: 0.85);
        canvas.save();
        canvas.clipPath(body);
        final band = Rect.fromLTRB(cx - r * 1.1, cy + r * 0.62, cx + r * 1.1, cy + r * 0.86);
        canvas.drawRect(band, Paint()..color = scarfColor);
        for (var x = band.left + r * 0.1; x < band.right; x += r * 0.3) {
          canvas.drawRect(
              Rect.fromLTWH(x, band.top, r * 0.08, band.height), stripe);
        }
        canvas.restore();
        final tail = Rect.fromLTWH(cx + r * 0.35, cy + r * 0.74, r * 0.24, r * 0.46);
        canvas.drawRRect(
            RRect.fromRectAndRadius(tail, Radius.circular(r * 0.06)),
            Paint()..color = scarfColor);
        canvas.drawRect(
            Rect.fromLTWH(tail.left, tail.bottom - r * 0.12, tail.width, r * 0.06),
            stripe);
      case BuddyAccessory.medal:
        final ribbon = Paint()
          ..color = const Color(0xFF3FA7F5)
          ..strokeWidth = w * 0.04
          ..strokeCap = StrokeCap.round;
        final c = Offset(cx, cy + r * 0.8);
        canvas.drawLine(Offset(cx - r * 0.3, cy + r * 0.6), c, ribbon);
        canvas.drawLine(Offset(cx + r * 0.3, cy + r * 0.6), c, ribbon);
        canvas.drawCircle(c, r * 0.18, Paint()..color = const Color(0xFFE0A91F));
        canvas.drawCircle(c, r * 0.13, Paint()..color = _gold);
        canvas.drawPath(_sparkle(c, r * 0.1), Paint()..color = Colors.white);
    }
  }

  /// Hats sit on the crown of the head, drawn after the body so they overlap
  /// it rather than being swallowed by it.
  void _paintHat(Canvas canvas, double cx, double cy, double r, double w) {
    if (hat == BuddyHat.none) return;
    final top = cy - r * 0.98;
    final fill = Paint()..style = PaintingStyle.fill;

    switch (hat) {
      case BuddyHat.none:
        return;

      case BuddyHat.bow:
        fill.color = const Color(0xFFFF5DA2);
        final left = Path()
          ..moveTo(cx, top + r * 0.06)
          ..lineTo(cx - r * 0.42, top - r * 0.18)
          ..lineTo(cx - r * 0.42, top + r * 0.28)
          ..close();
        final right = Path()
          ..moveTo(cx, top + r * 0.06)
          ..lineTo(cx + r * 0.42, top - r * 0.18)
          ..lineTo(cx + r * 0.42, top + r * 0.28)
          ..close();
        canvas.drawPath(left, fill);
        canvas.drawPath(right, fill);
        canvas.drawCircle(Offset(cx, top + r * 0.06), w * 0.05,
            Paint()..color = const Color(0xFFD6407F));

      case BuddyHat.cap:
        fill.color = const Color(0xFF3FA7F5);
        canvas.drawArc(
          Rect.fromCenter(
              center: Offset(cx, top + r * 0.12),
              width: r * 1.5,
              height: r * 1.1),
          3.14159,
          3.14159,
          true,
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - r * 0.1, top + r * 0.02, r * 1.0, r * 0.18),
            Radius.circular(r * 0.09),
          ),
          Paint()..color = const Color(0xFF2B7FC4),
        );

      case BuddyHat.party:
        fill.color = const Color(0xFFFFC93C);
        final cone = Path()
          ..moveTo(cx, top - r * 0.72)
          ..lineTo(cx - r * 0.44, top + r * 0.16)
          ..lineTo(cx + r * 0.44, top + r * 0.16)
          ..close();
        canvas.drawPath(cone, fill);
        canvas.drawCircle(Offset(cx, top - r * 0.72), w * 0.055,
            Paint()..color = const Color(0xFFFF5DA2));

      case BuddyHat.crown:
        fill.color = const Color(0xFFFFD24A);
        final crown = Path()
          ..moveTo(cx - r * 0.5, top + r * 0.2)
          ..lineTo(cx - r * 0.5, top - r * 0.34)
          ..lineTo(cx - r * 0.22, top - r * 0.02)
          ..lineTo(cx, top - r * 0.44)
          ..lineTo(cx + r * 0.22, top - r * 0.02)
          ..lineTo(cx + r * 0.5, top - r * 0.34)
          ..lineTo(cx + r * 0.5, top + r * 0.2)
          ..close();
        canvas.drawPath(crown, fill);
        canvas.drawCircle(Offset(cx, top - r * 0.44), w * 0.032,
            Paint()..color = const Color(0xFFFF5DA2));

      case BuddyHat.wizard:
        fill.color = const Color(0xFF7C5CFF);
        final cone = Path()
          ..moveTo(cx + r * 0.12, top - r * 0.95)
          ..lineTo(cx - r * 0.5, top + r * 0.14)
          ..lineTo(cx + r * 0.5, top + r * 0.14)
          ..close();
        canvas.drawPath(cone, fill);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, top + r * 0.18),
                width: r * 1.35,
                height: r * 0.2),
            Radius.circular(r * 0.1),
          ),
          Paint()..color = const Color(0xFF5A3FD6),
        );
        canvas.drawCircle(Offset(cx - r * 0.06, top - r * 0.36), w * 0.028,
            Paint()..color = const Color(0xFFFFD24A));
        canvas.drawCircle(Offset(cx + r * 0.14, top - r * 0.66), w * 0.02,
            Paint()..color = const Color(0xFFFFD24A));

      case BuddyHat.beanie:
        fill.color = AppColors.punchTeal;
        canvas.drawArc(
          Rect.fromCenter(
              center: Offset(cx, top + r * 0.2), width: r * 1.4, height: r * 1.3),
          math.pi,
          math.pi,
          true,
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, top + r * 0.2), width: r * 1.5, height: r * 0.26),
            Radius.circular(r * 0.12),
          ),
          Paint()..color = const Color(0xFF00957F),
        );
        canvas.drawCircle(Offset(cx, top - r * 0.5), r * 0.14,
            Paint()..color = Colors.white);

      case BuddyHat.flower:
        final c = Offset(cx + r * 0.42, top + r * 0.08);
        final petal = Paint()..color = const Color(0xFFFF7FB0);
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * 2 * math.pi / 5;
          canvas.drawCircle(
              c.translate(math.cos(a) * r * 0.17, math.sin(a) * r * 0.17),
              r * 0.13,
              petal);
        }
        canvas.drawCircle(c, r * 0.1, Paint()..color = _gold);

      case BuddyHat.headphones:
        canvas.drawArc(
          Rect.fromCenter(
              center: Offset(cx, cy - r * 0.05), width: r * 2.2, height: r * 2.2),
          math.pi * 1.02,
          math.pi * 0.96,
          false,
          Paint()
            ..color = _ink
            ..strokeWidth = w * 0.05
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
        for (final dir in [-1.0, 1.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx + dir * r * 1.02, cy - r * 0.08),
                  width: r * 0.32,
                  height: r * 0.54),
              Radius.circular(r * 0.14),
            ),
            Paint()..color = AppColors.punchPink,
          );
        }

      case BuddyHat.pirate:
        final bicorne = Path()
          ..moveTo(cx - r * 0.8, top + r * 0.2)
          ..quadraticBezierTo(cx, top - r * 0.95, cx + r * 0.8, top + r * 0.2)
          ..quadraticBezierTo(cx, top - r * 0.02, cx - r * 0.8, top + r * 0.2)
          ..close();
        canvas.drawPath(bicorne, Paint()..color = _ink);
        canvas.drawPath(
          Path()
            ..moveTo(cx - r * 0.72, top + r * 0.14)
            ..quadraticBezierTo(cx, top - r * 0.08, cx + r * 0.72, top + r * 0.14),
          Paint()
            ..color = _gold
            ..strokeWidth = w * 0.02
            ..style = PaintingStyle.stroke,
        );
        // Skull
        canvas.drawCircle(Offset(cx, top - r * 0.26), r * 0.12,
            Paint()..color = Colors.white);
        for (final dx in [-0.045, 0.045]) {
          canvas.drawCircle(Offset(cx + dx * r, top - r * 0.27), r * 0.03,
              Paint()..color = _ink);
        }

      case BuddyHat.halo:
        final ring = Rect.fromCenter(
            center: Offset(cx, top - r * 0.38), width: r * 1.15, height: r * 0.32);
        canvas.drawOval(
          ring,
          Paint()
            ..color = _gold.withValues(alpha: 0.35)
            ..strokeWidth = w * 0.07
            ..style = PaintingStyle.stroke,
        );
        canvas.drawOval(
          ring,
          Paint()
            ..color = _gold
            ..strokeWidth = w * 0.03
            ..style = PaintingStyle.stroke,
        );
    }
  }

  // ── Shapes ───────────────────────────────────────────────────────────────

  static Path _heart(Offset c, double s) => Path()
    ..moveTo(c.dx, c.dy + s * 0.75)
    ..cubicTo(c.dx - s * 1.3, c.dy - s * 0.1, c.dx - s * 0.55, c.dy - s * 1.05,
        c.dx, c.dy - s * 0.35)
    ..cubicTo(c.dx + s * 0.55, c.dy - s * 1.05, c.dx + s * 1.3, c.dy - s * 0.1,
        c.dx, c.dy + s * 0.75)
    ..close();

  static Path _sparkle(Offset c, double s) => Path()
    ..moveTo(c.dx, c.dy - s)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s)
    ..close();

  static Path _drop(Offset c, double s) => Path()
    ..moveTo(c.dx, c.dy - s)
    ..quadraticBezierTo(c.dx + s * 0.75, c.dy + s * 0.1, c.dx + s * 0.55, c.dy + s * 0.5)
    ..arcToPoint(Offset(c.dx - s * 0.55, c.dy + s * 0.5),
        radius: Radius.circular(s * 0.6))
    ..quadraticBezierTo(c.dx - s * 0.75, c.dy + s * 0.1, c.dx, c.dy - s)
    ..close();

  @override
  bool shouldRepaint(_BuddyPainter old) =>
      old.wave != wave ||
      old.variant != variant ||
      old.antennaColor != antennaColor ||
      old.hat != hat ||
      old.mood != mood ||
      old.expression != expression ||
      old.style != style ||
      old.accessory != accessory ||
      old.bodyColor != bodyColor ||
      old.cheekColor != cheekColor;
}
