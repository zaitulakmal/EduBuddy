import 'dart:math';
import 'package:flutter/material.dart';

class StorySceneWidget extends StatefulWidget {
  final int storybookId;
  final int pageNumber;

  const StorySceneWidget({
    super.key,
    required this.storybookId,
    required this.pageNumber,
  });

  @override
  State<StorySceneWidget> createState() => _StorySceneWidgetState();
}

class _StorySceneWidgetState extends State<StorySceneWidget>
    with TickerProviderStateMixin {
  late AnimationController _slow;
  late AnimationController _fast;
  late AnimationController _medium;
  late Animation<double> _slowAnim;
  late Animation<double> _fastAnim;
  late Animation<double> _mediumAnim;

  @override
  void initState() {
    super.initState();
    _slow = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _medium = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _fast = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _slowAnim = CurvedAnimation(parent: _slow, curve: Curves.easeInOut);
    _mediumAnim = CurvedAnimation(parent: _medium, curve: Curves.easeInOut);
    _fastAnim = CurvedAnimation(parent: _fast, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _slow.dispose();
    _medium.dispose();
    _fast.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slowAnim, _mediumAnim, _fastAnim]),
      builder: (_, __) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: CustomPaint(
            painter: _getPainter(),
            child: SizedBox.expand(),
          ),
        );
      },
    );
  }

  CustomPainter _getPainter() {
    final t = _slowAnim.value;
    final tm = _mediumAnim.value;
    final tf = _fastAnim.value;
    switch (widget.storybookId) {
      case 1:
        return _StarStoryPainter(page: widget.pageNumber, t: t, tm: tm, tf: tf);
      case 2:
        return _LionStoryPainter(page: widget.pageNumber, t: t, tm: tm, tf: tf);
      case 3:
        return _GardenStoryPainter(page: widget.pageNumber, t: t, tm: tm, tf: tf);
      default:
        return _DefaultScenePainter(t: t);
    }
  }
}

// ══════════════════════════════════════════════════════
// STORY 1 — THE LITTLE STAR
// ══════════════════════════════════════════════════════
class _StarStoryPainter extends CustomPainter {
  final int page;
  final double t, tm, tf;
  _StarStoryPainter({required this.page, required this.t, required this.tm, required this.tf});

  @override
  void paint(Canvas canvas, Size size) {
    switch (page) {
      case 1: _page1(canvas, size); break;
      case 2: _page2(canvas, size); break;
      case 3: _page3(canvas, size); break;
      case 4: _page4(canvas, size); break;
      case 5: _page5(canvas, size); break;
    }
  }

  // Page 1: Night sky, tiny sad star, bright stars around, Earth below
  void _page1(Canvas canvas, Size s) {
    _drawNightSky(canvas, s, topColor: const Color(0xFF050520), bottomColor: const Color(0xFF0D1B4E));
    _drawStarField(canvas, s, count: 30, seed: 42);
    _drawCrescentMoon(canvas, s, Offset(s.width * 0.78, s.height * 0.12), 38, t);
    _drawEarth(canvas, s, Offset(s.width / 2, s.height * 1.05), s.width * 0.55);
    // Hero little star (small, dim)
    _drawHeroStar(canvas, s, Offset(s.width * 0.28, s.height * 0.2), 28, t * 0.4 + 0.3,
        color: const Color(0xFFFFE066), sad: true);
    // Two bright nearby stars
    _drawBrightStar(canvas, s, Offset(s.width * 0.6, s.height * 0.15), 18, tm);
    _drawBrightStar(canvas, s, Offset(s.width * 0.5, s.height * 0.28), 22, tf);
  }

  // Page 2: Hero star alone, looking at other bright stars
  void _page2(Canvas canvas, Size s) {
    _drawNightSky(canvas, s, topColor: const Color(0xFF060618), bottomColor: const Color(0xFF0E1A40));
    _drawStarField(canvas, s, count: 20, seed: 99);
    // Big bright stars (others)
    _drawBrightStar(canvas, s, Offset(s.width * 0.65, s.height * 0.18), 30, t);
    _drawBrightStar(canvas, s, Offset(s.width * 0.75, s.height * 0.35), 24, tm);
    _drawBrightStar(canvas, s, Offset(s.width * 0.55, s.height * 0.38), 20, tf);
    // Hero star small and dim looking toward them
    _drawHeroStar(canvas, s, Offset(s.width * 0.2, s.height * 0.5), 22, t * 0.3 + 0.2,
        color: const Color(0xFFFFCC44), sad: true);
    // Sad face on hero star
    _drawSadFace(canvas, s, Offset(s.width * 0.2, s.height * 0.5), 22);
  }

  // Page 3: House on Earth, child looking up, star above
  void _page3(Canvas canvas, Size s) {
    _drawGradient(canvas, s, const Color(0xFF0A0A30), const Color(0xFF1A3060));
    _drawStarField(canvas, s, count: 25, seed: 7);
    _drawMountainSilhouette(canvas, s);
    _drawHouse(canvas, s, Offset(s.width * 0.3, s.height * 0.72), 80);
    _drawChild(canvas, s, Offset(s.width * 0.62, s.height * 0.76));
    // Star above with gentle glow
    _drawHeroStar(canvas, s, Offset(s.width * 0.52, s.height * 0.18), 26, t * 0.6 + 0.4,
        color: const Color(0xFFFFE55C));
    // Light beam from star to child
    _drawLightBeam(canvas, s,
        from: Offset(s.width * 0.52, s.height * 0.22),
        to: Offset(s.width * 0.62, s.height * 0.73),
        opacity: t * 0.3 + 0.1);
  }

  // Page 4: Star glowing warm, happy
  void _page4(Canvas canvas, Size s) {
    _drawGradient(canvas, s, const Color(0xFF08083A), const Color(0xFF1A1060));
    _drawStarField(canvas, s, count: 35, seed: 15);
    // Big glow around hero star
    final glow = t * 0.4 + 0.6;
    final paint = Paint()
      ..color = const Color(0xFFFFE066).withValues(alpha: glow * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.35), 100, paint);
    _drawHeroStar(canvas, s, Offset(s.width / 2, s.height * 0.35), 50, glow,
        color: const Color(0xFFFFE055), sad: false);
    _drawHappyFace(canvas, s, Offset(s.width / 2, s.height * 0.35), 50);
    // Sparkles around
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3 + t * pi;
      final r = 80 + t * 20;
      final pos = Offset(s.width / 2 + cos(angle) * r, s.height * 0.35 + sin(angle) * r);
      _drawSparkle(canvas, s, pos, 8 + tm * 4);
    }
    _drawCrescentMoon(canvas, s, Offset(s.width * 0.82, s.height * 0.12), 30, tm);
  }

  // Page 5: Full celebration - many stars dancing
  void _page5(Canvas canvas, Size s) {
    _drawGradient(canvas, s, const Color(0xFF04042E), const Color(0xFF12106A));
    // Animated star field (twinkling)
    _drawAnimatedStarField(canvas, s, count: 50, seed: 22, t: t);
    // Hero star in center, huge and bright
    final glow = t * 0.3 + 0.7;
    final glowPaint = Paint()
      ..color = const Color(0xFFFFE870).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.38), 130, glowPaint);
    _drawHeroStar(canvas, s, Offset(s.width / 2, s.height * 0.38), 60, glow,
        color: const Color(0xFFFFE040), sad: false);
    _drawHappyFace(canvas, s, Offset(s.width / 2, s.height * 0.38), 60);
    // Dancing stars around
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4 + t * 0.8;
      final r = 100 + sin(i + tm * pi) * 20;
      final pos = Offset(s.width / 2 + cos(angle) * r, s.height * 0.38 + sin(angle) * r);
      _drawHeroStar(canvas, s, pos, 18 + tm * 8, 0.6 + tf * 0.4,
          color: [
            const Color(0xFFFFA0A0),
            const Color(0xFFA0C8FF),
            const Color(0xFFA0FFA0),
            const Color(0xFFFFE066),
          ][i % 4]);
    }
    // Earth at bottom with lights
    _drawEarth(canvas, s, Offset(s.width / 2, s.height * 1.08), s.width * 0.6);
    _drawCityLights(canvas, s);
  }

  @override
  bool shouldRepaint(covariant _StarStoryPainter old) =>
      old.t != t || old.tm != tm || old.tf != tf;
}

// ══════════════════════════════════════════════════════
// STORY 2 — RAJA THE BRAVE LION
// ══════════════════════════════════════════════════════
class _LionStoryPainter extends CustomPainter {
  final int page;
  final double t, tm, tf;
  _LionStoryPainter({required this.page, required this.t, required this.tm, required this.tf});

  @override
  void paint(Canvas canvas, Size size) {
    switch (page) {
      case 1: _page1(canvas, size); break;
      case 2: _page2(canvas, size); break;
      case 3: _page3(canvas, size); break;
      case 4: _page4(canvas, size); break;
      case 5: _page5(canvas, size); break;
      case 6: _page6(canvas, size); break;
    }
  }

  // Page 1: Sunny jungle, young lion
  void _page1(Canvas canvas, Size s) {
    _drawSky(canvas, s, const Color(0xFF87CEEB), const Color(0xFF4A9CC8));
    _drawSun(canvas, s, Offset(s.width * 0.82, s.height * 0.12), 40, t);
    _drawClouds(canvas, s, t);
    _drawJungleGround(canvas, s);
    _drawTrees(canvas, s, count: 5, seed: 3);
    _drawBushes(canvas, s);
    _drawLion(canvas, s, Offset(s.width * 0.45, s.height * 0.72), 55, happy: true, t: tm);
    // Flowers
    for (var i = 0; i < 6; i++) {
      _drawFlower(canvas, s, Offset(s.width * (0.1 + i * 0.15), s.height * 0.88),
          20, [Colors.pink, Colors.yellow, Colors.white, Colors.orange, Colors.purple, Colors.red][i]);
    }
  }

  // Page 2: Dark cave entrance, lion looking scared
  void _page2(Canvas canvas, Size s) {
    _drawSky(canvas, s, const Color(0xFF667799), const Color(0xFF334455));
    _drawJungleGround(canvas, s);
    _drawTrees(canvas, s, count: 3, seed: 7);
    // Dark cave
    _drawCave(canvas, s, Offset(s.width * 0.65, s.height * 0.5), 100);
    // Scared lion outside cave
    _drawLion(canvas, s, Offset(s.width * 0.28, s.height * 0.72), 48, happy: false, t: tm);
    // Bats flying out of cave
    _drawBats(canvas, s, t);
    // Mysterious eyes in cave darkness
    _drawEyesInDark(canvas, s, Offset(s.width * 0.68, s.height * 0.52), t);
  }

  // Page 3: Wise elephant speaking
  void _page3(Canvas canvas, Size s) {
    _drawSky(canvas, s, const Color(0xFF9AC8E0), const Color(0xFF6AABCF));
    _drawJungleGround(canvas, s);
    _drawTrees(canvas, s, count: 4, seed: 11);
    _drawSun(canvas, s, Offset(s.width * 0.15, s.height * 0.12), 35, t);
    _drawElephant(canvas, s, Offset(s.width * 0.62, s.height * 0.68), 80);
    _drawLion(canvas, s, Offset(s.width * 0.22, s.height * 0.78), 44, happy: false, t: tm);
    // Speech bubble
    _drawSpeechBubble(canvas, s,
        from: Offset(s.width * 0.62, s.height * 0.42),
        text: '"Be brave!"');
  }

  // Page 4: Lion entering cave, rabbits inside
  void _page4(Canvas canvas, Size s) {
    _drawGradient(canvas, s, const Color(0xFF1A1A1A), const Color(0xFF2A2A3A));
    // Cave walls
    _drawCaveInterior(canvas, s);
    // Torch light
    _drawTorchLight(canvas, s, Offset(s.width * 0.2, s.height * 0.35), tm);
    // Lion walking in (silhouette at entrance)
    _drawLion(canvas, s, Offset(s.width * 0.22, s.height * 0.72), 46, happy: false, t: tm);
    // Rabbits huddled
    for (var i = 0; i < 3; i++) {
      _drawRabbit(canvas, s, Offset(s.width * (0.55 + i * 0.14), s.height * 0.75), 28);
    }
    // Glow from entrance
    final glowP = Paint()
      ..color = const Color(0xFFFFE080).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(0, s.height * 0.5), 80, glowP);
  }

  // Page 5: All animals cheering outside
  void _page5(Canvas canvas, Size s) {
    _drawSky(canvas, s, const Color(0xFF87CEEB), const Color(0xFF5BAAD0));
    _drawSun(canvas, s, Offset(s.width * 0.5, s.height * 0.1), 45, t);
    _drawJungleGround(canvas, s);
    _drawTrees(canvas, s, count: 4, seed: 5);
    _drawLion(canvas, s, Offset(s.width * 0.48, s.height * 0.68), 52, happy: true, t: tm);
    // Rabbits following
    for (var i = 0; i < 3; i++) {
      _drawRabbit(canvas, s, Offset(s.width * (0.68 + i * 0.1), s.height * 0.8), 22);
    }
    // Elephant cheering
    _drawElephant(canvas, s, Offset(s.width * 0.12, s.height * 0.72), 60);
    // Confetti / celebration
    _drawCelebrationConfetti(canvas, s, t);
    // Stars/sparkles in sky
    for (var i = 0; i < 5; i++) {
      _drawSparkle(canvas, s, Offset(s.width * (0.1 + i * 0.2), s.height * 0.2 + sin(i + t * 2) * 20), 12);
    }
  }

  // Page 6: Lion with crown (King of bravery)
  void _page6(Canvas canvas, Size s) {
    _drawGradient(canvas, s, const Color(0xFFFFF3CC), const Color(0xFFFFD966));
    _drawSun(canvas, s, Offset(s.width * 0.5, s.height * 0.12), 55, t);
    _drawJungleGround(canvas, s);
    _drawTrees(canvas, s, count: 6, seed: 9);
    // Heroic lion with crown
    _drawLion(canvas, s, Offset(s.width * 0.5, s.height * 0.65), 65, happy: true, t: tm);
    _drawCrown(canvas, s, Offset(s.width * 0.5, s.height * 0.38), 32);
    // Animals around
    _drawElephant(canvas, s, Offset(s.width * 0.08, s.height * 0.72), 50);
    _drawRabbit(canvas, s, Offset(s.width * 0.78, s.height * 0.82), 24);
    _drawRabbit(canvas, s, Offset(s.width * 0.86, s.height * 0.8), 20);
    // Hearts and sparkles
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4 + t * 0.5;
      final r = 110 + sin(i * 1.3) * 20;
      _drawHeart(canvas, s,
          Offset(s.width * 0.5 + cos(angle) * r, s.height * 0.58 + sin(angle) * r * 0.6),
          10 + tf * 5, Colors.red.withValues(alpha: 0.7 + t * 0.3));
    }
  }

  @override
  bool shouldRepaint(covariant _LionStoryPainter old) =>
      old.t != t || old.tm != tm || old.tf != tf;
}

// ══════════════════════════════════════════════════════
// STORY 3 — THE MAGIC GARDEN
// ══════════════════════════════════════════════════════
class _GardenStoryPainter extends CustomPainter {
  final int page;
  final double t, tm, tf;
  _GardenStoryPainter({required this.page, required this.t, required this.tm, required this.tf});

  @override
  void paint(Canvas canvas, Size size) {
    switch (page) {
      case 1: _page1(canvas, size); break;
      case 2: _page2(canvas, size); break;
      case 3: _page3(canvas, size); break;
      case 4: _page4(canvas, size); break;
      case 5: _page5(canvas, size); break;
    }
  }

  // Page 1: Old school, girl finding golden key
  void _page1(Canvas canvas, Size s) {
    _drawSky(canvas, s, const Color(0xFF87CEEB), const Color(0xFF60B0D0));
    _drawSun(canvas, s, Offset(s.width * 0.8, s.height * 0.12), 40, t);
    _drawClouds(canvas, s, t);
    _drawGardenGround(canvas, s);
    _drawSchoolBuilding(canvas, s, Offset(s.width * 0.38, s.height * 0.38));
    _drawGirl(canvas, s, Offset(s.width * 0.72, s.height * 0.74));
    // Golden key on ground, sparkling
    _drawGoldenKey(canvas, s, Offset(s.width * 0.6, s.height * 0.82), tm);
    _drawSparkle(canvas, s, Offset(s.width * 0.6, s.height * 0.78), 10 + t * 6);
  }

  // Page 2: Colorful garden full of flowers and butterflies
  void _page2(Canvas canvas, Size s) {
    _drawSky(canvas, s, const Color(0xFF98E0FF), const Color(0xFF60C8F0));
    _drawSun(canvas, s, Offset(s.width * 0.5, s.height * 0.08), 50, t);
    _drawClouds(canvas, s, tm);
    _drawGardenGround(canvas, s);
    // Lots of colourful flowers
    final colors = [Colors.pink, Colors.red, Colors.purple, Colors.orange,
      Colors.yellow, Colors.white, Colors.cyan, const Color(0xFFFF00FF)];
    for (var i = 0; i < 10; i++) {
      final x = s.width * (0.05 + i * 0.09);
      final h = 0.7 + sin(i * 1.7) * 0.08;
      _drawFlower(canvas, s, Offset(x, s.height * h), 22 + sin(i * 2.3) * 8,
          colors[i % colors.length]);
    }
    // Butterflies
    for (var i = 0; i < 4; i++) {
      final bx = s.width * (0.1 + i * 0.25) + sin(t * 2 + i) * 15;
      final by = s.height * (0.3 + cos(t + i) * 0.08);
      _drawButterfly(canvas, s, Offset(bx, by), t + i * 0.5,
          [Colors.pink, Colors.orange, Colors.purple, Colors.blue][i]);
    }
  }

  // Page 3: Talking sunflower, Aisha listening
  void _page3(Canvas canvas, Size s) {
    _drawSky(canvas, s, const Color(0xFF87E0FF), const Color(0xFF50B8E8));
    _drawSun(canvas, s, Offset(s.width * 0.18, s.height * 0.1), 42, t);
    _drawGardenGround(canvas, s);
    // Big sunflower (talking)
    _drawSunflower(canvas, s, Offset(s.width * 0.62, s.height * 0.52), 55, tm);
    // Speech bubble from sunflower
    _drawSpeechBubble(canvas, s,
        from: Offset(s.width * 0.62, s.height * 0.28),
        text: '"Sun & Water!"');
    // Girl listening
    _drawGirl(canvas, s, Offset(s.width * 0.25, s.height * 0.74));
    // Other flowers
    _drawFlower(canvas, s, Offset(s.width * 0.1, s.height * 0.82), 18, Colors.pink);
    _drawFlower(canvas, s, Offset(s.width * 0.82, s.height * 0.82), 20, Colors.red);
  }

  // Page 4: Girl watering plants, flowers growing
  void _page4(Canvas canvas, Size s) {
    _drawSky(canvas, s, const Color(0xFFAAE8FF), const Color(0xFF70C8F0));
    _drawSun(canvas, s, Offset(s.width * 0.75, s.height * 0.1), 38, t);
    _drawGardenGround(canvas, s);
    // Girl with watering can
    _drawGirlWatering(canvas, s, Offset(s.width * 0.3, s.height * 0.72), t);
    // Growing flowers at different stages
    for (var i = 0; i < 5; i++) {
      final growth = (0.3 + i * 0.14).clamp(0.0, 1.0);
      final x = s.width * (0.45 + i * 0.1);
      _drawGrowingPlant(canvas, s, Offset(x, s.height * 0.85), growth,
          [Colors.pink, Colors.yellow, Colors.purple, Colors.red, Colors.orange][i]);
    }
    // Water drops
    _drawWaterDrops(canvas, s, Offset(s.width * 0.42, s.height * 0.65), t);
  }

  // Page 5: All friends together in the beautiful garden
  void _page5(Canvas canvas, Size s) {
    _drawSky(canvas, s, const Color(0xFF87CEEB), const Color(0xFF5ABADF));
    _drawSun(canvas, s, Offset(s.width * 0.5, s.height * 0.08), 50, t);
    _drawClouds(canvas, s, tm);
    _drawGardenGround(canvas, s);
    // Many flowers
    final colors2 = [Colors.pink, Colors.red, Colors.purple, Colors.orange, Colors.yellow];
    for (var i = 0; i < 8; i++) {
      _drawFlower(canvas, s, Offset(s.width * (0.04 + i * 0.12), s.height * (0.78 + sin(i.toDouble()) * 0.06)),
          20 + sin(i * 1.5) * 8, colors2[i % colors2.length]);
    }
    // Girl + 3 friends
    _drawGirl(canvas, s, Offset(s.width * 0.3, s.height * 0.72));
    _drawGirlFriend(canvas, s, Offset(s.width * 0.48, s.height * 0.74), Colors.orange);
    _drawGirlFriend(canvas, s, Offset(s.width * 0.63, s.height * 0.73), Colors.purple);
    _drawGirlFriend(canvas, s, Offset(s.width * 0.78, s.height * 0.75), Colors.cyan);
    // Rainbow
    _drawRainbow(canvas, s);
    // Butterflies
    for (var i = 0; i < 5; i++) {
      final bx = s.width * (0.1 + i * 0.2) + sin(t * 1.5 + i) * 20;
      final by = s.height * (0.18 + cos(t + i * 0.8) * 0.06);
      _drawButterfly(canvas, s, Offset(bx, by), t + i * 0.6,
          [Colors.pink, Colors.orange, Colors.blue, Colors.green, Colors.purple][i]);
    }
  }

  @override
  bool shouldRepaint(covariant _GardenStoryPainter old) =>
      old.t != t || old.tm != tm || old.tf != tf;
}

// ══════════════════════════════════════════════════════
// DEFAULT SCENE
// ══════════════════════════════════════════════════════
class _DefaultScenePainter extends CustomPainter {
  final double t;
  _DefaultScenePainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    _drawGradient(canvas, size, const Color(0xFF667EEA), const Color(0xFF764BA2));
    _drawAnimatedStarField(canvas, size, count: 20, seed: 1, t: t);
  }
  @override
  bool shouldRepaint(_DefaultScenePainter old) => old.t != t;
}

// ══════════════════════════════════════════════════════
// SHARED DRAWING PRIMITIVES
// ══════════════════════════════════════════════════════

void _drawGradient(Canvas c, Size s, Color top, Color bottom) {
  final paint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, bottom],
    ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
  c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), paint);
}

void _drawNightSky(Canvas c, Size s, {required Color topColor, required Color bottomColor}) {
  _drawGradient(c, s, topColor, bottomColor);
}

void _drawSky(Canvas c, Size s, Color top, Color bottom) {
  _drawGradient(c, s, top, bottom);
}

void _drawStarField(Canvas c, Size s, {required int count, required int seed}) {
  final rng = Random(seed);
  final p = Paint()..color = Colors.white;
  for (var i = 0; i < count; i++) {
    final x = rng.nextDouble() * s.width;
    final y = rng.nextDouble() * s.height * 0.65;
    final r = rng.nextDouble() * 2.5 + 0.5;
    p.color = Colors.white.withValues(alpha: rng.nextDouble() * 0.6 + 0.4);
    c.drawCircle(Offset(x, y), r, p);
  }
}

void _drawAnimatedStarField(Canvas c, Size s, {required int count, required int seed, required double t}) {
  final rng = Random(seed);
  for (var i = 0; i < count; i++) {
    final x = rng.nextDouble() * s.width;
    final y = rng.nextDouble() * s.height;
    final r = rng.nextDouble() * 2.5 + 0.5;
    final phase = rng.nextDouble() * pi * 2;
    final alpha = 0.4 + sin(t * pi * 2 + phase) * 0.4;
    final p = Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0));
    c.drawCircle(Offset(x, y), r, p);
  }
}

void _drawCrescentMoon(Canvas c, Size s, Offset center, double r, double t) {
  // Glow
  final glowP = Paint()
    ..color = const Color(0xFFFFF4C2).withValues(alpha: 0.2 + t * 0.1)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  c.drawCircle(center, r * 1.4, glowP);
  // Moon body
  final moonP = Paint()..color = const Color(0xFFFFF9C4);
  c.drawCircle(center, r, moonP);
  // Cut-out for crescent
  final cutP = Paint()..blendMode = BlendMode.clear;
  c.drawCircle(center + Offset(r * 0.55, -r * 0.1), r * 0.82, cutP);
  // Small craters
  final craterP = Paint()..color = const Color(0xFFEEE8A0).withValues(alpha: 0.5);
  c.drawCircle(center + Offset(-r * 0.2, r * 0.15), r * 0.12, craterP);
  c.drawCircle(center + Offset(-r * 0.4, -r * 0.2), r * 0.08, craterP);
}

void _drawEarth(Canvas c, Size s, Offset center, double r) {
  // Ocean
  final ocean = Paint()..color = const Color(0xFF1E88E5);
  c.drawCircle(center, r, ocean);
  // Land masses (simplified)
  final land = Paint()..color = const Color(0xFF388E3C);
  c.drawCircle(center + Offset(-r * 0.2, -r * 0.1), r * 0.35, land);
  c.drawCircle(center + Offset(r * 0.25, -r * 0.05), r * 0.28, land);
  c.drawCircle(center + Offset(r * 0.05, r * 0.22), r * 0.22, land);
  // Clouds
  final cloud = Paint()..color = Colors.white.withValues(alpha: 0.6);
  c.drawCircle(center + Offset(-r * 0.1, -r * 0.3), r * 0.15, cloud);
  c.drawCircle(center + Offset(r * 0.3, r * 0.15), r * 0.12, cloud);
}

void _drawCityLights(Canvas c, Size s) {
  final rng = Random(7);
  final p = Paint()..color = const Color(0xFFFFEE88).withValues(alpha: 0.6);
  for (var i = 0; i < 15; i++) {
    final x = rng.nextDouble() * s.width;
    final y = s.height * 0.88 + rng.nextDouble() * s.height * 0.1;
    c.drawCircle(Offset(x, y), 1.5, p);
  }
}

void _drawHeroStar(Canvas c, Size s, Offset pos, double r, double glow,
    {Color color = const Color(0xFFFFE066), bool sad = false}) {
  // Outer glow
  final glowP = Paint()
    ..color = color.withValues(alpha: glow * 0.4)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.2);
  c.drawCircle(pos, r * 1.5, glowP);
  // Star shape (5-pointed)
  _draw5PointStar(c, pos, r, color, innerRatio: 0.4);
  // Face
  if (!sad) {
    _drawHappyFace(c, s, pos, r);
  }
}

void _draw5PointStar(Canvas c, Offset center, double r, Color color, {double innerRatio = 0.4}) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final angle = (i * pi / 5) - pi / 2;
    final radius = i.isEven ? r : r * innerRatio;
    final x = center.dx + cos(angle) * radius;
    final y = center.dy + sin(angle) * radius;
    if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
  }
  path.close();
  c.drawPath(path, Paint()..color = color);
  c.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
}

void _drawBrightStar(Canvas c, Size s, Offset pos, double r, double t) {
  final alpha = 0.6 + t * 0.4;
  _draw5PointStar(c, pos, r, Colors.white.withValues(alpha: alpha));
  final glowP = Paint()
    ..color = Colors.white.withValues(alpha: alpha * 0.3)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8);
  c.drawCircle(pos, r * 1.2, glowP);
}

void _drawSimpleStar(Canvas c, Size s, Offset pos, double r, double t) {
  _draw5PointStar(c, pos, r, const Color(0xFFFFF9C4).withValues(alpha: 0.5 + t * 0.5));
}

void _drawSparkle(Canvas c, Size s, Offset pos, double r) {
  final p = Paint()..color = Colors.white.withValues(alpha: 0.9)..strokeWidth = 1.5..style = PaintingStyle.stroke;
  for (var i = 0; i < 4; i++) {
    final angle = i * pi / 4;
    c.drawLine(pos + Offset(cos(angle) * r * 0.3, sin(angle) * r * 0.3),
        pos + Offset(cos(angle) * r, sin(angle) * r), p);
  }
  c.drawCircle(pos, r * 0.15, Paint()..color = Colors.white);
}

void _drawHappyFace(Canvas c, Size s, Offset pos, double r) {
  final scale = r / 50.0;
  final eyeP = Paint()..color = const Color(0xFF333333);
  // Eyes
  c.drawCircle(pos + Offset(-r * 0.22, -r * 0.1), r * 0.1, eyeP);
  c.drawCircle(pos + Offset(r * 0.22, -r * 0.1), r * 0.1, eyeP);
  // Smile
  final smilePath = Path();
  smilePath.addArc(
    Rect.fromCenter(center: pos + Offset(0, r * 0.05), width: r * 0.5, height: r * 0.3),
    0, pi,
  );
  c.drawPath(smilePath, Paint()..color = const Color(0xFF333333)..style = PaintingStyle.stroke..strokeWidth = scale * 3..strokeCap = StrokeCap.round);
}

void _drawSadFace(Canvas c, Size s, Offset pos, double r) {
  final scale = r / 50.0;
  final eyeP = Paint()..color = const Color(0xFF333333);
  c.drawCircle(pos + Offset(-r * 0.22, -r * 0.05), r * 0.09, eyeP);
  c.drawCircle(pos + Offset(r * 0.22, -r * 0.05), r * 0.09, eyeP);
  final frown = Path();
  frown.addArc(
    Rect.fromCenter(center: pos + Offset(0, r * 0.28), width: r * 0.45, height: r * 0.25),
    pi, pi,
  );
  c.drawPath(frown, Paint()..color = const Color(0xFF333333)..style = PaintingStyle.stroke..strokeWidth = scale * 3..strokeCap = StrokeCap.round);
}

void _drawLightBeam(Canvas c, Size s, {required Offset from, required Offset to, required double opacity}) {
  final p = Paint()
    ..shader = LinearGradient(
      colors: [const Color(0xFFFFE870).withValues(alpha: opacity), Colors.transparent],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromPoints(from, to))
    ..style = PaintingStyle.fill;
  final path = Path()
    ..moveTo(from.dx - 10, from.dy)
    ..lineTo(from.dx + 10, from.dy)
    ..lineTo(to.dx + 20, to.dy)
    ..lineTo(to.dx - 20, to.dy)
    ..close();
  c.drawPath(path, p);
}

void _drawMountainSilhouette(Canvas c, Size s) {
  final p = Paint()..color = const Color(0xFF1A2A4A);
  final path = Path()
    ..moveTo(0, s.height * 0.7)
    ..lineTo(s.width * 0.2, s.height * 0.45)
    ..lineTo(s.width * 0.4, s.height * 0.6)
    ..lineTo(s.width * 0.6, s.height * 0.38)
    ..lineTo(s.width * 0.8, s.height * 0.55)
    ..lineTo(s.width, s.height * 0.42)
    ..lineTo(s.width, s.height * 0.75)
    ..lineTo(0, s.height * 0.75)
    ..close();
  c.drawPath(path, p);
}

void _drawHouse(Canvas c, Size s, Offset pos, double size) {
  final wallP = Paint()..color = const Color(0xFFE8D5B0);
  final roofP = Paint()..color = const Color(0xFFCC4444);
  final doorP = Paint()..color = const Color(0xFF8B4513);
  final windowP = Paint()..color = const Color(0xFFAADDFF);
  final w = size;
  final h = size * 0.8;
  // Wall
  c.drawRect(Rect.fromLTWH(pos.dx - w / 2, pos.dy - h, w, h), wallP);
  // Roof
  final roof = Path()
    ..moveTo(pos.dx - w / 2 - 10, pos.dy - h)
    ..lineTo(pos.dx, pos.dy - h - size * 0.5)
    ..lineTo(pos.dx + w / 2 + 10, pos.dy - h)
    ..close();
  c.drawPath(roof, roofP);
  // Door
  c.drawRRect(
    RRect.fromRectAndCorners(
      Rect.fromLTWH(pos.dx - w * 0.12, pos.dy - h * 0.45, w * 0.24, h * 0.45),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    ),
    doorP,
  );
  // Windows
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx - w * 0.42, pos.dy - h * 0.75, w * 0.22, w * 0.22), const Radius.circular(4)), windowP);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx + w * 0.2, pos.dy - h * 0.75, w * 0.22, w * 0.22), const Radius.circular(4)), windowP);
  // Light in window
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx - w * 0.42, pos.dy - h * 0.75, w * 0.22, w * 0.22), const Radius.circular(4)),
    Paint()..color = const Color(0xFFFFEE88).withValues(alpha: 0.5));
  // Chimney
  c.drawRect(Rect.fromLTWH(pos.dx + w * 0.15, pos.dy - h - size * 0.65, w * 0.14, size * 0.35),
    Paint()..color = const Color(0xFFCC4444));
}

void _drawChild(Canvas c, Size s, Offset pos) {
  // Body
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx - 10, pos.dy - 40, 20, 35), const Radius.circular(5)),
    Paint()..color = const Color(0xFF4FC3F7));
  // Head
  c.drawCircle(pos + const Offset(0, -48), 16, Paint()..color = const Color(0xFFFFCC80));
  // Hair
  c.drawArc(Rect.fromCenter(center: pos + const Offset(0, -55), width: 32, height: 20), pi, pi,
    false, Paint()..color = const Color(0xFF4A3000)..style = PaintingStyle.fill);
  // Arms up (looking at sky)
  final armP = Paint()..color = const Color(0xFFFFCC80)..strokeWidth = 5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
  c.drawLine(pos + const Offset(-10, -28), pos + const Offset(-22, -48), armP);
  c.drawLine(pos + const Offset(10, -28), pos + const Offset(22, -48), armP);
  // Legs
  c.drawLine(pos + const Offset(-5, -5), pos + const Offset(-8, 20), armP..color = const Color(0xFF1565C0));
  c.drawLine(pos + const Offset(5, -5), pos + const Offset(8, 20), armP);
}

// ── Lion primitives ──
void _drawSun(Canvas c, Size s, Offset pos, double r, double t) {
  // Rays
  final rayP = Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.7)..strokeWidth = 2..style = PaintingStyle.stroke;
  for (var i = 0; i < 8; i++) {
    final angle = i * pi / 4 + t * 0.5;
    c.drawLine(pos + Offset(cos(angle) * (r + 6), sin(angle) * (r + 6)),
        pos + Offset(cos(angle) * (r + 20), sin(angle) * (r + 20)), rayP);
  }
  // Body
  c.drawCircle(pos, r, Paint()..color = const Color(0xFFFFD700));
  c.drawCircle(pos, r * 0.85, Paint()..color = const Color(0xFFFFE44D));
}

void _drawClouds(Canvas c, Size s, double t) {
  void cloud(Offset pos, double scale) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.9);
    c.drawCircle(pos, 22 * scale, p);
    c.drawCircle(pos + Offset(20 * scale, 5 * scale), 18 * scale, p);
    c.drawCircle(pos + Offset(-18 * scale, 5 * scale), 16 * scale, p);
    c.drawCircle(pos + Offset(8 * scale, 10 * scale), 20 * scale, p);
  }
  cloud(Offset(s.width * 0.25 + t * 15, s.height * 0.14), 1.0);
  cloud(Offset(s.width * 0.68 + t * 10, s.height * 0.11), 0.75);
}

void _drawJungleGround(Canvas c, Size s) {
  final p = Paint()..color = const Color(0xFF33691E);
  c.drawRect(Rect.fromLTWH(0, s.height * 0.82, s.width, s.height * 0.18), p);
  // Grass tuft details
  final gp = Paint()..color = const Color(0xFF558B2F)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
  final rng = Random(3);
  for (var i = 0; i < 20; i++) {
    final x = rng.nextDouble() * s.width;
    final y = s.height * 0.82;
    c.drawLine(Offset(x, y), Offset(x - 4 + rng.nextDouble() * 8, y - 12 - rng.nextDouble() * 10), gp);
  }
}

void _drawTrees(Canvas c, Size s, {required int count, required int seed}) {
  final rng = Random(seed);
  for (var i = 0; i < count; i++) {
    final x = rng.nextDouble() * s.width;
    final y = s.height * (0.72 + rng.nextDouble() * 0.1);
    final scale = 0.7 + rng.nextDouble() * 0.6;
    _drawSingleTree(c, Offset(x, y), scale * 60);
  }
}

void _drawSingleTree(Canvas c, Offset base, double h) {
  final trunkP = Paint()..color = const Color(0xFF5D4037);
  c.drawRect(Rect.fromLTWH(base.dx - h * 0.08, base.dy - h * 0.4, h * 0.16, h * 0.4), trunkP);
  // Foliage layers
  final leafColors = [const Color(0xFF2E7D32), const Color(0xFF388E3C), const Color(0xFF43A047)];
  for (var layer = 0; layer < 3; layer++) {
    final r = h * (0.35 - layer * 0.05);
    final yo = base.dy - h * (0.4 + layer * 0.2);
    c.drawCircle(Offset(base.dx, yo), r, Paint()..color = leafColors[layer]);
  }
}

void _drawBushes(Canvas c, Size s) {
  final p = Paint()..color = const Color(0xFF2E7D32);
  final positions = [0.08, 0.85, 0.4, 0.6];
  for (final x in positions) {
    c.drawCircle(Offset(s.width * x, s.height * 0.84), 20, p);
    c.drawCircle(Offset(s.width * x + 18, s.height * 0.86), 16, p);
    c.drawCircle(Offset(s.width * x - 18, s.height * 0.86), 15, p);
  }
}

void _drawFlower(Canvas c, Size s, Offset pos, double r, Color color) {
  // Stem
  final stemP = Paint()..color = const Color(0xFF4CAF50)..strokeWidth = 3..style = PaintingStyle.stroke;
  c.drawLine(pos, pos + Offset(0, r * 1.5), stemP);
  // Petals
  final petalP = Paint()..color = color;
  for (var i = 0; i < 5; i++) {
    final angle = i * pi * 2 / 5;
    c.drawCircle(pos + Offset(cos(angle) * r * 0.6, sin(angle) * r * 0.6), r * 0.45, petalP);
  }
  // Center
  c.drawCircle(pos, r * 0.3, Paint()..color = Colors.yellow);
}

void _drawLion(Canvas c, Size s, Offset pos, double r, {required bool happy, required double t}) {
  // Mane (behind head)
  final maneColors = [const Color(0xFFFF8C00), const Color(0xFFE65C00), const Color(0xFFFFAA00)];
  for (var i = 0; i < 8; i++) {
    final angle = i * pi / 4 + t * 0.3;
    final mp = Paint()..color = maneColors[i % 3];
    c.drawCircle(pos + Offset(cos(angle) * r * 0.8, sin(angle) * r * 0.8 - 5), r * 0.38, mp);
  }
  // Body
  c.drawOval(Rect.fromCenter(center: pos + Offset(0, r * 0.7), width: r * 1.2, height: r * 0.9),
    Paint()..color = const Color(0xFFFFC107));
  // Head
  c.drawCircle(pos, r, Paint()..color = const Color(0xFFFFD54F));
  // Ears
  final earP = Paint()..color = const Color(0xFFFFC107);
  c.drawCircle(pos + Offset(-r * 0.65, -r * 0.65), r * 0.28, earP);
  c.drawCircle(pos + Offset(r * 0.65, -r * 0.65), r * 0.28, earP);
  c.drawCircle(pos + Offset(-r * 0.65, -r * 0.65), r * 0.15, Paint()..color = const Color(0xFFFFB74D));
  c.drawCircle(pos + Offset(r * 0.65, -r * 0.65), r * 0.15, Paint()..color = const Color(0xFFFFB74D));
  // Eyes
  final eyeP = Paint()..color = const Color(0xFF4A2C00);
  c.drawCircle(pos + Offset(-r * 0.3, -r * 0.12), r * 0.14, eyeP);
  c.drawCircle(pos + Offset(r * 0.3, -r * 0.12), r * 0.14, eyeP);
  // Eye shines
  c.drawCircle(pos + Offset(-r * 0.26, -r * 0.15), r * 0.05, Paint()..color = Colors.white);
  c.drawCircle(pos + Offset(r * 0.34, -r * 0.15), r * 0.05, Paint()..color = Colors.white);
  // Nose
  final nosePath = Path()
    ..moveTo(pos.dx, pos.dy + r * 0.15)
    ..lineTo(pos.dx - r * 0.1, pos.dy + r * 0.25)
    ..lineTo(pos.dx + r * 0.1, pos.dy + r * 0.25)
    ..close();
  c.drawPath(nosePath, Paint()..color = const Color(0xFFE91E63));
  // Mouth
  final mouthP = Paint()..color = const Color(0xFF4A2C00)..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
  if (happy) {
    c.drawLine(pos + Offset(0, r * 0.28), pos + Offset(-r * 0.22, r * 0.42), mouthP);
    c.drawLine(pos + Offset(0, r * 0.28), pos + Offset(r * 0.22, r * 0.42), mouthP);
    final smilePath = Path();
    smilePath.addArc(Rect.fromCenter(center: pos + Offset(0, r * 0.3), width: r * 0.5, height: r * 0.28), 0, pi);
    c.drawPath(smilePath, mouthP);
  } else {
    final frownPath = Path();
    frownPath.addArc(Rect.fromCenter(center: pos + Offset(0, r * 0.5), width: r * 0.45, height: r * 0.22), pi, pi);
    c.drawPath(frownPath, mouthP);
  }
  // Tail
  final tailP = Paint()..color = const Color(0xFFFFC107)..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
  final tailPath = Path()
    ..moveTo(pos.dx + r * 0.5, pos.dy + r * 1.1)
    ..cubicTo(pos.dx + r * 1.3, pos.dy + r * 1.0, pos.dx + r * 1.4, pos.dy + r * 0.6, pos.dx + r * 1.1, pos.dy + r * 0.4);
  c.drawPath(tailPath, tailP);
  c.drawCircle(pos + Offset(r * 1.1, r * 0.35), r * 0.16, Paint()..color = const Color(0xFFFF8C00));
}

void _drawCave(Canvas c, Size s, Offset pos, double w) {
  final rockP = Paint()..color = const Color(0xFF5D4037);
  final darkP = Paint()..color = const Color(0xFF1A0A00);
  // Cave outline (rocky arch)
  final cavePath = Path()
    ..moveTo(pos.dx - w / 2 - 20, pos.dy + 60)
    ..lineTo(pos.dx - w / 2, pos.dy - 20)
    ..quadraticBezierTo(pos.dx, pos.dy - 80, pos.dx + w / 2, pos.dy - 20)
    ..lineTo(pos.dx + w / 2 + 20, pos.dy + 60)
    ..close();
  c.drawPath(cavePath, rockP);
  // Dark inside
  final innerPath = Path()
    ..moveTo(pos.dx - w / 2 + 15, pos.dy + 55)
    ..lineTo(pos.dx - w / 2 + 15, pos.dy - 10)
    ..quadraticBezierTo(pos.dx, pos.dy - 65, pos.dx + w / 2 - 15, pos.dy - 10)
    ..lineTo(pos.dx + w / 2 - 15, pos.dy + 55)
    ..close();
  c.drawPath(innerPath, darkP);
}

void _drawCaveInterior(Canvas c, Size s) {
  _drawGradient(c, s, const Color(0xFF1A1008), const Color(0xFF0A0805));
  // Rock texture on walls
  final rp = Paint()..color = const Color(0xFF2A1A0A).withValues(alpha: 0.8);
  final rng = Random(5);
  for (var i = 0; i < 8; i++) {
    final x = rng.nextDouble() * s.width * 0.25;
    final y = rng.nextDouble() * s.height;
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 30 + rng.nextDouble() * 40, height: 20 + rng.nextDouble() * 25), rp);
  }
  for (var i = 0; i < 8; i++) {
    final x = s.width * 0.75 + rng.nextDouble() * s.width * 0.25;
    final y = rng.nextDouble() * s.height;
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 30 + rng.nextDouble() * 40, height: 20 + rng.nextDouble() * 25), rp);
  }
}

void _drawTorchLight(Canvas c, Size s, Offset pos, double t) {
  // Torch glow
  final glowP = Paint()
    ..color = const Color(0xFFFF8C00).withValues(alpha: 0.15 + t * 0.1)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
  c.drawCircle(pos, 80, glowP);
  // Flame
  final flamePath = Path()
    ..moveTo(pos.dx, pos.dy + 10)
    ..cubicTo(pos.dx - 12 + t * 8, pos.dy - 10, pos.dx - 8 + t * 4, pos.dy - 30, pos.dx, pos.dy - 40)
    ..cubicTo(pos.dx + 8 - t * 4, pos.dy - 30, pos.dx + 12 - t * 8, pos.dy - 10, pos.dx, pos.dy + 10);
  c.drawPath(flamePath, Paint()..color = const Color(0xFFFF6D00));
  c.drawPath(flamePath, Paint()..color = const Color(0xFFFFD600).withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 2);
  // Handle
  c.drawRect(Rect.fromLTWH(pos.dx - 4, pos.dy + 8, 8, 25), Paint()..color = const Color(0xFF5D4037));
}

void _drawBats(Canvas c, Size s, double t) {
  for (var i = 0; i < 3; i++) {
    final bx = s.width * (0.5 + i * 0.12) + sin(t * 2 + i) * 20;
    final by = s.height * (0.3 + cos(t * 1.5 + i) * 0.1);
    _drawBat(c, Offset(bx, by), t + i * 0.8);
  }
}

void _drawBat(Canvas c, Offset pos, double t) {
  final wingFlap = sin(t * pi * 3);
  final bp = Paint()..color = const Color(0xFF2C1A4A);
  // Body
  c.drawOval(Rect.fromCenter(center: pos, width: 12, height: 8), bp);
  // Wings
  final leftWing = Path()
    ..moveTo(pos.dx - 6, pos.dy)
    ..cubicTo(pos.dx - 20, pos.dy - 15 * wingFlap, pos.dx - 28, pos.dy - 5 * wingFlap, pos.dx - 30, pos.dy + 5 * wingFlap)
    ..cubicTo(pos.dx - 22, pos.dy + 2 * wingFlap, pos.dx - 12, pos.dy + 3, pos.dx - 6, pos.dy);
  final rightWing = Path()
    ..moveTo(pos.dx + 6, pos.dy)
    ..cubicTo(pos.dx + 20, pos.dy - 15 * wingFlap, pos.dx + 28, pos.dy - 5 * wingFlap, pos.dx + 30, pos.dy + 5 * wingFlap)
    ..cubicTo(pos.dx + 22, pos.dy + 2 * wingFlap, pos.dx + 12, pos.dy + 3, pos.dx + 6, pos.dy);
  c.drawPath(leftWing, bp);
  c.drawPath(rightWing, bp);
}

void _drawEyesInDark(Canvas c, Size s, Offset pos, double t) {
  final alpha = 0.5 + t * 0.5;
  final glowP = Paint()..color = const Color(0xFFFFFF00).withValues(alpha: alpha * 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final eyeP = Paint()..color = const Color(0xFFFFFF00).withValues(alpha: alpha);
  for (var i = 0; i < 2; i++) {
    final ex = pos.dx + (i == 0 ? -12 : 12);
    c.drawCircle(Offset(ex, pos.dy), 10, glowP);
    c.drawOval(Rect.fromCenter(center: Offset(ex, pos.dy), width: 12, height: 8), eyeP);
    c.drawOval(Rect.fromCenter(center: Offset(ex, pos.dy), width: 4, height: 7), Paint()..color = Colors.black);
  }
}

void _drawElephant(Canvas c, Size s, Offset pos, double r) {
  final ep = Paint()..color = const Color(0xFF9E9E9E);
  final dp = Paint()..color = const Color(0xFF757575);
  // Body
  c.drawOval(Rect.fromCenter(center: pos + Offset(0, 10), width: r * 1.5, height: r * 1.0), ep);
  // Head
  c.drawCircle(pos + Offset(-r * 0.55, -r * 0.1), r * 0.55, ep);
  // Ear
  c.drawOval(Rect.fromCenter(center: pos + Offset(-r * 0.95, -r * 0.08), width: r * 0.45, height: r * 0.6), dp);
  // Trunk
  final trunkPath = Path()
    ..moveTo(pos.dx - r * 0.78, pos.dy + r * 0.1)
    ..cubicTo(pos.dx - r * 1.1, pos.dy + r * 0.3, pos.dx - r * 1.2, pos.dy + r * 0.6, pos.dx - r * 0.95, pos.dy + r * 0.7);
  c.drawPath(trunkPath, Paint()..color = const Color(0xFF9E9E9E)..strokeWidth = r * 0.22..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  // Eye
  c.drawCircle(pos + Offset(-r * 0.65, -r * 0.22), r * 0.1, Paint()..color = const Color(0xFF212121));
  c.drawCircle(pos + Offset(-r * 0.62, -r * 0.24), r * 0.04, Paint()..color = Colors.white);
  // Legs
  for (var i = 0; i < 4; i++) {
    final lx = pos.dx + (i < 2 ? -r * 0.35 : r * 0.35) + (i % 2 == 0 ? -r * 0.15 : r * 0.15);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(lx - r * 0.14, pos.dy + r * 0.35, r * 0.28, r * 0.45), const Radius.circular(8)), ep);
  }
  // Tail
  c.drawLine(pos + Offset(r * 0.72, r * 0.1), pos + Offset(r * 0.95, r * 0.45),
    Paint()..color = const Color(0xFF9E9E9E)..strokeWidth = 4..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
}

void _drawSpeechBubble(Canvas c, Size s, {required Offset from, required String text}) {
  final bubbleW = 110.0;
  final bubbleH = 42.0;
  final bubblePos = Offset(from.dx - bubbleW / 2, from.dy - bubbleH - 20);

  final rRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(bubblePos.dx, bubblePos.dy, bubbleW, bubbleH),
    const Radius.circular(14),
  );

  // Shadow
  c.drawRRect(rRect, Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  // Bubble body
  c.drawRRect(rRect, Paint()..color = Colors.white);
  c.drawRRect(rRect, Paint()..color = const Color(0xFFE0E0E0)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  // Tail pointing down
  final tailPath = Path()
    ..moveTo(from.dx - 8, bubblePos.dy + bubbleH)
    ..lineTo(from.dx, from.dy - 5)
    ..lineTo(from.dx + 8, bubblePos.dy + bubbleH)
    ..close();
  c.drawPath(tailPath, Paint()..color = Colors.white);

  // Text
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(color: Color(0xFF333333), fontSize: 13, fontWeight: FontWeight.bold),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: bubbleW - 16);
  tp.paint(c, bubblePos + Offset((bubbleW - tp.width) / 2, (bubbleH - tp.height) / 2));
}

void _drawRabbit(Canvas c, Size s, Offset pos, double r) {
  final rp = Paint()..color = const Color(0xFFF5F5F5);
  final pp = Paint()..color = const Color(0xFFFFCDD2);
  // Body
  c.drawOval(Rect.fromCenter(center: pos + Offset(0, r * 0.3), width: r * 1.1, height: r * 0.9), rp);
  // Head
  c.drawCircle(pos, r * 0.55, rp);
  // Ears
  c.drawOval(Rect.fromCenter(center: pos + Offset(-r * 0.22, -r * 0.7), width: r * 0.2, height: r * 0.5), rp);
  c.drawOval(Rect.fromCenter(center: pos + Offset(r * 0.22, -r * 0.7), width: r * 0.2, height: r * 0.5), rp);
  c.drawOval(Rect.fromCenter(center: pos + Offset(-r * 0.22, -r * 0.7), width: r * 0.1, height: r * 0.32), pp);
  c.drawOval(Rect.fromCenter(center: pos + Offset(r * 0.22, -r * 0.7), width: r * 0.1, height: r * 0.32), pp);
  // Eyes
  c.drawCircle(pos + Offset(-r * 0.18, -r * 0.1), r * 0.1, Paint()..color = const Color(0xFFE91E63));
  c.drawCircle(pos + Offset(r * 0.18, -r * 0.1), r * 0.1, Paint()..color = const Color(0xFFE91E63));
  // Nose + tail
  c.drawCircle(pos + Offset(0, r * 0.1), r * 0.06, pp);
  c.drawCircle(pos + Offset(r * 0.55, r * 0.22), r * 0.15, rp);
}

void _drawCrown(Canvas c, Size s, Offset pos, double r) {
  final goldP = Paint()..color = const Color(0xFFFFD700);
  final crownPath = Path()
    ..moveTo(pos.dx - r, pos.dy + r * 0.4)
    ..lineTo(pos.dx - r, pos.dy - r * 0.2)
    ..lineTo(pos.dx - r * 0.6, pos.dy - r * 0.7)
    ..lineTo(pos.dx, pos.dy - r * 0.1)
    ..lineTo(pos.dx + r * 0.6, pos.dy - r * 0.7)
    ..lineTo(pos.dx + r, pos.dy - r * 0.2)
    ..lineTo(pos.dx + r, pos.dy + r * 0.4)
    ..close();
  c.drawPath(crownPath, goldP);
  c.drawPath(crownPath, Paint()..color = const Color(0xFFB8860B)..style = PaintingStyle.stroke..strokeWidth = 2);
  // Gems
  c.drawCircle(pos + Offset(-r * 0.55, pos.dy * 0), r * 0.14, Paint()..color = const Color(0xFFE53935));
  c.drawCircle(pos, r * 0.14, Paint()..color = const Color(0xFF1E88E5));
  c.drawCircle(pos + Offset(r * 0.55, 0), r * 0.14, Paint()..color = const Color(0xFF43A047));
}

void _drawHeart(Canvas c, Size s, Offset pos, double r, Color color) {
  final p = Paint()..color = color;
  final path = Path();
  path.moveTo(pos.dx, pos.dy + r * 0.3);
  path.cubicTo(pos.dx - r * 1.5, pos.dy - r * 0.8, pos.dx - r * 1.5, pos.dy - r * 1.6, pos.dx, pos.dy - r * 0.9);
  path.cubicTo(pos.dx + r * 1.5, pos.dy - r * 1.6, pos.dx + r * 1.5, pos.dy - r * 0.8, pos.dx, pos.dy + r * 0.3);
  c.drawPath(path, p);
}

void _drawCelebrationConfetti(Canvas c, Size s, double t) {
  final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.pink];
  final rng = Random(4);
  for (var i = 0; i < 30; i++) {
    final x = rng.nextDouble() * s.width;
    final y = (rng.nextDouble() * s.height + t * 100) % s.height;
    final color = colors[i % colors.length];
    final rot = rng.nextDouble() * pi;
    c.save();
    c.translate(x, y);
    c.rotate(rot + t * 2);
    c.drawRect(Rect.fromCenter(center: Offset.zero, width: 8, height: 5),
      Paint()..color = color.withValues(alpha: 0.85));
    c.restore();
  }
}

// ── Garden primitives ──
void _drawGardenGround(Canvas c, Size s) {
  final p = Paint()..color = const Color(0xFF558B2F);
  c.drawRect(Rect.fromLTWH(0, s.height * 0.82, s.width, s.height * 0.18), p);
  final gp2 = Paint()..color = const Color(0xFF689F38);
  c.drawRect(Rect.fromLTWH(0, s.height * 0.8, s.width, s.height * 0.04), gp2);
}

void _drawSchoolBuilding(Canvas c, Size s, Offset pos) {
  final wallP = Paint()..color = const Color(0xFFFFCC80);
  final roofP = Paint()..color = const Color(0xFF8D6E63);
  final winP = Paint()..color = const Color(0xFF81D4FA);
  final dP = Paint()..color = const Color(0xFF6D4C41);
  // Main body
  c.drawRect(Rect.fromLTWH(pos.dx - 70, pos.dy - 100, 140, 120), wallP);
  // Roof
  final roof = Path()
    ..moveTo(pos.dx - 80, pos.dy - 100)
    ..lineTo(pos.dx, pos.dy - 150)
    ..lineTo(pos.dx + 80, pos.dy - 100)
    ..close();
  c.drawPath(roof, roofP);
  // Windows (3)
  for (var i = 0; i < 3; i++) {
    final wx = pos.dx - 50 + i * 40.0;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx, pos.dy - 90, 26, 30), const Radius.circular(4)), winP);
  }
  // Door
  c.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(pos.dx - 16, pos.dy - 50, 32, 50),
    topLeft: const Radius.circular(8), topRight: const Radius.circular(8)), dP);
  // Sign "SCHOOL"
  final tp = TextPainter(text: const TextSpan(text: 'SCHOOL', style: TextStyle(color: Color(0xFF5D4037), fontSize: 11, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
  tp.paint(c, Offset(pos.dx - tp.width / 2, pos.dy - 115));
}

void _drawGirl(Canvas c, Size s, Offset pos) {
  // Dress
  c.drawPath(
    (Path()
      ..moveTo(pos.dx - 14, pos.dy - 35)
      ..lineTo(pos.dx - 22, pos.dy + 10)
      ..lineTo(pos.dx + 22, pos.dy + 10)
      ..lineTo(pos.dx + 14, pos.dy - 35)
      ..close()),
    Paint()..color = const Color(0xFFF06292),
  );
  // Body/torso
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx - 12, pos.dy - 58, 24, 26), const Radius.circular(6)),
    Paint()..color = const Color(0xFFF06292),
  );
  // Head
  c.drawCircle(pos + const Offset(0, -72), 18, Paint()..color = const Color(0xFFFFCC80));
  // Hair
  c.drawArc(Rect.fromCenter(center: pos + const Offset(0, -80), width: 38, height: 22), pi, pi,
    false, Paint()..color = const Color(0xFF4A2000)..style = PaintingStyle.fill);
  // Hair ponytail
  c.drawOval(Rect.fromCenter(center: pos + const Offset(18, -70), width: 10, height: 22),
    Paint()..color = const Color(0xFF4A2000));
  // Eyes
  c.drawCircle(pos + const Offset(-6, -73), 4, Paint()..color = const Color(0xFF333333));
  c.drawCircle(pos + const Offset(6, -73), 4, Paint()..color = const Color(0xFF333333));
  c.drawCircle(pos + const Offset(-5, -74), 1.5, Paint()..color = Colors.white);
  c.drawCircle(pos + const Offset(7, -74), 1.5, Paint()..color = Colors.white);
  // Smile
  c.drawArc(Rect.fromCenter(center: pos + const Offset(0, -67), width: 14, height: 8), 0, pi,
    false, Paint()..color = const Color(0xFF333333)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);
  // Arms
  final armP = Paint()..color = const Color(0xFFFFCC80)..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
  c.drawLine(pos + const Offset(-12, -50), pos + const Offset(-26, -32), armP);
  c.drawLine(pos + const Offset(12, -50), pos + const Offset(26, -32), armP);
  // Legs
  final legP = Paint()..color = const Color(0xFFFFCC80)..strokeWidth = 7..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
  c.drawLine(pos + const Offset(-7, 10), pos + const Offset(-10, 36), legP);
  c.drawLine(pos + const Offset(7, 10), pos + const Offset(10, 36), legP);
  // Shoes
  c.drawOval(Rect.fromCenter(center: pos + const Offset(-10, 38), width: 18, height: 10), Paint()..color = const Color(0xFF880E4F));
  c.drawOval(Rect.fromCenter(center: pos + const Offset(10, 38), width: 18, height: 10), Paint()..color = const Color(0xFF880E4F));
}

void _drawGirlFriend(Canvas c, Size s, Offset pos, Color dressColor) {
  c.drawPath(
    (Path()
      ..moveTo(pos.dx - 12, pos.dy - 32)
      ..lineTo(pos.dx - 18, pos.dy + 8)
      ..lineTo(pos.dx + 18, pos.dy + 8)
      ..lineTo(pos.dx + 12, pos.dy - 32)
      ..close()),
    Paint()..color = dressColor,
  );
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx - 10, pos.dy - 52, 20, 22), const Radius.circular(5)), Paint()..color = dressColor);
  c.drawCircle(pos + const Offset(0, -62), 15, Paint()..color = const Color(0xFFFFCC80));
  c.drawCircle(pos + const Offset(-5, -63), 3, Paint()..color = const Color(0xFF333333));
  c.drawCircle(pos + const Offset(5, -63), 3, Paint()..color = const Color(0xFF333333));
  c.drawArc(Rect.fromCenter(center: pos + const Offset(0, -58), width: 12, height: 7), 0, pi,
    false, Paint()..color = const Color(0xFF333333)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);
}

void _drawGoldenKey(Canvas c, Size s, Offset pos, double t) {
  final p = Paint()..color = const Color(0xFFFFD700)..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
  final glow = Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.3 + t * 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  c.drawCircle(pos, 12, glow);
  // Key bow (circle top)
  c.drawCircle(pos, 10, p);
  // Key shaft
  c.drawLine(pos + const Offset(0, 10), pos + const Offset(0, 35), p);
  // Key teeth
  c.drawLine(pos + const Offset(0, 22), pos + const Offset(8, 22), p);
  c.drawLine(pos + const Offset(0, 30), pos + const Offset(6, 30), p);
}

void _drawSunflower(Canvas c, Size s, Offset pos, double r, double t) {
  // Stem
  c.drawLine(pos + Offset(0, r), pos + Offset(0, r * 2.5),
    Paint()..color = const Color(0xFF558B2F)..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  // Petals
  final petalP = Paint()..color = const Color(0xFFFFD600);
  for (var i = 0; i < 12; i++) {
    final angle = i * pi / 6 + t * 0.2;
    c.drawOval(
      Rect.fromCenter(
        center: pos + Offset(cos(angle) * r * 0.72, sin(angle) * r * 0.72),
        width: r * 0.35,
        height: r * 0.6,
      ),
      petalP,
    );
  }
  // Face on sunflower
  c.drawCircle(pos, r * 0.52, Paint()..color = const Color(0xFF5D4037));
  c.drawCircle(pos, r * 0.45, Paint()..color = const Color(0xFF6D4C41));
  // Eyes
  c.drawCircle(pos + Offset(-r * 0.15, -r * 0.08), r * 0.08, Paint()..color = Colors.white);
  c.drawCircle(pos + Offset(r * 0.15, -r * 0.08), r * 0.08, Paint()..color = Colors.white);
  // Smile
  c.drawArc(Rect.fromCenter(center: pos + Offset(0, r * 0.1), width: r * 0.35, height: r * 0.22), 0, pi,
    false, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
}

void _drawButterfly(Canvas c, Size s, Offset pos, double t, Color color) {
  final wing = sin(t * pi * 2) * 0.8;
  final bp = Paint()..color = color.withValues(alpha: 0.85);
  // Upper wings
  c.drawOval(Rect.fromCenter(center: pos + Offset(-15 * wing, -8), width: 28, height: 20), bp);
  c.drawOval(Rect.fromCenter(center: pos + Offset(15 * wing, -8), width: 28, height: 20), bp);
  // Lower wings
  c.drawOval(Rect.fromCenter(center: pos + Offset(-12 * wing, 6), width: 20, height: 14), bp);
  c.drawOval(Rect.fromCenter(center: pos + Offset(12 * wing, 6), width: 20, height: 14), bp);
  // Body
  c.drawOval(Rect.fromCenter(center: pos, width: 6, height: 22), Paint()..color = const Color(0xFF333333));
  // Antennae
  final ap = Paint()..color = const Color(0xFF555555)..strokeWidth = 1.5..style = PaintingStyle.stroke;
  c.drawLine(pos + const Offset(0, -10), pos + const Offset(-8, -22), ap);
  c.drawLine(pos + const Offset(0, -10), pos + const Offset(8, -22), ap);
  c.drawCircle(pos + const Offset(-8, -22), 2.5, Paint()..color = color);
  c.drawCircle(pos + const Offset(8, -22), 2.5, Paint()..color = color);
}

void _drawRainbow(Canvas c, Size s) {
  final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.indigo, Colors.purple];
  for (var i = 0; i < colors.length; i++) {
    final r = s.width * 0.55 - i * 12.0;
    final p = Paint()
      ..color = colors[i].withValues(alpha: 0.55)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    c.drawArc(
      Rect.fromCenter(center: Offset(s.width / 2, s.height * 0.82), width: r * 2, height: r * 1.5),
      pi, pi, false, p,
    );
  }
}

void _drawGirlWatering(Canvas c, Size s, Offset pos, double t) {
  _drawGirl(c, s, pos);
  // Watering can
  final canP = Paint()..color = const Color(0xFF1976D2);
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx + 14, pos.dy - 48, 32, 22), const Radius.circular(5)),
    canP,
  );
  // Spout
  c.drawLine(pos + const Offset(46, -44), pos + const Offset(58, -30),
    Paint()..color = const Color(0xFF1976D2)..strokeWidth = 7..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
}

void _drawWaterDrops(Canvas c, Size s, Offset from, double t) {
  final rng = Random(8);
  final dp = Paint()..color = const Color(0xFF64B5F6).withValues(alpha: 0.8);
  for (var i = 0; i < 8; i++) {
    final progress = ((t + i * 0.12) % 1.0);
    final x = from.dx + rng.nextDouble() * 40 - 20;
    final y = from.dy + progress * 80;
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 5, height: 8), dp);
  }
}

void _drawGrowingPlant(Canvas c, Size s, Offset base, double growth, Color flowerColor) {
  final h = growth * 60;
  // Stem
  c.drawLine(base, base + Offset(0, -h),
    Paint()..color = const Color(0xFF4CAF50)..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  // Leaves
  if (growth > 0.3) {
    c.drawOval(Rect.fromCenter(center: base + Offset(-10, -h * 0.5), width: 18, height: 10),
      Paint()..color = const Color(0xFF66BB6A));
  }
  // Flower (if grown enough)
  if (growth > 0.7) {
    _drawFlower(c, s, base + Offset(0, -h), 12 * growth, flowerColor);
  }
}
