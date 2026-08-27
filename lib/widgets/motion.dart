import 'package:flutter/material.dart';

/// Entrance animation: springs the child in with a little overshoot + fade.
class BouncyIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;

  const BouncyIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 520),
  });

  @override
  State<BouncyIn> createState() => _BouncyInState();
}

class _BouncyInState extends State<BouncyIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// A card that gently wiggles to feel alive. Tap handler optional.
class WiggleCard extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final VoidCallback? onTap;

  const WiggleCard({
    super.key,
    required this.child,
    this.enabled = true,
    this.onTap,
  });

  @override
  State<WiggleCard> createState() => _WiggleCardState();
}

class _WiggleCardState extends State<WiggleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rot;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _rot = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Center(child: widget.child);
    if (!widget.enabled) return body;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _rot,
        builder: (_, child) => Transform.rotate(angle: _rot.value, child: child),
        child: body,
      ),
    );
  }
}

/// A soft glassy card with a frosted look for the funky/modern vibe.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradient;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient!,
              )
            : null,
        color: gradient == null ? Colors.white.withValues(alpha: 0.72) : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A decorative gradient blob (for funky backgrounds).
class GradientBlob extends StatelessWidget {
  final List<Color> colors;
  final double size;
  final double opacity;

  const GradientBlob({
    super.key,
    required this.colors,
    this.size = 200,
    this.opacity = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: colors),
          shape: BoxShape.circle,
        ),
        child: const SizedBox.shrink(),
      ),
    );
  }
}
