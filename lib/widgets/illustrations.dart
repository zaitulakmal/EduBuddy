import 'package:flutter/material.dart';

/// Funky 2D-style vector decorations drawn in code (no external assets) so the
/// app reads as richly illustrated / "2D asset" flavoured while staying 100%
/// offline. Bold flat shapes, playful outlines, confetti dots, squiggles.

/// A scattered cluster of playful dots/stars — used as page background spice.
class FunkyScatter extends StatelessWidget {
  final List<Color> colors;
  final int count;
  final double size;

  const FunkyScatter({
    super.key,
    this.colors = const [Color(0xFFFFC93C), Color(0xFFFF6B35), Color(0xFF8A4FFF), Color(0xFF00C2A8)],
    this.count = 7,
    this.size = 320,
  });

  @override
  Widget build(BuildContext context) {
    final rnd = List.generate(count, (i) => (i * 37) % 100 / 100);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          final c = colors[i % colors.length];
          final left = (rnd[i] * size);
          final top = ((rnd[i] * 1.7) % 1) * size;
          final s = 10 + (i % 3) * 8.0;
          return Positioned(
            left: left,
            top: top,
            child: Opacity(
              opacity: 0.5,
              child: i % 2 == 0
                  ? _StarDot(size: s, color: c)
                  : Container(
                      width: s,
                      height: s,
                      decoration: BoxDecoration(
                        color: c,
                        shape: i % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: i % 3 == 0 ? null : BorderRadius.circular(4),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}

class _StarDot extends StatelessWidget {
  final double size;
  final Color color;
  const _StarDot({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Icon(Icons.star_rounded, color: color, size: size);
}

/// A bold outlined "speech bubble" callout used for question prompts.
class FunkyBubble extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color outline;
  final double radius;

  const FunkyBubble({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.outline = const Color(0xFF2B2440),
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: outline, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }
}

/// A chunky illustrated progress tracker: a row of Buddy-style dots that fill up.
class FunkyProgressDots extends StatelessWidget {
  final int total;
  final int current;
  final List<Color> colors;

  const FunkyProgressDots({
    super.key,
    required this.total,
    required this.current,
    this.colors = const [Color(0xFFFFC93C), Color(0xFFFF6B35), Color(0xFF8A4FFF), Color(0xFF00C2A8), Color(0xFFFF5DA2)],
  });

  /// Natural sizes, used whenever the dots comfortably fit.
  static const double _maxDot = 16;
  static const double _gap = 4;

  /// Floors: below these the dots stop shrinking and the row scrolls instead.
  static const double _minDot = 6;
  static const double _minGap = 1.5;

  /// A finished dot is this much wider than a pending one.
  static const double _doneRatio = 26 / 16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _maxDot,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Sized from the width actually available: a quiz with many
          // questions used to overrun this row and paint the debug stripes.
          // Budget for the worst case, every dot in its wider "done" state.
          var dot = _maxDot;
          var gap = _gap;
          if (total > 0 && constraints.maxWidth.isFinite) {
            final perDot = constraints.maxWidth / total;
            dot = (perDot - gap * 2) / _doneRatio;
            if (dot < _minDot) {
              // Tighten the spacing before shrinking the dots any further.
              gap = _minGap;
              dot = (perDot - gap * 2) / _doneRatio;
            }
            dot = dot.clamp(_minDot, _maxDot);
          }

          final rowWidth = total * (dot * _doneRatio + gap * 2);
          final overflows = constraints.maxWidth.isFinite &&
              rowWidth > constraints.maxWidth + 0.5;

          final row = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final done = i < current;
              final c = colors[i % colors.length];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: gap),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: done ? dot * _doneRatio : dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: done ? c : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(dot),
                    border: Border.all(
                      color: done ? Colors.black26 : Colors.transparent,
                      width: dot < 10 ? 1 : 1.5,
                    ),
                  ),
                ),
              );
            }),
          );

          // Past a certain question count no amount of shrinking fits, and a
          // scrollable row beats clipped dots or a debug-striped overflow.
          if (!overflows) return row;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: row,
          );
        },
      ),
    );
  }
}

/// A decorative squiggle / wave divider for funky section breaks.
class FunkySquiggle extends StatelessWidget {
  final Color color;
  final double height;
  const FunkySquiggle({super.key, this.color = const Color(0xFF8A4FFF), this.height = 14});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SquigglePainter(color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  final Color color;
  _SquigglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final mid = size.height / 2;
    path.moveTo(0, mid);
    for (double x = 0; x <= size.width; x += 20) {
      path.quadraticBezierTo(x + 10, mid - 8, x + 20, mid);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SquigglePainter old) => old.color != color;
}
