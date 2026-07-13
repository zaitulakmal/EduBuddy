import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/quiz_model.dart';
import '../../models/category_model.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/header_back_button.dart';
import 'quiz_play_screen.dart';

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  int? _selectedCategoryId; // null = show all

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final catMap = {for (final c in provider.categories) c.id: c};

        // Group quizzes by category
        final Map<int, List<QuizModel>> grouped = {};
        for (final quiz in provider.quizzes) {
          if (_selectedCategoryId != null &&
              quiz.categoryId != _selectedCategoryId) { continue; }
          grouped.putIfAbsent(quiz.categoryId, () => []).add(quiz);
        }

        final completed =
            provider.quizzes.where((q) => q.isCompleted).length;
        final total = provider.quizzes.length;
        final percent = total == 0 ? 0.0 : completed / total;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              _buildProgress(completed, total, percent),
              _buildCategoryFilter(provider, catMap),
              _buildGroupedList(context, provider, grouped, catMap),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Row(
              children: [
                const HeaderBackButton(),
                const Text('🧩', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.watch<AppProvider>().t('Quizzes', 'Kuiz'),
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text(
                        context
                            .watch<AppProvider>()
                            .t('Test Your Knowledge!', 'Uji Pengetahuan Anda!'),
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(int completed, int total, double percent) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📊 Your Progress',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  Text('$completed / $total',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.purple)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade100,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.purple),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                completed == total && total > 0
                    ? '🎉 Amazing! You completed all quizzes!'
                    : '⭐ Keep going! You\'re doing great!',
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(
      AppProvider provider, Map<int?, CategoryModel> catMap) {
    // Only show categories that have at least one quiz
    final quizCatIds = provider.quizzes.map((q) => q.categoryId).toSet();
    final filterCats = provider.categories
        .where((c) => quizCatIds.contains(c.id))
        .toList();

    if (filterCats.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by topic',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    icon: '🧩',
                    selected: _selectedCategoryId == null,
                    onTap: () =>
                        setState(() => _selectedCategoryId = null),
                    color: AppColors.purple,
                  ),
                  ...filterCats.map((cat) => _FilterChip(
                        label: cat.name,
                        icon: cat.icon,
                        selected: _selectedCategoryId == cat.id,
                        onTap: () =>
                            setState(() => _selectedCategoryId = cat.id),
                        color: cat.color,
                      )),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    AppProvider provider,
    Map<int, List<QuizModel>> grouped,
    Map<int?, CategoryModel> catMap,
  ) {
    if (grouped.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text('No quizzes found!',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
          ),
        ),
      );
    }

    // Build a flat list of items: each is a header widget or a card widget
    final rows = <Widget>[];
    int cardIndex = 0;

    grouped.forEach((catId, quizzes) {
      final cat = catMap[catId];
      rows.add(_SectionHeader(category: cat, count: quizzes.length));
      for (final quiz in quizzes) {
        rows.add(_QuizCard(
          quiz: quiz,
          index: cardIndex++,
          onTap: () => _startQuiz(context, provider, quiz),
        ));
      }
      rows.add(const SizedBox(height: 4));
    });

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => rows[i],
          childCount: rows.length,
        ),
      ),
    );
  }

  void _startQuiz(
      BuildContext context, AppProvider provider, QuizModel quiz) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizPlayScreen(quiz: quiz, provider: provider),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.grey.shade200, width: 1.5),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textDark)),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final CategoryModel? category;
  final int count;

  const _SectionHeader({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    final name = category?.name ?? 'General';
    final icon = category?.icon ?? '🎯';
    final color = category?.color ?? AppColors.purple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count quiz${count == 1 ? '' : 'zes'}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Quiz card ─────────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final int index;
  final VoidCallback onTap;

  const _QuizCard(
      {required this.quiz, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.gradients[index % AppColors.gradients.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncyButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              // Emoji icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: gradient[0].withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Center(
                    child: Text(quiz.emoji,
                        style: const TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 14),
              // Title + tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _tag(
                            quiz.ageGroup == 'preschool'
                                ? '🧒 Pre-K'
                                : quiz.ageGroup == 'primary'
                                    ? '📚 Primary'
                                    : '👨‍👩‍👧 All Ages',
                            AppColors.teal),
                        if (quiz.isCompleted) ...[
                          const SizedBox(width: 6),
                          _tag('✅ Done', AppColors.success),
                        ],
                      ],
                    ),
                    if (quiz.highScore > 0) ...[
                      const SizedBox(height: 4),
                      Text('⭐ Best: ${quiz.highScore} stars',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary
                                  .withValues(alpha: 0.9),
                              fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
              // Play button
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  quiz.isCompleted
                      ? Icons.replay_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
