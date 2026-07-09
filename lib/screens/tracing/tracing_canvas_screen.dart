import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';
import '../../services/sound_service.dart';

// Word associations for letters
const Map<String, String> _letterWords = {
  'A': 'Apple', 'B': 'Ball', 'C': 'Cat', 'D': 'Dog', 'E': 'Elephant',
  'F': 'Fish', 'G': 'Grapes', 'H': 'House', 'I': 'Ice Cream', 'J': 'Jellyfish',
  'K': 'Kite', 'L': 'Lion', 'M': 'Moon', 'N': 'Nest', 'O': 'Orange',
  'P': 'Penguin', 'Q': 'Queen', 'R': 'Rainbow', 'S': 'Star', 'T': 'Tiger',
  'U': 'Umbrella', 'V': 'Violin', 'W': 'Whale', 'X': 'Xylophone',
  'Y': 'Yak', 'Z': 'Zebra',
  '0': 'Zero', '1': 'One', '2': 'Two', '3': 'Three', '4': 'Four',
  '5': 'Five', '6': 'Six', '7': 'Seven', '8': 'Eight', '9': 'Nine',
};

class TracingCanvasScreen extends StatefulWidget {
  final String character;
  final List<String> allCharacters;
  final int currentIndex;

  const TracingCanvasScreen({
    super.key,
    required this.character,
    required this.allCharacters,
    required this.currentIndex,
  });

  @override
  State<TracingCanvasScreen> createState() => _TracingCanvasScreenState();
}

enum _DrawMode { pen, eraser }

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final _DrawMode mode;
  _Stroke(this.points, this.color, this.width, this.mode);
}

class _TracingCanvasScreenState extends State<TracingCanvasScreen>
    with TickerProviderStateMixin {
  final List<_Stroke> _strokes = [];
  List<Offset> _currentPoints = [];
  late ConfettiController _confettiController;
  bool _showCelebration = false;
  _DrawMode _drawMode = _DrawMode.pen;
  double _brushSize = 18;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<Color> _penColors = [
    const Color(0xFF4ECDC4),
    const Color(0xFFFF6B35),
    const Color(0xFFB388FF),
    const Color(0xFF7BC67E),
    const Color(0xFFFF80AB),
    const Color(0xFF64B5F6),
    const Color(0xFFFFD700),
    const Color(0xFFFF5252),
  ];

  late Color _strokeColor;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _strokeColor = _penColors[widget.currentIndex % _penColors.length];
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _celebrate() {
    if (_showCelebration) return;
    setState(() => _showCelebration = true);
    SoundService.instance.complete();
    _confettiController.play();
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentPoints = [];
      _showCelebration = false;
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
  }

  void _navigateTo(int index) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => TracingCanvasScreen(
          character: widget.allCharacters[index],
          allCharacters: widget.allCharacters,
          currentIndex: index,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  List<Color> get _gradient =>
      AppColors.gradients[widget.currentIndex % AppColors.gradients.length];

  String get _word => _letterWords[widget.character] ?? widget.character;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _gradient[0],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '"${widget.character}" is for $_word',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded, color: Colors.white),
            tooltip: 'Undo',
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Clear',
            onPressed: _clearCanvas,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildProgressHeader(),
              _buildWordBanner(),
              Expanded(child: _buildCanvas()),
              _buildToolbar(),
              _buildBottomBar(),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 45,
              gravity: 0.2,
              colors: [
                AppColors.primary, AppColors.secondary,
                AppColors.teal, AppColors.purple, AppColors.pink,
              ],
            ),
          ),
          if (_showCelebration) _buildCelebrationOverlay(),
        ],
      ),
    );
  }

  Widget _buildCelebrationOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, _) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _gradient),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: _gradient[0].withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 56)),
                    SizedBox(height: 8),
                    Text(
                      'Amazing!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Great writing!',
                      style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(gradient: LinearGradient(colors: _gradient)),
      child: Row(
        children: [
          _NavButton(
            icon: Icons.chevron_left_rounded,
            enabled: widget.currentIndex > 0,
            onTap: () => _navigateTo(widget.currentIndex - 1),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${widget.currentIndex + 1} / ${widget.allCharacters.length}',
                  style: const TextStyle(
                    color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (widget.currentIndex + 1) / widget.allCharacters.length,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          _NavButton(
            icon: Icons.chevron_right_rounded,
            enabled: widget.currentIndex < widget.allCharacters.length - 1,
            onTap: () => _navigateTo(widget.currentIndex + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildWordBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _gradient[0].withValues(alpha: 0.08),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, _) => Transform.scale(
              scale: 0.9 + 0.1 * _pulseAnim.value,
              child: CustomPaint(
                size: const Size(52, 52),
                painter: _LetterIconPainter(widget.character, _gradient),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${widget.character}" is for $_word',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _gradient[0],
                ),
              ),
              const Text(
                'Trace the letter with your finger!',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GestureDetector(
          onPanStart: (d) => setState(() {
            _currentPoints = [d.localPosition];
          }),
          onPanUpdate: (d) => setState(() {
            _currentPoints = List.from(_currentPoints)..add(d.localPosition);
          }),
          onPanEnd: (_) {
            if (_currentPoints.isNotEmpty) {
              setState(() {
                _strokes.add(_Stroke(
                  List.from(_currentPoints),
                  _strokeColor,
                  _brushSize,
                  _drawMode,
                ));
                _currentPoints = [];
              });
            }
          },
          child: CustomPaint(
            painter: _TracingPainter(
              character: widget.character,
              strokes: _strokes,
              currentPoints: _currentPoints,
              strokeColor: _strokeColor,
              brushSize: _brushSize,
              drawMode: _drawMode,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Draw / Eraser toggle
          _ToolButton(
            icon: Icons.brush_rounded,
            label: 'Draw',
            active: _drawMode == _DrawMode.pen,
            color: _gradient[0],
            onTap: () => setState(() => _drawMode = _DrawMode.pen),
          ),
          const SizedBox(width: 8),
          _ToolButton(
            icon: Icons.auto_fix_normal_rounded,
            label: 'Erase',
            active: _drawMode == _DrawMode.eraser,
            color: Colors.grey,
            onTap: () => setState(() => _drawMode = _DrawMode.eraser),
          ),
          const SizedBox(width: 12),
          // Brush size
          ...[ (10.0, 'S'), (18.0, 'M'), (28.0, 'L') ].map(
            (t) => GestureDetector(
              onTap: () => setState(() => _brushSize = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _brushSize == t.$1
                      ? _gradient[0].withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _brushSize == t.$1 ? _gradient[0] : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: t.$1 * 0.55,
                    height: t.$1 * 0.55,
                    decoration: BoxDecoration(
                      color: _brushSize == t.$1 ? _gradient[0] : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        children: [
          // Color picker
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _penColors.map((color) {
                final selected = color == _strokeColor && _drawMode == _DrawMode.pen;
                return GestureDetector(
                  onTap: () => setState(() {
                    _strokeColor = color;
                    _drawMode = _DrawMode.pen;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: selected ? 38 : 28,
                    height: selected ? 38 : 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.textDark : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 8, offset: const Offset(0, 3))]
                          : [],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          BouncyButton(
            onTap: _strokes.isNotEmpty ? _celebrate : () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: _gradient),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _gradient[0].withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _strokes.isEmpty ? '✏️  Start drawing!' : '🎉  Done!',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon, required this.label,
    required this.active, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? color : Colors.grey.shade300, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: active ? color : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? color : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: enabled ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.3), size: 28),
      ),
    );
  }
}

// ─── Letter icon painter (animated badge in word banner) ─────────────────────

class _LetterIconPainter extends CustomPainter {
  final String letter;
  final List<Color> gradient;
  _LetterIconPainter(this.letter, this.gradient);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), paint);

    final tp = TextPainter(
      text: TextSpan(
        text: letter,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_LetterIconPainter old) => old.letter != letter;
}

// ─── Main canvas painter ─────────────────────────────────────────────────────

class _TracingPainter extends CustomPainter {
  final String character;
  final List<_Stroke> strokes;
  final List<Offset> currentPoints;
  final Color strokeColor;
  final double brushSize;
  final _DrawMode drawMode;

  const _TracingPainter({
    required this.character,
    required this.strokes,
    required this.currentPoints,
    required this.strokeColor,
    required this.brushSize,
    required this.drawMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawNotebookLines(canvas, size);
    _drawGuide(canvas, size);
    _drawGuideArrows(canvas, size);
    for (final s in strokes) { _drawStroke(canvas, s.points, s.color, s.width, s.mode); }
    if (currentPoints.isNotEmpty) _drawStroke(canvas, currentPoints, strokeColor, brushSize, drawMode);
  }

  void _drawNotebookLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFADD8E6).withValues(alpha: 0.5)
      ..strokeWidth = 1.2;

    for (final pct in [0.25, 0.50, 0.75]) {
      final y = size.height * pct;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final dashPaint = Paint()
      ..color = const Color(0xFFADD8E6).withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + 6).clamp(0, size.height)),
        dashPaint,
      );
      y += 12;
    }
  }

  void _drawGuide(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(
          fontSize: size.height * 0.62,
          fontWeight: FontWeight.w900,
          color: Colors.grey.withValues(alpha: 0.08),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));

    final tp2 = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(
          fontSize: size.height * 0.62,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = Colors.grey.withValues(alpha: 0.15),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset((size.width - tp2.width) / 2, (size.height - tp2.height) / 2));
  }

  void _drawGuideArrows(Canvas canvas, Size size) {
    // Draw numbered start/direction dots at key positions for the character
    final positions = _getStartDots(character, size);
    for (int i = 0; i < positions.length; i++) {
      final pos = positions[i];
      // Outer ring
      canvas.drawCircle(
        pos,
        14,
        Paint()..color = Colors.orange.withValues(alpha: 0.25),
      );
      // Inner dot
      canvas.drawCircle(
        pos,
        9,
        Paint()..color = Colors.orange.withValues(alpha: 0.55),
      );
      // Number label
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  List<Offset> _getStartDots(String c, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final h = size.height;
    final w = size.width;
    switch (c) {
      case 'A': return [Offset(cx - w * 0.12, cy - h * 0.3), Offset(cx + w * 0.12, cy - h * 0.3)];
      case 'B': return [Offset(cx - w * 0.1, cy - h * 0.3)];
      case 'C': return [Offset(cx + w * 0.1, cy - h * 0.28)];
      case 'D': return [Offset(cx - w * 0.1, cy - h * 0.3)];
      case 'E': return [Offset(cx - w * 0.1, cy - h * 0.3), Offset(cx - w * 0.1, cy + h * 0.3)];
      case 'F': return [Offset(cx - w * 0.1, cy - h * 0.3)];
      case 'G': return [Offset(cx + w * 0.1, cy - h * 0.28)];
      case 'H': return [Offset(cx - w * 0.15, cy - h * 0.3), Offset(cx + w * 0.15, cy - h * 0.3)];
      case 'I': return [Offset(cx, cy - h * 0.3)];
      case 'J': return [Offset(cx + w * 0.1, cy - h * 0.3)];
      case 'K': return [Offset(cx - w * 0.12, cy - h * 0.3)];
      case 'L': return [Offset(cx - w * 0.1, cy - h * 0.3)];
      case 'M': return [Offset(cx - w * 0.15, cy - h * 0.3), Offset(cx + w * 0.15, cy - h * 0.3)];
      case 'N': return [Offset(cx - w * 0.12, cy - h * 0.3), Offset(cx + w * 0.12, cy - h * 0.3)];
      case 'O': return [Offset(cx, cy - h * 0.3)];
      case 'P': return [Offset(cx - w * 0.1, cy - h * 0.3)];
      case 'Q': return [Offset(cx, cy - h * 0.3)];
      case 'R': return [Offset(cx - w * 0.1, cy - h * 0.3)];
      case 'S': return [Offset(cx + w * 0.1, cy - h * 0.25)];
      case 'T': return [Offset(cx - w * 0.18, cy - h * 0.3), Offset(cx, cy - h * 0.3)];
      case 'U': return [Offset(cx - w * 0.12, cy - h * 0.3), Offset(cx + w * 0.12, cy - h * 0.3)];
      case 'V': return [Offset(cx - w * 0.15, cy - h * 0.3), Offset(cx + w * 0.15, cy - h * 0.3)];
      case 'W': return [Offset(cx - w * 0.18, cy - h * 0.3)];
      case 'X': return [Offset(cx - w * 0.15, cy - h * 0.3), Offset(cx + w * 0.15, cy - h * 0.3)];
      case 'Y': return [Offset(cx - w * 0.15, cy - h * 0.3), Offset(cx + w * 0.15, cy - h * 0.3)];
      case 'Z': return [Offset(cx - w * 0.14, cy - h * 0.3)];
      default:  return [Offset(cx, cy - h * 0.3)];
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color, double width, _DrawMode mode) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = mode == _DrawMode.eraser ? Colors.white : color
      ..strokeWidth = mode == _DrawMode.eraser ? width * 2.2 : width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = mode == _DrawMode.eraser ? BlendMode.clear : BlendMode.srcOver;

    if (points.length == 1) {
      canvas.drawCircle(points.first, width / 2, paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      if (i < points.length - 1) {
        final mid = Offset(
          (points[i].dx + points[i + 1].dx) / 2,
          (points[i].dy + points[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TracingPainter old) =>
      old.strokes != strokes ||
      old.currentPoints != currentPoints ||
      old.strokeColor != strokeColor ||
      old.brushSize != brushSize ||
      old.drawMode != drawMode;
}
