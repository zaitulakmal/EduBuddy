import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';

enum _Tool { pen, eraser, fill }

enum _StampShape { star, heart, circle, square, triangle }

class _DrawStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final _Tool tool;
  _DrawStroke(this.points, this.color, this.width, this.tool);
}

class _Stamp {
  final Offset position;
  final _StampShape shape;
  final Color color;
  _Stamp(this.position, this.shape, this.color);
}

class DrawingStudioScreen extends StatefulWidget {
  const DrawingStudioScreen({super.key});

  @override
  State<DrawingStudioScreen> createState() => _DrawingStudioScreenState();
}

class _DrawingStudioScreenState extends State<DrawingStudioScreen>
    with TickerProviderStateMixin {
  final List<_DrawStroke> _strokes = [];
  final List<_Stamp> _stamps = [];
  final List<_DrawStroke> _undoneStrokes = [];
  List<Offset> _currentPoints = [];
  late ConfettiController _confettiController;
  late AnimationController _toolbarAnim;

  _Tool _tool = _Tool.pen;
  _StampShape _selectedStamp = _StampShape.star;
  double _brushSize = 14;
  Color _color = const Color(0xFFFF6B35);
  Color _bgColor = Colors.white;

  final List<Color> _palette = [
    const Color(0xFFFF6B35), const Color(0xFFFF5252), const Color(0xFFFF80AB),
    const Color(0xFFFFD700), const Color(0xFF7BC67E), const Color(0xFF4ECDC4),
    const Color(0xFF64B5F6), const Color(0xFFB388FF), const Color(0xFF795548),
    const Color(0xFF000000), const Color(0xFF607D8B), Colors.white,
  ];

  final List<Color> _bgPalette = [
    Colors.white, const Color(0xFFFFF8F0), const Color(0xFFE3F2FD),
    const Color(0xFFF3E5F5), const Color(0xFFE8F5E9), const Color(0xFFFFF9C4),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _toolbarAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _toolbarAnim.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _toolbarAnim.dispose();
    super.dispose();
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _undoneStrokes.add(_strokes.removeLast());
      });
    } else if (_stamps.isNotEmpty) {
      setState(() => _stamps.removeLast());
    }
  }

  void _redo() {
    if (_undoneStrokes.isNotEmpty) {
      setState(() => _strokes.add(_undoneStrokes.removeLast()));
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _stamps.clear();
      _undoneStrokes.clear();
    });
  }

  void _celebrate() {
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildBgColorRow(),
              Expanded(child: _buildCanvas()),
              _buildToolRow(),
              _buildBrushSizeRow(),
              _buildPaletteRow(),
              _buildBottomActions(),
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
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF16213E),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        '🎨 Drawing Studio',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.undo_rounded, color: Colors.white70),
          onPressed: _undo,
          tooltip: 'Undo',
        ),
        IconButton(
          icon: const Icon(Icons.redo_rounded, color: Colors.white70),
          onPressed: _redo,
          tooltip: 'Redo',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
          onPressed: _clear,
          tooltip: 'Clear',
        ),
      ],
    );
  }

  Widget _buildBgColorRow() {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Text('Canvas:', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          ..._bgPalette.map((c) => GestureDetector(
            onTap: () => setState(() => _bgColor = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _bgColor == c ? 26 : 20,
              height: _bgColor == c ? 26 : 20,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _bgColor == c ? Colors.white : Colors.white24,
                  width: _bgColor == c ? 2 : 1,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onTapUp: (d) {
            if (_tool == _Tool.fill) {
              setState(() => _stamps.add(_Stamp(d.localPosition, _selectedStamp, _color)));
              _undoneStrokes.clear();
            }
          },
          onPanStart: (d) {
            if (_tool != _Tool.fill) {
              setState(() => _currentPoints = [d.localPosition]);
              _undoneStrokes.clear();
            }
          },
          onPanUpdate: (d) {
            if (_tool != _Tool.fill) {
              setState(() => _currentPoints = List.from(_currentPoints)..add(d.localPosition));
            }
          },
          onPanEnd: (_) {
            if (_tool != _Tool.fill && _currentPoints.isNotEmpty) {
              setState(() {
                _strokes.add(_DrawStroke(List.from(_currentPoints), _color, _brushSize, _tool));
                _currentPoints = [];
              });
            }
          },
          child: CustomPaint(
            painter: _StudioPainter(
              strokes: _strokes,
              stamps: _stamps,
              currentPoints: _currentPoints,
              currentColor: _color,
              currentWidth: _brushSize,
              currentTool: _tool,
              bgColor: _bgColor,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  Widget _buildToolRow() {
    final tools = [
      (_Tool.pen, Icons.brush_rounded, 'Draw'),
      (_Tool.eraser, Icons.auto_fix_normal_rounded, 'Erase'),
      (_Tool.fill, Icons.interests_rounded, 'Stamp'),
    ];
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          ...tools.map((t) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tool = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _tool == t.$1 ? _color.withValues(alpha: 0.25) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _tool == t.$1 ? _color : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$2, color: _tool == t.$1 ? _color : Colors.white54, size: 22),
                    const SizedBox(height: 2),
                    Text(t.$3, style: TextStyle(color: _tool == t.$1 ? _color : Colors.white54, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          )),
          if (_tool == _Tool.fill) ...[
            const SizedBox(width: 8),
            ..._StampShape.values.map((s) => GestureDetector(
              onTap: () => setState(() => _selectedStamp = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _selectedStamp == s ? _color.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedStamp == s ? _color : Colors.white24,
                  ),
                ),
                child: CustomPaint(
                  painter: _StampPreviewPainter(s, _selectedStamp == s ? _color : Colors.white38),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildBrushSizeRow() {
    final sizes = [(8.0, 'XS'), (14.0, 'S'), (22.0, 'M'), (34.0, 'L'), (50.0, 'XL')];
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: sizes.map((s) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _brushSize = s.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 36,
              decoration: BoxDecoration(
                color: _brushSize == s.$1 ? _color.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _brushSize == s.$1 ? _color : Colors.white12),
              ),
              child: Center(
                child: Container(
                  width: (s.$1 * 0.4).clamp(4, 22),
                  height: (s.$1 * 0.4).clamp(4, 22),
                  decoration: BoxDecoration(
                    color: _brushSize == s.$1 ? _color : Colors.white38,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildPaletteRow() {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _palette.map((c) {
            final selected = c == _color;
            return GestureDetector(
              onTap: () => setState(() {
                _color = c;
                if (_tool == _Tool.eraser) _tool = _Tool.pen;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 38 : 28,
                height: selected ? 38 : 28,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.white : Colors.white24,
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)]
                      : [],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: BouncyButton(
        onTap: _celebrate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF9F43)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🎉', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('I\'m Done!', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Painters ────────────────────────────────────────────────────────────────

class _StudioPainter extends CustomPainter {
  final List<_DrawStroke> strokes;
  final List<_Stamp> stamps;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final _Tool currentTool;
  final Color bgColor;

  const _StudioPainter({
    required this.strokes,
    required this.stamps,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.currentTool,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = bgColor);

    for (final stamp in stamps) {
      _drawStampShape(canvas, stamp.position, stamp.shape, stamp.color, 40);
    }
    for (final s in strokes) {
      _drawPath(canvas, s.points, s.color, s.width, s.tool);
    }
    if (currentPoints.isNotEmpty) {
      _drawPath(canvas, currentPoints, currentColor, currentWidth, currentTool);
    }
    canvas.restore();
  }

  void _drawPath(Canvas canvas, List<Offset> pts, Color color, double width, _Tool tool) {
    if (pts.isEmpty) return;
    final paint = Paint()
      ..color = tool == _Tool.eraser ? bgColor : color
      ..strokeWidth = tool == _Tool.eraser ? width * 2.5 : width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (pts.length == 1) {
      canvas.drawCircle(pts.first, width / 2, paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      if (i < pts.length - 1) {
        final mid = Offset((pts[i].dx + pts[i + 1].dx) / 2, (pts[i].dy + pts[i + 1].dy) / 2);
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
      } else {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawStampShape(Canvas canvas, Offset center, _StampShape shape, Color color, double size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = color.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 3;

    switch (shape) {
      case _StampShape.star:
        _drawStar(canvas, center, size, paint);
      case _StampShape.heart:
        _drawHeart(canvas, center, size, paint);
      case _StampShape.circle:
        canvas.drawCircle(center, size / 2, paint);
        canvas.drawCircle(center, size / 2, strokePaint);
      case _StampShape.square:
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: size, height: size), const Radius.circular(6)), paint);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: size, height: size), const Radius.circular(6)), strokePaint);
      case _StampShape.triangle:
        final path = Path()
          ..moveTo(center.dx, center.dy - size / 2)
          ..lineTo(center.dx + size / 2, center.dy + size / 2)
          ..lineTo(center.dx - size / 2, center.dy + size / 2)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 5;
    final outerR = size / 2;
    final innerR = outerR * 0.4;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * 3.14159265 / points) - 3.14159265 / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final s = size / 2;
    final path = Path();
    path.moveTo(center.dx, center.dy + s * 0.8);
    path.cubicTo(center.dx - s * 1.2, center.dy + s * 0.2, center.dx - s * 1.4, center.dy - s * 0.8, center.dx - s * 0.7, center.dy - s);
    path.cubicTo(center.dx - s * 0.3, center.dy - s * 1.1, center.dx, center.dy - s * 0.8, center.dx, center.dy - s * 0.5);
    path.cubicTo(center.dx, center.dy - s * 0.8, center.dx + s * 0.3, center.dy - s * 1.1, center.dx + s * 0.7, center.dy - s);
    path.cubicTo(center.dx + s * 1.4, center.dy - s * 0.8, center.dx + s * 1.2, center.dy + s * 0.2, center.dx, center.dy + s * 0.8);
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double a) => _cosImpl(a);
  double _sin(double a) => _cosImpl(a - 3.141592653589793 / 2);

  double _cosImpl(double a) {
    // Simple cos approximation
    a = a % (2 * 3.141592653589793);
    if (a < 0) a += 2 * 3.141592653589793;
    // Use 4-quadrant
    if (a < 3.141592653589793 / 2) return _cosTaylor(a);
    if (a < 3.141592653589793) return -_cosTaylor(3.141592653589793 - a);
    if (a < 3 * 3.141592653589793 / 2) return -_cosTaylor(a - 3.141592653589793);
    return _cosTaylor(2 * 3.141592653589793 - a);
  }

  double _cosTaylor(double x) {
    double x2 = x * x;
    return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720;
  }

  @override
  bool shouldRepaint(_StudioPainter old) => true;
}

class _StampPreviewPainter extends CustomPainter {
  final _StampShape shape;
  final Color color;
  _StampPreviewPainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final s = size.shortestSide * 0.7;
    switch (shape) {
      case _StampShape.star:
        _drawStar(canvas, center, s, paint);
      case _StampShape.heart:
        _drawHeart(canvas, center, s, paint);
      case _StampShape.circle:
        canvas.drawCircle(center, s / 2, paint);
      case _StampShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: s, height: s), const Radius.circular(4)),
          paint,
        );
      case _StampShape.triangle:
        final path = Path()
          ..moveTo(center.dx, center.dy - s / 2)
          ..lineTo(center.dx + s / 2, center.dy + s / 2)
          ..lineTo(center.dx - s / 2, center.dy + s / 2)
          ..close();
        canvas.drawPath(path, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 5;
    final outerR = size / 2;
    final innerR = outerR * 0.4;
    const pi = 3.141592653589793;
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final s = size / 2;
    final path = Path();
    path.moveTo(center.dx, center.dy + s * 0.8);
    path.cubicTo(center.dx - s * 1.2, center.dy + s * 0.2, center.dx - s * 1.4, center.dy - s * 0.8, center.dx - s * 0.7, center.dy - s);
    path.cubicTo(center.dx - s * 0.3, center.dy - s * 1.1, center.dx, center.dy - s * 0.8, center.dx, center.dy - s * 0.5);
    path.cubicTo(center.dx, center.dy - s * 0.8, center.dx + s * 0.3, center.dy - s * 1.1, center.dx + s * 0.7, center.dy - s);
    path.cubicTo(center.dx + s * 1.4, center.dy - s * 0.8, center.dx + s * 1.2, center.dy + s * 0.2, center.dx, center.dy + s * 0.8);
    path.close();
    canvas.drawPath(path, paint);
  }

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

  @override
  bool shouldRepaint(_StampPreviewPainter old) => old.shape != shape || old.color != color;
}
