import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/story_library.dart';
import '../models/story_sounds.dart';
import '../services/sound_service.dart';

/// Draws one [StoryShot]: a living backdrop with its actors on top.
///
/// Everything runs off a single 30 s clock. Drifting things (clouds, rain,
/// bubbles) move a whole number of widths per loop so the wrap is seamless;
/// bobbing actors cycle every two seconds.
///
/// When [interactive], tapping an actor makes it jump with a sparkle and plays
/// its sound. Until the first tap, a soft ring pulses around one actor so a
/// child knows the page can be touched.
class StoryStage extends StatefulWidget {
  final StoryShot shot;
  final bool interactive;
  const StoryStage({super.key, required this.shot, this.interactive = true});

  @override
  State<StoryStage> createState() => _StoryStageState();
}

class _StoryStageState extends State<StoryStage> with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 30));

  /// When each actor (by index) was last tapped.
  final Map<int, DateTime> _pokes = {};
  bool _touched = false;

  static const _pokeLength = Duration(milliseconds: 700);

  double _pokeOf(int index) {
    final at = _pokes[index];
    if (at == null) return -1;
    final p = DateTime.now().difference(at).inMilliseconds / _pokeLength.inMilliseconds;
    return p >= 1 ? -1 : p;
  }

  @override
  void didUpdateWidget(StoryStage old) {
    super.didUpdateWidget(old);
    if (old.shot != widget.shot) {
      _pokes.clear();
      _touched = false;
    }
  }

  void _onTap(Offset local, Size size) {
    final index = storyActorAt(widget.shot, local, size);
    if (index == null) return;
    final actor = widget.shot.actors[index].actor;
    setState(() {
      _pokes[index] = DateTime.now();
      _touched = true;
    });
    SoundService.instance.storySfx(storyActorSfx(actor));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = RepaintBoundary(
      child: CustomPaint(
        painter: StoryStagePainter(
          widget.shot,
          _clock,
          pokeOf: widget.interactive ? _pokeOf : null,
          hint: widget.interactive && !_touched,
        ),
        child: const SizedBox.expand(),
      ),
    );
    if (!widget.interactive) return stage;
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (d) => _onTap(d.localPosition, constraints.biggest),
        child: stage,
      ),
    );
  }
}

class StoryStagePainter extends CustomPainter {
  final StoryShot shot;
  final Animation<double>? clock;

  /// A fixed time for still renders (tests, previews).
  final double fixedT;

  /// Tap-reaction progress per actor index: 0..1 while reacting, else < 0.
  final double Function(int index)? pokeOf;

  /// Pulse a ring around the hint actor to invite a first tap.
  final bool hint;

  StoryStagePainter(this.shot, this.clock, {this.fixedT = 0, this.pokeOf, this.hint = false})
      : super(repaint: clock);

  double get t => clock?.value ?? fixedT;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final lights = <void Function()>[];
    final hasMoon = shot.actors.any((a) => a.actor == StoryActor.moon);
    final bd = _Backdrop(canvas, size, t, shot.night, lights, moon: !hasMoon);
    bd.paint(shot.backdrop);

    if (shot.night && shot.backdrop != StoryBackdrop.space && shot.backdrop != StoryBackdrop.underwater) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0B1030).withValues(alpha: 0.32));
    }
    for (final light in lights) {
      light();
    }
    if (shot.rain) bd.rain();

    final u = math.min(size.width, size.height);
    final hintIndex = hint ? storyHintActor(shot) : null;
    for (var i = 0; i < shot.actors.length; i++) {
      final spot = shot.actors[i];
      // Authored sizes read a touch small on a phone page; scale them up evenly.
      final s = spot.size * u * 1.2;
      final phase = t * 2 * math.pi * 15 + i * 1.3;
      var dx = 0.0, dy = 0.0, rot = 0.0;
      switch (spot.motion) {
        case StoryMotion.still:
          break;
        case StoryMotion.bob:
          dy = math.sin(phase) * u * 0.008;
        case StoryMotion.sway:
          rot = math.sin(phase) * 0.07;
        case StoryMotion.float:
          dy = math.sin(phase) * u * 0.022;
        case StoryMotion.hop:
          dy = -math.sin(phase).abs() * u * 0.035;
        case StoryMotion.fly:
          dx = math.sin(phase * 0.5) * u * 0.03;
          dy = math.cos(phase) * u * 0.02;
      }
      final poke = pokeOf?.call(i) ?? -1;
      var sx = 1.0, sy = 1.0;
      if (poke >= 0) {
        final decay = 1 - poke;
        dy -= math.sin(math.pi * math.min(poke * 1.6, 1)) * u * 0.07;
        sx = 1 + 0.14 * math.sin(2 * math.pi * poke) * decay;
        sy = 1 - 0.14 * math.sin(2 * math.pi * poke) * decay;
      }
      final centre = Offset(spot.x * size.width, spot.y * size.height);

      if (i == hintIndex) {
        final pulse = (t * 15 / 2) % 1.0; // one ring every four seconds
        final bounds = storyActorBounds(spot, u).shift(centre);
        final r = math.max(bounds.width, bounds.height) * (0.45 + 0.25 * pulse);
        canvas.drawCircle(
          bounds.center,
          r,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55 * (1 - pulse))
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.012,
        );
      }

      canvas.save();
      canvas.translate(centre.dx + dx, centre.dy + dy);
      if (rot != 0) canvas.rotate(rot);
      if (sx != 1 || sy != 1) canvas.scale(sx, sy);
      if (spot.flip) canvas.scale(-1, 1);
      _Actors(canvas, s, spot.feel, spot.tint == null ? null : Color(spot.tint!), phase)
          .paint(spot.actor);
      canvas.restore();

      if (poke >= 0) _sparkles(canvas, centre.translate(dx, dy), s, poke);
    }
    canvas.restore();
  }

  void _sparkles(Canvas canvas, Offset centre, double s, double p) {
    const colors = [Color(0xFFFFD24A), Color(0xFFFF7AA2), Color(0xFF7CE0FF), Colors.white];
    final alpha = 1 - p;
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4 + 0.3;
      final d = s * (0.35 + 0.55 * p);
      final o = centre.translate(math.cos(a) * d, math.sin(a) * d * 0.8 - s * 0.1);
      final r = s * 0.06 * (1 - p * 0.5);
      final path = Path()
        ..moveTo(o.dx, o.dy - r * 1.6)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + r * 1.6, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r * 1.6)
        ..quadraticBezierTo(o.dx, o.dy, o.dx - r * 1.6, o.dy)
        ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r * 1.6)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[k % colors.length].withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(StoryStagePainter old) =>
      old.shot != shot || old.fixedT != fixedT || old.hint != hint || old.pokeOf != pokeOf;
}

/// The actor to hint at: the largest one that is a character or object, not
/// scenery like the sun, clouds or a rainbow.
int? storyHintActor(StoryShot shot) {
  const scenery = {StoryActor.sun, StoryActor.cloud, StoryActor.rainbow, StoryActor.heart, StoryActor.star, StoryActor.fireworks};
  int? best;
  for (var i = 0; i < shot.actors.length; i++) {
    if (scenery.contains(shot.actors[i].actor)) continue;
    if (best == null || shot.actors[i].size > shot.actors[best].size) best = i;
  }
  return best ?? (shot.actors.isEmpty ? null : 0);
}

/// An actor's tappable area relative to its centre, for a page whose short
/// side is [u]. Generous on purpose: small fingers, small targets.
Rect storyActorBounds(StorySpot spot, double u) {
  final s = spot.size * u * 1.2;
  Rect r = switch (spot.actor) {
    StoryActor.crocodile => Rect.fromLTRB(-2.6 * s, -0.8 * s, 2.6 * s, 0.5 * s),
    StoryActor.caterpillar => Rect.fromLTRB(-1.8 * s, -0.7 * s, 0.45 * s, 0.5 * s),
    StoryActor.rainbow => Rect.fromLTRB(-1.4 * s, -0.9 * s, 1.4 * s, 0.5 * s),
    StoryActor.toyCar => Rect.fromLTRB(-0.8 * s, -0.5 * s, 0.8 * s, 0.5 * s),
    StoryActor.ant || StoryActor.grasshopper || StoryActor.kancil => Rect.fromLTRB(-0.6 * s, -0.55 * s, 0.7 * s, 0.5 * s),
    _ => Rect.fromLTRB(-0.55 * s, -0.55 * s, 0.55 * s, 0.55 * s),
  };
  if (spot.flip) r = Rect.fromLTRB(-r.right, r.top, -r.left, r.bottom);
  final minSide = 44.0;
  if (r.width < minSide || r.height < minSide) {
    r = Rect.fromCenter(center: r.center, width: math.max(r.width, minSide), height: math.max(r.height, minSide));
  }
  return r;
}

/// Index of the actor under [point], preferring the smallest target when
/// several overlap so a heart in front of a rainbow stays reachable.
int? storyActorAt(StoryShot shot, Offset point, Size size) {
  final u = math.min(size.width, size.height);
  int? hit;
  double hitArea = double.infinity;
  for (var i = 0; i < shot.actors.length; i++) {
    final spot = shot.actors[i];
    final bounds = storyActorBounds(spot, u).shift(Offset(spot.x * size.width, spot.y * size.height));
    if (!bounds.contains(point)) continue;
    final area = bounds.width * bounds.height;
    if (area <= hitArea) {
      hit = i;
      hitArea = area;
    }
  }
  return hit;
}

Paint _fill(Color c) => Paint()..color = c;

Paint _line(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

const _ink = Color(0xFF2B2440);

// ══════════════════════════════════════════════════════════════════════════
// BACKDROPS
// ══════════════════════════════════════════════════════════════════════════

class _Backdrop {
  final Canvas c;
  final Size size;
  final double t;
  final bool night;
  final List<void Function()> lights;

  /// False when the page already has a moon actor.
  final bool moon;

  _Backdrop(this.c, this.size, this.t, this.night, this.lights, {this.moon = true});

  double get w => size.width;
  double get h => size.height;
  double get u => math.min(w, h);

  void paint(StoryBackdrop b) {
    switch (b) {
      case StoryBackdrop.kampung:
        _kampung();
      case StoryBackdrop.home:
        _home();
      case StoryBackdrop.school:
        _school();
      case StoryBackdrop.market:
        _market();
      case StoryBackdrop.garden:
        _garden();
      case StoryBackdrop.field:
        _field();
      case StoryBackdrop.rainforest:
        _rainforest();
      case StoryBackdrop.river:
        _river();
      case StoryBackdrop.beach:
        _beach();
      case StoryBackdrop.sea:
        _sea();
      case StoryBackdrop.underwater:
        _underwater();
      case StoryBackdrop.sky:
        _highSky();
      case StoryBackdrop.space:
        _space();
    }
  }

  void _gradient(Rect r, List<Color> colors) {
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(r),
    );
  }

  /// Sky down to [bottom] (fraction of height), with sun/moon, clouds or stars.
  void _sky(double bottom, {bool clouds = true}) {
    final r = Rect.fromLTWH(0, 0, w, h * bottom + 1);
    if (night) {
      _gradient(r, const [Color(0xFF0B1638), Color(0xFF2E3F82)]);
      _stars(bottom, 26);
      if (moon) {
        final m = Offset(w * 0.84, h * 0.1);
        c.drawCircle(m, u * 0.09, _fill(const Color(0xFFFFF3B0).withValues(alpha: 0.18)));
        c.drawCircle(m, u * 0.05, _fill(const Color(0xFFFFF3B0)));
      }
    } else {
      _gradient(r, const [Color(0xFF6EC3F4), Color(0xFFD4F1FF)]);
      if (clouds) _clouds(bottom * 0.6, 3);
    }
  }

  void _stars(double bottom, int n) {
    final rng = math.Random(7);
    for (var i = 0; i < n; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h * bottom * 0.9;
      final tw = 0.5 + 0.5 * math.sin(t * 2 * math.pi * 8 + i);
      c.drawCircle(Offset(x, y), u * (0.004 + rng.nextDouble() * 0.004),
          _fill(Colors.white.withValues(alpha: 0.35 + 0.6 * tw)));
    }
  }

  void _cloudShape(Offset o, double s, Color color) {
    final p = _fill(color);
    c.drawCircle(o, s * 0.5, p);
    c.drawCircle(o.translate(-s * 0.55, s * 0.15), s * 0.36, p);
    c.drawCircle(o.translate(s * 0.55, s * 0.12), s * 0.4, p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(o.dx - s * 0.9, o.dy, o.dx + s * 0.95, o.dy + s * 0.5), Radius.circular(s * 0.25)),
        p);
  }

  void _clouds(double maxY, int n, {Color color = Colors.white}) {
    for (var i = 0; i < n; i++) {
      final base = i / n;
      final x = ((base + t) % 1.0) * (w * 1.4) - w * 0.2;
      final y = h * maxY * (0.35 + 0.5 * ((i * 37) % 10) / 10);
      _cloudShape(Offset(x, y), u * (0.09 + 0.03 * (i % 2)), color.withValues(alpha: 0.9));
    }
  }

  void _ground(double top, Color a, Color b) {
    _gradient(Rect.fromLTWH(0, h * top, w, h * (1 - top)), [a, b]);
  }

  void _hills(double top, Color color) {
    final path = Path()..moveTo(0, h * top + u * 0.06);
    for (var i = 0; i <= 4; i++) {
      final x = w * i / 4;
      path.quadraticBezierTo(x - w * 0.125, h * top - u * (i.isEven ? 0.08 : 0.02), x, h * top + u * 0.02);
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(path, _fill(color));
  }

  void _coconutTree(Offset base, double s) {
    final trunk = Path()
      ..moveTo(base.dx - s * 0.04, base.dy)
      ..quadraticBezierTo(base.dx + s * 0.1, base.dy - s * 0.5, base.dx + s * 0.02, base.dy - s)
      ..lineTo(base.dx + s * 0.08, base.dy - s)
      ..quadraticBezierTo(base.dx + s * 0.16, base.dy - s * 0.5, base.dx + s * 0.04, base.dy)
      ..close();
    c.drawPath(trunk, _fill(const Color(0xFF8B5E3C)));
    final top = Offset(base.dx + s * 0.05, base.dy - s);
    final sway = math.sin(t * 2 * math.pi * 10) * 0.06;
    for (var i = 0; i < 6; i++) {
      final a = -math.pi + i * math.pi / 5 + sway;
      final tip = top.translate(math.cos(a) * s * 0.42, math.sin(a) * s * 0.28 + s * 0.12);
      final frond = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo((top.dx + tip.dx) / 2, top.dy - s * 0.14, tip.dx, tip.dy)
        ..quadraticBezierTo((top.dx + tip.dx) / 2, top.dy - s * 0.02, top.dx, top.dy);
      c.drawPath(frond, _fill(const Color(0xFF2E8B57)));
    }
    c.drawCircle(top.translate(-s * 0.02, s * 0.04), s * 0.035, _fill(const Color(0xFF6B4226)));
    c.drawCircle(top.translate(s * 0.05, s * 0.05), s * 0.035, _fill(const Color(0xFF6B4226)));
  }

  void _roundTree(Offset base, double s, {Color leaf = const Color(0xFF3FA34D)}) {
    c.drawRect(Rect.fromCenter(center: base.translate(0, -s * 0.2), width: s * 0.12, height: s * 0.4),
        _fill(const Color(0xFF7A5230)));
    c.drawCircle(base.translate(0, -s * 0.55), s * 0.32, _fill(leaf));
    c.drawCircle(base.translate(-s * 0.2, -s * 0.42), s * 0.22, _fill(leaf));
    c.drawCircle(base.translate(s * 0.22, -s * 0.44), s * 0.22, _fill(leaf));
    c.drawCircle(base.translate(-s * 0.08, -s * 0.66), s * 0.12, _fill(Colors.white.withValues(alpha: 0.12)));
  }

  void _flower(Offset o, double r, Color color) {
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5;
      c.drawCircle(o.translate(math.cos(a) * r, math.sin(a) * r), r * 0.75, _fill(color));
    }
    c.drawCircle(o, r * 0.6, _fill(const Color(0xFFFFD24A)));
  }

  void _window(Rect r, {bool lit = false}) {
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.1)),
        _fill(night ? const Color(0xFF1E2A55) : const Color(0xFFBDE7FF)));
    if (night && lit) {
      lights.add(() {
        c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.1)), _fill(const Color(0xFFFFD27A)));
        c.drawCircle(r.center, r.width, _fill(const Color(0xFFFFD27A).withValues(alpha: 0.12)));
      });
    }
    c.drawLine(r.topCenter, r.bottomCenter, _line(const Color(0xFF6B4226), r.width * 0.08));
  }

  // ── Scenes ──────────────────────────────────────────────────────────────

  void _kampung() {
    _sky(0.6);
    _hills(0.5, const Color(0xFF7CC47F));
    _ground(0.6, const Color(0xFF8BD17C), const Color(0xFF5DAA55));
    // Kampung house on stilts.
    final hx = w * 0.72, hy = h * 0.5, hs = u * 0.42;
    for (final dx in [-0.36, -0.1, 0.16, 0.36]) {
      c.drawRect(Rect.fromLTWH(hx + dx * hs, hy, hs * 0.05, hs * 0.26), _fill(const Color(0xFF6B4226)));
    }
    final wall = Rect.fromCenter(center: Offset(hx, hy - hs * 0.14), width: hs * 0.86, height: hs * 0.36);
    c.drawRect(wall, _fill(const Color(0xFFB9824F)));
    for (var i = 1; i < 6; i++) {
      final y = wall.top + wall.height * i / 6;
      c.drawLine(Offset(wall.left, y), Offset(wall.right, y), _line(const Color(0xFF9A6A3C), hs * 0.006));
    }
    final roof = Path()
      ..moveTo(wall.left - hs * 0.1, wall.top + hs * 0.02)
      ..lineTo(hx, wall.top - hs * 0.3)
      ..lineTo(wall.right + hs * 0.1, wall.top + hs * 0.02)
      ..close();
    c.drawPath(roof, _fill(const Color(0xFF9C3D2E)));
    _window(Rect.fromCenter(center: Offset(hx - hs * 0.2, wall.center.dy), width: hs * 0.16, height: hs * 0.16), lit: true);
    _window(Rect.fromCenter(center: Offset(hx + hs * 0.2, wall.center.dy), width: hs * 0.16, height: hs * 0.16), lit: true);
    // Stairs
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(hx - hs * 0.62 + i * hs * 0.05, hy + hs * 0.24 - i * hs * 0.07, hs * 0.18, hs * 0.03),
          _fill(const Color(0xFF7A5230)));
    }
    _coconutTree(Offset(w * 0.12, h * 0.62), u * 0.5);
  }

  void _home() {
    final wallColor = night ? const Color(0xFFE9C9A8) : const Color(0xFFFFE6C7);
    _gradient(Rect.fromLTWH(0, 0, w, h * 0.66), [wallColor, Color.lerp(wallColor, const Color(0xFFD9A873), 0.4)!]);
    // Window to outside.
    final win = Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.32, h * 0.26);
    c.save();
    c.clipRect(win);
    _gradient(win, night ? const [Color(0xFF0B1638), Color(0xFF2E3F82)] : const [Color(0xFF6EC3F4), Color(0xFFD4F1FF)]);
    if (night) {
      c.drawCircle(win.topRight.translate(-win.width * 0.3, win.height * 0.3), win.width * 0.1, _fill(const Color(0xFFFFF3B0)));
    } else {
      _cloudShape(win.center, win.width * 0.16, Colors.white);
    }
    c.restore();
    c.drawRect(win, _line(const Color(0xFF8B5E3C), u * 0.02));
    c.drawLine(win.topCenter, win.bottomCenter, _line(const Color(0xFF8B5E3C), u * 0.012));
    // Curtains
    for (final left in [true, false]) {
      final x = left ? win.left : win.right;
      final dir = left ? -1.0 : 1.0;
      c.drawPath(
          Path()
            ..moveTo(x, win.top - u * 0.02)
            ..lineTo(x + dir * u * 0.07, win.top - u * 0.02)
            ..quadraticBezierTo(x + dir * u * 0.02, win.center.dy, x + dir * u * 0.06, win.bottom + u * 0.03)
            ..lineTo(x, win.bottom + u * 0.03)
            ..close(),
          _fill(const Color(0xFFE85D75)));
    }
    // Picture frame
    final frame = Rect.fromLTWH(w * 0.62, h * 0.14, w * 0.22, h * 0.14);
    c.drawRect(frame, _fill(const Color(0xFF9EDCA0)));
    c.drawRect(frame, _line(const Color(0xFFB8860B), u * 0.015));
    c.drawCircle(frame.center.translate(frame.width * 0.2, -frame.height * 0.15), frame.height * 0.14, _fill(const Color(0xFFFFD24A)));
    // Lamp glow at night.
    if (night) {
      lights.add(() {
        final glow = Rect.fromCircle(center: Offset(w * 0.5, 0), radius: u * 0.7);
        c.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFFFD27A).withValues(alpha: 0.22),
              const Color(0xFFFFD27A).withValues(alpha: 0),
            ]).createShader(glow),
        );
      });
    }
    // Wooden floor.
    _ground(0.66, const Color(0xFFC08A55), const Color(0xFF9A6A3C));
    for (var i = 1; i < 6; i++) {
      final x = w * i / 6;
      c.drawLine(Offset(x, h * 0.66), Offset(x - w * 0.1, h), _line(const Color(0xFF8B5E3C), u * 0.004));
    }
    c.drawRect(Rect.fromLTWH(0, h * 0.64, w, h * 0.025), _fill(const Color(0xFF8B5E3C)));
  }

  void _school() {
    _sky(0.6);
    _ground(0.6, const Color(0xFF8BD17C), const Color(0xFF5DAA55));
    final b = Rect.fromLTWH(w * 0.08, h * 0.24, w * 0.84, h * 0.36);
    c.drawRect(b, _fill(const Color(0xFFF5F0E6)));
    c.drawRect(Rect.fromLTWH(b.left, b.top + b.height * 0.48, b.width, b.height * 0.06), _fill(const Color(0xFF3FA7F5)));
    c.drawRect(Rect.fromLTWH(b.left - w * 0.02, b.top - h * 0.03, b.width + w * 0.04, h * 0.04), _fill(const Color(0xFF2B7FC4)));
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 5; col++) {
        _window(Rect.fromLTWH(b.left + b.width * (0.06 + col * 0.19), b.top + b.height * (0.12 + row * 0.5),
            b.width * 0.12, b.height * 0.26));
      }
    }
    // Flag pole with a simple striped flag.
    final px = w * 0.9;
    c.drawLine(Offset(px, h * 0.62), Offset(px, h * 0.08), _line(const Color(0xFF9AA5B8), u * 0.012));
    final wave = math.sin(t * 2 * math.pi * 15) * u * 0.01;
    final flag = Rect.fromLTWH(px - u * 0.16, h * 0.08, u * 0.16, u * 0.1);
    c.save();
    c.translate(0, wave * 0.3);
    for (var i = 0; i < 6; i++) {
      c.drawRect(Rect.fromLTWH(flag.left, flag.top + flag.height * i / 6, flag.width, flag.height / 12),
          _fill(const Color(0xFFE3342F)));
    }
    c.drawRect(Rect.fromLTWH(flag.left, flag.top, flag.width * 0.45, flag.height * 0.55), _fill(const Color(0xFF1F3A93)));
    c.drawCircle(Offset(flag.left + flag.width * 0.2, flag.top + flag.height * 0.27), flag.height * 0.14, _fill(const Color(0xFFFFD24A)));
    c.restore();
    // Fence
    for (var x = 0.0; x < w; x += w / 12) {
      c.drawRect(Rect.fromLTWH(x, h * 0.6, w * 0.015, h * 0.06), _fill(Colors.white));
    }
    c.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.012), _fill(Colors.white));
  }

  void _market() {
    _sky(0.5, clouds: false);
    _ground(0.6, const Color(0xFF6D6A75), const Color(0xFF4E4B57));
    const awnings = [Color(0xFFE74C3C), Color(0xFF3FA7F5), Color(0xFFFFB020)];
    for (var i = 0; i < 3; i++) {
      final left = w * (0.02 + i * 0.33);
      final sw = w * 0.3;
      final top = h * 0.3;
      // Posts and table
      c.drawRect(Rect.fromLTWH(left + sw * 0.05, top, sw * 0.04, h * 0.3), _fill(const Color(0xFF8B8B99)));
      c.drawRect(Rect.fromLTWH(left + sw * 0.91, top, sw * 0.04, h * 0.3), _fill(const Color(0xFF8B8B99)));
      c.drawRect(Rect.fromLTWH(left, h * 0.46, sw, h * 0.1), _fill(const Color(0xFFE8D8B8)));
      // Goods on the table
      for (var g = 0; g < 4; g++) {
        c.drawCircle(Offset(left + sw * (0.18 + g * 0.21), h * 0.45), sw * 0.07,
            _fill([const Color(0xFFFF9F43), const Color(0xFF7ED957), const Color(0xFFFF6B81), const Color(0xFFFFD24A)][(g + i) % 4]));
      }
      // Striped awning
      final stripes = 6;
      for (var sI = 0; sI < stripes; sI++) {
        final x0 = left + sw * sI / stripes;
        c.drawPath(
          Path()
            ..moveTo(x0, top)
            ..lineTo(x0 + sw / stripes, top)
            ..lineTo(x0 + sw / stripes, top + h * 0.06)
            ..quadraticBezierTo(x0 + sw / stripes / 2, top + h * 0.09, x0, top + h * 0.06)
            ..close(),
          _fill(sI.isEven ? awnings[i] : Colors.white),
        );
      }
      c.drawPath(
          Path()
            ..moveTo(left - sw * 0.02, top)
            ..lineTo(left + sw * 0.5, top - h * 0.07)
            ..lineTo(left + sw * 1.02, top)
            ..close(),
          _fill(awnings[i]));
    }
    // String lights across the top.
    final bulbs = <Offset>[];
    for (var i = 0; i <= 12; i++) {
      final x = w * i / 12;
      final y = h * 0.14 + math.sin(i / 12 * math.pi) * h * 0.06;
      bulbs.add(Offset(x, y));
    }
    final wire = Path()..moveTo(bulbs.first.dx, bulbs.first.dy);
    for (final b in bulbs.skip(1)) {
      wire.lineTo(b.dx, b.dy);
    }
    c.drawPath(wire, _line(const Color(0xFF3A3A48), u * 0.004));
    const bulbColors = [Color(0xFFFFE066), Color(0xFFFF7AA2), Color(0xFF7CE0FF), Color(0xFF9CFF7A)];
    void drawBulbs() {
      for (var i = 0; i < bulbs.length; i++) {
        final on = 0.6 + 0.4 * math.sin(t * 2 * math.pi * 12 + i);
        final color = bulbColors[i % bulbColors.length];
        c.drawCircle(bulbs[i].translate(0, u * 0.015), u * 0.03, _fill(color.withValues(alpha: 0.25 * on)));
        c.drawCircle(bulbs[i].translate(0, u * 0.015), u * 0.012, _fill(color));
      }
    }

    if (night) {
      lights.add(drawBulbs);
    } else {
      drawBulbs();
    }
  }

  void _garden() {
    _sky(0.58);
    _ground(0.58, const Color(0xFF9BDC7E), const Color(0xFF5DAA55));
    // Picket fence
    for (var x = w * 0.02; x < w; x += w / 10) {
      c.drawPath(
          Path()
            ..moveTo(x, h * 0.6)
            ..lineTo(x, h * 0.46)
            ..lineTo(x + w * 0.025, h * 0.43)
            ..lineTo(x + w * 0.05, h * 0.46)
            ..lineTo(x + w * 0.05, h * 0.6)
            ..close(),
          _fill(const Color(0xFFFFF8EC)));
    }
    c.drawRect(Rect.fromLTWH(0, h * 0.5, w, h * 0.015), _fill(const Color(0xFFFFF8EC)));
    // Big leaves in the corners.
    for (final left in [true, false]) {
      final base = Offset(left ? 0 : w, h * 0.62);
      for (var i = 0; i < 3; i++) {
        final a = (left ? -0.9 : -2.24) + (left ? 1 : -1) * i * 0.32 + math.sin(t * 2 * math.pi * 10 + i) * 0.03;
        final tip = base.translate(math.cos(a) * u * 0.34, math.sin(a) * u * 0.34);
        final mid = Offset((base.dx + tip.dx) / 2, (base.dy + tip.dy) / 2);
        final nrm = Offset(-(tip.dy - base.dy), tip.dx - base.dx) * 0.22;
        c.drawPath(
            Path()
              ..moveTo(base.dx, base.dy)
              ..quadraticBezierTo(mid.dx + nrm.dx, mid.dy + nrm.dy, tip.dx, tip.dy)
              ..quadraticBezierTo(mid.dx - nrm.dx, mid.dy - nrm.dy, base.dx, base.dy),
            _fill(Color.lerp(const Color(0xFF2E8B57), const Color(0xFF4CB86B), i / 3)!));
      }
    }
    const colors = [Color(0xFFFF6B81), Color(0xFFFFFFFF), Color(0xFFB57BFF), Color(0xFFFF9F43)];
    for (var i = 0; i < 7; i++) {
      final x = w * (0.08 + i * 0.14);
      final y = h * (0.6 + (i % 2) * 0.03);
      c.drawLine(Offset(x, y + u * 0.05), Offset(x, y), _line(const Color(0xFF2E8B57), u * 0.008));
      _flower(Offset(x, y), u * 0.018, colors[i % colors.length]);
    }
  }

  void _field() {
    _sky(0.56);
    _hills(0.48, const Color(0xFFA6D98C));
    _ground(0.56, const Color(0xFF8BD17C), const Color(0xFF5DAA55));
    _roundTree(Offset(w * 0.86, h * 0.58), u * 0.42);
    // Path
    c.drawPath(
        Path()
          ..moveTo(w * 0.38, h * 0.56)
          ..quadraticBezierTo(w * 0.2, h * 0.8, w * 0.1, h)
          ..lineTo(w * 0.6, h)
          ..quadraticBezierTo(w * 0.5, h * 0.8, w * 0.46, h * 0.56)
          ..close(),
        _fill(const Color(0xFFE3C58F)));
    for (var i = 0; i < 10; i++) {
      final x = w * ((i * 0.137) % 1.0);
      final y = h * (0.62 + ((i * 0.29) % 0.3));
      c.drawLine(Offset(x, y), Offset(x - u * 0.01, y - u * 0.03), _line(const Color(0xFF4E9A45), u * 0.006));
      c.drawLine(Offset(x, y), Offset(x + u * 0.012, y - u * 0.028), _line(const Color(0xFF4E9A45), u * 0.006));
    }
  }

  void _rainforest() {
    _gradient(Offset.zero & size, const [Color(0xFF9FE0B0), Color(0xFF2F7D4A)]);
    final rng = math.Random(3);
    for (var layer = 0; layer < 3; layer++) {
      final color = Color.lerp(const Color(0xFF6CBF84), const Color(0xFF1F5E36), layer / 2)!;
      for (var i = 0; i < 5; i++) {
        final x = w * (i / 4) + (rng.nextDouble() - 0.5) * w * 0.15;
        final base = h * (0.5 + layer * 0.06);
        c.drawRect(Rect.fromLTWH(x - u * 0.02, base - u * 0.2, u * 0.04, u * 0.4), _fill(Color.lerp(color, Colors.brown, 0.4)!));
        c.drawCircle(Offset(x, base - u * 0.28), u * (0.16 + rng.nextDouble() * 0.06), _fill(color));
      }
    }
    // Hanging vines
    for (var i = 0; i < 5; i++) {
      final x = w * (0.1 + i * 0.2);
      final sway = math.sin(t * 2 * math.pi * 10 + i) * u * 0.02;
      final path = Path()
        ..moveTo(x, 0)
        ..quadraticBezierTo(x + sway, h * 0.15, x + sway * 0.5, h * (0.18 + (i % 3) * 0.06));
      c.drawPath(path, _line(const Color(0xFF2E6B3A), u * 0.01));
      c.drawCircle(Offset(x + sway * 0.5, h * (0.18 + (i % 3) * 0.06)), u * 0.02, _fill(const Color(0xFF4CB86B)));
    }
    _ground(0.64, const Color(0xFF3F8F4F), const Color(0xFF285E33));
    // Ferns
    for (var i = 0; i < 6; i++) {
      final base = Offset(w * (0.05 + i * 0.18), h * 0.68);
      for (var f = -2; f <= 2; f++) {
        final a = -math.pi / 2 + f * 0.4;
        c.drawLine(base, base.translate(math.cos(a) * u * 0.08, math.sin(a) * u * 0.08), _line(const Color(0xFF5FC06F), u * 0.012));
      }
    }
    // Light rays
    for (var i = 0; i < 3; i++) {
      final x = w * (0.2 + i * 0.3);
      c.drawPath(
          Path()
            ..moveTo(x, 0)
            ..lineTo(x + w * 0.06, 0)
            ..lineTo(x + w * 0.16, h * 0.7)
            ..lineTo(x + w * 0.04, h * 0.7)
            ..close(),
          _fill(Colors.white.withValues(alpha: 0.07)));
    }
  }

  void _river() {
    _sky(0.24);
    // Far bank with trees
    _gradient(Rect.fromLTWH(0, h * 0.22, w, h * 0.18), const [Color(0xFF6CBF6A), Color(0xFF4E9E4E)]);
    for (var i = 0; i < 6; i++) {
      _roundTree(Offset(w * (0.05 + i * 0.19), h * 0.3), u * (0.2 + (i % 2) * 0.05), leaf: const Color(0xFF2F8A45));
    }
    // Water
    _gradient(Rect.fromLTWH(0, h * 0.38, w, h * 0.26), const [Color(0xFF4FB3E8), Color(0xFF2A7FC0)]);
    for (var row = 0; row < 4; row++) {
      final y = h * (0.42 + row * 0.055);
      for (var i = 0; i < 5; i++) {
        final x = ((i / 5 + t * (row.isEven ? 2 : 3)) % 1.0) * w * 1.2 - w * 0.1;
        c.drawLine(Offset(x, y), Offset(x + u * 0.06, y), _line(Colors.white.withValues(alpha: 0.45), u * 0.006));
      }
    }
    // Near bank
    final bank = Path()
      ..moveTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.66, w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(bank, _fill(const Color(0xFF7CC76A)));
    for (var i = 0; i < 4; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(w * (0.15 + i * 0.25), h * 0.64), width: u * 0.08, height: u * 0.04),
          _fill(const Color(0xFF9AA5B8)));
    }
  }

  void _waves(double top, List<Color> colors) {
    _gradient(Rect.fromLTWH(0, h * top, w, h * (1 - top)), colors);
    for (var row = 0; row < 6; row++) {
      final y = h * (top + 0.03 + row * 0.07);
      final path = Path()..moveTo(0, y);
      final shift = (t * (row.isEven ? 3 : -2)) % 1.0 * (w / 4);
      for (var x = -w / 4; x <= w * 1.25; x += w / 8) {
        path.quadraticBezierTo(x + shift + w / 16, y - u * 0.012, x + shift + w / 8, y);
      }
      c.drawPath(path, _line(Colors.white.withValues(alpha: 0.35), u * 0.006));
    }
  }

  void _beach() {
    _sky(0.38);
    _waves(0.36, const [Color(0xFF2FA4D8), Color(0xFF1F7FB8)]);
    // Foam line that laps in and out.
    final lap = math.sin(t * 2 * math.pi * 10) * h * 0.01;
    final sand = Path()
      ..moveTo(0, h * 0.52 + lap)
      ..quadraticBezierTo(w * 0.3, h * 0.49 + lap, w * 0.6, h * 0.52 + lap)
      ..quadraticBezierTo(w * 0.8, h * 0.54 + lap, w, h * 0.5 + lap)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(sand, _line(Colors.white.withValues(alpha: 0.8), u * 0.02));
    c.drawPath(sand, _fill(const Color(0xFFF2DBA5)));
    _gradient(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), [const Color(0xFFF2DBA5).withValues(alpha: 0), const Color(0xFFDDBB7C)]);
    for (var i = 0; i < 8; i++) {
      c.drawCircle(Offset(w * ((i * 0.23) % 1.0), h * (0.6 + ((i * 0.17) % 0.3))), u * 0.006, _fill(const Color(0xFFC9A36A)));
    }
    _coconutTree(Offset(w * 0.9, h * 0.6), u * 0.5);
    if (night) {
      // Moonlight glinting on the water.
      lights.add(() {
        for (var i = 0; i < 5; i++) {
          c.drawLine(Offset(w * 0.8 - u * 0.04 * i, h * (0.39 + i * 0.025)), Offset(w * 0.86 + u * 0.03 * i, h * (0.39 + i * 0.025)),
              _line(const Color(0xFFFFF3B0).withValues(alpha: 0.5), u * 0.006));
        }
      });
    }
  }

  void _sea() {
    _sky(0.44);
    _waves(0.42, const [Color(0xFF35A8E0), Color(0xFF14568F)]);
    // Little boat on the horizon.
    final bx = w * (0.15 + 0.1 * math.sin(t * 2 * math.pi));
    final by = h * 0.42;
    c.drawPath(
        Path()
          ..moveTo(bx - u * 0.06, by)
          ..lineTo(bx + u * 0.06, by)
          ..lineTo(bx + u * 0.04, by + u * 0.025)
          ..lineTo(bx - u * 0.04, by + u * 0.025)
          ..close(),
        _fill(const Color(0xFF8B5E3C)));
    c.drawPath(
        Path()
          ..moveTo(bx, by - u * 0.08)
          ..lineTo(bx + u * 0.045, by - u * 0.005)
          ..lineTo(bx, by - u * 0.005)
          ..close(),
        _fill(Colors.white));
  }

  void _highSky() {
    if (night) {
      _sky(1, clouds: false);
      return;
    }
    _gradient(Offset.zero & size, const [Color(0xFF4FAEF0), Color(0xFFBFE8FF)]);
    _clouds(0.9, 5);
    // Distant ground peeking at the bottom.
    _hills(0.9, const Color(0xFF8BD17C));
  }

  void _space() {
    _gradient(Offset.zero & size, const [Color(0xFF0A0A2A), Color(0xFF241A4A)]);
    c.drawCircle(Offset(w * 0.25, h * 0.3), u * 0.35, _fill(const Color(0xFF7C5CFF).withValues(alpha: 0.08)));
    c.drawCircle(Offset(w * 0.8, h * 0.7), u * 0.3, _fill(const Color(0xFFFF5DA2).withValues(alpha: 0.06)));
    _stars(1, 60);
  }

  void _underwater() {
    _gradient(Offset.zero & size, const [Color(0xFF3FC1E8), Color(0xFF0E4C8A)]);
    // Light rays from the surface
    for (var i = 0; i < 4; i++) {
      final x = w * (0.1 + i * 0.25) + math.sin(t * 2 * math.pi * 5 + i) * u * 0.02;
      c.drawPath(
          Path()
            ..moveTo(x, 0)
            ..lineTo(x + w * 0.08, 0)
            ..lineTo(x + w * 0.02, h * 0.7)
            ..lineTo(x - w * 0.08, h * 0.7)
            ..close(),
          _fill(Colors.white.withValues(alpha: 0.06)));
    }
    // Sandy floor
    c.drawPath(
        Path()
          ..moveTo(0, h * 0.6)
          ..quadraticBezierTo(w * 0.4, h * 0.56, w, h * 0.62)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        _fill(const Color(0xFFD9C08A)));
    // Seaweed
    for (var i = 0; i < 5; i++) {
      final base = Offset(w * (0.06 + i * 0.22), h * 0.62);
      final sway = math.sin(t * 2 * math.pi * 10 + i) * u * 0.04;
      c.drawPath(
          Path()
            ..moveTo(base.dx, base.dy)
            ..quadraticBezierTo(base.dx + sway, base.dy - u * 0.15, base.dx - sway * 0.5, base.dy - u * (0.24 + (i % 2) * 0.08)),
          _line(const Color(0xFF2E9E5B), u * 0.022));
    }
    // Coral
    const coral = [Color(0xFFFF7A8A), Color(0xFFFFB347), Color(0xFFB57BFF)];
    for (var i = 0; i < 3; i++) {
      final base = Offset(w * (0.2 + i * 0.3), h * 0.62);
      final p = _line(coral[i], u * 0.025);
      c.drawLine(base, base.translate(0, -u * 0.1), p);
      c.drawLine(base.translate(0, -u * 0.05), base.translate(-u * 0.05, -u * 0.1), p);
      c.drawLine(base.translate(0, -u * 0.06), base.translate(u * 0.05, -u * 0.12), p);
    }
    // Bubbles
    for (var i = 0; i < 10; i++) {
      final x = w * ((i * 0.13 + 0.05) % 1.0) + math.sin(t * 2 * math.pi * 6 + i) * u * 0.01;
      final y = h - ((i / 10 + t * 4) % 1.0) * h;
      c.drawCircle(Offset(x, y), u * (0.008 + (i % 3) * 0.004), _line(Colors.white.withValues(alpha: 0.6), u * 0.003));
    }
  }

  void rain() {
    c.drawRect(Offset.zero & size, _fill(const Color(0xFF3A4A66).withValues(alpha: 0.22)));
    final p = _line(Colors.white.withValues(alpha: 0.55), u * 0.005);
    final rng = math.Random(11);
    for (var i = 0; i < 60; i++) {
      final x0 = rng.nextDouble() * w * 1.2;
      final y = ((rng.nextDouble() + t * 40) % 1.0) * h * 1.1 - h * 0.05;
      final x = x0 - (y / h) * w * 0.1;
      c.drawLine(Offset(x, y), Offset(x - u * 0.012, y + u * 0.04), p);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ACTORS — each drawn centred on the origin, [s] tall.
// ══════════════════════════════════════════════════════════════════════════

class _Actors {
  final Canvas c;
  final double s;
  final StoryFeel feel;
  final Color? tint;
  final double phase;

  _Actors(this.c, this.s, this.feel, this.tint, this.phase);

  void paint(StoryActor a) {
    switch (a) {
      case StoryActor.boy:
        _person(skin: const Color(0xFFD9A07A), shirt: tint ?? const Color(0xFF3FB36B), hair: _Hair.short);
      case StoryActor.girl:
        _person(skin: const Color(0xFFF0C29B), shirt: tint ?? const Color(0xFFFF7AA2), hair: _Hair.tudung, tudung: const Color(0xFFFFE3EE));
      case StoryActor.girlPigtails:
        _person(skin: const Color(0xFFF6D3B3), shirt: tint ?? const Color(0xFFFFB020), hair: _Hair.pigtails);
      case StoryActor.woman:
        _person(skin: const Color(0xFFE6B48C), shirt: tint ?? const Color(0xFF2BB5A0), hair: _Hair.tudung, tudung: Color.lerp(tint ?? const Color(0xFF2BB5A0), Colors.white, 0.55)!, adult: true, dress: true);
      case StoryActor.atuk:
        _person(skin: const Color(0xFFC98E68), shirt: tint ?? const Color(0xFF4E8FD9), hair: _Hair.songkok, adult: true, beard: true);
      case StoryActor.nenek:
        _person(skin: const Color(0xFFDDA985), shirt: tint ?? const Color(0xFFB07BD6), hair: _Hair.tudung, tudung: Colors.white, adult: true, dress: true, glasses: true);
      case StoryActor.ant:
        _ant();
      case StoryActor.grasshopper:
        _grasshopper();
      case StoryActor.tortoise:
        _tortoise();
      case StoryActor.hare:
        _hare();
      case StoryActor.kancil:
        _kancil();
      case StoryActor.crocodile:
        _crocodile();
      case StoryActor.turtle:
        _turtle();
      case StoryActor.crab:
        _crab();
      case StoryActor.fish:
        _fish();
      case StoryActor.bird:
        _bird();
      case StoryActor.butterfly:
        _butterfly();
      case StoryActor.caterpillar:
        _caterpillar();
      case StoryActor.egg:
        _egg();
      case StoryActor.cocoon:
        _cocoon();
      case StoryActor.sprout:
        _sprout();
      case StoryActor.sun:
        _sun();
      case StoryActor.cloud:
        _cloud();
      case StoryActor.raindrop:
        _raindrop();
      case StoryActor.moon:
        _moon();
      case StoryActor.star:
        _star();
      case StoryActor.planet:
        _planet(ringed: false);
      case StoryActor.planetRinged:
        _planet(ringed: true);
      case StoryActor.earth:
        _earth();
      case StoryActor.rainbow:
        _rainbow();
      case StoryActor.fireworks:
        _fireworks();
      case StoryActor.rambutan:
        _rambutan();
      case StoryActor.rocket:
        _rocket();
      case StoryActor.wallet:
        _wallet();
      case StoryActor.coins:
        _coins();
      case StoryActor.umbrella:
        _umbrella();
      case StoryActor.kite:
        _kite();
      case StoryActor.ketupat:
        _ketupat();
      case StoryActor.pelita:
        _pelita();
      case StoryActor.basket:
        _basket();
      case StoryActor.grain:
        _grain();
      case StoryActor.flag:
        _flag();
      case StoryActor.kuih:
        _kuih();
      case StoryActor.cup:
        _cup();
      case StoryActor.snackBag:
        _snackBag();
      case StoryActor.toyCar:
        _toyCar();
      case StoryActor.heart:
        _heart(Offset.zero, s * 0.5, const Color(0xFFFF4D6D));
    }
  }

  /// Eyes and mouth centred on [o], sized by [r] (roughly the head radius).
  void _face(Offset o, double r, {Color ink = _ink, bool cheeks = true, double spread = 0.36}) {
    final eyeY = o.dy - r * 0.08;
    for (final dir in [-1.0, 1.0]) {
      final e = Offset(o.dx + dir * r * spread, eyeY);
      switch (feel) {
        case StoryFeel.sleepy:
          c.drawArc(Rect.fromCenter(center: e, width: r * 0.3, height: r * 0.22), 0, math.pi, false, _line(ink, r * 0.07));
        case StoryFeel.surprised:
          c.drawCircle(e, r * 0.14, _fill(Colors.white));
          c.drawCircle(e, r * 0.08, _fill(ink));
        case StoryFeel.happy:
        case StoryFeel.sad:
          c.drawCircle(e, r * 0.1, _fill(ink));
          c.drawCircle(e.translate(-r * 0.03, -r * 0.03), r * 0.03, _fill(Colors.white));
      }
      if (feel == StoryFeel.sad) {
        c.drawLine(e.translate(-dir * r * 0.14, -r * 0.2), e.translate(dir * r * 0.1, -r * 0.26), _line(ink, r * 0.05));
      }
    }
    if (cheeks && feel != StoryFeel.sad) {
      for (final dir in [-1.0, 1.0]) {
        c.drawCircle(Offset(o.dx + dir * r * 0.55, o.dy + r * 0.18), r * 0.1, _fill(const Color(0xFFFF8FA8).withValues(alpha: 0.55)));
      }
    }
    final my = o.dy + r * 0.28;
    switch (feel) {
      case StoryFeel.happy:
        c.drawArc(Rect.fromCenter(center: Offset(o.dx, my - r * 0.06), width: r * 0.42, height: r * 0.3), 0.15, math.pi - 0.3, false, _line(ink, r * 0.06));
      case StoryFeel.sad:
        c.drawArc(Rect.fromCenter(center: Offset(o.dx, my + r * 0.08), width: r * 0.36, height: r * 0.24), math.pi + 0.2, math.pi - 0.4, false, _line(ink, r * 0.06));
      case StoryFeel.surprised:
        c.drawOval(Rect.fromCenter(center: Offset(o.dx, my), width: r * 0.16, height: r * 0.22), _fill(ink));
      case StoryFeel.sleepy:
        c.drawLine(Offset(o.dx - r * 0.1, my), Offset(o.dx + r * 0.1, my), _line(ink, r * 0.05));
    }
  }

  // ── People ──────────────────────────────────────────────────────────────

  void _person({
    required Color skin,
    required Color shirt,
    required _Hair hair,
    Color tudung = Colors.white,
    bool adult = false,
    bool dress = false,
    bool beard = false,
    bool glasses = false,
  }) {
    final headR = s * (adult ? 0.14 : 0.18);
    final headC = Offset(0, -s * 0.5 + headR * 1.05);
    final bodyTop = headC.dy + headR * 0.9;
    final legTop = s * (adult ? 0.28 : 0.24);
    final shade = Color.lerp(shirt, Colors.black, 0.2)!;

    // Legs
    if (!dress) {
      for (final dx in [-0.07, 0.07]) {
        c.drawLine(Offset(s * dx, legTop), Offset(s * dx, s * 0.46), _line(const Color(0xFF3B4A6B), s * 0.07));
      }
    }
    for (final dx in [-0.08, 0.08]) {
      c.drawOval(Rect.fromCenter(center: Offset(s * dx * 1.1, s * 0.48), width: s * 0.11, height: s * 0.05), _fill(_ink));
    }
    // Arms
    final wave = math.sin(phase) * 0.15;
    for (final dir in [-1.0, 1.0]) {
      final shoulder = Offset(dir * s * 0.13, bodyTop + s * 0.06);
      final hand = shoulder.translate(dir * s * 0.1, s * 0.2 + (dir > 0 ? wave * s * 0.2 : 0));
      c.drawLine(shoulder, hand, _line(shirt, s * 0.07));
      c.drawCircle(hand, s * 0.035, _fill(skin));
    }
    // Body
    final body = Path();
    if (dress) {
      body
        ..moveTo(-s * 0.13, bodyTop)
        ..lineTo(s * 0.13, bodyTop)
        ..lineTo(s * 0.2, s * 0.46)
        ..lineTo(-s * 0.2, s * 0.46)
        ..close();
    } else {
      body.addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-s * 0.14, bodyTop, s * 0.14, legTop + s * 0.02), Radius.circular(s * 0.06)));
    }
    c.drawPath(body, _fill(shirt));
    c.drawLine(Offset(0, bodyTop + s * 0.04), Offset(0, bodyTop + s * 0.14), _line(shade, s * 0.012));

    // Hair / headwear behind the head
    if (hair == _Hair.tudung) {
      c.drawPath(
          Path()
            ..addOval(Rect.fromCircle(center: headC.translate(0, -headR * 0.05), radius: headR * 1.22))
            ..moveTo(-headR * 1.15, headC.dy)
            ..lineTo(-headR * 1.3, bodyTop + s * 0.12)
            ..lineTo(headR * 1.3, bodyTop + s * 0.12)
            ..lineTo(headR * 1.15, headC.dy)
            ..close(),
          _fill(tudung));
    }
    if (hair == _Hair.pigtails) {
      for (final dir in [-1.0, 1.0]) {
        c.drawCircle(headC.translate(dir * headR * 1.1, headR * 0.2), headR * 0.4, _fill(const Color(0xFF2A1B14)));
        c.drawCircle(headC.translate(dir * headR * 0.95, -headR * 0.2), headR * 0.12, _fill(shirt));
      }
    }
    // Head
    c.drawCircle(headC, headR, _fill(skin));
    switch (hair) {
      case _Hair.short:
        c.drawArc(Rect.fromCircle(center: headC, radius: headR * 1.02), math.pi * 1.02, math.pi * 0.96, true, _fill(const Color(0xFF2A1B14)));
      case _Hair.pigtails:
        c.drawArc(Rect.fromCircle(center: headC, radius: headR * 1.03), math.pi * 1.05, math.pi * 0.9, true, _fill(const Color(0xFF2A1B14)));
      case _Hair.songkok:
        c.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTRB(-headR * 0.8, headC.dy - headR * 1.35, headR * 0.8, headC.dy - headR * 0.55), Radius.circular(headR * 0.12)),
            _fill(const Color(0xFF1E1A2E)));
        c.drawArc(Rect.fromCircle(center: headC, radius: headR * 1.02), math.pi * 1.1, math.pi * 0.8, false, _line(Colors.white70, headR * 0.12));
      case _Hair.tudung:
        c.drawArc(Rect.fromCircle(center: headC.translate(0, -headR * 0.05), radius: headR * 1.08), math.pi * 1.05, math.pi * 0.9, true, _fill(tudung));
    }
    if (beard) {
      c.drawArc(Rect.fromCircle(center: headC.translate(0, headR * 0.25), radius: headR * 0.75), 0.2, math.pi - 0.4, true, _fill(Colors.white));
    }
    _face(headC.translate(0, headR * 0.08), headR, cheeks: !beard);
    if (glasses) {
      for (final dir in [-1.0, 1.0]) {
        c.drawCircle(headC.translate(dir * headR * 0.36, 0), headR * 0.24, _line(_ink, headR * 0.06));
      }
    }
  }

  // ── Animals ─────────────────────────────────────────────────────────────

  void _ant() {
    final body = _fill(const Color(0xFF6B3A2A));
    final legs = _line(const Color(0xFF4A2419), s * 0.04);
    final walk = math.sin(phase * 2) * s * 0.04;
    for (var i = -1; i <= 1; i++) {
      c.drawLine(Offset(i * s * 0.14, s * 0.05), Offset(i * s * 0.22 - walk * i.sign, s * 0.3), legs);
      c.drawLine(Offset(i * s * 0.14, s * 0.05), Offset(i * s * 0.18 + walk, s * 0.3), legs);
    }
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.3, s * 0.02), width: s * 0.42, height: s * 0.34), body);
    c.drawCircle(Offset(0, 0), s * 0.13, body);
    c.drawCircle(Offset(s * 0.26, -s * 0.06), s * 0.18, body);
    c.drawLine(Offset(s * 0.3, -s * 0.22), Offset(s * 0.36, -s * 0.44), legs);
    c.drawLine(Offset(s * 0.36, -s * 0.44), Offset(s * 0.46, -s * 0.48), legs);
    _face(Offset(s * 0.3, -s * 0.05), s * 0.16, ink: Colors.white, cheeks: false, spread: 0.4);
  }

  void _grasshopper() {
    const green = Color(0xFF6CC24A);
    final dark = Color.lerp(green, Colors.black, 0.25)!;
    final leg = _line(dark, s * 0.045);
    // Big back leg
    c.drawLine(Offset(-s * 0.1, s * 0.05), Offset(-s * 0.32, -s * 0.18), leg);
    c.drawLine(Offset(-s * 0.32, -s * 0.18), Offset(-s * 0.42, s * 0.3), leg);
    c.drawLine(Offset(s * 0.1, s * 0.1), Offset(s * 0.06, s * 0.3), leg);
    c.drawLine(Offset(s * 0.2, s * 0.08), Offset(s * 0.24, s * 0.3), leg);
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.02, s * 0.06), width: s * 0.7, height: s * 0.24), _fill(green));
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.06, s * 0.0), width: s * 0.5, height: s * 0.12), _fill(dark));
    c.drawCircle(Offset(s * 0.34, -s * 0.04), s * 0.15, _fill(green));
    c.drawLine(Offset(s * 0.36, -s * 0.18), Offset(s * 0.2, -s * 0.48), _line(dark, s * 0.02));
    c.drawLine(Offset(s * 0.4, -s * 0.18), Offset(s * 0.44, -s * 0.5), _line(dark, s * 0.02));
    _face(Offset(s * 0.36, -s * 0.03), s * 0.13, cheeks: false);
  }

  void _tortoise() {
    const skin = Color(0xFF9BCB6B);
    for (final dx in [-0.28, 0.2]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(s * dx, s * 0.26), width: s * 0.16, height: s * 0.2), Radius.circular(s * 0.06)), _fill(skin));
    }
    c.drawCircle(Offset(s * 0.48, -s * 0.02), s * 0.17, _fill(skin));
    _face(Offset(s * 0.5, -s * 0.02), s * 0.15, cheeks: false);
    final shell = Path()
      ..moveTo(-s * 0.5, s * 0.2)
      ..quadraticBezierTo(-s * 0.46, -s * 0.46, 0, -s * 0.46)
      ..quadraticBezierTo(s * 0.46, -s * 0.46, s * 0.42, s * 0.2)
      ..close();
    c.drawPath(shell, _fill(const Color(0xFF4E9A5B)));
    final pat = _line(const Color(0xFF3A7A45), s * 0.03);
    c.drawCircle(Offset(-s * 0.04, -s * 0.12), s * 0.14, pat);
    c.drawLine(Offset(-s * 0.18, -s * 0.12), Offset(-s * 0.4, -s * 0.02), pat);
    c.drawLine(Offset(s * 0.1, -s * 0.12), Offset(s * 0.34, -s * 0.02), pat);
    c.drawLine(Offset(-s * 0.04, s * 0.02), Offset(-s * 0.04, s * 0.2), pat);
    c.drawRect(Rect.fromLTRB(-s * 0.52, s * 0.16, s * 0.44, s * 0.22), _fill(const Color(0xFF3A7A45)));
  }

  void _hare() {
    const fur = Color(0xFFE2CFB6);
    const inner = Color(0xFFFFB3C1);
    final hop = feel == StoryFeel.sleepy ? 0.0 : 1.0;
    // Ears
    for (final dx in [0.14, 0.3]) {
      c.save();
      c.translate(s * dx, -s * 0.28);
      c.rotate((dx - 0.22) * 1.6 + (feel == StoryFeel.sleepy ? 0.9 : 0));
      c.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.16), width: s * 0.12, height: s * 0.38), _fill(fur));
      c.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.16), width: s * 0.06, height: s * 0.28), _fill(inner));
      c.restore();
    }
    c.drawCircle(Offset(-s * 0.36, s * 0.1), s * 0.08, _fill(Colors.white));
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.08, s * 0.14), width: s * 0.6, height: s * 0.4 * (0.9 + 0.1 * hop)), _fill(fur));
    c.drawOval(Rect.fromCenter(center: Offset(s * 0.1, s * 0.4), width: s * 0.22, height: s * 0.08), _fill(fur));
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.26, s * 0.38), width: s * 0.26, height: s * 0.1), _fill(fur));
    c.drawCircle(Offset(s * 0.22, -s * 0.12), s * 0.2, _fill(fur));
    c.drawCircle(Offset(s * 0.4, -s * 0.06), s * 0.03, _fill(const Color(0xFFFF7A8A)));
    _face(Offset(s * 0.24, -s * 0.12), s * 0.18);
  }

  void _kancil() {
    const coat = Color(0xFFB07A45);
    final leg = _line(const Color(0xFF8A5A30), s * 0.05);
    for (final dx in [-0.3, -0.18, 0.12, 0.24]) {
      c.drawLine(Offset(s * dx, s * 0.1), Offset(s * dx, s * 0.46), leg);
    }
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.04, s * 0.06), width: s * 0.7, height: s * 0.32), _fill(coat));
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.04, s * 0.14), width: s * 0.44, height: s * 0.12), _fill(const Color(0xFFF3DDBF)));
    c.drawLine(Offset(s * 0.22, 0), Offset(s * 0.34, -s * 0.22), _line(coat, s * 0.14));
    // Head with a pointy snout
    c.drawPath(
        Path()
          ..addOval(Rect.fromCenter(center: Offset(s * 0.36, -s * 0.28), width: s * 0.26, height: s * 0.22))
          ..moveTo(s * 0.4, -s * 0.36)
          ..lineTo(s * 0.62, -s * 0.24)
          ..lineTo(s * 0.4, -s * 0.18)
          ..close(),
        _fill(coat));
    c.drawCircle(Offset(s * 0.62, -s * 0.24), s * 0.025, _fill(_ink));
    for (final dx in [0.26, 0.36]) {
      c.drawOval(Rect.fromCenter(center: Offset(s * dx, -s * 0.44), width: s * 0.08, height: s * 0.14), _fill(const Color(0xFF8A5A30)));
    }
    c.drawLine(Offset(-s * 0.38, 0), Offset(-s * 0.46, -s * 0.06), _line(coat, s * 0.05));
    final eye = Offset(s * 0.4, -s * 0.3);
    if (feel == StoryFeel.sleepy) {
      c.drawArc(Rect.fromCenter(center: eye, width: s * 0.08, height: s * 0.06), 0, math.pi, false, _line(_ink, s * 0.02));
    } else {
      c.drawCircle(eye, s * (feel == StoryFeel.surprised ? 0.05 : 0.04), _fill(_ink));
      c.drawCircle(eye.translate(-s * 0.012, -s * 0.012), s * 0.012, _fill(Colors.white));
    }
    if (feel == StoryFeel.happy) {
      c.drawArc(Rect.fromCenter(center: Offset(s * 0.5, -s * 0.2), width: s * 0.1, height: s * 0.06), 0.2, math.pi - 0.4, false, _line(_ink, s * 0.015));
    }
  }

  void _crocodile() {
    // s is the body height; the croc is about 5 × as long.
    const green = Color(0xFF4F8A3C);
    final dark = Color.lerp(green, Colors.black, 0.25)!;
    final len = s * 5;
    c.drawPath(
        Path()
          ..moveTo(-len * 0.5, 0)
          ..quadraticBezierTo(-len * 0.3, -s * 0.5, 0, -s * 0.5)
          ..lineTo(len * 0.28, -s * 0.4)
          ..lineTo(len * 0.5, -s * 0.12)
          ..lineTo(len * 0.5, s * 0.12)
          ..lineTo(len * 0.28, s * 0.3)
          ..lineTo(0, s * 0.4)
          ..quadraticBezierTo(-len * 0.3, s * 0.3, -len * 0.5, 0)
          ..close(),
        _fill(green));
    for (var i = 0; i < 6; i++) {
      final x = -len * 0.32 + i * len * 0.08;
      c.drawPath(
          Path()
            ..moveTo(x - s * 0.1, -s * 0.44)
            ..lineTo(x, -s * 0.7)
            ..lineTo(x + s * 0.1, -s * 0.44)
            ..close(),
          _fill(dark));
    }
    // Teeth along the snout
    for (var i = 0; i < 5; i++) {
      final x = len * 0.3 + i * len * 0.04;
      c.drawPath(Path()..moveTo(x, s * 0.02)..lineTo(x + s * 0.06, s * 0.14)..lineTo(x + s * 0.12, s * 0.02)..close(), _fill(Colors.white));
    }
    c.drawLine(Offset(len * 0.28, s * 0.02), Offset(len * 0.5, s * 0.02), _line(dark, s * 0.05));
    // Eye bump
    final eye = Offset(len * 0.24, -s * 0.5);
    c.drawCircle(eye, s * 0.22, _fill(green));
    c.drawCircle(eye, s * 0.14, _fill(const Color(0xFFFFF3B0)));
    c.drawCircle(eye, s * (feel == StoryFeel.surprised ? 0.05 : 0.08), _fill(_ink));
    if (feel == StoryFeel.sad) {
      c.drawLine(eye.translate(-s * 0.2, -s * 0.22), eye.translate(s * 0.18, -s * 0.12), _line(_ink, s * 0.06));
    }
    // Water line over the belly
    c.drawRect(Rect.fromLTRB(-len * 0.55, s * 0.18, len * 0.55, s * 0.5), _fill(const Color(0xFF3A93D0).withValues(alpha: 0.7)));
  }

  void _turtle() {
    const skin = Color(0xFF8FC57A);
    final flap = math.sin(phase) * 0.3;
    for (final dir in [-1.0, 1.0]) {
      c.save();
      c.translate(s * 0.14, dir * s * 0.24);
      c.rotate(dir * (0.5 + flap));
      c.drawOval(Rect.fromCenter(center: Offset(s * 0.12, 0), width: s * 0.34, height: s * 0.12), _fill(skin));
      c.restore();
      c.drawOval(Rect.fromCenter(center: Offset(-s * 0.3, dir * s * 0.2), width: s * 0.18, height: s * 0.08), _fill(skin));
    }
    c.drawCircle(Offset(s * 0.42, 0), s * 0.14, _fill(skin));
    _face(Offset(s * 0.44, 0), s * 0.13, cheeks: false);
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.02, 0), width: s * 0.66, height: s * 0.52), _fill(const Color(0xFF6E8B3D)));
    final pat = _fill(const Color(0xFF8FAE55));
    c.drawCircle(Offset(-s * 0.02, 0), s * 0.1, pat);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      c.drawCircle(Offset(-s * 0.02 + math.cos(a) * s * 0.19, math.sin(a) * s * 0.15), s * 0.055, pat);
    }
  }

  void _crab() {
    const red = Color(0xFFE8553F);
    final leg = _line(const Color(0xFFC23F2C), s * 0.05);
    for (final dir in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(dir * s * 0.2, s * 0.08), Offset(dir * s * (0.42 + i * 0.04), s * (0.2 + i * 0.1)), leg);
      }
      final snap = math.sin(phase * 2) * 0.2;
      c.save();
      c.translate(dir * s * 0.38, -s * 0.18);
      c.rotate(dir * snap);
      c.drawCircle(Offset.zero, s * 0.12, _fill(red));
      c.drawPath(Path()..moveTo(0, 0)..lineTo(dir * s * 0.14, -s * 0.1)..lineTo(dir * s * 0.14, s * 0.02)..close(), _fill(const Color(0xFFF2DBA5)));
      c.restore();
      c.drawLine(Offset(dir * s * 0.1, -s * 0.1), Offset(dir * s * 0.12, -s * 0.26), _line(red, s * 0.03));
      c.drawCircle(Offset(dir * s * 0.12, -s * 0.28), s * 0.05, _fill(Colors.white));
      c.drawCircle(Offset(dir * s * 0.12, -s * 0.28), s * 0.025, _fill(_ink));
    }
    c.drawOval(Rect.fromCenter(center: Offset(0, s * 0.04), width: s * 0.52, height: s * 0.34), _fill(red));
    c.drawArc(Rect.fromCenter(center: Offset(0, s * 0.06), width: s * 0.16, height: s * 0.1), 0.2, math.pi - 0.4, false, _line(_ink, s * 0.025));
  }

  void _fish() {
    final body = tint ?? const Color(0xFFFF9F43);
    final wag = math.sin(phase * 2) * s * 0.1;
    c.drawPath(Path()..moveTo(-s * 0.4, 0)..lineTo(-s * 0.75, -s * 0.3 + wag)..lineTo(-s * 0.75, s * 0.3 + wag)..close(), _fill(Color.lerp(body, Colors.black, 0.15)!));
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 1.0, height: s * 0.7), _fill(body));
    c.drawLine(Offset(-s * 0.1, -s * 0.32), Offset(-s * 0.1, s * 0.32), _line(Colors.white.withValues(alpha: 0.6), s * 0.08));
    c.drawCircle(Offset(s * 0.24, -s * 0.06), s * 0.1, _fill(Colors.white));
    c.drawCircle(Offset(s * 0.26, -s * 0.06), s * 0.05, _fill(_ink));
  }

  void _bird() {
    final body = tint ?? const Color(0xFF3FA7F5);
    final flap = math.sin(phase * 3);
    c.drawPath(Path()..moveTo(-s * 0.3, 0)..lineTo(-s * 0.55, -s * 0.12)..lineTo(-s * 0.5, s * 0.1)..close(), _fill(body));
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.7, height: s * 0.5), _fill(body));
    c.drawOval(Rect.fromCenter(center: Offset(0, s * 0.08), width: s * 0.4, height: s * 0.26), _fill(Colors.white.withValues(alpha: 0.7)));
    c.drawPath(
        Path()
          ..moveTo(-s * 0.1, -s * 0.05)
          ..quadraticBezierTo(-s * 0.05, -s * 0.5 * flap, s * 0.16, -s * 0.05)
          ..close(),
        _fill(Color.lerp(body, Colors.black, 0.2)!));
    c.drawPath(Path()..moveTo(s * 0.32, -s * 0.06)..lineTo(s * 0.48, 0)..lineTo(s * 0.32, s * 0.06)..close(), _fill(const Color(0xFFFFB020)));
    c.drawCircle(Offset(s * 0.2, -s * 0.08), s * 0.05, _fill(_ink));
  }

  void _butterfly() {
    final wing = tint ?? const Color(0xFFFF8A3D);
    final flap = 0.55 + 0.45 * math.sin(phase * 3).abs();
    for (final dir in [-1.0, 1.0]) {
      c.save();
      c.scale(flap, 1);
      c.drawOval(Rect.fromCenter(center: Offset(dir * s * 0.24, -s * 0.14), width: s * 0.44, height: s * 0.4), _fill(wing));
      c.drawOval(Rect.fromCenter(center: Offset(dir * s * 0.18, s * 0.16), width: s * 0.3, height: s * 0.28), _fill(Color.lerp(wing, const Color(0xFFFF4D6D), 0.4)!));
      c.drawCircle(Offset(dir * s * 0.26, -s * 0.16), s * 0.07, _fill(Colors.white.withValues(alpha: 0.8)));
      c.drawCircle(Offset(dir * s * 0.18, s * 0.16), s * 0.04, _fill(_ink.withValues(alpha: 0.6)));
      c.restore();
      c.drawLine(Offset(0, -s * 0.24), Offset(dir * s * 0.1, -s * 0.44), _line(_ink, s * 0.02));
      c.drawCircle(Offset(dir * s * 0.1, -s * 0.44), s * 0.025, _fill(_ink));
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * 0.08, height: s * 0.5), Radius.circular(s * 0.04)), _fill(_ink));
  }

  void _caterpillar() {
    const green = Color(0xFF7ED957);
    final dark = Color.lerp(green, Colors.black, 0.2)!;
    // s is segment height; the caterpillar is about 3 × as long.
    for (var i = 4; i >= 1; i--) {
      final y = math.sin(phase + i) * s * 0.08;
      c.drawCircle(Offset(-i * s * 0.38, y + s * 0.06), s * 0.3, _fill(i.isEven ? green : dark));
      c.drawLine(Offset(-i * s * 0.38, y + s * 0.34), Offset(-i * s * 0.38, y + s * 0.44), _line(_ink, s * 0.05));
    }
    c.drawCircle(Offset.zero, s * 0.38, _fill(green));
    c.drawLine(Offset(-s * 0.1, -s * 0.34), Offset(-s * 0.2, -s * 0.6), _line(_ink, s * 0.04));
    c.drawLine(Offset(s * 0.1, -s * 0.34), Offset(s * 0.2, -s * 0.6), _line(_ink, s * 0.04));
    c.drawCircle(Offset(-s * 0.2, -s * 0.6), s * 0.05, _fill(const Color(0xFFFF4D6D)));
    c.drawCircle(Offset(s * 0.2, -s * 0.6), s * 0.05, _fill(const Color(0xFFFF4D6D)));
    _face(Offset.zero, s * 0.36);
  }

  // ── Nature ──────────────────────────────────────────────────────────────

  void _leaf(Offset o, double len, double angle) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    c.drawPath(
        Path()
          ..moveTo(-len / 2, 0)
          ..quadraticBezierTo(0, -len * 0.4, len / 2, 0)
          ..quadraticBezierTo(0, len * 0.4, -len / 2, 0),
        _fill(const Color(0xFF3FA34D)));
    c.drawLine(Offset(-len / 2, 0), Offset(len / 2, 0), _line(const Color(0xFF2E7D3A), len * 0.03));
    c.restore();
  }

  void _egg() {
    if (tint == null) _leaf(Offset(0, s * 0.2), s * 1.4, -0.15);
    c.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.05), width: s * 0.4, height: s * 0.52), _fill(tint ?? const Color(0xFFFFF3C4)));
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.06, -s * 0.16), width: s * 0.1, height: s * 0.14), _fill(Colors.white.withValues(alpha: 0.7)));
  }

  void _cocoon() {
    c.drawLine(Offset(-s * 0.5, -s * 0.46), Offset(s * 0.5, -s * 0.5), _line(const Color(0xFF7A5230), s * 0.05));
    _leaf(Offset(s * 0.3, -s * 0.56), s * 0.4, -0.4);
    c.drawLine(Offset(0, -s * 0.48), Offset(0, -s * 0.36), _line(const Color(0xFF7A5230), s * 0.02));
    c.drawPath(
        Path()
          ..moveTo(0, -s * 0.38)
          ..quadraticBezierTo(s * 0.22, -s * 0.2, s * 0.14, s * 0.2)
          ..quadraticBezierTo(0, s * 0.44, -s * 0.14, s * 0.2)
          ..quadraticBezierTo(-s * 0.22, -s * 0.2, 0, -s * 0.38)
          ..close(),
        _fill(const Color(0xFF9CB85A)));
    for (var i = 0; i < 4; i++) {
      final y = -s * 0.2 + i * s * 0.12;
      c.drawArc(Rect.fromCenter(center: Offset(0, y), width: s * 0.3, height: s * 0.08), 0, math.pi, false, _line(const Color(0xFF7C9A40), s * 0.015));
    }
  }

  void _sprout() {
    c.drawOval(Rect.fromCenter(center: Offset(0, s * 0.4), width: s * 0.8, height: s * 0.22), _fill(const Color(0xFF8B5E3C)));
    c.drawLine(Offset(0, s * 0.36), Offset(0, -s * 0.1), _line(const Color(0xFF3FA34D), s * 0.06));
    _leaf(Offset(-s * 0.18, -s * 0.12), s * 0.42, -0.5);
    _leaf(Offset(s * 0.18, -s * 0.2), s * 0.42, 0.5);
  }

  void _sun() {
    const yellow = Color(0xFFFFC93C);
    final spin = phase * 0.05;
    for (var i = 0; i < 10; i++) {
      final a = spin + i * math.pi / 5;
      c.drawLine(Offset(math.cos(a) * s * 0.34, math.sin(a) * s * 0.34), Offset(math.cos(a) * s * 0.48, math.sin(a) * s * 0.48), _line(yellow, s * 0.06));
    }
    c.drawCircle(Offset.zero, s * 0.5, _fill(yellow.withValues(alpha: 0.18)));
    c.drawCircle(Offset.zero, s * 0.3, _fill(yellow));
    _face(Offset.zero, s * 0.28, ink: const Color(0xFF8A5A00));
  }

  void _cloud() {
    final color = tint ?? Colors.white;
    final p = _fill(color);
    c.drawCircle(Offset(-s * 0.3, s * 0.06), s * 0.28, p);
    c.drawCircle(Offset(s * 0.32, s * 0.08), s * 0.26, p);
    c.drawCircle(Offset(0, -s * 0.08), s * 0.4, p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-s * 0.58, s * 0.0, s * 0.58, s * 0.34), Radius.circular(s * 0.17)), p);
    _face(Offset(0, s * 0.04), s * 0.3, ink: tint == null ? const Color(0xFF6B7A99) : _ink);
  }

  void _raindrop() {
    const blue = Color(0xFF5AC8FA);
    c.drawPath(
        Path()
          ..moveTo(0, -s * 0.5)
          ..quadraticBezierTo(s * 0.4, -s * 0.05, s * 0.34, s * 0.18)
          ..arcToPoint(Offset(-s * 0.34, s * 0.18), radius: Radius.circular(s * 0.35))
          ..quadraticBezierTo(-s * 0.4, -s * 0.05, 0, -s * 0.5)
          ..close(),
        _fill(blue));
    c.drawOval(Rect.fromCenter(center: Offset(-s * 0.14, -s * 0.06), width: s * 0.1, height: s * 0.2), _fill(Colors.white.withValues(alpha: 0.6)));
    _face(Offset(0, s * 0.12), s * 0.26, ink: const Color(0xFF0E4C8A));
  }

  void _moon() {
    final disc = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: s * 0.5));
    final bite = Path()..addOval(Rect.fromCircle(center: Offset(s * 0.26, -s * 0.12), radius: s * 0.42));
    c.drawCircle(Offset.zero, s * 0.7, _fill(const Color(0xFFFFF3B0).withValues(alpha: 0.15)));
    c.drawPath(Path.combine(PathOperation.difference, disc, bite), _fill(const Color(0xFFFFE680)));
    c.drawCircle(Offset(-s * 0.3, s * 0.02), s * 0.04, _fill(_ink));
    c.drawArc(Rect.fromCenter(center: Offset(-s * 0.22, s * 0.16), width: s * 0.14, height: s * 0.1), 0.2, math.pi - 0.4, false, _line(_ink, s * 0.03));
  }

  void _star() {
    _starPath(Offset.zero, s * 0.5, const Color(0xFFFFD24A), glow: true);
    _face(Offset(0, s * 0.04), s * 0.2, ink: const Color(0xFF8A5A00));
  }

  void _starPath(Offset o, double r, Color color, {bool glow = false}) {
    if (glow) c.drawCircle(o, r * 1.3, _fill(color.withValues(alpha: 0.18)));
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(o.dx + math.cos(a) * rad, o.dy + math.sin(a) * rad);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path..close(), _fill(color));
  }

  void _planet({required bool ringed}) {
    final color = tint ?? const Color(0xFFD9A066);
    final r = s * 0.5;
    final ring = Rect.fromCenter(center: Offset.zero, width: r * 3.2, height: r * 0.8);
    final ringPaint = _line(Color.lerp(color, Colors.white, 0.35)!, r * 0.16);
    if (ringed) {
      c.save();
      c.rotate(-0.25);
      c.drawArc(ring, math.pi, math.pi, false, ringPaint);
      c.restore();
    }
    c.drawCircle(Offset.zero, r, _fill(color));
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
    for (var i = -2; i <= 2; i++) {
      c.drawRect(Rect.fromCenter(center: Offset(0, i * r * 0.36), width: r * 2, height: r * 0.12), _fill(Colors.white.withValues(alpha: 0.14)));
    }
    if (!ringed && color.toARGB32() == 0xFFD9A066) {
      c.drawOval(Rect.fromCenter(center: Offset(r * 0.3, r * 0.3), width: r * 0.4, height: r * 0.24), _fill(const Color(0xFFB8452E)));
    }
    c.drawCircle(Offset(r * 0.35, r * 0.2), r, _fill(Colors.black.withValues(alpha: 0.12)));
    c.restore();
    if (ringed) {
      c.save();
      c.rotate(-0.25);
      c.drawArc(ring, 0, math.pi, false, ringPaint);
      c.restore();
    }
  }

  void _earth() {
    final r = s * 0.5;
    c.drawCircle(Offset.zero, r * 1.08, _fill(const Color(0xFF8ED8FF).withValues(alpha: 0.3)));
    c.drawCircle(Offset.zero, r, _fill(const Color(0xFF2E86DE)));
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r)));
    final land = _fill(const Color(0xFF3FB36B));
    c.drawOval(Rect.fromCenter(center: Offset(-r * 0.3, -r * 0.3), width: r * 0.8, height: r * 0.6), land);
    c.drawOval(Rect.fromCenter(center: Offset(r * 0.4, r * 0.2), width: r * 0.6, height: r * 0.9), land);
    c.drawOval(Rect.fromCenter(center: Offset(-r * 0.4, r * 0.5), width: r * 0.5, height: r * 0.3), land);
    c.drawOval(Rect.fromCenter(center: Offset(0, -r * 0.9), width: r * 1.2, height: r * 0.3), _fill(Colors.white.withValues(alpha: 0.8)));
    c.restore();
  }

  void _rainbow() {
    const colors = [Color(0xFFFF5A5F), Color(0xFFFF9F43), Color(0xFFFFD24A), Color(0xFF7ED957), Color(0xFF4FB3E8), Color(0xFF9B6BD6)];
    for (var i = 0; i < colors.length; i++) {
      final r = s * (1.3 - i * 0.12);
      c.drawArc(Rect.fromCircle(center: Offset(0, s * 0.5), radius: r), math.pi, math.pi, false, _line(colors[i].withValues(alpha: 0.8), s * 0.12));
    }
  }

  void _fireworks() {
    final base = tint ?? const Color(0xFFFFD24A);
    final burst = 0.5 + 0.5 * math.sin(phase * 0.8).abs();
    const others = [Color(0xFFFF7AA2), Color(0xFF7CE0FF)];
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final color = i % 3 == 0 ? base : others[i % 2];
      final from = Offset(math.cos(a) * s * 0.12 * burst, math.sin(a) * s * 0.12 * burst);
      final to = Offset(math.cos(a) * s * 0.5 * burst, math.sin(a) * s * 0.5 * burst);
      c.drawLine(from, to, _line(color, s * 0.03));
      c.drawCircle(to, s * 0.03, _fill(color));
    }
    c.drawCircle(Offset.zero, s * 0.06, _fill(Colors.white));
  }

  void _rambutan() {
    c.drawLine(Offset(-s * 0.4, -s * 0.46), Offset(s * 0.1, -s * 0.2), _line(const Color(0xFF7A5230), s * 0.04));
    _leaf(Offset(-s * 0.3, -s * 0.5), s * 0.4, 0.3);
    _leaf(Offset(s * 0.2, -s * 0.36), s * 0.36, -0.6);
    for (final o in [Offset(-s * 0.1, 0), Offset(s * 0.18, s * 0.06), Offset(s * 0.02, s * 0.28), Offset(-s * 0.26, s * 0.22)]) {
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        c.drawLine(o + Offset(math.cos(a), math.sin(a)) * s * 0.14, o + Offset(math.cos(a), math.sin(a)) * s * 0.2, _line(const Color(0xFF5FA83A), s * 0.02));
      }
      c.drawCircle(o, s * 0.15, _fill(const Color(0xFFE0303C)));
      c.drawCircle(o.translate(-s * 0.05, -s * 0.05), s * 0.04, _fill(Colors.white.withValues(alpha: 0.4)));
    }
  }

  // ── Things ──────────────────────────────────────────────────────────────

  void _rocket() {
    final flicker = 0.8 + 0.2 * math.sin(phase * 4);
    c.drawPath(Path()..moveTo(-s * 0.1, s * 0.34)..lineTo(0, s * (0.34 + 0.22 * flicker))..lineTo(s * 0.1, s * 0.34)..close(), _fill(const Color(0xFFFF9F43)));
    c.drawPath(Path()..moveTo(-s * 0.05, s * 0.34)..lineTo(0, s * (0.34 + 0.12 * flicker))..lineTo(s * 0.05, s * 0.34)..close(), _fill(const Color(0xFFFFE066)));
    const red = Color(0xFFE74C3C);
    for (final dir in [-1.0, 1.0]) {
      c.drawPath(Path()..moveTo(dir * s * 0.12, s * 0.06)..lineTo(dir * s * 0.28, s * 0.36)..lineTo(dir * s * 0.1, s * 0.3)..close(), _fill(red));
    }
    c.drawPath(
        Path()
          ..moveTo(0, -s * 0.5)
          ..quadraticBezierTo(s * 0.2, -s * 0.3, s * 0.14, s * 0.34)
          ..lineTo(-s * 0.14, s * 0.34)
          ..quadraticBezierTo(-s * 0.2, -s * 0.3, 0, -s * 0.5)
          ..close(),
        _fill(const Color(0xFFF5F5FA)));
    c.drawPath(Path()..moveTo(0, -s * 0.5)..quadraticBezierTo(s * 0.12, -s * 0.38, s * 0.15, -s * 0.28)..lineTo(-s * 0.15, -s * 0.28)..quadraticBezierTo(-s * 0.12, -s * 0.38, 0, -s * 0.5)..close(), _fill(red));
    c.drawCircle(Offset(0, -s * 0.08), s * 0.08, _fill(const Color(0xFF5B6EF5)));
    c.drawCircle(Offset(0, -s * 0.08), s * 0.08, _line(const Color(0xFF9AA5B8), s * 0.025));
  }

  void _wallet() {
    const brown = Color(0xFF8B5A2B);
    c.drawRect(Rect.fromLTRB(-s * 0.3, -s * 0.36, s * 0.2, -s * 0.1), _fill(const Color(0xFF6CC084)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-s * 0.5, -s * 0.24, s * 0.5, s * 0.34), Radius.circular(s * 0.08)), _fill(brown));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(s * 0.1, -s * 0.04, s * 0.5, s * 0.16), Radius.circular(s * 0.06)), _fill(Color.lerp(brown, Colors.black, 0.2)!));
    c.drawCircle(Offset(s * 0.36, s * 0.06), s * 0.04, _fill(const Color(0xFFFFD24A)));
    c.drawLine(Offset(-s * 0.42, -s * 0.16), Offset(s * 0.42, -s * 0.16), _line(const Color(0xFFB07A45), s * 0.02));
  }

  void _coins() {
    for (var i = 0; i < 3; i++) {
      final y = s * 0.24 - i * s * 0.12;
      c.drawOval(Rect.fromCenter(center: Offset(0, y + s * 0.04), width: s * 0.8, height: s * 0.28), _fill(const Color(0xFFD69E1F)));
      c.drawOval(Rect.fromCenter(center: Offset(0, y), width: s * 0.8, height: s * 0.28), _fill(const Color(0xFFFFC93C)));
    }
    c.drawOval(Rect.fromCenter(center: Offset(0, s * 0.0), width: s * 0.5, height: s * 0.16), _line(const Color(0xFFD69E1F), s * 0.03));
    for (var i = 0; i < 2; i++) {
      final a = phase * 0.5 + i * math.pi;
      _starPath(Offset(math.cos(a) * s * 0.5, -s * 0.3 + math.sin(a) * s * 0.1), s * 0.08, Colors.white);
    }
  }

  void _umbrella() {
    final color = tint ?? const Color(0xFFFFC93C);
    c.drawLine(Offset(0, -s * 0.2), Offset(0, s * 0.4), _line(const Color(0xFF6B4226), s * 0.03));
    c.drawArc(Rect.fromCenter(center: Offset(-s * 0.06, s * 0.4), width: s * 0.12, height: s * 0.12), 0, math.pi, false, _line(const Color(0xFF6B4226), s * 0.03));
    final canopy = Path()..moveTo(-s * 0.5, 0)..quadraticBezierTo(-s * 0.46, -s * 0.46, 0, -s * 0.46)..quadraticBezierTo(s * 0.46, -s * 0.46, s * 0.5, 0);
    for (var i = 0; i < 4; i++) {
      final x1 = s * 0.5 - i * s * 0.25;
      canopy.quadraticBezierTo(x1 - s * 0.125, -s * 0.1, x1 - s * 0.25, 0);
    }
    c.drawPath(canopy..close(), _fill(color));
    c.drawPath(Path()..moveTo(0, -s * 0.46)..quadraticBezierTo(s * 0.12, -s * 0.2, s * 0.25, 0)..lineTo(0, 0)..close(), _fill(Colors.white.withValues(alpha: 0.25)));
    c.drawCircle(Offset(0, -s * 0.48), s * 0.03, _fill(const Color(0xFF6B4226)));
  }

  void _kite() {
    // Wau bulan: wide wings on top, a crescent tail below.
    final paper = tint ?? const Color(0xFFFFF0D0);
    const red = Color(0xFFE74C3C);
    const blue = Color(0xFF2E86DE);
    const gold = Color(0xFFFFC93C);
    c.drawPath(
        Path()
          ..moveTo(0, -s * 0.34)
          ..quadraticBezierTo(s * 0.5, -s * 0.34, s * 0.56, -s * 0.08)
          ..quadraticBezierTo(s * 0.3, -s * 0.02, 0, s * 0.02)
          ..quadraticBezierTo(-s * 0.3, -s * 0.02, -s * 0.56, -s * 0.08)
          ..quadraticBezierTo(-s * 0.5, -s * 0.34, 0, -s * 0.34)
          ..close(),
        _fill(paper));
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCenter(center: Offset(0, s * 0.26), width: s * 0.8, height: s * 0.44)),
      Path()..addOval(Rect.fromCenter(center: Offset(0, s * 0.12), width: s * 0.66, height: s * 0.36)),
    );
    c.drawPath(moon, _fill(paper));
    c.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.08), width: s * 0.16, height: s * 0.36), _fill(paper));
    if (tint == null) {
      for (final dir in [-1.0, 1.0]) {
        c.drawCircle(Offset(dir * s * 0.28, -s * 0.18), s * 0.06, _fill(red));
        c.drawCircle(Offset(dir * s * 0.28, -s * 0.18), s * 0.025, _fill(gold));
        c.drawCircle(Offset(dir * s * 0.44, -s * 0.12), s * 0.035, _fill(blue));
        c.drawCircle(Offset(dir * s * 0.14, -s * 0.22), s * 0.03, _fill(blue));
      }
      c.drawPath(moon, _line(red, s * 0.02));
      c.drawCircle(Offset(0, -s * 0.08), s * 0.05, _fill(red));
    }
    final frame = _line(const Color(0xFF8B5E3C), s * 0.015);
    c.drawLine(Offset(0, -s * 0.36), Offset(0, s * 0.46), frame);
    c.drawLine(Offset(-s * 0.56, -s * 0.1), Offset(s * 0.56, -s * 0.1), frame);
    // String
    c.drawPath(Path()..moveTo(0, s * 0.04)..quadraticBezierTo(-s * 0.3, s * 0.6, -s * 0.8, s * 1.2), _line(Colors.white.withValues(alpha: 0.8), s * 0.01));
  }

  void _ketupat() {
    const leaf = Color(0xFF9CCB4A);
    const dark = Color(0xFF6E9E2E);
    c.drawLine(Offset(s * 0.2, -s * 0.2), Offset(s * 0.46, -s * 0.5), _line(leaf, s * 0.05));
    c.drawLine(Offset(-s * 0.2, s * 0.2), Offset(-s * 0.4, s * 0.48), _line(leaf, s * 0.05));
    final diamond = Path()
      ..moveTo(0, -s * 0.36)
      ..lineTo(s * 0.36, 0)
      ..lineTo(0, s * 0.36)
      ..lineTo(-s * 0.36, 0)
      ..close();
    c.drawPath(diamond, _fill(leaf));
    c.save();
    c.clipPath(diamond);
    final weave = _line(dark, s * 0.03);
    for (var i = -3; i <= 3; i++) {
      c.drawLine(Offset(-s * 0.4 + i * s * 0.12, -s * 0.4), Offset(s * 0.4 + i * s * 0.12, s * 0.4), weave);
      c.drawLine(Offset(s * 0.4 + i * s * 0.12, -s * 0.4), Offset(-s * 0.4 + i * s * 0.12, s * 0.4), weave);
    }
    c.restore();
  }

  void _pelita() {
    c.drawLine(Offset(0, s * 0.5), Offset(0, -s * 0.24), _line(const Color(0xFFB8864B), s * 0.07));
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(-s * 0.035, s * (0.3 - i * 0.22)), Offset(s * 0.035, s * (0.3 - i * 0.22)), _line(const Color(0xFF8B5E3C), s * 0.02));
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -s * 0.27), width: s * 0.14, height: s * 0.1), Radius.circular(s * 0.03)), _fill(const Color(0xFF9AA5B8)));
    final f = 0.85 + 0.15 * math.sin(phase * 4);
    c.drawCircle(Offset(0, -s * 0.4), s * 0.2 * f, _fill(const Color(0xFFFFB347).withValues(alpha: 0.25)));
    c.drawPath(
        Path()
          ..moveTo(0, -s * (0.34 + 0.2 * f))
          ..quadraticBezierTo(s * 0.08, -s * 0.38, 0, -s * 0.32)
          ..quadraticBezierTo(-s * 0.08, -s * 0.38, 0, -s * (0.34 + 0.2 * f))
          ..close(),
        _fill(const Color(0xFFFFD24A)));
  }

  void _basket() {
    for (var i = 0; i < 9; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(-s * 0.32 + (i % 5) * s * 0.16, -s * (0.02 + (i ~/ 5) * 0.1)), width: s * 0.14, height: s * 0.08),
          _fill(const Color(0xFFFFF3C4)));
    }
    final bowl = Path()
      ..moveTo(-s * 0.5, -s * 0.05)
      ..lineTo(s * 0.5, -s * 0.05)
      ..quadraticBezierTo(s * 0.44, s * 0.4, 0, s * 0.4)
      ..quadraticBezierTo(-s * 0.44, s * 0.4, -s * 0.5, -s * 0.05)
      ..close();
    c.drawPath(bowl, _fill(const Color(0xFFC08A55)));
    c.save();
    c.clipPath(bowl);
    for (var i = 0; i < 5; i++) {
      c.drawLine(Offset(-s * 0.5, s * (0.02 + i * 0.08)), Offset(s * 0.5, s * (0.02 + i * 0.08)), _line(const Color(0xFF9A6A3C), s * 0.02));
    }
    c.restore();
  }

  void _grain() {
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.6, height: s), _fill(const Color(0xFFFFF8E1)));
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 0.6, height: s), _line(const Color(0xFFD9C79A), s * 0.08));
  }

  void _flag() {
    c.drawLine(Offset(0, s * 0.5), Offset(0, -s * 0.5), _line(const Color(0xFF8B5E3C), s * 0.05));
    final wave = math.sin(phase * 2) * s * 0.04;
    final flag = Path()
      ..moveTo(0, -s * 0.48)
      ..quadraticBezierTo(s * 0.2, -s * 0.48 + wave, s * 0.4, -s * 0.44)
      ..lineTo(s * 0.4, -s * 0.14)
      ..quadraticBezierTo(s * 0.2, -s * 0.18 + wave, 0, -s * 0.18)
      ..close();
    c.drawPath(flag, _fill(Colors.white));
    c.save();
    c.clipPath(flag);
    for (var r = 0; r < 3; r++) {
      for (var col = 0; col < 4; col++) {
        if ((r + col).isEven) {
          c.drawRect(Rect.fromLTWH(col * s * 0.1, -s * 0.5 + r * s * 0.12, s * 0.1, s * 0.12), _fill(_ink));
        }
      }
    }
    c.restore();
  }

  void _kuih() {
    c.drawOval(Rect.fromCenter(center: Offset(0, s * 0.2), width: s * 1.1, height: s * 0.3), _fill(Colors.white));
    c.drawOval(Rect.fromCenter(center: Offset(0, s * 0.2), width: s * 1.1, height: s * 0.3), _line(const Color(0xFFD9D9E3), s * 0.03));
    const layers = [Color(0xFF7ED957), Color(0xFFFFFFFF), Color(0xFFFF7AA2), Color(0xFFFFFFFF), Color(0xFF7ED957)];
    for (final dx in [-0.24, 0.04]) {
      for (var i = 0; i < layers.length; i++) {
        c.drawRect(Rect.fromLTWH(s * dx, s * (0.1 - (i + 1) * 0.08), s * 0.24, s * 0.08), _fill(layers[i]));
      }
    }
    c.drawCircle(Offset(s * 0.36, s * 0.04), s * 0.1, _fill(const Color(0xFF6B3A2A)));
    c.drawCircle(Offset(s * 0.36, s * 0.02), s * 0.04, _fill(Colors.white));
  }

  void _cup() {
    c.drawLine(Offset(s * 0.06, -s * 0.2), Offset(s * 0.2, -s * 0.52), _line(const Color(0xFFFF5A5F), s * 0.05));
    final cup = Path()
      ..moveTo(-s * 0.26, -s * 0.28)
      ..lineTo(s * 0.26, -s * 0.28)
      ..lineTo(s * 0.2, s * 0.44)
      ..lineTo(-s * 0.2, s * 0.44)
      ..close();
    c.drawPath(cup, _fill(Colors.white.withValues(alpha: 0.85)));
    c.save();
    c.clipPath(cup);
    c.drawRect(Rect.fromLTRB(-s * 0.3, -s * 0.14, s * 0.3, s * 0.5), _fill(const Color(0xFFC6E07A)));
    for (var i = 0; i < 4; i++) {
      c.drawCircle(Offset(-s * 0.1 + i * s * 0.07, s * (0.1 + (i % 2) * 0.14)), s * 0.035, _fill(Colors.white.withValues(alpha: 0.7)));
    }
    c.restore();
    c.drawPath(cup, _line(const Color(0xFFB8C1CC), s * 0.02));
  }

  void _snackBag() {
    final bag = Path()
      ..moveTo(-s * 0.32, -s * 0.2)
      ..lineTo(s * 0.32, -s * 0.2)
      ..lineTo(s * 0.36, s * 0.44)
      ..lineTo(-s * 0.36, s * 0.44)
      ..close();
    for (var i = 0; i < 3; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(-s * 0.16 + i * s * 0.16, -s * 0.26 - (i % 2) * s * 0.06), width: s * 0.2, height: s * 0.3),
          _fill(const Color(0xFFE0A030)));
    }
    c.drawPath(bag, _fill(const Color(0xFFF2E6CF)));
    c.drawPath(
        Path()
          ..moveTo(-s * 0.32, -s * 0.2)
          ..lineTo(-s * 0.2, -s * 0.12)
          ..lineTo(-s * 0.08, -s * 0.2)
          ..lineTo(s * 0.04, -s * 0.12)
          ..lineTo(s * 0.16, -s * 0.2)
          ..lineTo(s * 0.32, -s * 0.12),
        _line(const Color(0xFFD9C79A), s * 0.02));
    c.drawCircle(Offset(0, s * 0.14), s * 0.1, _fill(const Color(0xFFFF5A5F)));
  }

  void _toyCar() {
    const red = Color(0xFFE74C3C);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-s * 0.7, -s * 0.1, s * 0.7, s * 0.28), Radius.circular(s * 0.1)), _fill(red));
    c.drawPath(
        Path()
          ..moveTo(-s * 0.36, -s * 0.1)
          ..lineTo(-s * 0.22, -s * 0.42)
          ..lineTo(s * 0.26, -s * 0.42)
          ..lineTo(s * 0.42, -s * 0.1)
          ..close(),
        _fill(red));
    c.drawPath(Path()..moveTo(-s * 0.26, -s * 0.12)..lineTo(-s * 0.16, -s * 0.34)..lineTo(-s * 0.02, -s * 0.34)..lineTo(-s * 0.02, -s * 0.12)..close(), _fill(const Color(0xFFBDE7FF)));
    c.drawPath(Path()..moveTo(s * 0.06, -s * 0.12)..lineTo(s * 0.06, -s * 0.34)..lineTo(s * 0.22, -s * 0.34)..lineTo(s * 0.32, -s * 0.12)..close(), _fill(const Color(0xFFBDE7FF)));
    for (final dx in [-0.4, 0.4]) {
      c.drawCircle(Offset(s * dx, s * 0.3), s * 0.17, _fill(_ink));
      c.drawCircle(Offset(s * dx, s * 0.3), s * 0.07, _fill(const Color(0xFF9AA5B8)));
    }
    c.drawCircle(Offset(s * 0.64, s * 0.04), s * 0.05, _fill(const Color(0xFFFFE066)));
  }

  void _heart(Offset o, double r, Color color) {
    c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy + r * 0.8)
          ..cubicTo(o.dx - r * 1.4, o.dy - r * 0.1, o.dx - r * 0.6, o.dy - r * 1.1, o.dx, o.dy - r * 0.35)
          ..cubicTo(o.dx + r * 0.6, o.dy - r * 1.1, o.dx + r * 1.4, o.dy - r * 0.1, o.dx, o.dy + r * 0.8)
          ..close(),
        _fill(color));
    c.drawCircle(o.translate(-r * 0.4, -r * 0.35), r * 0.14, _fill(Colors.white.withValues(alpha: 0.6)));
  }
}

enum _Hair { short, pigtails, songkok, tudung }
