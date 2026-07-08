import 'package:flutter/material.dart';

/// A circular translucent back button meant to sit on a coloured gradient
/// header (white icon on a semi-transparent white circle).
///
/// It renders nothing when there is no route to pop — so the same screen can
/// be used both as a bottom-nav tab (no back button) and as a pushed route
/// (back button appears automatically).
class HeaderBackButton extends StatelessWidget {
  const HeaderBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
