import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StarDisplay extends StatelessWidget {
  final int stars;
  final double size;
  final Color color;

  const StarDisplay({
    super.key,
    required this.stars,
    this.size = 18,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: color, size: size),
        const SizedBox(width: 2),
        Text(
          '$stars',
          style: TextStyle(
            fontSize: size - 2,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
