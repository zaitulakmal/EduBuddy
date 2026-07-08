import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/video_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';

// ── Scene type enum ───────────────────────────────────────────────────────────
enum _SceneType { animals, space, math, rainbow, ocean, abcs, music, garden, general }

_SceneType _sceneFor(String emoji) {
  switch (emoji) {
    case '🐄': case '🦊': case '🐠': return _SceneType.animals;
    case '🚀': return _SceneType.space;
    case '🤖': case '🍎': return _SceneType.math;
    case '🌈': case '⭐': return _SceneType.rainbow;
    case '🔤': return _SceneType.abcs;
    case '🎶': return _SceneType.music;
    case '🌱': return _SceneType.garden;
    default: return _SceneType.general;
  }
}

// Lyric lines per emoji
const _kLyrics = <String, List<String>>{
  '🐄': ['🐄  Old MacDonald had a farm!', '🐓  With a cluck cluck here...', '🐑  And a baa baa there!', '🌾  E-I-E-I-O!'],
  '🦊': ['🦊  Welcome to the wild!', '🦁  Lions roar SO loud!', '🐘  Elephants never forget!', '🐺  Wolves run in packs!'],
  '🤖': ['🔢  Let\'s count together!', '⭐  1 + 1 = 2!', '🤖  Numbers are our friends!', '💡  Can you count to 10?'],
  '🌈': ['🌈  Red, orange, yellow!', '🟢  Green, blue, and more!', '🎨  Mix colors together!', '✨  Rainbows are magic!'],
  '🚀': ['🚀  3... 2... 1... BLAST OFF!', '⭐  Stars are giant suns!', '🪐  Saturn has huge rings!', '🌙  8 planets in our sky!'],
  '🔤': ['📚  A is for Apple!', '✏️  B is for Ball!', '🐱  C is for Cat!', '🎵  Now sing A-B-C!'],
  '🍎': ['➕  2 plus 2 equals 4!', '🍎  Count the apples!', '✋  Use your fingers!', '⭐  Math is super fun!'],
  '🎶': ['🎵  Do Re Mi Fa Sol!', '🎸  Music fills the air!', '🥁  Feel the beat!', '🎤  Sing along with us!'],
  '🐠': ['🌊  Dive into the ocean!', '🐠  Colorful fish swim by!', '🦈  Sharks rule the deep!', '🐙  Octopus has 8 arms!'],
  '⭐': ['⭕  Circles are round!', '⬛  Squares have 4 sides!', '🔺  Triangles have 3!', '✨  Shapes are everywhere!'],
  '🌱': ['💧  Seeds need water!', '☀️  Plants love sunshine!', '🌻  Flowers bloom in spring!', '🍃  Nature is beautiful!'],
};

List<String> _lyricsFor(String emoji) =>
    _kLyrics[emoji] ?? ['⭐  Learning is fun!', '🚀  Keep exploring!', '🧠  You are so smart!', '🎉  Great job!'];

// ── Main Screen ───────────────────────────────────────────────────────────────
class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final AppProvider provider;
  const VideoPlayerScreen({super.key, required this.video, required this.provider});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  bool _hasMarkedWatched = false;

  late AnimationController _mainCtrl;   // drives all scene motion (fast)
  late AnimationController _sceneCtrl;  // drives scene fade/transitions
  late AnimationController _idleCtrl;   // slow idle bob

  int _lyricIndex = 0;
  int _sceneStage = 0; // 0-3 cycling scene stages
  Timer? _lyricTimer;
  Timer? _stageTimer;
  Timer? _progressTimer;
  double _fakeProgress = 0;

  late _SceneType _sceneType;

  @override
  void initState() {
    super.initState();
    _sceneType = _sceneFor(widget.video.thumbnailEmoji);

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _sceneCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _idleCtrl.dispose();
    _sceneCtrl.dispose();
    _lyricTimer?.cancel();
    _stageTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _startTimers();
      if (!_hasMarkedWatched) {
        _hasMarkedWatched = true;
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            widget.provider.markVideoWatched(widget.video.id!);
            _showWatchedSnack();
          }
        });
      }
    } else {
      _stopTimers();
    }
  }

  void _startTimers() {
    _lyricTimer?.cancel();
    _lyricTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final lyrics = _lyricsFor(widget.video.thumbnailEmoji);
      setState(() => _lyricIndex = (_lyricIndex + 1) % lyrics.length);
    });

    _stageTimer?.cancel();
    _stageTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _sceneCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _sceneStage = (_sceneStage + 1) % 4);
        _sceneCtrl.reverse();
      });
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || !_isPlaying) return;
      setState(() {
        _fakeProgress = (_fakeProgress + 0.002).clamp(0.0, 1.0);
        if (_fakeProgress >= 1.0) _fakeProgress = 0;
      });
    });
  }

  void _stopTimers() {
    _lyricTimer?.cancel();
    _stageTimer?.cancel();
    _progressTimer?.cancel();
  }

  void _showWatchedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Text('⭐', style: TextStyle(fontSize: 20)),
        SizedBox(width: 8),
        Text('Video marked as watched! Great job!',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context),
          Expanded(flex: 5, child: _buildScene()),
          const SizedBox(height: 14),
          Expanded(flex: 3, child: _buildInfoCard()),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        BouncyButton(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(widget.video.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }

  Widget _buildScene() {
    final lyrics = _lyricsFor(widget.video.thumbnailEmoji);

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(children: [
            // ── Animated cartoon scene (full background) ─────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_mainCtrl, _idleCtrl]),
                builder: (_, _) {
                  return CustomPaint(
                    painter: _ScenePainter(
                      t: _mainCtrl.value,
                      idle: _idleCtrl.value,
                      stage: _sceneStage,
                      sceneType: _sceneType,
                      isPlaying: _isPlaying,
                    ),
                  );
                },
              ),
            ),

            // ── NOW PLAYING badge + wave bars ─────────────────────────
            if (_isPlaying)
              Positioned(
                top: 14,
                left: 14,
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(children: [
                      Icon(Icons.fiber_manual_record,
                          color: Colors.redAccent, size: 8),
                      SizedBox(width: 5),
                      Text('NOW PLAYING',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  _WaveBars(ctrl: _mainCtrl),
                ]),
              ),

            // ── Pause button top-right ────────────────────────────────
            if (_isPlaying)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pause_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),

            // ── Play button when paused ───────────────────────────────
            if (!_isPlaying)
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white54, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.black38, blurRadius: 20)
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Tap to play! ▶',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),

            // ── Lyric bar at bottom ───────────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Column(children: [
                if (_isPlaying)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0, 0.5), end: Offset.zero)
                            .animate(anim),
                        child: child,
                      ),
                    ),
                    child: Container(
                      key: ValueKey(_lyricIndex),
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.80),
                          ],
                        ),
                      ),
                      child: Text(
                        lyrics[_lyricIndex % lyrics.length],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 6)
                          ],
                        ),
                      ),
                    ),
                  ),
                LinearProgressIndicator(
                  value: _fakeProgress,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Colors.white54),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.video.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Row(children: [
          _InfoChip('⏱ ${widget.video.duration}', Colors.white12),
          const SizedBox(width: 8),
          _InfoChip('👶 ${widget.video.ageGroup}', Colors.white12),
          if (widget.video.isWatched) ...[
            const SizedBox(width: 8),
            _InfoChip('✅ Watched', AppColors.success.withValues(alpha: 0.3)),
          ],
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: Text(widget.video.description,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ── Scene Painter ─────────────────────────────────────────────────────────────
class _ScenePainter extends CustomPainter {
  final double t;
  final double idle;
  final int stage;
  final _SceneType sceneType;
  final bool isPlaying;

  const _ScenePainter({
    required this.t,
    required this.idle,
    required this.stage,
    required this.sceneType,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (sceneType) {
      case _SceneType.animals: _paintAnimals(canvas, size); break;
      case _SceneType.space:   _paintSpace(canvas, size);   break;
      case _SceneType.math:    _paintMath(canvas, size);    break;
      case _SceneType.rainbow: _paintRainbow(canvas, size); break;
      case _SceneType.abcs:    _paintABCs(canvas, size);    break;
      case _SceneType.music:   _paintMusic(canvas, size);   break;
      case _SceneType.garden:  _paintGarden(canvas, size);  break;
      case _SceneType.ocean:   _paintOcean(canvas, size);   break;
      case _SceneType.general: _paintGeneral(canvas, size); break;
    }
  }

  // ── ANIMALS SCENE ────────────────────────────────────────────────────────
  void _paintAnimals(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final at = t * 2 * pi;

    // Sky gradient
    _fillGradient(canvas, size, const Color(0xFF87CEEB), const Color(0xFF98E4FF));

    // Moving clouds
    _drawCloud(canvas, w * 0.1 + sin(at * 0.3) * 20, h * 0.12, 60, Colors.white.withValues(alpha: 0.85));
    _drawCloud(canvas, w * 0.65 + sin(at * 0.2 + 1) * 15, h * 0.08, 45, Colors.white.withValues(alpha: 0.75));
    _drawCloud(canvas, w * 0.42 + sin(at * 0.25) * 18, h * 0.18, 55, Colors.white.withValues(alpha: 0.70));

    // Sun (pulsing)
    final sunR = 28.0 + (isPlaying ? sin(at) * 4 : 0);
    final sunPaint = Paint()..color = const Color(0xFFFFC107);
    canvas.drawCircle(Offset(w * 0.85, h * 0.12), sunR, sunPaint);
    // Sun rays
    for (int i = 0; i < 8; i++) {
      final angle = at * 0.2 + i * pi / 4;
      final p1 = Offset(w * 0.85 + cos(angle) * (sunR + 6), h * 0.12 + sin(angle) * (sunR + 6));
      final p2 = Offset(w * 0.85 + cos(angle) * (sunR + 14), h * 0.12 + sin(angle) * (sunR + 14));
      canvas.drawLine(p1, p2, Paint()..color = const Color(0xFFFFC107)..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    }

    // Green ground
    final groundPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38), groundPaint);
    // Darker ground strip
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.04),
        Paint()..color = const Color(0xFF388E3C));

    // Trees
    _drawTree(canvas, w * 0.1, h * 0.62, h * 0.16, at);
    _drawTree(canvas, w * 0.88, h * 0.62, h * 0.13, at + 1);

    // Grass tufts (animated sway)
    for (int i = 0; i < 8; i++) {
      final gx = w * (0.1 + i * 0.11);
      final sway = sin(at * 0.8 + i) * 3;
      _drawGrass(canvas, gx, h * 0.62, sway);
    }

    // Main animal — lion in center
    final bounceY = isPlaying ? sin(at) * 10 : sin(idle * pi) * 4;
    _drawLion(canvas, Offset(w * 0.5, h * 0.50 + bounceY), h * 0.16, at);

    // Left side — elephant
    final elephantX = w * (0.18 + sin(at * 0.4) * 0.04);
    _drawElephant(canvas, Offset(elephantX, h * 0.56), h * 0.13, at);

    // Right side — giraffe
    _drawGiraffe(canvas, Offset(w * 0.80, h * 0.52), h * 0.15, at);

    // Flowers on ground
    for (int i = 0; i < 5; i++) {
      final fx = w * (0.15 + i * 0.18);
      final bloom = 0.5 + sin(at * 0.5 + i) * 0.5;
      _drawFlower(canvas, Offset(fx, h * 0.65), 7 + bloom * 4);
    }
  }

  // ── SPACE SCENE ──────────────────────────────────────────────────────────
  void _paintSpace(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final at = t * 2 * pi;

    // Deep space background
    _fillGradient(canvas, size, const Color(0xFF0B0B2A), const Color(0xFF1A1A6E));

    // Twinkling stars
    final rng = Random(42);
    for (int i = 0; i < 50; i++) {
      final sx = rng.nextDouble() * w;
      final sy = rng.nextDouble() * h * 0.85;
      final bright = 0.3 + 0.7 * sin(at + i * 0.7).abs();
      final sr = 1.0 + rng.nextDouble() * 2;
      canvas.drawCircle(Offset(sx, sy), sr,
          Paint()..color = Colors.white.withValues(alpha: bright));
    }

    // Milky way streak
    final mwPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.35),
        width: w * 1.4, height: h * 0.25), mwPaint);

    // Earth (bottom-left)
    final earthPaint = Paint()..color = const Color(0xFF1565C0);
    canvas.drawCircle(Offset(w * 0.15, h * 0.78), h * 0.14, earthPaint);
    canvas.drawCircle(Offset(w * 0.15 + h * 0.04, h * 0.72), h * 0.05,
        Paint()..color = const Color(0xFF2E7D32));
    canvas.drawCircle(Offset(w * 0.10, h * 0.80), h * 0.04,
        Paint()..color = const Color(0xFF2E7D32));
    // Earth atmosphere glow
    canvas.drawCircle(Offset(w * 0.15, h * 0.78), h * 0.15,
        Paint()..color = Colors.blue.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Saturn (orbiting)
    final satAngle = at * 0.2;
    final satX = w * 0.5 + cos(satAngle) * w * 0.28;
    final satY = h * 0.32 + sin(satAngle) * h * 0.06;
    final satR = h * 0.08;
    canvas.drawCircle(Offset(satX, satY), satR,
        Paint()..color = const Color(0xFFE8C470));
    // Ring
    final ringPaint = Paint()
      ..color = const Color(0xFFD4A843)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawOval(
        Rect.fromCenter(center: Offset(satX, satY),
            width: satR * 2.8, height: satR * 0.6), ringPaint);

    // Main rocket (center, bouncing)
    final rocketY = h * 0.42 + (isPlaying ? sin(at) * 12 : sin(idle * pi) * 5);
    final rocketTilt = isPlaying ? sin(at * 0.5) * 0.12 : 0.0;
    canvas.save();
    canvas.translate(w * 0.5, rocketY);
    canvas.rotate(rocketTilt);
    _drawRocket(canvas, h * 0.18);
    canvas.restore();

    // Moon
    canvas.drawCircle(Offset(w * 0.85, h * 0.18), h * 0.07,
        Paint()..color = const Color(0xFFE0E0E0));
    canvas.drawCircle(Offset(w * 0.84 + h * 0.02, h * 0.16), h * 0.02,
        Paint()..color = const Color(0xFFBDBDBD));
    canvas.drawCircle(Offset(w * 0.87, h * 0.20), h * 0.015,
        Paint()..color = const Color(0xFFBDBDBD));
  }

  // ── MATH SCENE ───────────────────────────────────────────────────────────
  void _paintMath(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final at = t * 2 * pi;

    // Colorful classroom background
    _fillGradient(canvas, size, const Color(0xFF1565C0), const Color(0xFF1976D2));

    // Chalkboard style
    final boardPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.06, w * 0.84, h * 0.35),
        const Radius.circular(12)), boardPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.05, w * 0.88, h * 0.37),
        const Radius.circular(14)),
        Paint()..color = const Color(0xFF4E342E)..style = PaintingStyle.stroke..strokeWidth = 4);

    // Math expressions on board (animated chalk)
    final expressions = ['1+1=2', '3+4=7', '5×2=10', '10-3=7'];
    final expr = expressions[stage % expressions.length];
    _drawChalkText(canvas, expr, Offset(w * 0.5, h * 0.245), 22);

    // Stars / reward sparkles
    for (int i = 0; i < 5; i++) {
      final sx = w * (0.12 + i * 0.19);
      final sy = h * 0.08 + sin(at + i) * 3;
      _drawStar(canvas, Offset(sx, sy), 10, const Color(0xFFFFD700));
    }

    // Bouncing numbers — floor tiles
    final numColors = [
      const Color(0xFFE91E63), const Color(0xFF9C27B0),
      const Color(0xFF2196F3), const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
    ];
    for (int i = 0; i < 5; i++) {
      final nx = w * (0.12 + i * 0.19);
      final bounceAmt = sin(at + i * 1.2) * (isPlaying ? 12 : 4);
      final ny = h * 0.65 + bounceAmt;
      final r = h * 0.065;
      canvas.drawCircle(Offset(nx, ny), r, Paint()..color = numColors[i]);
      // Shadow
      canvas.drawCircle(Offset(nx, h * 0.72), r * 0.3,
          Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      _drawChalkText(canvas, '${i + 1}', Offset(nx, ny), 20);
    }

    // Robot mascot (center bottom)
    final robotBounce = isPlaying ? sin(at) * 8 : sin(idle * pi) * 3;
    _drawRobot(canvas, Offset(w * 0.5, h * 0.51 + robotBounce), h * 0.14, at);

    // Plus/equals signs floating
    for (int i = 0; i < 3; i++) {
      final fx = w * (0.25 + i * 0.25);
      final fy = h * 0.47 + sin(at * 0.7 + i) * 8;
      _drawChalkText(canvas, ['+', '=', '×'][i], Offset(fx, fy), 18);
    }
  }

  // ── RAINBOW SCENE ────────────────────────────────────────────────────────
  void _paintRainbow(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final at = t * 2 * pi;

    // Blue sky
    _fillGradient(canvas, size, const Color(0xFF87CEEB), const Color(0xFFB3E5FC));

    // Rainbow arc
    final colors = [
      Colors.red, Colors.orange, Colors.yellow,
      Colors.green, Colors.blue, const Color(0xFF4B0082), Colors.purple,
    ];
    for (int i = 0; i < colors.length; i++) {
      final radius = w * 0.35 + i * 8.0;
      final paint = Paint()
        ..color = colors[i].withValues(alpha: isPlaying ? 0.85 : 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.7), width: radius * 2, height: radius * 1.6),
        pi, pi, false, paint,
      );
    }

    // White fluffy clouds with smiley
    _drawSmileCloud(canvas, w * 0.18 + sin(at * 0.2) * 8, h * 0.15, 55, at);
    _drawSmileCloud(canvas, w * 0.75 + sin(at * 0.18 + 1) * 8, h * 0.12, 48, at + 1);

    // Rain drops of color
    for (int i = 0; i < 12; i++) {
      final rx = w * (0.05 + (i % 6) * 0.17) + sin(at * 0.4 + i) * 5;
      final ry = h * (0.3 + (i / 6).floor() * 0.15) + (isPlaying ? (t * h * 0.3 + i * h * 0.08) % (h * 0.3) : 0);
      final dropColor = colors[i % colors.length];
      final dropPaint = Paint()..color = dropColor.withValues(alpha: 0.8);
      final dropPath = Path()
        ..moveTo(rx, ry - 8)
        ..quadraticBezierTo(rx + 4, ry, rx, ry + 6)
        ..quadraticBezierTo(rx - 4, ry, rx, ry - 8);
      canvas.drawPath(dropPath, dropPaint);
    }

    // Green hills at bottom
    _fillGradient(canvas, Rect.fromLTWH(0, h * 0.72, w, h * 0.28),
        const Color(0xFF66BB6A), const Color(0xFF4CAF50));
    // Hill curves
    final hillPath = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.25, h * 0.65, w * 0.5, h * 0.72)
      ..quadraticBezierTo(w * 0.75, h * 0.79, w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = const Color(0xFF81C784));

    // Color palette circles at bottom
    for (int i = 0; i < 6; i++) {
      final cx = w * (0.12 + i * 0.15);
      final cy = h * 0.84 + sin(at + i * 0.8) * (isPlaying ? 6 : 2);
      canvas.drawCircle(Offset(cx, cy), 14, Paint()..color = colors[i]);
    }
  }

  // ── ABCs SCENE ───────────────────────────────────────────────────────────
  void _paintABCs(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final at = t * 2 * pi;

    // Purple classroom
    _fillGradient(canvas, size, const Color(0xFF4A148C), const Color(0xFF7B1FA2));

    // Floating letters
    final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final letterColors = [
      const Color(0xFFE91E63), const Color(0xFF2196F3), const Color(0xFF4CAF50),
      const Color(0xFFFF9800), const Color(0xFF9C27B0), const Color(0xFF00BCD4),
      const Color(0xFFF44336), const Color(0xFF8BC34A),
    ];
    for (int i = 0; i < letters.length; i++) {
      final lx = w * (0.1 + (i % 4) * 0.27);
      final row = (i / 4).floor();
      final ly = h * (0.12 + row * 0.28) + sin(at + i * 0.8) * (isPlaying ? 10 : 3);
      final lr = 26.0 + sin(at + i) * (isPlaying ? 4 : 1);
      canvas.drawCircle(Offset(lx, ly), lr, Paint()..color = letterColors[i]);
      _drawText(canvas, letters[i], Offset(lx, ly), 22, Colors.white, bold: true);
    }

    // Apple with A label
    final appleY = h * 0.58 + sin(at * 0.8) * (isPlaying ? 8 : 3);
    _drawApple(canvas, Offset(w * 0.5, appleY), h * 0.12);

    // ABC text in arc
    final arcLetters = 'ABCDE'.split('');
    for (int i = 0; i < arcLetters.length; i++) {
      final angle = pi * 0.15 + i * (pi * 0.7 / 4);
      final r = h * 0.27;
      final lx = w * 0.5 + cos(angle) * r;
      final ly = h * 0.78 - sin(angle) * r * 0.5 + sin(at + i) * 3;
      _drawText(canvas, arcLetters[i], Offset(lx, ly), 18,
          const Color(0xFFFFD700), bold: true);
    }
  }

  // ── MUSIC SCENE ──────────────────────────────────────────────────────────
  void _paintMusic(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final at = t * 2 * pi;

    // Deep purple stage
    _fillGradient(canvas, size, const Color(0xFF1A0533), const Color(0xFF4A148C));

    // Spotlight beams
    for (int i = 0; i < 3; i++) {
      final sx = w * (0.2 + i * 0.3);
      final beamPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: isPlaying ? 0.12 : 0.04), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(sx, 0), radius: h * 0.8));
      final spotPath = Path()
        ..moveTo(sx, 0)
        ..lineTo(sx - h * 0.22, h)
        ..lineTo(sx + h * 0.22, h)
        ..close();
      canvas.drawPath(spotPath, beamPaint);
    }

    // Stage floor
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
        Paint()..color = const Color(0xFF3E2723));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.015),
        Paint()..color = const Color(0xFFFFC107));

    // Musical notes floating
    final notePositions = [
      Offset(w * 0.12, h * 0.22 + sin(at) * 12),
      Offset(w * 0.28, h * 0.15 + sin(at + 1) * 10),
      Offset(w * 0.72, h * 0.18 + sin(at + 2) * 14),
      Offset(w * 0.86, h * 0.24 + sin(at + 0.5) * 11),
    ];
    for (final pos in notePositions) {
      _drawMusicNote(canvas, pos, isPlaying ? 22 : 16, const Color(0xFFFFD700));
    }

    // Guitar (left side)
    _drawGuitar(canvas, Offset(w * 0.2, h * 0.55), h * 0.28, at);

    // Main character — microphone singer in center
    final singerBounce = isPlaying ? sin(at) * 10 : sin(idle * pi) * 4;
    _drawSingerKid(canvas, Offset(w * 0.5, h * 0.55 + singerBounce), h * 0.22, at);

    // Piano keys (right side)
    _drawPianoKeys(canvas, Offset(w * 0.82, h * 0.52), h * 0.25, at);

    // Colorful lights
    final lightColors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple];
    for (int i = 0; i < 5; i++) {
      final lx = w * (0.1 + i * 0.2);
      final pulse = 0.4 + (isPlaying ? sin(at * 2 + i) * 0.3 : 0);
      canvas.drawCircle(Offset(lx, h * 0.04), 8,
          Paint()..color = lightColors[i].withValues(alpha: pulse.abs()));
    }
  }

  // ── GARDEN SCENE ─────────────────────────────────────────────────────────
  void _paintGarden(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final at = t * 2 * pi;

    // Sky
    _fillGradient(canvas, size, const Color(0xFF87CEEB), const Color(0xFFE3F2FD));

    // Sun with face
    final sunX = w * 0.82; final sunY = h * 0.12;
    canvas.drawCircle(Offset(sunX, sunY), 32, Paint()..color = const Color(0xFFFFC107));
    for (int i = 0; i < 8; i++) {
      final a = at * 0.15 + i * pi / 4;
      canvas.drawLine(
          Offset(sunX + cos(a) * 36, sunY + sin(a) * 36),
          Offset(sunX + cos(a) * 46, sunY + sin(a) * 46),
          Paint()..color = const Color(0xFFFFC107)..strokeWidth = 3..strokeCap = StrokeCap.round);
    }
    // Sun smile
    _drawSmile(canvas, Offset(sunX, sunY + 6), 14, const Color(0xFFE65100));

    // Ground
    _fillGradient(canvas, Rect.fromLTWH(0, h * 0.60, w, h * 0.40),
        const Color(0xFF8D6E63), const Color(0xFF795548));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.60, w, h * 0.06),
        Paint()..color = const Color(0xFF4CAF50));

    // Multiple plants growing at different stages
    final plantStages = [0.4, 0.7, 1.0, 0.55, 0.85];
    for (int i = 0; i < 5; i++) {
      final px = w * (0.12 + i * 0.19);
      final sway = sin(at * 0.6 + i) * 4;
      _drawPlant(canvas, Offset(px, h * 0.60), h * 0.22 * plantStages[i], sway,
          i % 3 == 0 ? const Color(0xFFE91E63) :
          i % 3 == 1 ? const Color(0xFFFF9800) : const Color(0xFF9C27B0));
    }

    // Butterfly flying
    if (isPlaying) {
      final bfx = w * (0.3 + sin(at * 0.5) * 0.35);
      final bfy = h * (0.38 + sin(at * 0.7) * 0.08);
      _drawButterfly(canvas, Offset(bfx, bfy), at);
    }

    // Watering can (left side)
    _drawWateringCan(canvas, Offset(w * 0.08, h * 0.64));

    // Water drops
    if (isPlaying) {
      for (int i = 0; i < 4; i++) {
        final wx = w * 0.12 + i * 5.0;
        final wy = h * 0.60 + (t * h * 0.12 + i * h * 0.03) % (h * 0.12);
        canvas.drawCircle(Offset(wx, wy), 2.5,
            Paint()..color = Colors.blue.withValues(alpha: 0.7));
      }
    }

    // Ladybug (right side)
    _drawLadybug(canvas,
        Offset(w * 0.88, h * 0.56 + sin(at * 0.4) * (isPlaying ? 6 : 2)));
  }

  // ── OCEAN SCENE ──────────────────────────────────────────────────────────
  void _paintOcean(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final at = t * 2 * pi;

    // Deep ocean background
    _fillGradient(canvas, size, const Color(0xFF001B44), const Color(0xFF0D47A1));

    // Animated waves (multiple layers)
    for (int layer = 0; layer < 3; layer++) {
      final waveColor = Color.lerp(
          const Color(0xFF1565C0), const Color(0xFF42A5F5), layer / 2)!;
      final wavePath = Path();
      wavePath.moveTo(0, h * (0.25 + layer * 0.06));
      for (double x = 0; x <= w; x += 5) {
        final y = h * (0.25 + layer * 0.06) +
            sin(x / w * 4 * pi + at + layer) * h * 0.025;
        wavePath.lineTo(x, y);
      }
      wavePath.lineTo(w, h);
      wavePath.lineTo(0, h);
      wavePath.close();
      canvas.drawPath(wavePath,
          Paint()..color = waveColor.withValues(alpha: 0.6 - layer * 0.15));
    }

    // Bubbles rising
    final rng = Random(123);
    for (int i = 0; i < 15; i++) {
      final bx = rng.nextDouble() * w;
      final baseY = h * 0.4 + rng.nextDouble() * h * 0.55;
      final by = isPlaying
          ? ((baseY - t * h * 0.6 + i * h * 0.04) % h * 1.2)
          : baseY;
      final br = 3.0 + rng.nextDouble() * 5;
      canvas.drawCircle(Offset(bx, by), br,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    // Seabed
    canvas.drawRect(Rect.fromLTWH(0, h * 0.82, w, h * 0.18),
        Paint()..color = const Color(0xFFBF8D5B));
    // Seaweed
    for (int i = 0; i < 6; i++) {
      final sx = w * (0.1 + i * 0.16);
      _drawSeaweed(canvas, Offset(sx, h * 0.82), h * 0.12, at + i);
    }

    // Main fish — clownfish center
    final fishY = h * 0.5 + sin(at) * (isPlaying ? 14 : 5);
    final fishX = w * 0.5 + cos(at * 0.4) * w * 0.12;
    _drawClownfish(canvas, Offset(fishX, fishY), h * 0.10, at);

    // Small fish swimming
    for (int i = 0; i < 4; i++) {
      final sfx = (w * (0.1 + i * 0.22) + (isPlaying ? t * w * 0.8 : 0) + i * w * 0.2) % w;
      final sfy = h * (0.38 + i * 0.08) + sin(at + i) * 6;
      _drawSmallFish(canvas, Offset(sfx, sfy),
          [const Color(0xFFFF9800), const Color(0xFF9C27B0),
           const Color(0xFF4CAF50), const Color(0xFFE91E63)][i]);
    }

    // Octopus (right side)
    _drawOctopus(canvas, Offset(w * 0.82, h * 0.70), h * 0.15, at);

    // Coral (left side)
    _drawCoral(canvas, Offset(w * 0.12, h * 0.82));
  }

  // ── GENERAL SCENE ────────────────────────────────────────────────────────
  void _paintGeneral(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final at = t * 2 * pi;

    _fillGradient(canvas, size, const Color(0xFF7B1FA2), const Color(0xFF1565C0));

    // Shooting stars
    if (isPlaying) {
      for (int i = 0; i < 3; i++) {
        final sx = (w * (0.1 + i * 0.4) + t * w * 0.6) % (w * 1.2) - w * 0.1;
        final sy = h * (0.1 + i * 0.12);
        canvas.drawLine(Offset(sx, sy), Offset(sx + 40, sy - 20),
            Paint()..color = Colors.white.withValues(alpha: 0.6)..strokeWidth = 2);
        canvas.drawCircle(Offset(sx, sy), 2.5, Paint()..color = Colors.white70);
      }
    }

    // Stars twinkling
    final rng = Random(99);
    for (int i = 0; i < 30; i++) {
      final sx = rng.nextDouble() * w;
      final sy = rng.nextDouble() * h * 0.7;
      final bright = 0.3 + 0.7 * sin(at * 1.3 + i * 0.9).abs();
      canvas.drawCircle(Offset(sx, sy), 1.5 + rng.nextDouble() * 2,
          Paint()..color = Colors.white.withValues(alpha: bright));
    }

    // Central star burst
    final starBounce = isPlaying ? sin(at) * 10 : sin(idle * pi) * 4;
    _drawStar(canvas, Offset(w * 0.5, h * 0.45 + starBounce), h * 0.12,
        const Color(0xFFFFD700));

    // Floating shapes
    final shapeColors = [const Color(0xFFE91E63), const Color(0xFF4CAF50),
                         const Color(0xFF2196F3), const Color(0xFFFF9800)];
    for (int i = 0; i < 4; i++) {
      final sx = w * (0.15 + i * 0.24);
      final sy = h * 0.68 + sin(at + i) * (isPlaying ? 10 : 3);
      canvas.drawCircle(Offset(sx, sy), 18, Paint()..color = shapeColors[i]);
      _drawText(canvas, '${i + 1}', Offset(sx, sy), 16, Colors.white, bold: true);
    }
  }

  // ── HELPER DRAW METHODS ───────────────────────────────────────────────────

  void _fillGradient(Canvas canvas, dynamic sizeOrRect, Color top, Color bottom) {
    Rect rect;
    if (sizeOrRect is Size) {
      rect = Rect.fromLTWH(0, 0, sizeOrRect.width, sizeOrRect.height);
    } else {
      rect = sizeOrRect as Rect;
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );
  }

  void _drawCloud(Canvas canvas, double x, double y, double r, Color color) {
    final p = Paint()..color = color;
    canvas.drawCircle(Offset(x, y), r * 0.55, p);
    canvas.drawCircle(Offset(x - r * 0.45, y + r * 0.2), r * 0.42, p);
    canvas.drawCircle(Offset(x + r * 0.45, y + r * 0.18), r * 0.38, p);
    canvas.drawCircle(Offset(x + r * 0.1, y + r * 0.35), r * 0.45, p);
    canvas.drawCircle(Offset(x - r * 0.15, y + r * 0.35), r * 0.40, p);
  }

  void _drawSmileCloud(Canvas canvas, double x, double y, double r, double at) {
    _drawCloud(canvas, x, y, r, Colors.white.withValues(alpha: 0.9));
    // Eyes
    canvas.drawCircle(Offset(x - 10, y - 2), 3, Paint()..color = const Color(0xFF555555));
    canvas.drawCircle(Offset(x + 10, y - 2), 3, Paint()..color = const Color(0xFF555555));
    _drawSmile(canvas, Offset(x, y + 4), 10, const Color(0xFF555555));
  }

  void _drawSmile(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx - r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + r * 0.8, center.dx + r, center.dy);
    canvas.drawPath(
        path, Paint()..color = color..style = PaintingStyle.stroke
            ..strokeWidth = 2..strokeCap = StrokeCap.round);
  }

  void _drawTree(Canvas canvas, double x, double baseY, double h, double at) {
    // Trunk
    canvas.drawRect(Rect.fromCenter(center: Offset(x, baseY - h * 0.15),
        width: h * 0.1, height: h * 0.3),
        Paint()..color = const Color(0xFF795548));
    // Foliage (3 stacked triangles, sway)
    final sway = sin(at * 0.3) * 3;
    for (int i = 0; i < 3; i++) {
      final ty = baseY - h * (0.25 + i * 0.22);
      final tw = h * (0.6 - i * 0.1);
      final path = Path()
        ..moveTo(x + sway, ty - h * 0.2)
        ..lineTo(x - tw / 2 + sway * 0.5, ty)
        ..lineTo(x + tw / 2 + sway * 0.5, ty)
        ..close();
      canvas.drawPath(path,
          Paint()..color = Color.lerp(const Color(0xFF2E7D32),
              const Color(0xFF81C784), i / 2)!);
    }
  }

  void _drawGrass(Canvas canvas, double x, double baseY, double sway) {
    final p = Paint()..color = const Color(0xFF388E3C)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(Offset(x + i * 5, baseY),
          Offset(x + i * 5 + sway, baseY - 14), p);
    }
  }

  void _drawFlower(Canvas canvas, Offset center, double r) {
    final colors = [Colors.pink, Colors.red, Colors.yellow, Colors.purple, Colors.orange];
    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * pi / 5;
      canvas.drawCircle(Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r),
          r * 0.55, Paint()..color = colors[i % colors.length].withValues(alpha: 0.85));
    }
    canvas.drawCircle(center, r * 0.5, Paint()..color = const Color(0xFFFFD700));
  }

  void _drawLion(Canvas canvas, Offset center, double size, double at) {
    // Mane
    final maneR = size * 0.7;
    for (int i = 0; i < 12; i++) {
      final a = i * pi / 6;
      canvas.drawCircle(Offset(center.dx + cos(a) * maneR, center.dy + sin(a) * maneR),
          maneR * 0.28, Paint()..color = const Color(0xFFE65100));
    }
    // Body
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + size * 0.4),
        width: size * 1.0, height: size * 0.7), Paint()..color = const Color(0xFFFFB74D));
    // Head
    canvas.drawCircle(center, size * 0.52, Paint()..color = const Color(0xFFFFA726));
    // Eyes
    canvas.drawCircle(Offset(center.dx - size * 0.18, center.dy - size * 0.1),
        size * 0.1, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx + size * 0.18, center.dy - size * 0.1),
        size * 0.1, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx - size * 0.15, center.dy - size * 0.1),
        size * 0.055, Paint()..color = Colors.black87);
    canvas.drawCircle(Offset(center.dx + size * 0.15, center.dy - size * 0.1),
        size * 0.055, Paint()..color = Colors.black87);
    // Nose
    canvas.drawCircle(Offset(center.dx, center.dy + size * 0.08),
        size * 0.07, Paint()..color = const Color(0xFFE91E63));
    // Smile
    _drawSmile(canvas, Offset(center.dx, center.dy + size * 0.18), size * 0.18,
        const Color(0xFFBF360C));
    // Ears
    _drawEar(canvas, Offset(center.dx - size * 0.44, center.dy - size * 0.42),
        size * 0.16, const Color(0xFFFFA726));
    _drawEar(canvas, Offset(center.dx + size * 0.44, center.dy - size * 0.42),
        size * 0.16, const Color(0xFFFFA726));
    // Tail
    final tailPath = Path()
      ..moveTo(center.dx + size * 0.45, center.dy + size * 0.4)
      ..quadraticBezierTo(center.dx + size * 0.8, center.dy + size * 0.6,
          center.dx + size * 0.7, center.dy + size * 0.9);
    canvas.drawPath(tailPath,
        Paint()..color = const Color(0xFFE65100)..style = PaintingStyle.stroke
            ..strokeWidth = size * 0.07..strokeCap = StrokeCap.round);
  }

  void _drawEar(Canvas canvas, Offset center, double r, Color color) {
    canvas.drawCircle(center, r, Paint()..color = color);
    canvas.drawCircle(center, r * 0.55, Paint()..color = const Color(0xFFE91E63).withValues(alpha: 0.5));
  }

  void _drawElephant(Canvas canvas, Offset center, double size, double at) {
    final grey = const Color(0xFF90A4AE);
    // Body
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + size * 0.1),
        width: size * 1.1, height: size * 0.85), Paint()..color = grey);
    // Head
    canvas.drawCircle(Offset(center.dx - size * 0.35, center.dy - size * 0.18),
        size * 0.42, Paint()..color = grey);
    // Ear
    canvas.drawOval(Rect.fromCenter(
        center: Offset(center.dx - size * 0.62, center.dy - size * 0.1),
        width: size * 0.38, height: size * 0.5),
        Paint()..color = const Color(0xFFEF9A9A));
    // Trunk (animated)
    final trunkSway = sin(at * 0.5) * 6;
    final trunkPath = Path()
      ..moveTo(center.dx - size * 0.5, center.dy - size * 0.08)
      ..quadraticBezierTo(
          center.dx - size * 0.7 + trunkSway, center.dy + size * 0.3,
          center.dx - size * 0.55 + trunkSway, center.dy + size * 0.45);
    canvas.drawPath(trunkPath,
        Paint()..color = grey..style = PaintingStyle.stroke
            ..strokeWidth = size * 0.12..strokeCap = StrokeCap.round);
    // Eye
    canvas.drawCircle(Offset(center.dx - size * 0.42, center.dy - size * 0.22),
        size * 0.06, Paint()..color = Colors.black87);
    // Legs
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.dx + (i % 2 == 0 ? -size * 0.22 : size * 0.22) + (i < 2 ? -size * 0.1 : size * 0.1),
              center.dy + size * 0.55),
              width: size * 0.2, height: size * 0.3),
          const Radius.circular(6)), Paint()..color = grey);
    }
  }

  void _drawGiraffe(Canvas canvas, Offset center, double size, double at) {
    final yellow = const Color(0xFFFFC107);
    final spots = const Color(0xFFE65100);
    // Neck (long)
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - size * 0.35),
            width: size * 0.22, height: size * 0.75),
        const Radius.circular(8)), Paint()..color = yellow);
    // Body
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + size * 0.1),
        width: size * 0.65, height: size * 0.5), Paint()..color = yellow);
    // Head
    canvas.drawOval(Rect.fromCenter(
        center: Offset(center.dx + size * 0.05, center.dy - size * 0.68),
        width: size * 0.3, height: size * 0.22), Paint()..color = yellow);
    // Spots on neck
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(Offset(center.dx + (i % 2 == 0 ? 4.0 : -4.0),
          center.dy - size * 0.15 - i * size * 0.14), size * 0.07,
          Paint()..color = spots);
    }
    // Eye
    canvas.drawCircle(Offset(center.dx + size * 0.1, center.dy - size * 0.7),
        size * 0.05, Paint()..color = Colors.black87);
    // Horns
    canvas.drawLine(Offset(center.dx - size * 0.04, center.dy - size * 0.76),
        Offset(center.dx - size * 0.04, center.dy - size * 0.88),
        Paint()..color = const Color(0xFF795548)..strokeWidth = 4..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(center.dx + size * 0.1, center.dy - size * 0.74),
        Offset(center.dx + size * 0.1, center.dy - size * 0.85),
        Paint()..color = const Color(0xFF795548)..strokeWidth = 4..strokeCap = StrokeCap.round);
  }

  void _drawRocket(Canvas canvas, double size) {
    // Flame
    final flamePath = Path()
      ..moveTo(-size * 0.12, size * 0.52)
      ..quadraticBezierTo(0, size * 0.9, size * 0.12, size * 0.52);
    canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFF6D00));
    final flame2 = Path()
      ..moveTo(-size * 0.07, size * 0.52)
      ..quadraticBezierTo(0, size * 0.72, size * 0.07, size * 0.52);
    canvas.drawPath(flame2, Paint()..color = const Color(0xFFFFD600));
    // Body
    final bodyPath = Path()
      ..moveTo(0, -size * 0.6)
      ..quadraticBezierTo(size * 0.2, -size * 0.3, size * 0.2, size * 0.4)
      ..lineTo(-size * 0.2, size * 0.4)
      ..quadraticBezierTo(-size * 0.2, -size * 0.3, 0, -size * 0.6);
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFFE53935));
    // Window
    canvas.drawCircle(const Offset(0, 0), size * 0.14, Paint()..color = const Color(0xFF81D4FA));
    canvas.drawCircle(const Offset(0, 0), size * 0.1,
        Paint()..color = const Color(0xFF29B6F6)..style = PaintingStyle.stroke..strokeWidth = 2);
    // Fins
    final leftFin = Path()
      ..moveTo(-size * 0.2, size * 0.25)
      ..lineTo(-size * 0.42, size * 0.48)
      ..lineTo(-size * 0.2, size * 0.45)
      ..close();
    final rightFin = Path()
      ..moveTo(size * 0.2, size * 0.25)
      ..lineTo(size * 0.42, size * 0.48)
      ..lineTo(size * 0.2, size * 0.45)
      ..close();
    canvas.drawPath(leftFin, Paint()..color = const Color(0xFFB71C1C));
    canvas.drawPath(rightFin, Paint()..color = const Color(0xFFB71C1C));
    // Stars on body
    canvas.drawCircle(Offset(-size * 0.08, -size * 0.3), size * 0.04,
        Paint()..color = Colors.white70);
    canvas.drawCircle(Offset(size * 0.08, -size * 0.18), size * 0.04,
        Paint()..color = Colors.white70);
  }

  void _drawRobot(Canvas canvas, Offset center, double size, double at) {
    final blue = const Color(0xFF1565C0);
    final silver = const Color(0xFF90A4AE);
    // Body
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + size * 0.12),
            width: size * 0.75, height: size * 0.65),
        const Radius.circular(8)), Paint()..color = blue);
    // Head
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - size * 0.28),
            width: size * 0.6, height: size * 0.45),
        const Radius.circular(10)), Paint()..color = silver);
    // Antenna
    canvas.drawLine(Offset(center.dx, center.dy - size * 0.5),
        Offset(center.dx, center.dy - size * 0.7),
        Paint()..color = silver..strokeWidth = 3);
    canvas.drawCircle(Offset(center.dx, center.dy - size * 0.72), 5,
        Paint()..color = const Color(0xFFE91E63));
    // Eyes
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - size * 0.13, center.dy - size * 0.28),
            width: size * 0.16, height: size * 0.14), const Radius.circular(3)),
        Paint()..color = const Color(0xFF00E5FF));
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + size * 0.13, center.dy - size * 0.28),
            width: size * 0.16, height: size * 0.14), const Radius.circular(3)),
        Paint()..color = const Color(0xFF00E5FF));
    // Mouth (row of LEDs)
    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(Offset(center.dx - size * 0.15 + i * size * 0.1, center.dy - size * 0.14),
          3, Paint()..color = i < (isPlaying ? (t * 4).floor() % 5 : 2)
              ? const Color(0xFF4CAF50) : Colors.grey);
    }
    // Arms (animated)
    final armAngle = sin(at) * 0.4;
    canvas.drawLine(Offset(center.dx - size * 0.38, center.dy + size * 0.1),
        Offset(center.dx - size * 0.38 + cos(pi - armAngle) * size * 0.28,
            center.dy + size * 0.1 + sin(pi - armAngle) * size * 0.28),
        Paint()..color = silver..strokeWidth = size * 0.1..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(center.dx + size * 0.38, center.dy + size * 0.1),
        Offset(center.dx + size * 0.38 + cos(armAngle) * size * 0.28,
            center.dy + size * 0.1 + sin(armAngle) * size * 0.28),
        Paint()..color = silver..strokeWidth = size * 0.1..strokeCap = StrokeCap.round);
    // Legs
    canvas.drawLine(Offset(center.dx - size * 0.18, center.dy + size * 0.44),
        Offset(center.dx - size * 0.18, center.dy + size * 0.65),
        Paint()..color = silver..strokeWidth = size * 0.12..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(center.dx + size * 0.18, center.dy + size * 0.44),
        Offset(center.dx + size * 0.18, center.dy + size * 0.65),
        Paint()..color = silver..strokeWidth = size * 0.12..strokeCap = StrokeCap.round);
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = i * pi / 5 - pi / 2;
      final radius = i % 2 == 0 ? r : r * 0.42;
      final p = Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
      if (i == 0) { path.moveTo(p.dx, p.dy); } else { path.lineTo(p.dx, p.dy); }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _drawMusicNote(Canvas canvas, Offset pos, double size, Color color) {
    final p = Paint()..color = color;
    canvas.drawCircle(Offset(pos.dx, pos.dy + size * 0.55), size * 0.3, p);
    canvas.drawRect(Rect.fromLTWH(pos.dx + size * 0.22, pos.dy - size * 0.2,
        size * 0.1, size * 0.78), p);
    canvas.drawRect(Rect.fromLTWH(pos.dx + size * 0.22, pos.dy - size * 0.2,
        size * 0.35, size * 0.1), p);
  }

  void _drawGuitar(Canvas canvas, Offset center, double size, double at) {
    // Guitar body (figure-8)
    canvas.drawCircle(Offset(center.dx, center.dy + size * 0.15), size * 0.2,
        Paint()..color = const Color(0xFF795548));
    canvas.drawCircle(Offset(center.dx, center.dy - size * 0.08), size * 0.14,
        Paint()..color = const Color(0xFF795548));
    // Neck
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - size * 0.42),
            width: size * 0.07, height: size * 0.55),
        const Radius.circular(3)), Paint()..color = const Color(0xFFA1887F));
    // Strings (animated)
    for (int i = 0; i < 3; i++) {
      final sx = center.dx - size * 0.04 + i * size * 0.04;
      final vibrate = isPlaying ? sin(at * 8 + i * 2) * 2 : 0.0;
      canvas.drawLine(Offset(sx, center.dy - size * 0.68),
          Offset(sx + vibrate, center.dy + size * 0.3),
          Paint()..color = Colors.white60..strokeWidth = 1.2);
    }
    // Sound hole
    canvas.drawCircle(Offset(center.dx, center.dy + size * 0.08), size * 0.07,
        Paint()..color = Colors.black45);
  }

  void _drawPianoKeys(Canvas canvas, Offset pos, double size, double at) {
    // White keys
    for (int i = 0; i < 6; i++) {
      final pressed = isPlaying && ((t * 6 + i).floor() % 6 == i);
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx - size * 0.18 + i * size * 0.065,
              pos.dy - size * 0.3 + (pressed ? 3.0 : 0.0),
              size * 0.058, size * 0.28),
          const Radius.circular(3)),
          Paint()..color = pressed ? Colors.grey.shade100 : Colors.white);
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx - size * 0.18 + i * size * 0.065,
              pos.dy - size * 0.3,
              size * 0.058, size * 0.28),
          const Radius.circular(3)),
          Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 0.5);
    }
    // Black keys
    for (int i = 0; i < 4; i++) {
      if (i == 1) continue;
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(pos.dx - size * 0.155 + i * size * 0.065 + size * 0.04,
              pos.dy - size * 0.3, size * 0.038, size * 0.17),
          const Radius.circular(2)),
          Paint()..color = Colors.black87);
    }
  }

  void _drawSingerKid(Canvas canvas, Offset center, double size, double at) {
    // Body
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + size * 0.25),
        width: size * 0.55, height: size * 0.55), Paint()..color = const Color(0xFFFFA726));
    // Head
    canvas.drawCircle(center, size * 0.3, Paint()..color = const Color(0xFFFFCC02));
    // Hair
    canvas.drawArc(Rect.fromCenter(center: Offset(center.dx, center.dy - size * 0.04),
        width: size * 0.62, height: size * 0.5),
        pi, pi, false, Paint()..color = const Color(0xFF5D4037)..strokeWidth = size * 0.1
            ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    // Eyes
    canvas.drawCircle(Offset(center.dx - size * 0.1, center.dy - size * 0.04),
        size * 0.055, Paint()..color = Colors.black87);
    canvas.drawCircle(Offset(center.dx + size * 0.1, center.dy - size * 0.04),
        size * 0.055, Paint()..color = Colors.black87);
    // Open singing mouth
    final mouthOpen = isPlaying ? 0.4 + sin(at * 3) * 0.2 : 0.2;
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy + size * 0.1),
        width: size * 0.18, height: size * mouthOpen), Paint()..color = const Color(0xFFE91E63));
    // Microphone
    canvas.drawLine(Offset(center.dx + size * 0.25, center.dy),
        Offset(center.dx + size * 0.38, center.dy + size * 0.3),
        Paint()..color = Colors.grey..strokeWidth = size * 0.06..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(center.dx + size * 0.22, center.dy - size * 0.04),
        size * 0.08, Paint()..color = Colors.grey.shade700);
    // Musical notes from mouth
    if (isPlaying) {
      for (int i = 0; i < 2; i++) {
        final nx = center.dx - size * (0.2 + i * 0.18) + sin(at + i) * 5;
        final ny = center.dy - size * (0.1 + i * 0.12);
        _drawMusicNote(canvas, Offset(nx, ny), 12, const Color(0xFFFFD700));
      }
    }
  }

  void _drawApple(Canvas canvas, Offset center, double r) {
    // Leaf
    final leafPath = Path()
      ..moveTo(center.dx, center.dy - r * 1.1)
      ..quadraticBezierTo(center.dx + r * 0.4, center.dy - r * 1.4,
          center.dx + r * 0.2, center.dy - r * 0.8);
    canvas.drawPath(leafPath, Paint()..color = const Color(0xFF4CAF50)
        ..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round);
    // Body
    canvas.drawCircle(Offset(center.dx - r * 0.07, center.dy + r * 0.05), r,
        Paint()..color = const Color(0xFFE53935));
    // Shine
    canvas.drawCircle(Offset(center.dx - r * 0.3, center.dy - r * 0.3), r * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.5));
    // Stem
    canvas.drawLine(Offset(center.dx + r * 0.05, center.dy - r),
        Offset(center.dx + r * 0.05, center.dy - r * 1.25),
        Paint()..color = const Color(0xFF795548)..strokeWidth = 4..strokeCap = StrokeCap.round);
  }

  void _drawPlant(Canvas canvas, Offset base, double h, double sway, Color flowerColor) {
    // Stem
    final stemPath = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + sway * 2, base.dy - h * 0.5,
          base.dx + sway, base.dy - h);
    canvas.drawPath(stemPath, Paint()..color = const Color(0xFF388E3C)
        ..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);
    // Leaves
    for (int i = 0; i < 2; i++) {
      final ly = base.dy - h * (0.35 + i * 0.3);
      final lx = base.dx + sway * (0.5 + i * 0.3);
      final leafPath = Path()
        ..moveTo(lx, ly)
        ..quadraticBezierTo(lx + (i == 0 ? 18 : -18), ly - 10, lx + (i == 0 ? 8 : -8), ly + 4);
      canvas.drawPath(leafPath, Paint()..color = const Color(0xFF4CAF50)
          ..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round);
    }
    // Flower top
    if (h > 40) {
      final fx = base.dx + sway;
      final fy = base.dy - h;
      for (int i = 0; i < 5; i++) {
        final a = i * 2 * pi / 5;
        canvas.drawCircle(Offset(fx + cos(a) * 8, fy + sin(a) * 8), 7,
            Paint()..color = flowerColor.withValues(alpha: 0.85));
      }
      canvas.drawCircle(Offset(fx, fy), 6, Paint()..color = const Color(0xFFFFD700));
    }
  }

  void _drawButterfly(Canvas canvas, Offset center, double at) {
    final wingFlap = sin(at * 8) * 0.4;
    final colors = [const Color(0xFFE91E63), const Color(0xFF9C27B0)];
    for (int side = 0; side < 2; side++) {
      final xMul = side == 0 ? -1.0 : 1.0;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(xMul, 1);
      canvas.rotate(wingFlap);
      final wingPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(25, -20, 35, 0)
        ..quadraticBezierTo(30, 15, 0, 8)
        ..close();
      canvas.drawPath(wingPath, Paint()..color = colors[side].withValues(alpha: 0.85));
      final wingPath2 = Path()
        ..moveTo(0, 5)
        ..quadraticBezierTo(20, 15, 22, 28)
        ..quadraticBezierTo(10, 30, 0, 16)
        ..close();
      canvas.drawPath(wingPath2, Paint()..color = colors[side].withValues(alpha: 0.7));
      canvas.restore();
    }
    canvas.drawOval(Rect.fromCenter(center: center, width: 6, height: 16),
        Paint()..color = Colors.black87);
  }

  void _drawWateringCan(Canvas canvas, Offset pos) {
    canvas.drawOval(Rect.fromCenter(center: pos, width: 36, height: 28),
        Paint()..color = const Color(0xFF42A5F5));
    canvas.drawLine(Offset(pos.dx + 18, pos.dy - 4),
        Offset(pos.dx + 36, pos.dy - 18),
        Paint()..color = const Color(0xFF1565C0)..strokeWidth = 6..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(pos.dx + 36, pos.dy - 18), 6,
        Paint()..color = const Color(0xFF1565C0));
    canvas.drawLine(Offset(pos.dx - 18, pos.dy),
        Offset(pos.dx - 28, pos.dy + 10),
        Paint()..color = const Color(0xFF1565C0)..strokeWidth = 5..strokeCap = StrokeCap.round);
  }

  void _drawLadybug(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 12, Paint()..color = const Color(0xFFE53935));
    canvas.drawLine(Offset(center.dx, center.dy - 12), Offset(center.dx, center.dy + 12),
        Paint()..color = Colors.black..strokeWidth = 1.5);
    for (int i = 0; i < 4; i++) {
      final dx = (i % 2 == 0 ? -6.0 : 6.0);
      final dy = -4.0 + (i / 2).floor() * 8.0;
      canvas.drawCircle(Offset(center.dx + dx, center.dy + dy), 3, Paint()..color = Colors.black87);
    }
    canvas.drawCircle(Offset(center.dx, center.dy - 14), 7,
        Paint()..color = Colors.black87);
    canvas.drawCircle(Offset(center.dx - 3, center.dy - 15), 2.5,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx + 3, center.dy - 15), 2.5,
        Paint()..color = Colors.white);
  }

  void _drawClownfish(Canvas canvas, Offset center, double size, double at) {
    final orange = const Color(0xFFFF6D00);
    // Body
    final bodyPath = Path()
      ..moveTo(center.dx - size * 0.5, center.dy)
      ..quadraticBezierTo(center.dx - size * 0.1, center.dy - size * 0.45,
          center.dx + size * 0.3, center.dy)
      ..quadraticBezierTo(center.dx - size * 0.1, center.dy + size * 0.45,
          center.dx - size * 0.5, center.dy)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = orange);
    // White stripes
    for (int i = 0; i < 3; i++) {
      final sx = center.dx - size * 0.25 + i * size * 0.25;
      canvas.drawLine(Offset(sx, center.dy - size * 0.35), Offset(sx, center.dy + size * 0.35),
          Paint()..color = Colors.white..strokeWidth = 5);
    }
    // Tail
    final tailPath = Path()
      ..moveTo(center.dx + size * 0.3, center.dy)
      ..lineTo(center.dx + size * 0.55, center.dy - size * 0.28)
      ..lineTo(center.dx + size * 0.55, center.dy + size * 0.28)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = orange);
    // Eye
    canvas.drawCircle(Offset(center.dx - size * 0.22, center.dy - size * 0.1),
        size * 0.1, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx - size * 0.2, center.dy - size * 0.1),
        size * 0.055, Paint()..color = Colors.black87);
    // Fins (animated)
    final finAngle = sin(at * 2) * 0.3;
    canvas.save();
    canvas.translate(center.dx, center.dy - size * 0.3);
    canvas.rotate(finAngle);
    final finPath = Path()
      ..moveTo(0, 0)
      ..lineTo(-size * 0.15, -size * 0.22)
      ..lineTo(size * 0.08, -size * 0.15)
      ..close();
    canvas.drawPath(finPath, Paint()..color = orange.withValues(alpha: 0.85));
    canvas.restore();
  }

  void _drawSmallFish(Canvas canvas, Offset center, Color color) {
    final fishPath = Path()
      ..moveTo(center.dx - 12, center.dy)
      ..quadraticBezierTo(center.dx, center.dy - 8, center.dx + 10, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + 8, center.dx - 12, center.dy)
      ..close();
    canvas.drawPath(fishPath, Paint()..color = color);
    final tailPath = Path()
      ..moveTo(center.dx + 10, center.dy)
      ..lineTo(center.dx + 18, center.dy - 7)
      ..lineTo(center.dx + 18, center.dy + 7)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = color);
    canvas.drawCircle(Offset(center.dx - 4, center.dy - 2), 3,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx - 3, center.dy - 2), 2,
        Paint()..color = Colors.black87);
  }

  void _drawOctopus(Canvas canvas, Offset center, double size, double at) {
    // Tentacles
    for (int i = 0; i < 8; i++) {
      final baseAngle = (i - 3.5) * pi / 5;
      final tentPath = Path();
      tentPath.moveTo(center.dx + cos(baseAngle) * size * 0.3,
          center.dy + sin(baseAngle) * size * 0.3 + size * 0.15);
      final cp1x = center.dx + cos(baseAngle) * size * 0.6;
      final cp1y = center.dy + sin(baseAngle) * size * 0.6 + size * 0.3 + sin(at + i) * 8;
      final ep = Offset(cp1x + cos(baseAngle + 0.5) * size * 0.25,
          cp1y + sin(baseAngle + 0.5) * size * 0.3);
      tentPath.quadraticBezierTo(cp1x, cp1y, ep.dx, ep.dy);
      canvas.drawPath(tentPath, Paint()..color = const Color(0xFF9C27B0)
          ..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round);
    }
    // Body
    canvas.drawOval(Rect.fromCenter(center: center, width: size * 0.65, height: size * 0.6),
        Paint()..color = const Color(0xFFAB47BC));
    // Eyes
    canvas.drawCircle(Offset(center.dx - size * 0.14, center.dy - size * 0.1),
        size * 0.1, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx + size * 0.14, center.dy - size * 0.1),
        size * 0.1, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx - size * 0.1, center.dy - size * 0.1),
        size * 0.055, Paint()..color = Colors.black87);
    canvas.drawCircle(Offset(center.dx + size * 0.1, center.dy - size * 0.1),
        size * 0.055, Paint()..color = Colors.black87);
  }

  void _drawSeaweed(Canvas canvas, Offset base, double h, double at) {
    final path = Path();
    path.moveTo(base.dx, base.dy);
    for (int i = 1; i <= 6; i++) {
      final sx = base.dx + sin(at + i * 0.8) * 8;
      path.lineTo(sx, base.dy - h * i / 6);
    }
    canvas.drawPath(path, Paint()..color = const Color(0xFF2E7D32)
        ..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round);
  }

  void _drawCoral(Canvas canvas, Offset base) {
    for (int i = 0; i < 5; i++) {
      final cx = base.dx + (i - 2) * 8.0;
      final ch = 16.0 + (i % 3) * 8;
      canvas.drawLine(Offset(cx, base.dy), Offset(cx, base.dy - ch),
          Paint()..color = const Color(0xFFFF7043)..strokeWidth = 5..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(cx, base.dy - ch), 5, Paint()..color = const Color(0xFFFF5722));
    }
  }

  void _drawChalkText(Canvas canvas, String text, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(text: text,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.95),
              fontSize: fontSize, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawText(Canvas canvas, String text, Offset center, double fontSize,
      Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text,
          style: TextStyle(color: color, fontSize: fontSize,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_ScenePainter old) => true;
}

// ── Wave bars ──────────────────────────────────────────────────────────────────
class _WaveBars extends StatelessWidget {
  final AnimationController ctrl;
  const _WaveBars({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final h = 5 + sin((ctrl.value + i / 7) * pi * 2).abs() * 20;
            return Container(
              width: 4,
              height: h,
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Info chip ──────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String text;
  final Color bg;
  const _InfoChip(this.text, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
