import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/star_display.dart';
import '../../widgets/buddy_mascot.dart';
import '../../services/sound_service.dart';
import '../quizzes/quizzes_screen.dart';
import '../storybooks/storybooks_screen.dart';
import '../worksheets/worksheets_screen.dart';
import '../tracing/tracing_screen.dart';
import '../drawing/drawing_studio_screen.dart';
import '../coloring/coloring_screen.dart';
import '../counting/counting_screen.dart';
import '../games/math_blast_screen.dart';
import '../games/memory_match_screen.dart';
import '../games/word_builder_screen.dart';

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
              _buildSectionTitle(context, provider.t('Quick Start', 'Mula Cepat'),
                  provider.t('Jump right in!', 'Terus mula!')),
              _buildQuickStartGrid(context, provider),
              _buildSectionTitle(
                  context,
                  provider.t('Creative Activities', 'Aktiviti Kreatif'),
                  provider.t('Draw, colour & create!', 'Lukis, warna & cipta!')),
              _buildCreativeActivities(context, provider),
              _buildSectionTitle(
                  context,
                  provider.t('Writing Practice', 'Latihan Menulis'),
                  provider.t('Trace letters & numbers!', 'Surih huruf & nombor!')),
              _buildTracingBanner(context, provider),
              _buildSectionTitle(context, provider.t("Today's Challenge", 'Cabaran Hari Ini'),
                  provider.t('Try something new!', 'Cuba sesuatu yang baru!')),
              _buildDailyChallenge(context, provider),
              _buildSectionTitle(context, provider.t('Recent Activity', 'Aktiviti Terkini'),
                  provider.t('Keep it up!', 'Teruskan!')),
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
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Row(
              children: [
                // Buddy mascot (original, animated, reacts)
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, _) => Transform.translate(
                    offset: Offset(0, _floatOffset.value * 0.5),
                    child: const BuddyMascot(
                      size: 72,
                      waving: true,
                      // Same reason as the splash: the header is that yellow.
                      antennaColor: Color(0xFF23348C),
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
                          'Hello, ${provider.userName}!',
                          style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        provider.t('Ready to learn today?', 'Sedia belajar hari ini?'),
                        style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                BouncyButton(
                  onTap: () => SoundService.instance.speakBilingual(
                    'Hello! Let\'s learn something fun today!',
                    'Hai! Mari belajar sesuatu yang seronok hari ini!',
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: StarDisplay(stars: provider.totalStars, color: Colors.white, size: 20),
                  ),
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
            _AnimatedStatCard(value: '${provider.quizzesCompleted}', label: provider.t('Quizzes', 'Kuiz'), gradient: AppColors.gradients[3]),
            const SizedBox(width: 10),
            _AnimatedStatCard(value: '${provider.storiesRead}', label: provider.t('Stories', 'Cerita'), gradient: AppColors.gradients[1]),
            const SizedBox(width: 10),
            _AnimatedStatCard(value: '${provider.worksheetsDone}', label: provider.t('Sheets', 'Lembaran'), gradient: AppColors.gradients[2]),
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
      _QuickItem(provider.t('Word Builder', 'Eja Perkataan'),
          provider.t('Spell b _ s = bus!', 'Eja b _ s = bas!'),
          AppColors.gradients[2], Icons.abc_rounded,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WordBuilderScreen()))),
      _QuickItem(provider.t('Math Blast', 'Kira Cepat'),
          provider.t('3 + 2 = ?', '3 + 2 = ?'),
          AppColors.gradients[5], Icons.calculate_rounded,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MathBlastScreen()))),
      _QuickItem(provider.t('Quizzes', 'Kuiz'),
          provider.t('Test yourself!', 'Uji diri anda!'),
          AppColors.gradients[3], Icons.psychology_rounded,
          () => _navigate(context, 2)),
      _QuickItem(provider.t('Memory Match', 'Padanan Memori'),
          provider.t('30 levels!', '30 tahap!'),
          AppColors.gradients[1], Icons.grid_view_rounded,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MemoryMatchScreen()))),
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
                    child: _QuickStartCard(item: entry.value),
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

  Widget _buildCreativeActivities(BuildContext context, AppProvider provider) {
    final activities = [
      _CreativeItem(
        title: provider.t('Drawing\nStudio', 'Studio\nLukisan'),
        subtitle: provider.t('Free draw!', 'Lukis bebas!'),
        gradient: AppColors.gradients[0],
        icon: Icons.brush_rounded,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DrawingStudioScreen())),
      ),
      _CreativeItem(
        title: provider.t('Coloring\nBook', 'Buku\nMewarna'),
        subtitle: provider.t('Tap to fill!', 'Tap untuk warna!'),
        gradient: AppColors.gradients[1],
        icon: Icons.palette_rounded,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ColoringScreen())),
      ),
      _CreativeItem(
        title: provider.t('Counting\nGame', 'Permainan\nMengira'),
        subtitle: provider.t('Count it!', 'Kira!'),
        gradient: AppColors.gradients[4],
        icon: Icons.confirmation_number_rounded,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CountingScreen())),
      ),
      _CreativeItem(
        title: provider.t('Work\nSheets', 'Lembaran\nKerja'),
        subtitle: provider.t('Practice!', 'Latihan!'),
        gradient: AppColors.gradients[5],
        icon: Icons.assignment_rounded,
        onTap: () => _navigateToWorksheets(context),
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

  Widget _buildTracingBanner(BuildContext context, AppProvider provider) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: BouncyButton(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TracingScreen())),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.t('Writing Practice', 'Latihan Menulis'),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                          provider.t('Trace A–Z and 0–9 with your finger',
                              'Surih A–Z dan 0–9 dengan jari anda'),
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
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
              color: const Color(0xFF667EEA),
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
                  child: Center(child: Icon(Icons.psychology_rounded, color: Colors.white, size: 34)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.t("Today's Quiz", 'Kuiz Hari Ini'),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(quiz.title,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Row(children: [
                        _badge(provider.t('5 Questions', '5 Soalan'), Colors.white24),
                        const SizedBox(width: 6),
                        if (quiz.highScore > 0)
                          _badge(provider.t('Best: ${quiz.highScore}', 'Terbaik: ${quiz.highScore}'), Colors.white24),
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
    final completedQuizzes = provider.quizzes.where((q) => q.isCompleted).take(2).toList();

    if (completedQuizzes.isEmpty) {
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
            child: Column(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 48, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(provider.t('No activity yet!', 'Belum ada aktiviti!'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(
                    provider.t('Start exploring to track your progress',
                        'Mula meneroka untuk menjejak kemajuan anda'),
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
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
            ...completedQuizzes.map((q) => _ActivityTile(
                  icon: Icons.psychology_rounded, title: q.title,
                  subtitle: provider.t('Best score: ${q.highScore}', 'Skor terbaik: ${q.highScore}'),
                  color: AppColors.indigo)),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => index == 2 ? const QuizzesScreen() : const StorybooksScreen(),
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
  final IconData icon;
  final VoidCallback onTap;
  _QuickItem(this.title, this.subtitle, this.gradient, this.icon, this.onTap);
}

class _CreativeItem {
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onTap;
  _CreativeItem({required this.title, required this.subtitle, required this.gradient, required this.icon, required this.onTap});
}

/// Cohesive icon chip: a Material icon on a soft tinted circle (no emoji).
class _IconGraphic extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _IconGraphic(this.icon, this.color, {this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 24,
      height: size + 24,
      decoration: BoxDecoration(
        color: AppColors.tintFor(color),
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(icon, color: color, size: size)),
    );
  }
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
          color: gradient[0].withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gradient[0].withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: gradient[0],
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

  const _QuickStartCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: item.gradient[0],
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
                  child: _IconGraphic(item.icon, item.gradient[0], size: 34),
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
          color: item.gradient[0],
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
                  child: _IconGraphic(item.icon, item.gradient[0], size: 30),
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
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityTile({required this.icon, required this.title, required this.subtitle, required this.color});

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
            decoration: BoxDecoration(color: AppColors.tintFor(color), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Icon(icon, color: color, size: 22)),
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
