import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/star_display.dart';
import '../videos/videos_screen.dart';
import '../quizzes/quizzes_screen.dart';
import '../storybooks/storybooks_screen.dart';
import '../worksheets/worksheets_screen.dart';
import '../tracing/tracing_screen.dart';
import '../drawing/drawing_studio_screen.dart';
import '../coloring/coloring_screen.dart';
import '../counting/counting_screen.dart';
import '../games/memory_match_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnim;
  late AnimationController _floatAnim;
  late Animation<double> _floatOffset;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _floatAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _floatAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildHeader(context, provider),
              _buildStatsRow(context, provider),
              _buildSectionTitle(context, 'Quick Start', 'Jump right in!'),
              _buildQuickStartGrid(context, provider),
              _buildSectionTitle(context, 'Creative Activities', 'Draw, colour & create!'),
              _buildCreativeActivities(context),
              _buildSectionTitle(context, 'Writing Practice', 'Trace letters & numbers!'),
              _buildTracingBanner(context),
              _buildSectionTitle(context, "Today's Challenge", 'Try something new!'),
              _buildDailyChallenge(context, provider),
              _buildSectionTitle(context, 'Recent Activity', 'Keep it up!'),
              _buildRecentActivity(context, provider),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B35), Color(0xFFFF9F43)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Row(
              children: [
                // Animated avatar
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, _) => Transform.translate(
                    offset: Offset(0, _floatOffset.value * 0.5),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _AvatarPainter(provider.userAvatar),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _headerAnim,
                        child: Text(
                          'Hello, ${provider.userName}! 👋',
                          style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white,
                          ),
                        ),
                      ),
                      const Text(
                        'Ready to learn today?',
                        style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: StarDisplay(stars: provider.totalStars, color: AppColors.secondary, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(BuildContext context, AppProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          children: [
            _AnimatedStatCard(value: '${provider.videosWatched}', label: 'Videos', gradient: AppColors.gradients[5]),
            const SizedBox(width: 10),
            _AnimatedStatCard(value: '${provider.quizzesCompleted}', label: 'Quizzes', gradient: AppColors.gradients[3]),
            const SizedBox(width: 10),
            _AnimatedStatCard(value: '${provider.storiesRead}', label: 'Stories', gradient: AppColors.gradients[1]),
            const SizedBox(width: 10),
            _AnimatedStatCard(value: '${provider.worksheetsDone}', label: 'Sheets', gradient: AppColors.gradients[2]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, String subtitle) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Start grid ──────────────────────────────────────────────────────

  Widget _buildQuickStartGrid(BuildContext context, AppProvider provider) {
    final items = [
      _QuickItem('Videos', '${provider.videos.length} available', AppColors.gradients[5], const _EmojiGraphic('▶️'), () => _navigate(context, 1)),
      _QuickItem('Quizzes', '${provider.quizzes.length} quizzes', AppColors.gradients[3], const _EmojiGraphic('🧠'), () => _navigate(context, 2)),
      _QuickItem('Stories', '${provider.storybooks.length} books', AppColors.gradients[0], const _EmojiGraphic('📖'), () => _navigate(context, 3)),
      _QuickItem('Worksheets', '${provider.worksheets.length} sheets', AppColors.gradients[2], const _EmojiGraphic('📄'), () => _navigateToWorksheets(context)),
    ];

    return SliverToBoxAdapter(
      child: AnimationLimiter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            primary: false,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
            children: items.asMap().entries.map((entry) {
              return AnimationConfiguration.staggeredGrid(
                position: entry.key,
                columnCount: 2,
                duration: const Duration(milliseconds: 250),
                child: ScaleAnimation(
                  scale: 0.85,
                  child: FadeInAnimation(
                    child: _QuickStartCard(item: entry.value, floatAnim: _floatAnim),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Creative activities row ───────────────────────────────────────────────

  Widget _buildCreativeActivities(BuildContext context) {
    final activities = [
      _CreativeItem(
        title: 'Drawing\nStudio',
        subtitle: 'Free draw!',
        gradient: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
        graphic: _DrawingGraphic(),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DrawingStudioScreen())),
      ),
      _CreativeItem(
        title: 'Coloring\nBook',
        subtitle: 'Tap to fill!',
        gradient: [const Color(0xFFFF6B35), const Color(0xFFFF9F43)],
        graphic: _ColoringGraphic(),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ColoringScreen())),
      ),
      _CreativeItem(
        title: 'Counting\nGame',
        subtitle: 'Count it!',
        gradient: [const Color(0xFF7BC67E), const Color(0xFF4CAF50)],
        graphic: _CountingGraphic(),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CountingScreen())),
      ),
      _CreativeItem(
        title: 'Memory\nMatch',
        subtitle: 'Find pairs!',
        gradient: [const Color(0xFF7B6EC8), const Color(0xFF5B4DA8)],
        graphic: _MemoryGraphic(),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryMatchScreen())),
      ),
    ];

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemCount: activities.length,
          itemBuilder: (_, i) => _CreativeCard(item: activities[i], floatAnim: _floatAnim),
        ),
      ),
    );
  }

  // ── Tracing banner ────────────────────────────────────────────────────────

  Widget _buildTracingBanner(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: BouncyButton(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TracingScreen())),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A8B3)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: const Color(0xFF4ECDC4).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, _) => Transform.translate(
                    offset: Offset(0, _floatOffset.value * 0.4),
                    child: CustomPaint(
                      size: const Size(64, 64),
                      painter: _TracingBannerGraphic(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Writing Practice',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Trace A–Z and 0–9 with your finger',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.draw_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Daily challenge ───────────────────────────────────────────────────────

  Widget _buildDailyChallenge(BuildContext context, AppProvider provider) {
    if (provider.quizzes.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    final quiz = provider.quizzes.firstWhere((q) => !q.isCompleted, orElse: () => provider.quizzes.first);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: BouncyButton(
          onTap: () => _navigate(context, 2),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Text(quiz.emoji, style: const TextStyle(fontSize: 36))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Quiz",
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(quiz.title,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Row(children: [
                        _badge('5 Questions', Colors.white24),
                        const SizedBox(width: 6),
                        if (quiz.highScore > 0) _badge('Best: ${quiz.highScore}⭐', Colors.white24),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  // ── Recent activity ───────────────────────────────────────────────────────

  Widget _buildRecentActivity(BuildContext context, AppProvider provider) {
    final watchedVideos = provider.videos.where((v) => v.isWatched).take(3).toList();
    final completedQuizzes = provider.quizzes.where((q) => q.isCompleted).take(2).toList();

    if (watchedVideos.isEmpty && completedQuizzes.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Column(
              children: [
                Text('🌟', style: TextStyle(fontSize: 48)),
                SizedBox(height: 8),
                Text('No activity yet!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                SizedBox(height: 4),
                Text('Start exploring to track your progress',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            ...watchedVideos.map((v) => _ActivityTile(
                  emoji: v.thumbnailEmoji, title: v.title,
                  subtitle: 'Video watched', color: AppColors.blue)),
            ...completedQuizzes.map((q) => _ActivityTile(
                  emoji: q.emoji, title: q.title,
                  subtitle: 'Best score: ${q.highScore} ⭐', color: AppColors.purple)),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => index == 1 ? const VideosScreen() : index == 2 ? const QuizzesScreen() : const StorybooksScreen(),
    ));
  }

  void _navigateToWorksheets(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorksheetsScreen()));
  }
}

// ─── Data models ─────────────────────────────────────────────────────────────

class _QuickItem {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Widget graphic;
  final VoidCallback onTap;
  _QuickItem(this.title, this.subtitle, this.gradient, this.graphic, this.onTap);
}

class _CreativeItem {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Widget graphic;
  final VoidCallback onTap;
  _CreativeItem({required this.title, required this.subtitle, required this.gradient, required this.graphic, required this.onTap});
}

// ─── Animated stat card ───────────────────────────────────────────────────────

class _AnimatedStatCard extends StatelessWidget {
  final String value;
  final String label;
  final List<Color> gradient;

  const _AnimatedStatCard({required this.value, required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradient[0].withValues(alpha: 0.15), gradient[1].withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gradient[0].withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: gradient[0])),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Start card ─────────────────────────────────────────────────────────

class _QuickStartCard extends StatelessWidget {
  final _QuickItem item;
  final AnimationController floatAnim;

  const _QuickStartCard({required this.item, required this.floatAnim});

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: item.gradient),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: item.gradient[0].withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: floatAnim,
                    builder: (_, _) => Transform.translate(
                      offset: Offset(0, floatAnim.value * 3 - 3),
                      child: SizedBox(width: 72, height: 72, child: item.graphic),
                    ),
                  ),
                ),
              ),
              Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(item.subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Creative card ────────────────────────────────────────────────────────────

class _CreativeCard extends StatelessWidget {
  final _CreativeItem item;
  final AnimationController floatAnim;

  const _CreativeCard({required this.item, required this.floatAnim});

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: item.onTap,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: item.gradient),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: item.gradient[0].withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: floatAnim,
                builder: (_, _) => Transform.translate(
                  offset: Offset(0, floatAnim.value * 2.5 - 2.5),
                  child: SizedBox(width: 56, height: 56, child: item.graphic),
                ),
              ),
              const Spacer(),
              Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
              const SizedBox(height: 2),
              Text(item.subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Activity tile ────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityTile({required this.emoji, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Custom Painter Graphics
// ═══════════════════════════════════════════════════════════════════════════════

// Avatar painter — draws a round smiley with the emoji
class _AvatarPainter extends CustomPainter {
  final String emoji;
  _AvatarPainter(this.emoji);

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: size.shortestSide * 0.55)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.emoji != emoji;
}

// Simple emoji graphic — used for Quick Start cards (Videos, Quizzes, Stories, Worksheets)
class _EmojiGraphic extends StatelessWidget {
  final String emoji;
  const _EmojiGraphic(this.emoji);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(emoji, style: const TextStyle(fontSize: 44)),
    );
  }
}

// Drawing Studio graphic — palette
class _DrawingGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DrawingIconPainter());
  }
}

class _DrawingIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = size.shortestSide * 0.42;
    // Palette body
    final palettePath = Path();
    palettePath.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    palettePath.addOval(Rect.fromCircle(center: Offset(cx + r * 0.3, cy + r * 0.3), radius: r * 0.35));
    palettePath.fillType = PathFillType.evenOdd;
    canvas.drawPath(palettePath, Paint()..color = Colors.white);
    // Color dots on palette
    final dots = [
      (Offset(cx - r * 0.38, cy - r * 0.2), const Color(0xFFFF5252)),
      (Offset(cx, cy - r * 0.55), const Color(0xFFFFD740)),
      (Offset(cx + r * 0.38, cy - r * 0.2), const Color(0xFF69F0AE)),
      (Offset(cx + r * 0.25, cy + r * 0.35), const Color(0xFF40C4FF)),
      (Offset(cx - r * 0.35, cy + r * 0.35), const Color(0xFFFF80AB)),
    ];
    for (final d in dots) {
      canvas.drawCircle(d.$1, r * 0.16, Paint()..color = d.$2);
    }
  }

  @override
  bool shouldRepaint(_DrawingIconPainter _) => false;
}

// Coloring graphic — crayon
class _ColoringGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ColoringIconPainter());
  }
}

class _ColoringIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final h = size.height, w = size.width;

    // Crayon body
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - h * 0.05), width: w * 0.3, height: h * 0.7),
      const Radius.circular(8),
    );
    canvas.drawRRect(body, Paint()..color = Colors.white);

    // Crayon label band
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + h * 0.08), width: w * 0.3, height: h * 0.18),
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );

    // Crayon tip
    final tip = Path()
      ..moveTo(cx - w * 0.15, cy + h * 0.31)
      ..lineTo(cx + w * 0.15, cy + h * 0.31)
      ..lineTo(cx, cy + h * 0.48)
      ..close();
    canvas.drawPath(tip, Paint()..color = Colors.white.withValues(alpha: 0.75));

    // Stars burst around
    for (int i = 0; i < 4; i++) {
      const pi = 3.141592653589793;
      final angle = i * pi / 2 + pi / 4;
      final dx = cx + w * 0.4 * _cosImpl(angle);
      final dy = cy + h * 0.4 * _sinImpl(angle);
      final sp = Paint()..color = Colors.white.withValues(alpha: 0.6);
      canvas.drawCircle(Offset(dx, dy), w * 0.05, sp);
    }
  }

  double _cosImpl(double a) {
    const pi = 3.141592653589793;
    a = a % (2 * pi); if (a < 0) a += 2 * pi;
    if (a < pi / 2) return _ct(a);
    if (a < pi) return -_ct(pi - a);
    if (a < 3 * pi / 2) return -_ct(a - pi);
    return _ct(2 * pi - a);
  }
  double _sinImpl(double a) => _cosImpl(a - 3.141592653589793 / 2);
  double _ct(double x) { final x2 = x * x; return 1 - x2/2 + x2*x2/24 - x2*x2*x2/720; }

  @override
  bool shouldRepaint(_ColoringIconPainter _) => false;
}

// Memory Match graphic — two flipped cards
class _MemoryGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MemoryIconPainter());
  }
}

class _MemoryIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cardW = w * 0.42, cardH = h * 0.62;

    // Back card (left, tilted)
    canvas.save();
    canvas.translate(w * 0.36, h * 0.52);
    canvas.rotate(-0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: cardW, height: cardH), const Radius.circular(8)),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.restore();

    // Front card (right, tilted, with star)
    canvas.save();
    canvas.translate(w * 0.62, h * 0.48);
    canvas.rotate(0.14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: cardW, height: cardH), const Radius.circular(8)),
      Paint()..color = Colors.white,
    );
    final tp = TextPainter(
      text: TextSpan(text: '★', style: TextStyle(fontSize: cardH * 0.42, color: const Color(0xFF7B6EC8).withValues(alpha: 0.7))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MemoryIconPainter _) => false;
}

// Counting graphic — floating stars
class _CountingGraphic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CountingIconPainter());
  }
}

class _CountingIconPainter extends CustomPainter {
  static const _pi = 3.141592653589793;
  static const _positions = [
    (0.5, 0.22, 0.28), (0.18, 0.55, 0.2), (0.82, 0.55, 0.2),
    (0.32, 0.82, 0.18), (0.68, 0.82, 0.18),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (px, py, pr) in _positions) {
      final center = Offset(size.width * px, size.height * py);
      final r = size.shortestSide * pr;
      _drawStar(canvas, center, r, Colors.white);
    }
    // Number "5"
    final tp = TextPainter(
      text: TextSpan(text: '5', style: TextStyle(fontSize: size.height * 0.28, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.4))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width * 0.38, size.height * 0.36));
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    const n = 5;
    final inner = r * 0.42;
    for (int i = 0; i < n * 2; i++) {
      final angle = i * _pi / n - _pi / 2;
      final rad = i.isEven ? r : inner;
      final x = center.dx + rad * _cosImpl(angle);
      final y = center.dy + rad * _sinImpl(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  double _cosImpl(double a) {
    a = a % (2 * _pi); if (a < 0) a += 2 * _pi;
    if (a < _pi / 2) return _ct(a);
    if (a < _pi) return -_ct(_pi - a);
    if (a < 3 * _pi / 2) return -_ct(a - _pi);
    return _ct(2 * _pi - a);
  }
  double _sinImpl(double a) => _cosImpl(a - _pi / 2);
  double _ct(double x) { final x2 = x * x; return 1 - x2/2 + x2*x2/24 - x2*x2*x2/720; }

  @override
  bool shouldRepaint(_CountingIconPainter _) => false;
}

// Tracing banner graphic — stylised pencil + letter A
class _TracingBannerGraphic extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final w = size.width, h = size.height;

    // Pencil
    final body = Path()
      ..moveTo(cx - w * 0.28, cy - h * 0.42)
      ..lineTo(cx + w * 0.28, cy - h * 0.42)
      ..lineTo(cx + w * 0.28, cy + h * 0.28)
      ..lineTo(cx - w * 0.28, cy + h * 0.28)
      ..close();
    canvas.drawPath(body, Paint()..color = Colors.white.withValues(alpha: 0.3));
    final tip = Path()
      ..moveTo(cx - w * 0.28, cy + h * 0.28)
      ..lineTo(cx + w * 0.28, cy + h * 0.28)
      ..lineTo(cx, cy + h * 0.48)
      ..close();
    canvas.drawPath(tip, Paint()..color = Colors.white.withValues(alpha: 0.55));

    // Big letter on canvas
    final tp = TextPainter(
      text: TextSpan(text: 'A', style: TextStyle(fontSize: h * 0.52, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.9))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2 - h * 0.06));
  }

  @override
  bool shouldRepaint(_TracingBannerGraphic _) => false;
}
