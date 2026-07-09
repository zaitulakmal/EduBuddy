import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';

// Each coloring page is a list of regions, each region is a path builder + default color
class _Region {
  final String id;
  final Color defaultColor;
  final Path Function(Size) pathBuilder;
  _Region(this.id, this.defaultColor, this.pathBuilder);
}

class _ColoringPage {
  final String title;
  final String emoji;
  final List<Color> gradient;
  final List<_Region> Function(Size) regionBuilder;
  _ColoringPage(this.title, this.emoji, this.gradient, this.regionBuilder);
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
    _ColoringPage('Sunshine', '☀️', AppColors.gradients[6], _sunRegions),
    _ColoringPage('Happy Cat', '🐱', AppColors.gradients[4], _catRegions),
    _ColoringPage('Big Tree', '🌳', AppColors.gradients[2], _treeRegions),
    _ColoringPage('Rainbow', '🌈', AppColors.gradients[3], _rainbowRegions),
    _ColoringPage('Cute Fish', '🐟', AppColors.gradients[1], _fishRegions),
  ];

  // ── Sun regions ────────────────────────────────────────────────────────────
  List<_Region> _sunRegions(Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    final r = s.shortestSide * 0.22;
    return [
      _Region('sun_body', const Color(0xFFFFEB3B), (sz) {
        final p = Path();
        p.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
        return p;
      }),
      _Region('sun_rays', const Color(0xFFFF9800), (sz) {
        final p = Path();
        const beams = 8;
        for (int i = 0; i < beams; i++) {
          final angle = (i * 3.14159265 * 2 / beams) - 3.14159265 / 2;
          final inner = r + 6;
          final outer = r + s.shortestSide * 0.14;
          final half = 0.15;
          p.moveTo(cx + inner * _cos(angle - half), cy + inner * _sin(angle - half));
          p.lineTo(cx + outer * _cos(angle), cy + outer * _sin(angle));
          p.lineTo(cx + inner * _cos(angle + half), cy + inner * _sin(angle + half));
          p.close();
        }
        return p;
      }),
      _Region('sky', const Color(0xFF90CAF9), (sz) {
        final p = Path();
        p.addRect(Rect.fromLTWH(0, 0, sz.width, sz.height * 0.55));
        return p;
      }),
      _Region('ground', const Color(0xFF8BC34A), (sz) {
        final p = Path();
        p.addRect(Rect.fromLTWH(0, sz.height * 0.55, sz.width, sz.height * 0.45));
        return p;
      }),
    ];
  }

  // ── Cat regions ────────────────────────────────────────────────────────────
  List<_Region> _catRegions(Size s) {
    final cx = s.width / 2, cy = s.height * 0.42;
    final head = s.shortestSide * 0.28;
    return [
      _Region('cat_head', const Color(0xFFFFCC80), (sz) {
        final p = Path();
        p.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: head));
        return p;
      }),
      _Region('cat_ear_l', const Color(0xFFFFCC80), (sz) {
        final p = Path();
        p.moveTo(cx - head * 0.7, cy - head * 0.7);
        p.lineTo(cx - head * 0.3, cy - head * 1.1);
        p.lineTo(cx - head * 0.05, cy - head * 0.75);
        p.close();
        return p;
      }),
      _Region('cat_ear_r', const Color(0xFFFFCC80), (sz) {
        final p = Path();
        p.moveTo(cx + head * 0.7, cy - head * 0.7);
        p.lineTo(cx + head * 0.3, cy - head * 1.1);
        p.lineTo(cx + head * 0.05, cy - head * 0.75);
        p.close();
        return p;
      }),
      _Region('cat_body', const Color(0xFFFFB74D), (sz) {
        final p = Path();
        p.addOval(Rect.fromCenter(
            center: Offset(cx, cy + head * 1.6),
            width: head * 1.6, height: head * 2.0));
        return p;
      }),
      _Region('cat_face', const Color(0xFFFF7043), (sz) {
        final p = Path();
        p.addOval(Rect.fromCircle(center: Offset(cx - head * 0.28, cy - head * 0.05), radius: head * 0.12));
        p.addOval(Rect.fromCircle(center: Offset(cx + head * 0.28, cy - head * 0.05), radius: head * 0.12));
        return p;
      }),
    ];
  }

  // ── Tree regions ───────────────────────────────────────────────────────────
  List<_Region> _treeRegions(Size s) {
    final cx = s.width / 2, by = s.height * 0.85;
    return [
      _Region('trunk', const Color(0xFF795548), (sz) {
        final p = Path();
        p.addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, by - sz.height * 0.12), width: sz.width * 0.12, height: sz.height * 0.3),
          const Radius.circular(6),
        ));
        return p;
      }),
      _Region('leaves_bot', const Color(0xFF66BB6A), (sz) {
        final p = Path();
        p.moveTo(cx, by - sz.height * 0.9);
        p.lineTo(cx + sz.width * 0.4, by - sz.height * 0.45);
        p.lineTo(cx - sz.width * 0.4, by - sz.height * 0.45);
        p.close();
        return p;
      }),
      _Region('leaves_mid', const Color(0xFF43A047), (sz) {
        final p = Path();
        p.moveTo(cx, by - sz.height * 0.98);
        p.lineTo(cx + sz.width * 0.3, by - sz.height * 0.62);
        p.lineTo(cx - sz.width * 0.3, by - sz.height * 0.62);
        p.close();
        return p;
      }),
      _Region('leaves_top', const Color(0xFF2E7D32), (sz) {
        final p = Path();
        p.moveTo(cx, by - sz.height * 1.02);
        p.lineTo(cx + sz.width * 0.18, by - sz.height * 0.78);
        p.lineTo(cx - sz.width * 0.18, by - sz.height * 0.78);
        p.close();
        return p;
      }),
      _Region('ground', const Color(0xFF8BC34A), (sz) {
        final p = Path();
        p.addRect(Rect.fromLTWH(0, by - sz.height * 0.03, sz.width, sz.height * 0.08));
        return p;
      }),
    ];
  }

  // ── Rainbow regions ────────────────────────────────────────────────────────
  List<_Region> _rainbowRegions(Size s) {
    final cx = s.width / 2, cy = s.height * 0.72;
    final bands = [
      ('red', const Color(0xFFEF5350)),
      ('orange', const Color(0xFFFF9800)),
      ('yellow', const Color(0xFFFFEE58)),
      ('green', const Color(0xFF66BB6A)),
      ('blue', const Color(0xFF42A5F5)),
      ('violet', const Color(0xFFAB47BC)),
    ];
    final maxR = s.width * 0.52;
    return [
      for (int i = 0; i < bands.length; i++)
        _Region('band_$i', bands[i].$2, (sz) {
          final r1 = maxR - i * sz.width * 0.07;
          final r2 = r1 - sz.width * 0.06;
          final p = Path();
          p.addArc(Rect.fromCircle(center: Offset(cx, cy), radius: r1), 3.14159265, 3.14159265);
          p.addArc(Rect.fromCircle(center: Offset(cx, cy), radius: r2), 0, -3.14159265);
          p.close();
          return p;
        }),
      _Region('clouds', Colors.white, (sz) {
        final p = Path();
        void cloud(double x, double y, double r) {
          p.addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
          p.addOval(Rect.fromCircle(center: Offset(x + r * 0.9, y + r * 0.2), radius: r * 0.75));
          p.addOval(Rect.fromCircle(center: Offset(x - r * 0.9, y + r * 0.2), radius: r * 0.75));
        }
        cloud(sz.width * 0.15, cy, sz.width * 0.08);
        cloud(sz.width * 0.85, cy, sz.width * 0.08);
        return p;
      }),
    ];
  }

  // ── Fish regions ───────────────────────────────────────────────────────────
  List<_Region> _fishRegions(Size s) {
    final cx = s.width / 2, cy = s.height / 2;
    return [
      _Region('water', const Color(0xFF81D4FA), (sz) {
        final p = Path();
        p.addRect(Rect.fromLTWH(0, sz.height * 0.45, sz.width, sz.height));
        return p;
      }),
      _Region('fish_body', const Color(0xFFFF7043), (sz) {
        final p = Path();
        p.addOval(Rect.fromCenter(center: Offset(cx, cy), width: sz.width * 0.55, height: sz.height * 0.28));
        return p;
      }),
      _Region('fish_tail', const Color(0xFFFF5722), (sz) {
        final p = Path();
        p.moveTo(cx + sz.width * 0.28, cy);
        p.lineTo(cx + sz.width * 0.44, cy - sz.height * 0.14);
        p.lineTo(cx + sz.width * 0.44, cy + sz.height * 0.14);
        p.close();
        return p;
      }),
      _Region('fish_fin', const Color(0xFFFF8A65), (sz) {
        final p = Path();
        p.moveTo(cx - sz.width * 0.05, cy - sz.height * 0.14);
        p.lineTo(cx + sz.width * 0.1, cy - sz.height * 0.24);
        p.lineTo(cx + sz.width * 0.18, cy - sz.height * 0.14);
        p.close();
        return p;
      }),
      _Region('fish_eye', const Color(0xFF1A1A2E), (sz) {
        final p = Path();
        p.addOval(Rect.fromCircle(center: Offset(cx - sz.width * 0.14, cy - sz.height * 0.04), radius: sz.width * 0.035));
        return p;
      }),
      _Region('bubbles', Colors.white, (sz) {
        final p = Path();
        p.addOval(Rect.fromCircle(center: Offset(cx - sz.width * 0.25, cy - sz.height * 0.2), radius: sz.width * 0.025));
        p.addOval(Rect.fromCircle(center: Offset(cx - sz.width * 0.32, cy - sz.height * 0.3), radius: sz.width * 0.018));
        p.addOval(Rect.fromCircle(center: Offset(cx - sz.width * 0.18, cy - sz.height * 0.35), radius: sz.width * 0.02));
        return p;
      }),
    ];
  }

  // ── Trig helpers ───────────────────────────────────────────────────────────
  double _cos(double a) => _cosImpl(a);
  double _sin(double a) => _cosImpl(a - 3.141592653589793 / 2);
  double _cosImpl(double a) {
    const pi = 3.141592653589793;
    a = a % (2 * pi);
    if (a < 0) a += 2 * pi;
    if (a < pi / 2) return _cosTaylor(a);
    if (a < pi) return -_cosTaylor(pi - a);
    if (a < 3 * pi / 2) return -_cosTaylor(a - pi);
    return _cosTaylor(2 * pi - a);
  }
  double _cosTaylor(double x) {
    final x2 = x * x;
    return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720;
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

  Widget _buildCelebrationBanner(  _ColoringPage page) {
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
          const Text('Tap any area to fill it with your colour!',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
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

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.white);

    final regions = page.regionBuilder(size);
    for (final region in regions) {
      final path = region.pathBuilder(size);
      final fillColor = fills['${pageIndex}_${region.id}'] ?? region.defaultColor;
      // Fill
      canvas.drawPath(path, Paint()..color = fillColor..style = PaintingStyle.fill);
      // Outline
      canvas.drawPath(path, Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
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
