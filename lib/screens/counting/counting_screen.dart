import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';

class _FloatItem {
  Offset position;
  final double size;
  final int type; // 0-4 shape types
  final Color color;
  bool counted;

  _FloatItem({
    required this.position,
    required this.size,
    required this.type,
    required this.color,
    this.counted = false,
  });
}

class CountingScreen extends StatefulWidget {
  const CountingScreen({super.key});

  @override
  State<CountingScreen> createState() => _CountingScreenState();
}

class _CountingScreenState extends State<CountingScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _bounceController;
  late AnimationController _questionAnim;
  final _rand = Random();

  int _level = 1;
  int _score = 0;
  int _targetCount = 0;
  int _tappedCount = 0;
  List<_FloatItem> _items = [];
  bool _celebrating = false;
  bool _wrongAnswer = false;
  String _questionLabel = '';
  int _lives = 3;
  bool _gameOver = false;

  static const _itemColors = [
    Color(0xFFFF6B35), Color(0xFFFFD700), Color(0xFF7BC67E),
    Color(0xFF64B5F6), Color(0xFFFF80AB), Color(0xFFB388FF),
    Color(0xFF4ECDC4), Color(0xFFFF5252),
  ];

  static const _labels = [
    'stars', 'suns', 'hearts', 'circles', 'triangles',
    'squares', 'diamonds', 'clouds',
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _questionAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _newRound();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _bounceController.dispose();
    _questionAnim.dispose();
    super.dispose();
  }

  void _newRound() {
    _targetCount = _level <= 3 ? _rand.nextInt(3) + 1 : _rand.nextInt(5) + _level;
    if (_targetCount > 10) _targetCount = 10;
    _tappedCount = 0;
    _celebrating = false;
    _wrongAnswer = false;
    final type = _rand.nextInt(8);
    _questionLabel = _labels[type];
    _items = List.generate(_targetCount + _rand.nextInt(4), (i) {
      final angle = _rand.nextDouble() * 2 * pi;
      final dist = _rand.nextDouble();
      return _FloatItem(
        position: Offset(
          0.1 + dist * 0.8 * cos(angle) * 0.5 + 0.5,
          0.1 + dist * 0.8 * sin(angle) * 0.5 + 0.5,
        ),
        size: 66 + _rand.nextDouble() * 22,
        type: type,
        color: _itemColors[i % _itemColors.length],
        counted: false,
      );
    });
    // Only the first _targetCount are "correct" to tap; extras are distractors of different type
    for (int i = _targetCount; i < _items.length; i++) {
      _items[i] = _FloatItem(
        position: _items[i].position,
        size: _items[i].size,
        type: (type + 1 + _rand.nextInt(7)) % 8,
        color: _itemColors[(i + 3) % _itemColors.length],
      );
    }
    _items.shuffle(_rand);
    _questionAnim.forward(from: 0);
  }

  void _onTapItem(int index) {
    if (_celebrating || _gameOver) return;
    final item = _items[index];
    if (item.counted) return;

    if (item.type == _getTargetType()) {
      // Correct tap
      SoundService.instance.star();
      setState(() {
        item.counted = true;
        _tappedCount++;
      });
      if (_tappedCount == _targetCount) {
        _onSuccess();
      }
    } else {
      // Wrong item tapped
      SoundService.instance.wrong();
      setState(() {
        _wrongAnswer = true;
        _lives--;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _wrongAnswer = false);
      });
      if (_lives <= 0) {
        setState(() => _gameOver = true);
      }
    }
  }

  int _getTargetType() => _items.isNotEmpty
      ? _items.firstWhere((i) => !i.counted || i.type == _items[0].type, orElse: () => _items[0]).type
      : 0;

  void _onSuccess() {
    setState(() {
      _celebrating = true;
      _score += _targetCount * 10 * _level;
    });
    SoundService.instance.win();
    _confettiController.play();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _level++);
        _newRound();
      }
    });
  }

  void _restart() {
    setState(() {
      _level = 1;
      _score = 0;
      _lives = 3;
      _gameOver = false;
    });
    _newRound();
  }

  @override
  Widget build(BuildContext context) {
    final grad = AppColors.gradients[(_level - 1) % AppColors.gradients.length];
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [grad[0].withValues(alpha: 0.15), grad[1].withValues(alpha: 0.08)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(grad),
                _buildQuestion(grad),
                Expanded(child: _buildPlayArea()),
                _buildBottomHint(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 50,
              gravity: 0.25,
              colors: AppColors.gradients.map((g) => g[0]).toList(),
            ),
          ),
          if (_celebrating) _buildCelebration(grad),
          if (_gameOver) _buildGameOver(),
        ],
      ),
    );
  }

  Widget _buildTopBar(List<Color> grad) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: grad[0].withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_rounded, color: grad[0], size: 22),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text('Level $_level', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: grad[0])),
            ),
          ),
          // Lives
          Row(
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(Icons.favorite_rounded, color: i < _lives ? Colors.red : Colors.grey.shade300, size: 20),
            )),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text('$_score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(List<Color> grad) {
    final remaining = _targetCount - _tappedCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: AnimatedBuilder(
        animation: _questionAnim,
        builder: (_, _) => Transform.scale(
          scale: 0.8 + 0.2 * _questionAnim.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: grad[0].withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                Text(
                  'Tap $_targetCount $_questionLabel!',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(_targetCount, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: i < _tappedCount ? Colors.white : Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 1.5),
                        ),
                      ),
                    )),
                    const SizedBox(width: 10),
                    Text(
                      '$remaining left',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayArea() {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Stack(
        children: [
          // Subtle grid lines
          CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
          // Items
          ..._items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final x = item.position.dx * (w - item.size);
            final y = item.position.dy * (h - item.size);
            return Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                onTap: () => _onTapItem(i),
                child: AnimatedBuilder(
                  animation: _bounceController,
                  builder: (_, _) {
                    final phase = _bounceController.value * pi + i * 0.8;
                    final bounce = item.counted ? 0.0 : sin(phase) * 7;
                    final wobble = item.counted ? 0.0 : sin(phase * 0.7) * 0.06;
                    return Transform.translate(
                      offset: Offset(0, bounce),
                      child: Transform.rotate(
                        angle: wobble,
                        child: AnimatedScale(
                          scale: item.counted ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticIn,
                          child: AnimatedOpacity(
                            opacity: item.counted ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            child: CustomPaint(
                              size: Size(item.size, item.size),
                              painter: _ItemPainter(item.type, item.color, item.counted),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
          // Wrong answer flash
          if (_wrongAnswer)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildBottomHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Text(
        'Tap the $_questionLabel — ignore the other shapes!',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCelebration(List<Color> grad) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: grad[0].withValues(alpha: 0.5), blurRadius: 30)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 6),
                const Text('Correct!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                Text('+${_targetCount * 10 * (_level - 1)} points!',
                    style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💫', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text('Game Over!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                const SizedBox(height: 6),
                Text('Score: $_score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                Text('Level reached: $_level', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _restart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF9F43)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Text('Play Again!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Grid background painter ──────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.withValues(alpha: 0.06)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ─── Item shape painter ───────────────────────────────────────────────────────

class _ItemPainter extends CustomPainter {
  final int type;
  final Color color;
  final bool faded;

  _ItemPainter(this.type, this.color, this.faded);

  static const _cos30 = 0.866025;

  Color _lighten(Color c, double amt) => Color.lerp(c, Colors.white, amt)!;
  Color _darken(Color c, double amt) => Color.lerp(c, Colors.black, amt)!;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.shortestSide / 2 - 4;
    final center = Offset(cx, cy);

    if (faded) {
      final p = Paint()..color = color.withValues(alpha: 0.2);
      canvas.drawPath(_shapePath(center, r), p);
      return;
    }

    // Sun beams sit behind everything else
    if (type % 8 == 1) {
      final beam = Paint()
        ..color = _darken(color, 0.05)
        ..strokeWidth = r * 0.14
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final a = i * pi / 4 + pi / 8;
        canvas.drawLine(
          center + Offset(cos(a), sin(a)) * r * 0.68,
          center + Offset(cos(a), sin(a)) * r * 0.98,
          beam,
        );
      }
    }

    final path = _shapePath(center, r);

    // Soft drop shadow
    canvas.save();
    canvas.translate(0, r * 0.12);
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.restore();

    // Gradient body — light falls from the top-left like a sticker
    final bounds = Rect.fromCircle(center: center, radius: r * 1.2);
    canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            radius: 1.3,
            colors: [_lighten(color, 0.38), color, _darken(color, 0.16)],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(bounds));

    // Sticker border
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = (r * 0.10).clamp(2.5, 4.5)
          ..strokeJoin = StrokeJoin.round);

    // Glossy highlight
    canvas.save();
    canvas.translate(cx - r * 0.32, cy - r * 0.42);
    canvas.rotate(-0.5);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 0.5, height: r * 0.26),
        Paint()..color = Colors.white.withValues(alpha: 0.45));
    canvas.restore();

    _drawFace(canvas, center, r);
  }

  /// Cute face: two sparkly eyes + a smile. Offset tuned per shape.
  void _drawFace(Canvas canvas, Offset center, double r) {
    final t = type % 8;
    // Face anchor per shape (hearts sit higher, triangles lower, sun on core)
    final dy = switch (t) {
      2 => -r * 0.12, // heart
      4 => r * 0.22,  // triangle
      1 => 0.0,       // sun core
      7 => 0.05 * r,  // cloud
      _ => 0.0,
    };
    final scale = switch (t) {
      1 => 0.62, // sun face fits its core circle
      6 => 0.72, // diamond is narrow
      _ => 1.0,
    };
    final fc = Offset(center.dx, center.dy + dy);
    final er = r * 0.11 * scale; // eye radius
    final ex = r * 0.30 * scale; // eye x-spread
    final eyeY = fc.dy - r * 0.06 * scale;

    for (final side in [-1, 1]) {
      final eye = Offset(fc.dx + side * ex, eyeY);
      canvas.drawCircle(eye, er * 1.35, Paint()..color = Colors.white);
      canvas.drawCircle(eye, er, Paint()..color = const Color(0xFF3A3A3A));
      canvas.drawCircle(eye + Offset(-er * 0.3, -er * 0.35), er * 0.32,
          Paint()..color = Colors.white);
    }

    // Smile
    canvas.drawArc(
      Rect.fromCircle(center: Offset(fc.dx, eyeY + r * 0.18 * scale), radius: r * 0.20 * scale),
      0.25 * pi,
      0.5 * pi,
      false,
      Paint()
        ..color = const Color(0xFF3A3A3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (r * 0.07 * scale).clamp(2.0, 4.0)
        ..strokeCap = StrokeCap.round,
    );

    // Rosy cheeks
    final cheek = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.45);
    for (final side in [-1, 1]) {
      canvas.drawCircle(
          Offset(fc.dx + side * ex * 1.5, eyeY + r * 0.16 * scale), er * 0.7, cheek);
    }
  }

  Path _shapePath(Offset center, double r) {
    final cx = center.dx, cy = center.dy;
    switch (type % 8) {
      case 0: // star
        final path = Path();
        const n = 5;
        final inner = r * 0.5;
        for (int i = 0; i < n * 2; i++) {
          final angle = i * pi / n - pi / 2;
          final rad = i.isEven ? r : inner;
          final p = center + Offset(cos(angle), sin(angle)) * rad;
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        return path..close();
      case 1: // sun core (beams drawn separately)
        return Path()..addOval(Rect.fromCircle(center: center, radius: r * 0.58));
      case 2: // heart
        final s = r * 0.8;
        return Path()
          ..moveTo(cx, cy + s * 0.85)
          ..cubicTo(cx - s * 1.2, cy + s * 0.2, cx - s * 1.35, cy - s * 0.75, cx - s * 0.7, cy - s * 0.95)
          ..cubicTo(cx - s * 0.3, cy - s * 1.05, cx, cy - s * 0.75, cx, cy - s * 0.45)
          ..cubicTo(cx, cy - s * 0.75, cx + s * 0.3, cy - s * 1.05, cx + s * 0.7, cy - s * 0.95)
          ..cubicTo(cx + s * 1.35, cy - s * 0.75, cx + s * 1.2, cy + s * 0.2, cx, cy + s * 0.85)
          ..close();
      case 3: // circle
        return Path()..addOval(Rect.fromCircle(center: center, radius: r * 0.92));
      case 4: // triangle (rounded corners via arcs approximation: plain path)
        return Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * _cos30, cy + r * 0.5)
          ..lineTo(cx - r * _cos30, cy + r * 0.5)
          ..close();
      case 5: // square
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: center, width: r * 1.75, height: r * 1.75),
              Radius.circular(r * 0.35)));
      case 6: // diamond
        return Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * 0.75, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r * 0.75, cy)
          ..close();
      default: // cloud (single united path so the border has no inner seams)
        var cloud = Path()
          ..addOval(Rect.fromCenter(center: center, width: r * 1.9, height: r * 1.05));
        cloud = Path.combine(PathOperation.union, cloud,
            Path()..addOval(Rect.fromCircle(center: Offset(cx - r * 0.45, cy - r * 0.28), radius: r * 0.48)));
        cloud = Path.combine(PathOperation.union, cloud,
            Path()..addOval(Rect.fromCircle(center: Offset(cx + r * 0.32, cy - r * 0.34), radius: r * 0.42)));
        return cloud;
    }
  }

  @override
  bool shouldRepaint(_ItemPainter old) => old.type != type || old.color != color || old.faded != faded;
}
