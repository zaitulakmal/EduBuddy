import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';

// Each coloring page is a list of regions. Regions start WHITE (real coloring
// book style) with a small "suggested colour" hint dot; kids tap to fill.
class _Region {
  final String id;
  final Color defaultColor; // suggested colour, shown as a hint dot
  final Path Function(Size) pathBuilder;
  final bool hintDot; // large background regions can opt out
  _Region(this.id, this.defaultColor, this.pathBuilder, {this.hintDot = true});
}

class _ColoringPage {
  final String title;
  final String emoji;
  final List<Color> gradient;
  final List<_Region> Function(Size) regionBuilder;
  final Path Function(Size)? detailBuilder; // stroke-only line art on top
  _ColoringPage(this.title, this.emoji, this.gradient, this.regionBuilder,
      {this.detailBuilder});
}

class ColoringScreen extends StatefulWidget {
  const ColoringScreen({super.key});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _celebrateAnim;
  int _pageIndex = 0;
  Color _selectedColor = const Color(0xFFFF6B35);
  Size _canvasSize = Size.zero;
  final Map<String, Color> _fills = {};
  bool _celebrating = false;

  final List<Color> _palette = [
    const Color(0xFFFF6B35), const Color(0xFFFF5252), const Color(0xFFFF80AB),
    const Color(0xFFFFD700), const Color(0xFF7BC67E), const Color(0xFF4ECDC4),
    const Color(0xFF64B5F6), const Color(0xFFB388FF), const Color(0xFF795548),
    const Color(0xFF9E9E9E), const Color(0xFF000000), Colors.white,
  ];

  // ── Pages ──────────────────────────────────────────────────────────────────

  List<_ColoringPage> get _pages => [
    _ColoringPage('Sunshine', '☀️', AppColors.gradients[6], _sunRegions,
        detailBuilder: _sunDetails),
    _ColoringPage('Happy Cat', '🐱', AppColors.gradients[4], _catRegions,
        detailBuilder: _catDetails),
    _ColoringPage('Big Tree', '🌳', AppColors.gradients[2], _treeRegions,
        detailBuilder: _treeDetails),
    _ColoringPage('Rainbow', '🌈', AppColors.gradients[3], _rainbowRegions,
        detailBuilder: _rainbowDetails),
    _ColoringPage('Cute Fish', '🐟', AppColors.gradients[1], _fishRegions,
        detailBuilder: _fishDetails),
    _ColoringPage('Butterfly', '🦋', AppColors.gradients[0], _butterflyRegions,
        detailBuilder: _butterflyDetails),
  ];

  // Wavy seaweed blade: two S-curved edges joined at a rounded tip.
  Path _seaweed(Offset base, double height, double width) {
    final p = Path();
    final bx = base.dx, by = base.dy;
    p.moveTo(bx - width * 0.5, by);
    p.cubicTo(bx - width * 1.6, by - height * 0.35, bx + width * 0.6, by - height * 0.55,
        bx - width * 0.5, by - height * 0.9);
    p.quadraticBezierTo(bx - width * 0.1, by - height * 1.05, bx + width * 0.35, by - height * 0.85);
    p.cubicTo(bx + width * 1.4, by - height * 0.5, bx - width * 0.5, by - height * 0.3,
        bx + width * 0.5, by);
    p.close();
    return p;
  }

  // Fluffy cloud: union of overlapping circles => one smooth outline.
  Path _cloud(Offset c, double r) {
    var p = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(c.dx, c.dy + r * 0.25), width: r * 3.0, height: r * 1.3));
    p = Path.combine(PathOperation.union, p,
        Path()..addOval(Rect.fromCircle(center: Offset(c.dx - r * 0.7, c.dy), radius: r * 0.72)));
    p = Path.combine(PathOperation.union, p,
        Path()..addOval(Rect.fromCircle(center: Offset(c.dx + r * 0.1, c.dy - r * 0.35), radius: r * 0.85)));
    p = Path.combine(PathOperation.union, p,
        Path()..addOval(Rect.fromCircle(center: Offset(c.dx + r * 0.85, c.dy), radius: r * 0.6)));
    return p;
  }

  // ── Sunshine ────────────────────────────────────────────────────────────────
  List<_Region> _sunRegions(Size s) {
    final w = s.width, h = s.height;
    final sunC = Offset(w * 0.5, h * 0.30);
    final r = s.shortestSide * 0.16;
    return [
      _Region('sky', const Color(0xFF90CAF9), (sz) {
        return Path()..addRect(Rect.fromLTWH(0, 0, sz.width, sz.height));
      }, hintDot: false),
      _Region('ground', const Color(0xFF8BC34A), (sz) {
        final p = Path()..moveTo(0, sz.height * 0.72);
        p.quadraticBezierTo(sz.width * 0.3, sz.height * 0.64, sz.width * 0.55, sz.height * 0.70);
        p.quadraticBezierTo(sz.width * 0.8, sz.height * 0.76, sz.width, sz.height * 0.68);
        p.lineTo(sz.width, sz.height);
        p.lineTo(0, sz.height);
        p.close();
        return p;
      }, hintDot: false),
      _Region('sun_rays', const Color(0xFFFF9800), (sz) {
        final p = Path();
        const beams = 10;
        for (int i = 0; i < beams; i++) {
          final a = i * 2 * pi / beams - pi / 2;
          final inner = r * 1.15;
          final outer = r * 1.7;
          const half = 0.16;
          p.moveTo(sunC.dx + inner * cos(a - half), sunC.dy + inner * sin(a - half));
          p.lineTo(sunC.dx + outer * cos(a), sunC.dy + outer * sin(a));
          p.lineTo(sunC.dx + inner * cos(a + half), sunC.dy + inner * sin(a + half));
          p.close();
        }
        return p;
      }),
      _Region('sun_body', const Color(0xFFFFEB3B), (sz) {
        return Path()..addOval(Rect.fromCircle(center: sunC, radius: r));
      }),
      _Region('cloud_l', Colors.white, (sz) => _cloud(Offset(sz.width * 0.17, sz.height * 0.15), sz.width * 0.075)),
      _Region('cloud_r', Colors.white, (sz) => _cloud(Offset(sz.width * 0.83, sz.height * 0.22), sz.width * 0.065)),
      _Region('flower_petals', const Color(0xFFFF80AB), (sz) {
        final c = Offset(sz.width * 0.22, sz.height * 0.80);
        final pr = sz.width * 0.045;
        var p = Path();
        for (int i = 0; i < 5; i++) {
          final a = i * 2 * pi / 5 - pi / 2;
          final petal = Path()
            ..addOval(Rect.fromCircle(
                center: Offset(c.dx + pr * 1.35 * cos(a), c.dy + pr * 1.35 * sin(a)),
                radius: pr));
          p = i == 0 ? petal : Path.combine(PathOperation.union, p, petal);
        }
        return p;
      }),
      _Region('flower_center', const Color(0xFFFFD700), (sz) {
        final c = Offset(sz.width * 0.22, sz.height * 0.80);
        return Path()..addOval(Rect.fromCircle(center: c, radius: sz.width * 0.032));
      }),
      _Region('flower2_petals', const Color(0xFFB388FF), (sz) {
        final c = Offset(sz.width * 0.78, sz.height * 0.86);
        final pr = sz.width * 0.038;
        var p = Path();
        for (int i = 0; i < 5; i++) {
          final a = i * 2 * pi / 5 - pi / 2;
          final petal = Path()
            ..addOval(Rect.fromCircle(
                center: Offset(c.dx + pr * 1.35 * cos(a), c.dy + pr * 1.35 * sin(a)),
                radius: pr));
          p = i == 0 ? petal : Path.combine(PathOperation.union, p, petal);
        }
        return p;
      }),
      _Region('flower2_center', const Color(0xFFFFD700), (sz) {
        final c = Offset(sz.width * 0.78, sz.height * 0.86);
        return Path()..addOval(Rect.fromCircle(center: c, radius: sz.width * 0.026));
      }),
    ];
  }

  Path _sunDetails(Size sz) {
    final p = Path();
    final sunC = Offset(sz.width * 0.5, sz.height * 0.30);
    final r = sz.shortestSide * 0.16;
    // sleepy happy eyes (arcs) + smile
    p.addArc(Rect.fromCircle(center: Offset(sunC.dx - r * 0.35, sunC.dy - r * 0.15), radius: r * 0.13), pi, pi);
    p.addArc(Rect.fromCircle(center: Offset(sunC.dx + r * 0.35, sunC.dy - r * 0.15), radius: r * 0.13), pi, pi);
    p.addArc(Rect.fromCircle(center: Offset(sunC.dx, sunC.dy + r * 0.25), radius: r * 0.32), 0.15 * pi, 0.7 * pi);
    // flower stems
    p.moveTo(sz.width * 0.22, sz.height * 0.84);
    p.quadraticBezierTo(sz.width * 0.21, sz.height * 0.90, sz.width * 0.22, sz.height * 0.95);
    p.moveTo(sz.width * 0.78, sz.height * 0.895);
    p.quadraticBezierTo(sz.width * 0.79, sz.height * 0.94, sz.width * 0.78, sz.height * 0.98);
    // grass tufts
    for (final gx in [0.08, 0.38, 0.55, 0.65, 0.92]) {
      final x = sz.width * gx;
      final y = sz.height * (0.80 + 0.1 * ((gx * 7) % 1) * 0.5);
      p.moveTo(x, y);
      p.relativeQuadraticBezierTo(-4, -14, -8, -16);
      p.moveTo(x, y);
      p.relativeQuadraticBezierTo(2, -16, 0, -20);
      p.moveTo(x, y);
      p.relativeQuadraticBezierTo(6, -12, 10, -14);
    }
    // birds
    for (final b in [(0.30, 0.12), (0.38, 0.09)]) {
      final bx = sz.width * b.$1, by = sz.height * b.$2;
      p.moveTo(bx - 10, by);
      p.quadraticBezierTo(bx - 5, by - 7, bx, by);
      p.quadraticBezierTo(bx + 5, by - 7, bx + 10, by);
    }
    return p;
  }

  // ── Happy Cat ───────────────────────────────────────────────────────────────
  List<_Region> _catRegions(Size s) {
    final w = s.width, h = s.height;
    final cx = w / 2;
    final headC = Offset(cx, h * 0.33);
    final hr = s.shortestSide * 0.21;
    return [
      _Region('background', const Color(0xFFFFF3E0), (sz) {
        return Path()..addRect(Rect.fromLTWH(0, 0, sz.width, sz.height));
      }, hintDot: false),
      _Region('tail', const Color(0xFFFFB74D), (sz) {
        final p = Path();
        final bx = cx + hr * 1.35, by = sz.height * 0.72;
        p.moveTo(bx - hr * 0.2, by);
        p.cubicTo(bx + hr * 0.9, by + hr * 0.1, bx + hr * 1.1, by - hr * 1.2, bx + hr * 0.35, by - hr * 1.45);
        p.cubicTo(bx + hr * 0.85, by - hr * 1.1, bx + hr * 0.7, by - hr * 0.15, bx - hr * 0.2, by - hr * 0.42);
        p.close();
        return p;
      }),
      _Region('body', const Color(0xFFFFCC80), (sz) {
        final p = Path();
        final top = headC.dy + hr * 0.75;
        final bot = sz.height * 0.82;
        p.moveTo(cx - hr * 1.05, bot);
        p.quadraticBezierTo(cx - hr * 1.15, top + hr * 0.2, cx - hr * 0.55, top);
        p.quadraticBezierTo(cx, top - hr * 0.18, cx + hr * 0.55, top);
        p.quadraticBezierTo(cx + hr * 1.15, top + hr * 0.2, cx + hr * 1.05, bot);
        p.close();
        return p;
      }),
      _Region('tummy', Colors.white, (sz) {
        return Path()
          ..addOval(Rect.fromCenter(
              center: Offset(cx, sz.height * 0.68),
              width: hr * 1.1, height: hr * 1.35));
      }),
      _Region('paw_l', const Color(0xFFFFCC80), (sz) {
        return Path()
          ..addOval(Rect.fromCenter(
              center: Offset(cx - hr * 0.55, sz.height * 0.82),
              width: hr * 0.62, height: hr * 0.45));
      }),
      _Region('paw_r', const Color(0xFFFFCC80), (sz) {
        return Path()
          ..addOval(Rect.fromCenter(
              center: Offset(cx + hr * 0.55, sz.height * 0.82),
              width: hr * 0.62, height: hr * 0.45));
      }),
      _Region('ear_outer_l', const Color(0xFFFFB74D), (sz) {
        final p = Path();
        p.moveTo(headC.dx - hr * 0.85, headC.dy - hr * 0.45);
        p.quadraticBezierTo(headC.dx - hr * 0.95, headC.dy - hr * 1.35, headC.dx - hr * 0.30, headC.dy - hr * 0.95);
        p.quadraticBezierTo(headC.dx - hr * 0.55, headC.dy - hr * 0.75, headC.dx - hr * 0.85, headC.dy - hr * 0.45);
        p.close();
        return p;
      }),
      _Region('ear_outer_r', const Color(0xFFFFB74D), (sz) {
        final p = Path();
        p.moveTo(headC.dx + hr * 0.85, headC.dy - hr * 0.45);
        p.quadraticBezierTo(headC.dx + hr * 0.95, headC.dy - hr * 1.35, headC.dx + hr * 0.30, headC.dy - hr * 0.95);
        p.quadraticBezierTo(headC.dx + hr * 0.55, headC.dy - hr * 0.75, headC.dx + hr * 0.85, headC.dy - hr * 0.45);
        p.close();
        return p;
      }),
      _Region('head', const Color(0xFFFFCC80), (sz) {
        return Path()
          ..addOval(Rect.fromCenter(center: headC, width: hr * 2.1, height: hr * 1.9));
      }),
      _Region('ear_inner_l', const Color(0xFFFF80AB), (sz) {
        final p = Path();
        p.moveTo(headC.dx - hr * 0.68, headC.dy - hr * 0.60);
        p.quadraticBezierTo(headC.dx - hr * 0.75, headC.dy - hr * 1.10, headC.dx - hr * 0.38, headC.dy - hr * 0.85);
        p.close();
        return p;
      }),
      _Region('ear_inner_r', const Color(0xFFFF80AB), (sz) {
        final p = Path();
        p.moveTo(headC.dx + hr * 0.68, headC.dy - hr * 0.60);
        p.quadraticBezierTo(headC.dx + hr * 0.75, headC.dy - hr * 1.10, headC.dx + hr * 0.38, headC.dy - hr * 0.85);
        p.close();
        return p;
      }),
      _Region('nose', const Color(0xFFFF80AB), (sz) {
        final p = Path();
        p.moveTo(headC.dx - hr * 0.10, headC.dy + hr * 0.12);
        p.lineTo(headC.dx + hr * 0.10, headC.dy + hr * 0.12);
        p.quadraticBezierTo(headC.dx, headC.dy + hr * 0.30, headC.dx - hr * 0.10, headC.dy + hr * 0.12);
        p.close();
        return p;
      }),
    ];
  }

  Path _catDetails(Size sz) {
    final cx = sz.width / 2;
    final headC = Offset(cx, sz.height * 0.33);
    final hr = sz.shortestSide * 0.21;
    final p = Path();
    // eyes: outline circles + pupils
    for (final side in [-1, 1]) {
      final e = Offset(headC.dx + side * hr * 0.42, headC.dy - hr * 0.10);
      p.addOval(Rect.fromCircle(center: e, radius: hr * 0.15));
      p.addOval(Rect.fromCircle(center: Offset(e.dx, e.dy + hr * 0.02), radius: hr * 0.055));
    }
    // mouth: w-shape under nose
    p.moveTo(headC.dx, headC.dy + hr * 0.30);
    p.quadraticBezierTo(headC.dx - hr * 0.16, headC.dy + hr * 0.46, headC.dx - hr * 0.30, headC.dy + hr * 0.34);
    p.moveTo(headC.dx, headC.dy + hr * 0.30);
    p.quadraticBezierTo(headC.dx + hr * 0.16, headC.dy + hr * 0.46, headC.dx + hr * 0.30, headC.dy + hr * 0.34);
    // whiskers
    for (final side in [-1, 1]) {
      for (int i = 0; i < 3; i++) {
        final y = headC.dy + hr * (0.12 + i * 0.14);
        p.moveTo(headC.dx + side * hr * 0.55, y);
        p.quadraticBezierTo(headC.dx + side * hr * 1.1, y - hr * 0.05,
            headC.dx + side * hr * 1.45, y + (i - 1) * hr * 0.10);
      }
    }
    // paw toes
    for (final side in [-1, 1]) {
      final px = cx + side * hr * 0.55;
      final py = sz.height * 0.82;
      p.moveTo(px - hr * 0.10, py - hr * 0.05);
      p.lineTo(px - hr * 0.10, py + hr * 0.12);
      p.moveTo(px + hr * 0.10, py - hr * 0.05);
      p.lineTo(px + hr * 0.10, py + hr * 0.12);
    }
    return p;
  }

  // ── Big Tree ────────────────────────────────────────────────────────────────
  List<_Region> _treeRegions(Size s) {
    final w = s.width, h = s.height;
    final cx = w / 2;
    final canopyC = Offset(cx, h * 0.33);
    final cr = s.shortestSide * 0.20;
    return [
      _Region('sky', const Color(0xFF90CAF9), (sz) {
        return Path()..addRect(Rect.fromLTWH(0, 0, sz.width, sz.height));
      }, hintDot: false),
      _Region('ground', const Color(0xFF8BC34A), (sz) {
        final p = Path()..moveTo(0, sz.height * 0.78);
        p.quadraticBezierTo(sz.width * 0.5, sz.height * 0.70, sz.width, sz.height * 0.78);
        p.lineTo(sz.width, sz.height);
        p.lineTo(0, sz.height);
        p.close();
        return p;
      }, hintDot: false),
      _Region('trunk', const Color(0xFF795548), (sz) {
        final p = Path();
        final baseY = sz.height * 0.80;
        final topY = canopyC.dy + cr * 0.6;
        p.moveTo(cx - cr * 0.38, baseY);
        p.quadraticBezierTo(cx - cr * 0.18, baseY - (baseY - topY) * 0.5, cx - cr * 0.22, topY);
        p.lineTo(cx + cr * 0.22, topY);
        p.quadraticBezierTo(cx + cr * 0.18, baseY - (baseY - topY) * 0.5, cx + cr * 0.38, baseY);
        p.quadraticBezierTo(cx, baseY + cr * 0.15, cx - cr * 0.38, baseY);
        p.close();
        return p;
      }),
      _Region('canopy', const Color(0xFF66BB6A), (sz) {
        var p = Path()..addOval(Rect.fromCircle(center: canopyC, radius: cr));
        for (final o in [
          Offset(-cr * 0.95, cr * 0.35), Offset(cr * 0.95, cr * 0.35),
          Offset(-cr * 0.55, -cr * 0.75), Offset(cr * 0.55, -cr * 0.75),
          Offset(0, cr * 0.65),
        ]) {
          p = Path.combine(PathOperation.union, p,
              Path()..addOval(Rect.fromCircle(center: canopyC + o, radius: cr * 0.72)));
        }
        return p;
      }),
      _Region('apple_1', const Color(0xFFEF5350), (sz) =>
          Path()..addOval(Rect.fromCircle(center: canopyC + Offset(-cr * 0.75, cr * 0.1), radius: cr * 0.18))),
      _Region('apple_2', const Color(0xFFEF5350), (sz) =>
          Path()..addOval(Rect.fromCircle(center: canopyC + Offset(cr * 0.55, -cr * 0.45), radius: cr * 0.18))),
      _Region('apple_3', const Color(0xFFEF5350), (sz) =>
          Path()..addOval(Rect.fromCircle(center: canopyC + Offset(cr * 0.35, cr * 0.7), radius: cr * 0.18))),
      _Region('bush', const Color(0xFF7BC67E), (sz) {
        final c = Offset(sz.width * 0.14, sz.height * 0.78);
        var p = Path()..addOval(Rect.fromCircle(center: c, radius: sz.width * 0.07));
        p = Path.combine(PathOperation.union, p,
            Path()..addOval(Rect.fromCircle(center: Offset(c.dx + sz.width * 0.08, c.dy + 4), radius: sz.width * 0.055)));
        p = Path.combine(PathOperation.union, p,
            Path()..addOval(Rect.fromCircle(center: Offset(c.dx - sz.width * 0.07, c.dy + 5), radius: sz.width * 0.05)));
        return p;
      }),
    ];
  }

  Path _treeDetails(Size sz) {
    final cx = sz.width / 2;
    final p = Path();
    final baseY = sz.height * 0.80;
    // bark lines
    p.moveTo(cx - 6, baseY - 8);
    p.quadraticBezierTo(cx - 2, baseY - 40, cx - 8, baseY - 70);
    p.moveTo(cx + 8, baseY - 14);
    p.quadraticBezierTo(cx + 5, baseY - 45, cx + 10, baseY - 75);
    // apple stems
    final canopyC = Offset(cx, sz.height * 0.33);
    final cr = sz.shortestSide * 0.20;
    for (final o in [Offset(-cr * 0.75, cr * 0.1), Offset(cr * 0.55, -cr * 0.45), Offset(cr * 0.35, cr * 0.7)]) {
      final a = canopyC + o;
      p.moveTo(a.dx, a.dy - cr * 0.18);
      p.quadraticBezierTo(a.dx + 3, a.dy - cr * 0.28, a.dx + 6, a.dy - cr * 0.30);
    }
    // grass tufts
    for (final gx in [0.3, 0.5, 0.72, 0.9]) {
      final x = sz.width * gx;
      final y = sz.height * 0.85;
      p.moveTo(x, y);
      p.relativeQuadraticBezierTo(-4, -12, -8, -14);
      p.moveTo(x, y);
      p.relativeQuadraticBezierTo(2, -14, 0, -18);
      p.moveTo(x, y);
      p.relativeQuadraticBezierTo(6, -10, 10, -12);
    }
    return p;
  }

  // ── Rainbow ────────────────────────────────────────────────────────────────
  List<_Region> _rainbowRegions(Size s) {
    final cx = s.width / 2, cy = s.height * 0.72;
    final bands = [
      const Color(0xFFEF5350), const Color(0xFFFF9800), const Color(0xFFFFEE58),
      const Color(0xFF66BB6A), const Color(0xFF42A5F5), const Color(0xFFAB47BC),
    ];
    final maxR = s.width * 0.46;
    final bandW = s.width * 0.055;
    return [
      _Region('sky', const Color(0xFF90CAF9), (sz) {
        return Path()..addRect(Rect.fromLTWH(0, 0, sz.width, sz.height));
      }, hintDot: false),
      _Region('sun_corner', const Color(0xFFFFEB3B), (sz) {
        final c = Offset(sz.width * 0.08, sz.height * 0.08);
        var p = Path()..addOval(Rect.fromCircle(center: c, radius: sz.width * 0.13));
        // rays
        for (int i = 0; i < 6; i++) {
          final a = i * pi / 5 - pi / 12;
          final ray = Path();
          ray.moveTo(c.dx + sz.width * 0.15 * cos(a - 0.1), c.dy + sz.width * 0.15 * sin(a - 0.1));
          ray.lineTo(c.dx + sz.width * 0.22 * cos(a), c.dy + sz.width * 0.22 * sin(a));
          ray.lineTo(c.dx + sz.width * 0.15 * cos(a + 0.1), c.dy + sz.width * 0.15 * sin(a + 0.1));
          ray.close();
          p = Path.combine(PathOperation.union, p, ray);
        }
        return p;
      }),
      // bands drawn big -> small; each half-disc covers the previous
      for (int i = 0; i < bands.length; i++)
        _Region('band_$i', bands[i], (sz) {
          final r = maxR - i * bandW;
          final p = Path();
          p.moveTo(cx - r, cy);
          p.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), pi, pi, false);
          p.close();
          return p;
        }),
      _Region('arch_inside', const Color(0xFFE1F5FE), (sz) {
        final r = maxR - bands.length * bandW;
        final p = Path();
        p.moveTo(cx - r, cy);
        p.arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r), pi, pi, false);
        p.close();
        return p;
      }),
      _Region('cloud_l', Colors.white, (sz) =>
          _cloud(Offset(cx - maxR, cy - sz.width * 0.01), sz.width * 0.085)),
      _Region('cloud_r', Colors.white, (sz) =>
          _cloud(Offset(cx + maxR, cy - sz.width * 0.01), sz.width * 0.085)),
      _Region('heart', const Color(0xFFFF80AB), (sz) {
        final c = Offset(sz.width * 0.85, sz.height * 0.18);
        final r = sz.width * 0.05;
        final p = Path();
        p.moveTo(c.dx, c.dy + r);
        p.cubicTo(c.dx - r * 1.6, c.dy, c.dx - r * 1.2, c.dy - r * 1.4, c.dx, c.dy - r * 0.5);
        p.cubicTo(c.dx + r * 1.2, c.dy - r * 1.4, c.dx + r * 1.6, c.dy, c.dx, c.dy + r);
        p.close();
        return p;
      }),
    ];
  }

  Path _rainbowDetails(Size sz) {
    final p = Path();
    // sparkle crosses in the sky
    for (final sp in [(0.3, 0.2), (0.55, 0.12), (0.68, 0.3)]) {
      final x = sz.width * sp.$1, y = sz.height * sp.$2;
      p.moveTo(x - 7, y);
      p.lineTo(x + 7, y);
      p.moveTo(x, y - 7);
      p.lineTo(x, y + 7);
    }
    return p;
  }

  // ── Cute Fish ───────────────────────────────────────────────────────────────
  List<_Region> _fishRegions(Size s) {
    final w = s.width, h = s.height;
    final fc = Offset(w * 0.45, h * 0.40);
    final fw = w * 0.30, fh = h * 0.13;
    return [
      _Region('water', const Color(0xFF81D4FA), (sz) {
        return Path()..addRect(Rect.fromLTWH(0, 0, sz.width, sz.height));
      }, hintDot: false),
      _Region('sand', const Color(0xFFFFE0B2), (sz) {
        final p = Path()..moveTo(0, sz.height * 0.85);
        p.quadraticBezierTo(sz.width * 0.25, sz.height * 0.80, sz.width * 0.5, sz.height * 0.85);
        p.quadraticBezierTo(sz.width * 0.75, sz.height * 0.90, sz.width, sz.height * 0.84);
        p.lineTo(sz.width, sz.height);
        p.lineTo(0, sz.height);
        p.close();
        return p;
      }, hintDot: false),
      _Region('seaweed_1', const Color(0xFF66BB6A), (sz) =>
          _seaweed(Offset(sz.width * 0.12, sz.height * 0.88), sz.height * 0.28, sz.width * 0.05)),
      _Region('seaweed_2', const Color(0xFF4CAF50), (sz) =>
          _seaweed(Offset(sz.width * 0.88, sz.height * 0.87), sz.height * 0.32, sz.width * 0.055)),
      _Region('starfish', const Color(0xFFFF8A65), (sz) {
        final c = Offset(sz.width * 0.3, sz.height * 0.91);
        final r = sz.width * 0.055;
        final p = Path();
        for (int i = 0; i < 10; i++) {
          final a = i * pi / 5 - pi / 2;
          final rad = i.isEven ? r : r * 0.45;
          final pt = Offset(c.dx + rad * cos(a), c.dy + rad * sin(a));
          if (i == 0) {
            p.moveTo(pt.dx, pt.dy);
          } else {
            p.lineTo(pt.dx, pt.dy);
          }
        }
        p.close();
        return p;
      }),
      _Region('fish_tail', const Color(0xFFFF8A65), (sz) {
        final p = Path();
        final tx = fc.dx + fw * 0.92;
        p.moveTo(tx - fw * 0.15, fc.dy);
        p.quadraticBezierTo(tx + fw * 0.35, fc.dy - fh * 1.5, tx + fw * 0.45, fc.dy - fh * 0.9);
        p.quadraticBezierTo(tx + fw * 0.18, fc.dy - fh * 0.1, tx + fw * 0.45, fc.dy + fh * 0.9);
        p.quadraticBezierTo(tx + fw * 0.35, fc.dy + fh * 1.5, tx - fw * 0.15, fc.dy);
        p.close();
        return p;
      }),
      _Region('fin_top', const Color(0xFFFF8A65), (sz) {
        final p = Path();
        p.moveTo(fc.dx - fw * 0.15, fc.dy - fh * 0.85);
        p.quadraticBezierTo(fc.dx + fw * 0.05, fc.dy - fh * 1.8, fc.dx + fw * 0.42, fc.dy - fh * 0.85);
        p.close();
        return p;
      }),
      _Region('fish_body', const Color(0xFFFF7043), (sz) {
        final p = Path();
        p.moveTo(fc.dx - fw, fc.dy);
        p.cubicTo(fc.dx - fw * 0.6, fc.dy - fh * 1.15, fc.dx + fw * 0.5, fc.dy - fh * 1.1, fc.dx + fw, fc.dy);
        p.cubicTo(fc.dx + fw * 0.5, fc.dy + fh * 1.1, fc.dx - fw * 0.6, fc.dy + fh * 1.15, fc.dx - fw, fc.dy);
        p.close();
        return p;
      }),
      _Region('fin_side', const Color(0xFFFFAB91), (sz) {
        final p = Path();
        p.moveTo(fc.dx + fw * 0.05, fc.dy + fh * 0.1);
        p.quadraticBezierTo(fc.dx + fw * 0.4, fc.dy + fh * 0.5, fc.dx + fw * 0.28, fc.dy + fh * 0.95);
        p.quadraticBezierTo(fc.dx + fw * 0.05, fc.dy + fh * 0.6, fc.dx + fw * 0.05, fc.dy + fh * 0.1);
        p.close();
        return p;
      }),
      _Region('bubbles', Colors.white, (sz) {
        final p = Path();
        p.addOval(Rect.fromCircle(center: Offset(fc.dx - fw * 1.35, fc.dy - fh * 1.6), radius: sz.width * 0.028));
        p.addOval(Rect.fromCircle(center: Offset(fc.dx - fw * 1.15, fc.dy - fh * 2.6), radius: sz.width * 0.020));
        p.addOval(Rect.fromCircle(center: Offset(fc.dx - fw * 1.45, fc.dy - fh * 3.4), radius: sz.width * 0.024));
        return p;
      }),
    ];
  }

  Path _fishDetails(Size sz) {
    final fc = Offset(sz.width * 0.45, sz.height * 0.40);
    final fw = sz.width * 0.30, fh = sz.height * 0.13;
    final p = Path();
    // eye + pupil
    p.addOval(Rect.fromCircle(center: Offset(fc.dx - fw * 0.55, fc.dy - fh * 0.2), radius: fw * 0.11));
    p.addOval(Rect.fromCircle(center: Offset(fc.dx - fw * 0.52, fc.dy - fh * 0.18), radius: fw * 0.045));
    // smile
    p.moveTo(fc.dx - fw * 0.85, fc.dy + fh * 0.25);
    p.quadraticBezierTo(fc.dx - fw * 0.7, fc.dy + fh * 0.5, fc.dx - fw * 0.5, fc.dy + fh * 0.4);
    // gill
    p.moveTo(fc.dx - fw * 0.3, fc.dy - fh * 0.5);
    p.quadraticBezierTo(fc.dx - fw * 0.15, fc.dy, fc.dx - fw * 0.3, fc.dy + fh * 0.5);
    // scales
    for (final sc in [(0.05, -0.35), (0.3, -0.3), (0.15, 0.15), (0.42, 0.2)]) {
      final x = fc.dx + fw * sc.$1, y = fc.dy + fh * sc.$2 * 2;
      p.addArc(Rect.fromCircle(center: Offset(x, y), radius: fw * 0.09), 0.2 * pi, 0.6 * pi);
    }
    // sand dots
    for (final d in [(0.5, 0.92), (0.62, 0.90), (0.75, 0.93)]) {
      p.addOval(Rect.fromCircle(center: Offset(sz.width * d.$1, sz.height * d.$2), radius: 2.5));
    }
    return p;
  }

  // ── Butterfly ───────────────────────────────────────────────────────────────
  List<_Region> _butterflyRegions(Size s) {
    final w = s.width, h = s.height;
    final cx = w / 2, cy = h * 0.44;
    final ww = w * 0.30; // wing size
    return [
      _Region('sky', const Color(0xFFE1F5FE), (sz) {
        return Path()..addRect(Rect.fromLTWH(0, 0, sz.width, sz.height));
      }, hintDot: false),
      _Region('grass', const Color(0xFF8BC34A), (sz) {
        final p = Path()..moveTo(0, sz.height * 0.86);
        p.quadraticBezierTo(sz.width * 0.5, sz.height * 0.80, sz.width, sz.height * 0.86);
        p.lineTo(sz.width, sz.height);
        p.lineTo(0, sz.height);
        p.close();
        return p;
      }, hintDot: false),
      for (final side in [-1, 1])
        _Region(side < 0 ? 'wing_top_l' : 'wing_top_r', const Color(0xFF64B5F6), (sz) {
          final p = Path();
          p.moveTo(cx, cy - ww * 0.1);
          p.cubicTo(cx + side * ww * 0.5, cy - ww * 1.35, cx + side * ww * 1.5, cy - ww * 1.1, cx + side * ww * 1.25, cy - ww * 0.25);
          p.cubicTo(cx + side * ww * 1.15, cy + ww * 0.15, cx + side * ww * 0.4, cy + ww * 0.15, cx, cy - ww * 0.1);
          p.close();
          return p;
        }),
      for (final side in [-1, 1])
        _Region(side < 0 ? 'wing_bot_l' : 'wing_bot_r', const Color(0xFFB388FF), (sz) {
          final p = Path();
          p.moveTo(cx, cy + ww * 0.05);
          p.cubicTo(cx + side * ww * 0.75, cy + ww * 0.05, cx + side * ww * 1.05, cy + ww * 0.75, cx + side * ww * 0.6, cy + ww * 1.05);
          p.cubicTo(cx + side * ww * 0.25, cy + ww * 1.25, cx, cy + ww * 0.55, cx, cy + ww * 0.05);
          p.close();
          return p;
        }),
      for (final spot in [(-1.0, -0.75, 0.20), (1.0, -0.75, 0.20), (-0.55, 0.6, 0.14), (0.55, 0.6, 0.14)])
        _Region('spot_${spot.$1}_${spot.$2}', const Color(0xFFFFD700), (sz) {
          return Path()
            ..addOval(Rect.fromCircle(
                center: Offset(cx + spot.$1 * ww * 0.85, cy + spot.$2 * ww),
                radius: ww * spot.$3));
        }),
      _Region('body', const Color(0xFF795548), (sz) {
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy + ww * 0.1), width: ww * 0.28, height: ww * 1.5),
              Radius.circular(ww * 0.14)));
      }),
      _Region('head', const Color(0xFF795548), (sz) {
        return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy - ww * 0.75), radius: ww * 0.19));
      }),
    ];
  }

  Path _butterflyDetails(Size sz) {
    final cx = sz.width / 2, cy = sz.height * 0.44;
    final ww = sz.width * 0.30;
    final p = Path();
    // antennae with curls
    for (final side in [-1, 1]) {
      p.moveTo(cx + side * ww * 0.08, cy - ww * 0.88);
      p.quadraticBezierTo(cx + side * ww * 0.3, cy - ww * 1.3, cx + side * ww * 0.45, cy - ww * 1.35);
      p.addOval(Rect.fromCircle(center: Offset(cx + side * ww * 0.5, cy - ww * 1.36), radius: 3));
    }
    // face
    p.addOval(Rect.fromCircle(center: Offset(cx - ww * 0.06, cy - ww * 0.78), radius: 2.5));
    p.addOval(Rect.fromCircle(center: Offset(cx + ww * 0.06, cy - ww * 0.78), radius: 2.5));
    p.addArc(Rect.fromCircle(center: Offset(cx, cy - ww * 0.72), radius: ww * 0.08), 0.2 * pi, 0.6 * pi);
    // body segments
    for (int i = 0; i < 3; i++) {
      final y = cy - ww * 0.25 + i * ww * 0.35;
      p.moveTo(cx - ww * 0.13, y);
      p.lineTo(cx + ww * 0.13, y);
    }
    // wing veins
    for (final side in [-1, 1]) {
      p.moveTo(cx + side * ww * 0.15, cy - ww * 0.3);
      p.quadraticBezierTo(cx + side * ww * 0.6, cy - ww * 0.7, cx + side * ww * 1.0, cy - ww * 0.7);
      p.moveTo(cx + side * ww * 0.12, cy + ww * 0.25);
      p.quadraticBezierTo(cx + side * ww * 0.45, cy + ww * 0.5, cx + side * ww * 0.65, cy + ww * 0.8);
    }
    // grass tufts
    for (final gx in [0.15, 0.45, 0.7, 0.9]) {
      final x = sz.width * gx;
      final y = sz.height * 0.92;
      p.moveTo(x, y);
      p.relativeQuadraticBezierTo(-4, -12, -8, -14);
      p.moveTo(x, y);
      p.relativeQuadraticBezierTo(2, -14, 0, -18);
      p.moveTo(x, y);
      p.relativeQuadraticBezierTo(6, -10, 10, -12);
    }
    return p;
  }

  // ── Hit test ───────────────────────────────────────────────────────────────
  void _onTap(Offset localPos) {
    final page = _pages[_pageIndex];
    final regions = page.regionBuilder(_canvasSize);
    // Test from top (last rendered) to bottom
    for (final region in regions.reversed) {
      final path = region.pathBuilder(_canvasSize);
      if (path.contains(localPos)) {
        SoundService.instance.tap();
        setState(() => _fills['${_pageIndex}_${region.id}'] = _selectedColor);
        return;
      }
    }
  }

  void _checkDone() {
    final page = _pages[_pageIndex];
    final regions = page.regionBuilder(_canvasSize);
    final allFilled = regions.every((r) => _fills.containsKey('${_pageIndex}_${r.id}'));
    if (allFilled && !_celebrating) {
      setState(() => _celebrating = true);
      SoundService.instance.complete();
      _confettiController.play();
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _celebrating = false);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _celebrateAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _celebrateAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_pageIndex];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: page.gradient[0],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${page.emoji} ${page.title}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Reset',
            onPressed: () => setState(() {
              _fills.removeWhere((k, _) => k.startsWith('${_pageIndex}_'));
              _celebrating = false;
            }),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildPageSelector(),
              Expanded(child: _buildCanvas(page)),
              _buildPalette(),
              _buildHint(),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 60,
              gravity: 0.2,
              colors: AppColors.gradients.map((g) => g[0]).toList(),
            ),
          ),
          if (_celebrating) _buildCelebrationBanner(page),
        ],
      ),
    );
  }

  Widget _buildCelebrationBanner(_ColoringPage page) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _celebrateAnim,
            builder: (_, _) => Transform.scale(
              scale: 0.92 + 0.08 * _celebrateAnim.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: page.gradient),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: page.gradient[0].withValues(alpha: 0.5), blurRadius: 30)],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎨', style: TextStyle(fontSize: 52)),
                    SizedBox(height: 8),
                    Text('Masterpiece!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                    Text('You colored it all!', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageSelector() {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _pages.length,
        itemBuilder: (_, i) {
          final p = _pages[i];
          final selected = i == _pageIndex;
          return GestureDetector(
            onTap: () => setState(() => _pageIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: selected ? LinearGradient(colors: p.gradient) : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade200, width: 1.5),
                boxShadow: selected ? [BoxShadow(color: p.gradient[0].withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(p.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? Colors.white : AppColors.textDark)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCanvas(_ColoringPage page) {
    return LayoutBuilder(builder: (_, constraints) {
      _canvasSize = Size(constraints.maxWidth - 32, constraints.maxHeight - 16);
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: GestureDetector(
            onTapUp: (d) {
              _onTap(d.localPosition);
              _checkDone();
            },
            child: CustomPaint(
              painter: _ColoringPainter(
                page: page,
                fills: Map.from(_fills),
                pageIndex: _pageIndex,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPalette() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _palette.map((c) {
            final sel = c == _selectedColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: sel ? 42 : 32,
                height: sel ? 42 : 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? AppColors.textDark : Colors.grey.shade300, width: sel ? 3 : 1.5),
                  boxShadow: sel ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 10)] : [],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: _selectedColor, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Tap any area to fill it — dots show suggested colours!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

// ─── Coloring Painter ─────────────────────────────────────────────────────────

class _ColoringPainter extends CustomPainter {
  final _ColoringPage page;
  final Map<String, Color> fills;
  final int pageIndex;

  _ColoringPainter({required this.page, required this.fills, required this.pageIndex});

  static const _ink = Color(0xFF3A3A44);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);

    final regions = page.regionBuilder(size);
    for (final region in regions) {
      final path = region.pathBuilder(size);
      final fill = fills['${pageIndex}_${region.id}'];
      // Real coloring-book style: white until the child fills it
      canvas.drawPath(path, Paint()..color = (fill ?? Colors.white)..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round);
    }

    // Suggested-colour hint dots on unfilled regions
    for (final region in regions) {
      if (!region.hintDot) continue;
      if (fills.containsKey('${pageIndex}_${region.id}')) continue;
      final c = region.pathBuilder(size).getBounds().center;
      canvas.drawCircle(c, 6, Paint()..color = region.defaultColor.withValues(alpha: 0.85));
      canvas.drawCircle(c, 6, Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }

    // Line-art details on top (eyes, whiskers, grass...)
    final details = page.detailBuilder?.call(size);
    if (details != null) {
      canvas.drawPath(details, Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_ColoringPainter old) =>
      old.fills != fills || old.pageIndex != pageIndex;
}
