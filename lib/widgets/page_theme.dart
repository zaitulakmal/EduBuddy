import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'buddy_mascot.dart';

/// Per-page personality: each screen gets its OWN accent colour + its OWN
/// Buddy monster variant/animation, so the app feels funky and varied instead
/// of one flat colour everywhere. All stay cohesive (warm, playful).
class PagePalette {
  final Color accent;
  final Color accentDeep;
  final Color accentSoft;
  final List<Color> gradient; // for header blobs / hero
  final BuddyVariant buddy;
  final BuddyAnim anim;
  final String buddyName; // little voice line

  const PagePalette({
    required this.accent,
    required this.accentDeep,
    required this.accentSoft,
    required this.gradient,
    required this.buddy,
    required this.anim,
    required this.buddyName,
  });

  static const PagePalette home = PagePalette(
    accent: AppColors.primary,
    accentDeep: AppColors.primaryDeep,
    accentSoft: AppColors.primarySoft,
    gradient: [Color(0xFFFFC93C), Color(0xFFFF6B35)],
    buddy: BuddyVariant.buddy,
    anim: BuddyAnim.wave,
    buddyName: 'Buddy',
  );
  static const PagePalette profile = PagePalette(
    accent: Color(0xFF00C2A8),
    accentDeep: Color(0xFF0E9E8F),
    accentSoft: Color(0xFFDDF5F1),
    gradient: [Color(0xFF0E9E8F), Color(0xFF00C2A8)],
    buddy: BuddyVariant.coco,
    anim: BuddyAnim.bounce,
    buddyName: 'Coco',
  );
  static const PagePalette quizzes = PagePalette(
    accent: Color(0xFF5B6EF5),
    accentDeep: Color(0xFF3A4FCF),
    accentSoft: Color(0xFFE8EBFD),
    gradient: [Color(0xFF5B6EF5), Color(0xFF9B6BFF)],
    buddy: BuddyVariant.tako,
    anim: BuddyAnim.think,
    buddyName: 'Tako',
  );
  static const PagePalette quizPlay = PagePalette(
    accent: Color(0xFF5B6EF5),
    accentDeep: Color(0xFF3A4FCF),
    accentSoft: Color(0xFFE8EBFD),
    gradient: [Color(0xFF5B6EF5), Color(0xFF8A4FFF)],
    buddy: BuddyVariant.nova,
    anim: BuddyAnim.cheer,
    buddyName: 'Nova',
  );
  static const PagePalette storybooks = PagePalette(
    accent: Color(0xFF9B6BFF),
    accentDeep: Color(0xFF7A45E0),
    accentSoft: Color(0xFFF0E9FF),
    gradient: [Color(0xFF9B6BFF), Color(0xFFFF5DA2)],
    buddy: BuddyVariant.zuzu,
    anim: BuddyAnim.hop,
    buddyName: 'Zuzu',
  );
  static const PagePalette storyReader = PagePalette(
    accent: Color(0xFF9B6BFF),
    accentDeep: Color(0xFF7A45E0),
    accentSoft: Color(0xFFF0E9FF),
    gradient: [Color(0xFF9B6BFF), Color(0xFF8A4FFF)],
    buddy: BuddyVariant.zuzu,
    anim: BuddyAnim.idle,
    buddyName: 'Zuzu',
  );
  static const PagePalette wordBuilder = PagePalette(
    accent: Color(0xFF3FB36B),
    accentDeep: Color(0xFF2C8A4E),
    accentSoft: Color(0xFFE4F5EA),
    gradient: [Color(0xFF3FB36B), Color(0xFFA4E02A)],
    buddy: BuddyVariant.pip,
    anim: BuddyAnim.cheer,
    buddyName: 'Pip',
  );
  static const PagePalette mathBlast = PagePalette(
    accent: Color(0xFF00C2A8),
    accentDeep: Color(0xFF008F7E),
    accentSoft: Color(0xFFE2F4F1),
    gradient: [Color(0xFF00C2A8), Color(0xFFA4E02A)],
    buddy: BuddyVariant.bub,
    anim: BuddyAnim.bounce,
    buddyName: 'Bub',
  );
  static const PagePalette counting = PagePalette(
    accent: Color(0xFFA4E02A),
    accentDeep: Color(0xFF7CAB1C),
    accentSoft: Color(0xFFF2F8DA),
    gradient: [Color(0xFFA4E02A), Color(0xFF3FB36B)],
    buddy: BuddyVariant.pip,
    anim: BuddyAnim.hop,
    buddyName: 'Pip',
  );
  static const PagePalette tracing = PagePalette(
    accent: Color(0xFF3FA7F5),
    accentDeep: Color(0xFF2A7FCB),
    accentSoft: Color(0xFFE4F1FC),
    gradient: [Color(0xFF3FA7F5), Color(0xFF5B6EF5)],
    buddy: BuddyVariant.lumi,
    anim: BuddyAnim.think,
    buddyName: 'Lumi',
  );
  static const PagePalette drawing = PagePalette(
    accent: Color(0xFFFF6B35),
    accentDeep: Color(0xFFD2491C),
    accentSoft: Color(0xFFFFEDE3),
    gradient: [Color(0xFFFF6B35), Color(0xFFFFC93C)],
    buddy: BuddyVariant.tako,
    anim: BuddyAnim.cheer,
    buddyName: 'Tako',
  );
  static const PagePalette coloring = PagePalette(
    accent: Color(0xFFFF6B35),
    accentDeep: Color(0xFFD2491C),
    accentSoft: Color(0xFFFFEDE3),
    gradient: [Color(0xFFFF6B35), Color(0xFFFF5DA2)],
    buddy: BuddyVariant.tako,
    anim: BuddyAnim.spin,
    buddyName: 'Tako',
  );
  static const PagePalette worksheets = PagePalette(
    accent: Color(0xFF2BB3A3),
    accentDeep: Color(0xFF1C8A7E),
    accentSoft: Color(0xFFE2F4F1),
    gradient: [Color(0xFF2BB3A3), Color(0xFF3FA7F5)],
    buddy: BuddyVariant.bub,
    anim: BuddyAnim.wave,
    buddyName: 'Bub',
  );
  static const PagePalette memoryMatch = PagePalette(
    accent: Color(0xFF8A4FFF),
    accentDeep: Color(0xFF6A2FD6),
    accentSoft: Color(0xFFF0E9FF),
    gradient: [Color(0xFF8A4FFF), Color(0xFF5B6EF5)],
    buddy: BuddyVariant.nova,
    anim: BuddyAnim.spin,
    buddyName: 'Nova',
  );
}

/// A funky, colourful header used at the top of every page: gradient blobs +
/// the page's own Buddy monster + title. Replaces the plain Material AppBar.
class FunkyHeader extends StatelessWidget {
  final PagePalette palette;
  final String title;
  final String? subtitle;
  final List<Color>? overrideGradient;
  final double height;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool centerTitle;

  const FunkyHeader({
    super.key,
    required this.palette,
    required this.title,
    this.subtitle,
    this.overrideGradient,
    this.height = 150,
    this.onBack,
    this.trailing,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: palette.accent,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                  ),
                ),
              if (onBack != null) const SizedBox(width: 10),
              BuddyMascot(
                size: 60,
                variant: palette.buddy,
                animation: palette.anim,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
