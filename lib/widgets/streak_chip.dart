import 'package:flutter/material.dart';

/// The daily streak, shown as a flame with the day count.
///
/// Sits in the Home header because a streak only works as a habit cue if it is
/// the first thing seen on opening the app.
class StreakChip extends StatefulWidget {
  final int days;

  /// Freezes banked. Shown as a small shield so a child understands they have
  /// a spare day, rather than discovering it only when it saves them.
  final int freezes;

  final VoidCallback? onTap;

  const StreakChip({
    super.key,
    required this.days,
    this.freezes = 0,
    this.onTap,
  });

  @override
  State<StreakChip> createState() => _StreakChipState();
}

class _StreakChipState extends State<StreakChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A streak of zero would be a cold, discouraging badge on a first open, so
    // the chip only appears once there is something to keep.
    if (widget.days < 1) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _flicker,
              builder: (_, child) => Transform.scale(
                scale: 1 + _flicker.value * 0.16,
                child: child,
              ),
              child: const Text('🔥', style: TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 5),
            Text(
              '${widget.days}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            if (widget.freezes > 0) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🛡️', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 2),
                    Text(
                      '${widget.freezes}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
