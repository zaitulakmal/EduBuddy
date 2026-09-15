import 'dart:math';
import 'package:flutter/material.dart';

/// The living backdrop behind Buddy Reader.
///
/// Four storybook worlds, one per chapter in rotation, so finishing a chapter
/// also changes where you are. Everything drifts slowly — clouds, birds, waves,
/// snow, fireflies — and holds still when the device asks for reduced motion.
enum ReaderSceneTheme { meadow, beach, sunset, snow }

ReaderSceneTheme readerSceneFor(int chapter) =>
    ReaderSceneTheme.values[(max(chapter, 1) - 1) % ReaderSceneTheme.values.length];

class ReaderScenery extends StatefulWidget {
  final ReaderSceneTheme theme;
  const ReaderScenery({super.key, this.theme = ReaderSceneTheme.meadow});

  @override
  State<ReaderScenery> createState() => _ReaderSceneryState();
}

class _ReaderSceneryState extends State<ReaderScenery> with SingleTickerProviderStateMixin {
  // One slow master clock; every moving thing is a multiple of it.
  late final AnimationController _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 40));

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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: RepaintBoundary(
        key: ValueKey(widget.theme),
        child: CustomPaint(
          painter: _ScenePainter(widget.theme, _clock),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ─── Painter ──────────────────────────────────────────────────────────────────

class _ScenePainter extends CustomPainter {
  final ReaderSceneTheme theme;
  final Animation<double> clock;
  _ScenePainter(this.theme, this.clock) : super(repaint: clock);

  late Canvas _c;
  late double _w, _h, _t;

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    _w = size.width;
    _h = size.height;
    _t = clock.value;
    canvas.clipRect(Offset.zero & size);
    switch (theme) {
      case ReaderSceneTheme.meadow: _meadow();
      case ReaderSceneTheme.beach: _beach();
      case ReaderSceneTheme.sunset: _sunset();
      case ReaderSceneTheme.snow: _snow();
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.theme != theme;

  // ── Worlds ────────────────────────────────────────────────────────────────

  void _meadow() {
    _sky(const [Color(0xFF7FD0F5), Color(0xFFB8E7F7), Color(0xFFE9F8F1)]);
    _sun(Offset(_w * 0.82, _h * 0.12), _w * 0.085, const Color(0xFFFFC93C));
    _clouds(Colors.white);
    _birds();
    const far = _Ridge(0.60, 0.025, 1.6, 0.4);
    const mid = _Ridge(0.71, 0.03, 1.2, 2.2);
    const near = _Ridge(0.84, 0.018, 2.0, 1.0);
    _land(far, const Color(0xFFBDE59A));
    _roundTrees(far, const Color(0xFF8CCB6A), const Color(0xFF9A6A45), count: 6, scale: 0.7, seed: 3);
    _land(mid, const Color(0xFF92D46C));
    _bushes(mid, const Color(0xFF6FB84F), seed: 5);
    _flowers(mid, seed: 9, count: 10);
    _land(near, const Color(0xFF6CBF4A));
    _grass(near, const Color(0xFF4E9A36), seed: 2);
    _flowers(near, seed: 4, count: 14, big: true);
  }

  void _beach() {
    _sky(const [Color(0xFF6CC7F2), Color(0xFFA9E1F7), Color(0xFFE3F6FB)]);
    _sun(Offset(_w * 0.18, _h * 0.12), _w * 0.08, const Color(0xFFFFD45C));
    _clouds(Colors.white);
    _birds();

    // Sea
    final seaTop = _h * 0.58;
    _c.drawRect(
      Rect.fromLTWH(0, seaTop, _w, _h - seaTop),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF3FA7F5), Color(0xFF2BB3C9)],
        ).createShader(Rect.fromLTWH(0, seaTop, _w, _h - seaTop)),
    );
    // Little sailboat far out
    final bx = (0.15 + _t * 0.7) % 1.2 * _w - _w * 0.1;
    final by = seaTop + _h * 0.015 + sin(_t * 2 * pi * 10) * 1.5;
    _c.drawPath(
        Path()
          ..moveTo(bx, by)
          ..lineTo(bx + 18, by)
          ..lineTo(bx + 14, by + 5)
          ..lineTo(bx + 4, by + 5)
          ..close(),
        Paint()..color = const Color(0xFFFF6B35));
    _c.drawPath(
        Path()
          ..moveTo(bx + 9, by - 16)
          ..lineTo(bx + 9, by - 1)
          ..lineTo(bx + 17, by - 1)
          ..close(),
        Paint()..color = Colors.white);
    // Rolling wave lines
    for (var row = 0; row < 4; row++) {
      final y = seaTop + _h * (0.035 + row * 0.03);
      final phase = _t * 2 * pi * 8 + row * 1.3;
      final path = Path();
      for (double x = -10; x <= _w + 10; x += 6) {
        final yy = y + sin(x / _w * 2 * pi * 5 + phase) * 2.5;
        x == -10 ? path.moveTo(x, yy) : path.lineTo(x, yy);
      }
      _c.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35 - row * 0.05)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
    }

    // Sand, with foam where it meets the sea
    const sand = _Ridge(0.74, 0.02, 1.4, 0.8);
    final foam = Path();
    for (double x = 0; x <= _w; x += 6) {
      final y = sand.y(x, _w, _h) - 5 + sin(_t * 2 * pi * 6 + x / 30) * 2;
      x == 0 ? foam.moveTo(x, y) : foam.lineTo(x, y);
    }
    _c.drawPath(
        foam,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
    _land(sand, const Color(0xFFF6DDA6));
    final rand = Random(7);
    for (var i = 0; i < 40; i++) {
      final x = rand.nextDouble() * _w;
      final y = sand.y(x, _w, _h) + 12 + rand.nextDouble() * (_h - sand.y(x, _w, _h) - 12);
      _c.drawCircle(Offset(x, y), 1.4, Paint()..color = const Color(0xFFD9B77A));
    }
    _starfish(Offset(_w * 0.62, _h * 0.9), 13, const Color(0xFFFF8A65));
    _shell(Offset(_w * 0.42, _h * 0.95), 10);
    _palm(Offset(_w * 0.9, sand.y(_w * 0.9, _w, _h) + 8));
  }

  void _sunset() {
    _sky(const [Color(0xFF8E7CF0), Color(0xFFFF9EB5), Color(0xFFFFD08A)]);
    // Twinkles appearing at the top of the sky
    final rand = Random(11);
    for (var i = 0; i < 18; i++) {
      final p = Offset(rand.nextDouble() * _w, rand.nextDouble() * _h * 0.28);
      final tw = (sin(_t * 2 * pi * (6 + i % 4) + i) + 1) / 2;
      _sparkle(p, 2 + tw * 2.5, Colors.white.withValues(alpha: 0.35 + tw * 0.55));
    }
    // Big low sun with retro stripes, half behind the hills
    final sun = Offset(_w * 0.5, _h * 0.6);
    final r = _w * 0.24;
    _c.drawCircle(sun, r * 1.35, Paint()..color = const Color(0x33FFE27A));
    _c.save();
    _c.clipPath(Path()..addOval(Rect.fromCircle(center: sun, radius: r)));
    _c.drawRect(
      Rect.fromCircle(center: sun, radius: r),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE27A), Color(0xFFFF8A5B)],
        ).createShader(Rect.fromCircle(center: sun, radius: r)),
    );
    for (var i = 0; i < 4; i++) {
      final y = sun.dy - r * 0.05 + i * r * 0.18;
      _c.drawRect(Rect.fromLTWH(sun.dx - r, y, r * 2, 3.0 + i * 1.5),
          Paint()..color = const Color(0xFFFF9EB5));
    }
    _c.restore();
    _clouds(const Color(0xFFFFE3EC));

    const far = _Ridge(0.62, 0.03, 1.4, 0.9);
    const mid = _Ridge(0.73, 0.025, 1.1, 2.6);
    const near = _Ridge(0.85, 0.02, 1.8, 0.3);
    _land(far, const Color(0xFFC28AD6));
    _roundTrees(far, const Color(0xFFA56FC4), const Color(0xFF7D4E97), count: 5, scale: 0.7, seed: 8);
    _land(mid, const Color(0xFF9C6BC8));
    _bushes(mid, const Color(0xFF8656B5), seed: 12);
    _land(near, const Color(0xFF7A55B0));
    _grass(near, const Color(0xFF5F3F92), seed: 6);
    // Fireflies drifting in the foreground
    final ff = Random(21);
    for (var i = 0; i < 12; i++) {
      final bx = ff.nextDouble() * _w;
      final by = _h * (0.62 + ff.nextDouble() * 0.34);
      final a = _t * 2 * pi * (3 + i % 3) + i;
      final p = Offset(bx + sin(a) * 14, by + cos(a * 0.7) * 10);
      final glow = (sin(a * 2) + 1) / 2;
      _c.drawCircle(p, 7, Paint()..color = const Color(0xFFFFF3A0).withValues(alpha: 0.15 + glow * 0.2));
      _c.drawCircle(p, 2.4, Paint()..color = const Color(0xFFFFF3A0).withValues(alpha: 0.6 + glow * 0.4));
    }
  }

  void _snow() {
    _sky(const [Color(0xFF9FC9F2), Color(0xFFCFE6FA), Color(0xFFF1F8FE)]);
    _sun(Offset(_w * 0.8, _h * 0.13), _w * 0.07, const Color(0xFFFFE9A8), rays: false);
    _clouds(const Color(0xFFF4F8FF));
    const far = _Ridge(0.60, 0.035, 1.3, 1.4);
    const mid = _Ridge(0.72, 0.028, 1.0, 0.2);
    const near = _Ridge(0.85, 0.018, 1.7, 2.4);
    _land(far, const Color(0xFFE2EEFA), edge: const Color(0xFFC6DAF0));
    _pines(far, count: 6, scale: 0.6, seed: 4);
    _land(mid, const Color(0xFFF2F7FD), edge: const Color(0xFFCFDFF2));
    _pines(mid, count: 3, scale: 0.9, seed: 10);
    _land(near, Colors.white, edge: const Color(0xFFD6E4F4));
    _snowman(Offset(_w * 0.86, near.y(_w * 0.86, _w, _h) + 4));
    // Falling snow
    final rand = Random(31);
    for (var i = 0; i < 46; i++) {
      final sx = rand.nextDouble();
      final sy = rand.nextDouble();
      final speed = 3 + rand.nextDouble() * 3;
      final y = ((sy + _t * speed) % 1.0) * (_h + 20) - 10;
      final x = sx * _w + sin(_t * 2 * pi * 4 + i) * 12;
      final r = 1.6 + rand.nextDouble() * 2.6;
      _c.drawCircle(Offset(x, y), r, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }
  }

  // ── Pieces of scenery ─────────────────────────────────────────────────────

  void _sky(List<Color> colors) {
    final rect = Rect.fromLTWH(0, 0, _w, _h);
    _c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0, 0.45, 0.8],
        ).createShader(rect),
    );
  }

  void _sun(Offset center, double r, Color color, {bool rays = true}) {
    if (rays) {
      final spin = _t * 2 * pi;
      final ray = Paint()..color = color.withValues(alpha: 0.35);
      for (var i = 0; i < 12; i++) {
        final a = spin + i * pi / 6;
        final path = Path()
          ..moveTo(center.dx + cos(a - 0.12) * r * 1.25, center.dy + sin(a - 0.12) * r * 1.25)
          ..lineTo(center.dx + cos(a) * r * (i.isEven ? 2.0 : 1.7),
              center.dy + sin(a) * r * (i.isEven ? 2.0 : 1.7))
          ..lineTo(center.dx + cos(a + 0.12) * r * 1.25, center.dy + sin(a + 0.12) * r * 1.25)
          ..close();
        _c.drawPath(path, ray);
      }
    }
    _c.drawCircle(center, r * 1.25, Paint()..color = color.withValues(alpha: 0.3));
    _c.drawCircle(center, r, Paint()..color = color);
    _c.drawCircle(center + Offset(-r * 0.3, -r * 0.3), r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.45));
  }

  void _clouds(Color color) {
    const clouds = [
      (0.10, 1.0, 0.00),
      (0.22, 0.7, 0.45),
      (0.34, 0.85, 0.75),
      (0.16, 0.55, 0.25),
    ];
    for (var i = 0; i < clouds.length; i++) {
      final (y, scale, offset) = clouds[i];
      final speed = 0.6 + i * 0.25;
      final x = ((offset + _t * speed) % 1.3 - 0.2) * _w;
      _cloud(Offset(x, _h * y), scale * _w / 390, color);
    }
  }

  void _cloud(Offset o, double s, Color color) {
    final shadow = Paint()..color = const Color(0xFF6A8FB5).withValues(alpha: 0.12);
    final fill = Paint()..color = color;
    Path puff(double dy) => Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx, o.dy + dy, 86 * s, 26 * s), Radius.circular(13 * s)))
      ..addOval(Rect.fromCircle(center: o + Offset(26 * s, 4 * s + dy), radius: 18 * s))
      ..addOval(Rect.fromCircle(center: o + Offset(52 * s, 0 + dy), radius: 23 * s))
      ..addOval(Rect.fromCircle(center: o + Offset(70 * s, 8 * s + dy), radius: 14 * s));
    _c.drawPath(puff(4 * s), shadow);
    _c.drawPath(puff(0), fill);
  }

  void _birds() {
    for (var i = 0; i < 3; i++) {
      final x = ((0.1 + i * 0.3 + _t * (1.1 + i * 0.2)) % 1.2 - 0.1) * _w;
      final y = _h * (0.2 + i * 0.05) + sin(_t * 2 * pi * 5 + i) * 6;
      final flap = sin(_t * 2 * pi * 30 + i * 2) * 3;
      final s = 6.0 + i;
      _c.drawPath(
          Path()
            ..moveTo(x - s, y - s * 0.3 + flap)
            ..quadraticBezierTo(x - s * 0.5, y - s * 0.7, x, y)
            ..quadraticBezierTo(x + s * 0.5, y - s * 0.7, x + s, y - s * 0.3 + flap),
          Paint()
            ..color = const Color(0xFF3D3526).withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round);
    }
  }

  void _land(_Ridge ridge, Color color, {Color? edge}) {
    final path = Path()..moveTo(0, _h);
    for (double x = 0; x <= _w + 8; x += 8) {
      path.lineTo(x, ridge.y(x, _w, _h));
    }
    path
      ..lineTo(_w, _h)
      ..close();
    _c.drawPath(path, Paint()..color = color);
    // A slightly darker crest line gives the flat colour an illustrated edge.
    final crest = Path();
    for (double x = 0; x <= _w + 8; x += 8) {
      final y = ridge.y(x, _w, _h) + 1.5;
      x == 0 ? crest.moveTo(x, y) : crest.lineTo(x, y);
    }
    _c.drawPath(
        crest,
        Paint()
          ..color = edge ?? Color.lerp(color, Colors.black, 0.12)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  void _roundTrees(_Ridge ridge, Color leaf, Color trunk,
      {required int count, required double scale, required int seed}) {
    final rand = Random(seed);
    for (var i = 0; i < count; i++) {
      final x = (i + 0.3 + rand.nextDouble() * 0.4) / count * _w;
      final base = ridge.y(x, _w, _h) + 4;
      final s = scale * (0.8 + rand.nextDouble() * 0.4) * _w / 390;
      _c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 3 * s, base - 22 * s, 6 * s, 22 * s), Radius.circular(3 * s)),
          Paint()..color = trunk);
      _c.drawCircle(Offset(x, base - 30 * s), 16 * s, Paint()..color = leaf);
      _c.drawCircle(Offset(x - 5 * s, base - 35 * s), 5 * s,
          Paint()..color = Colors.white.withValues(alpha: 0.18));
    }
  }

  void _bushes(_Ridge ridge, Color color, {required int seed}) {
    final rand = Random(seed);
    for (var i = 0; i < 5; i++) {
      final x = rand.nextDouble() * _w;
      final base = ridge.y(x, _w, _h) + 10;
      final s = (0.7 + rand.nextDouble() * 0.5) * _w / 390;
      final p = Paint()..color = color;
      _c.drawCircle(Offset(x - 12 * s, base), 11 * s, p);
      _c.drawCircle(Offset(x, base - 6 * s), 14 * s, p);
      _c.drawCircle(Offset(x + 13 * s, base), 10 * s, p);
    }
  }

  void _flowers(_Ridge ridge, {required int seed, required int count, bool big = false}) {
    const petals = [Color(0xFFFF9EC4), Colors.white, Color(0xFFFFC93C), Color(0xFFB79CFF)];
    final rand = Random(seed);
    for (var i = 0; i < count; i++) {
      final x = rand.nextDouble() * _w;
      final top = ridge.y(x, _w, _h);
      final y = top + 14 + rand.nextDouble() * (big ? (_h - top - 24) : 30);
      final r = (big ? 4.2 : 2.8) * _w / 390;
      final sway = sin(_t * 2 * pi * 4 + i) * 1.2;
      final center = Offset(x + sway, y);
      final paint = Paint()..color = petals[i % petals.length];
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * pi / 5;
        _c.drawCircle(center + Offset(cos(a) * r, sin(a) * r), r * 0.75, paint);
      }
      _c.drawCircle(center, r * 0.6, Paint()..color = const Color(0xFFFF9F43));
    }
  }

  void _grass(_Ridge ridge, Color color, {required int seed}) {
    final rand = Random(seed);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 22; i++) {
      final x = rand.nextDouble() * _w;
      final top = ridge.y(x, _w, _h);
      final y = top + 10 + rand.nextDouble() * (_h - top - 14);
      final sway = sin(_t * 2 * pi * 3 + i) * 1.5;
      for (final dx in [-4.0, 0.0, 4.0]) {
        _c.drawLine(Offset(x + dx * 0.5, y), Offset(x + dx + sway, y - 10 + dx.abs() * 0.6), paint);
      }
    }
  }

  void _pines(_Ridge ridge, {required int count, required double scale, required int seed}) {
    final rand = Random(seed);
    for (var i = 0; i < count; i++) {
      final x = (i + 0.2 + rand.nextDouble() * 0.6) / count * _w;
      final base = ridge.y(x, _w, _h) + 6;
      final s = scale * (0.85 + rand.nextDouble() * 0.3) * _w / 390;
      _c.drawRect(Rect.fromLTWH(x - 3 * s, base - 10 * s, 6 * s, 10 * s),
          Paint()..color = const Color(0xFF8A6A4F));
      for (var k = 0; k < 3; k++) {
        final w = (22 - k * 5) * s;
        final y = base - 8 * s - k * 13 * s;
        final tri = Path()
          ..moveTo(x - w, y)
          ..lineTo(x, y - 20 * s)
          ..lineTo(x + w, y)
          ..close();
        _c.drawPath(tri, Paint()..color = const Color(0xFF3F8F6B));
        final cap = Path()
          ..moveTo(x - w * 0.45, y - 11 * s)
          ..lineTo(x, y - 20 * s)
          ..lineTo(x + w * 0.45, y - 11 * s)
          ..quadraticBezierTo(x, y - 8 * s, x - w * 0.45, y - 11 * s)
          ..close();
        _c.drawPath(cap, Paint()..color = Colors.white);
      }
    }
  }

  void _snowman(Offset base) {
    final s = _w / 390;
    final white = Paint()..color = Colors.white;
    final line = Paint()
      ..color = const Color(0xFFB9CDE4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final bottom = base + Offset(0, -18 * s);
    final top = base + Offset(0, -46 * s);
    _c.drawCircle(bottom, 20 * s, white);
    _c.drawCircle(bottom, 20 * s, line);
    _c.drawCircle(top, 14 * s, white);
    _c.drawCircle(top, 14 * s, line);
    final ink = Paint()..color = const Color(0xFF3D3526);
    _c.drawCircle(top + Offset(-5 * s, -3 * s), 2 * s, ink);
    _c.drawCircle(top + Offset(5 * s, -3 * s), 2 * s, ink);
    _c.drawPath(
        Path()
          ..moveTo(top.dx, top.dy + 1 * s)
          ..lineTo(top.dx + 12 * s, top.dy + 4 * s)
          ..lineTo(top.dx, top.dy + 5 * s)
          ..close(),
        Paint()..color = const Color(0xFFFF9F43));
    _c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(top.dx - 15 * s, top.dy + 9 * s, 30 * s, 6 * s), Radius.circular(3 * s)),
        Paint()..color = const Color(0xFFFF5A5F));
  }

  void _palm(Offset base) {
    final s = _w / 390;
    final trunk = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx - 6 * s, base.dy - 60 * s, base.dx - 22 * s, base.dy - 110 * s);
    _c.drawPath(
        trunk,
        Paint()
          ..color = const Color(0xFFB9784A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10 * s
          ..strokeCap = StrokeCap.round);
    final crown = base + Offset(-22 * s, -110 * s);
    final sway = sin(_t * 2 * pi * 3) * 0.06;
    final leaf = Paint()..color = const Color(0xFF4E9A36);
    for (final a in [-2.6, -2.0, -1.2, -0.5, 0.1]) {
      final ang = a + sway;
      final tip = crown + Offset(cos(ang) * 58 * s, sin(ang) * 58 * s + 26 * s);
      final ctrl = crown + Offset(cos(ang) * 30 * s, sin(ang) * 30 * s - 14 * s);
      _c.drawPath(
          Path()
            ..moveTo(crown.dx, crown.dy)
            ..quadraticBezierTo(ctrl.dx, ctrl.dy - 8 * s, tip.dx, tip.dy)
            ..quadraticBezierTo(ctrl.dx, ctrl.dy + 8 * s, crown.dx, crown.dy)
            ..close(),
          leaf);
    }
    _c.drawCircle(crown + Offset(4 * s, 6 * s), 6 * s, Paint()..color = const Color(0xFF8A5A3A));
    _c.drawCircle(crown + Offset(-6 * s, 8 * s), 6 * s, Paint()..color = const Color(0xFF8A5A3A));
  }

  void _starfish(Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -pi / 2 + i * pi / 5;
      final p = c + Offset(cos(a) * rr, sin(a) * rr);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    _c.drawPath(path..close(), Paint()..color = color);
  }

  void _shell(Offset c, double r) {
    _c.drawPath(
        Path()
          ..moveTo(c.dx - r, c.dy)
          ..quadraticBezierTo(c.dx, c.dy - r * 1.6, c.dx + r, c.dy)
          ..close(),
        Paint()..color = const Color(0xFFFFC4D6));
    for (final dx in [-0.5, 0.0, 0.5]) {
      _c.drawLine(Offset(c.dx, c.dy), Offset(c.dx + dx * r, c.dy - r * 0.7),
          Paint()
            ..color = const Color(0xFFE59AB3)
            ..strokeWidth = 1.2);
    }
  }

  void _sparkle(Offset c, double r, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 2)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 2, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 2)
      ..close();
    _c.drawPath(path, Paint()..color = color);
  }
}

/// A gentle hill line: height as a fraction of the screen, wobbling on a sine.
class _Ridge {
  final double base;
  final double amp;
  final double waves;
  final double phase;
  const _Ridge(this.base, this.amp, this.waves, this.phase);

  double y(double x, double w, double h) =>
      h * (base + amp * sin(x / w * 2 * pi * waves + phase));
}
