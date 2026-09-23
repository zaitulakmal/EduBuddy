import 'package:flutter/material.dart';

/// A star total that counts up to its new value instead of snapping.
///
/// The count-up is the point: watching the number climb is what makes a
/// reward feel earned, where a number that simply changes reads as bookkeeping.
class AnimatedStarCount extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedStarCount({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.round()}', style: style),
    );
  }
}
