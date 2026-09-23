import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/worksheet_model.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/buddy_mascot.dart';
import '../../widgets/page_theme.dart';
import '../../widgets/reward_overlay.dart';

class WorksheetsScreen extends StatefulWidget {
  const WorksheetsScreen({super.key});

  @override
  State<WorksheetsScreen> createState() => _WorksheetsScreenState();
}

class _WorksheetsScreenState extends State<WorksheetsScreen> {
  /// Marks a worksheet done, then celebrates any badge it earned.
  Future<void> _markDone(
      BuildContext context, AppProvider provider, int id) async {
    try {
      await provider.markWorksheetDone(id);
    } catch (_) {
      return;
    }
    final badges = List.of(provider.newlyEarnedBadges);
    if (!mounted || badges.isEmpty) return;
    if (!context.mounted) return;
    await showRewardSheet(
      context,
      title: provider.t('New badge!', 'Lencana baharu!'),
      badges: badges,
      buddy: buddyVariantFromId(provider.userAvatar),
      hat: provider.buddyHat,
      accessory: provider.buddyAccessory,
    );
  }

  String _selectedGrade = 'All';

  final List<String> _grades = ['All', 'Pre-school', 'Year 1', 'Year 2', 'Year 3'];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final filtered = _selectedGrade == 'All'
            ? provider.worksheets
            : provider.worksheets
                .where((w) => w.grade == _selectedGrade)
                .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildFilter(),
              _buildStats(provider),
              _buildList(context, provider, filtered),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: FunkyHeader(
        palette: PagePalette.worksheets,
        title: 'Worksheets',
        subtitle: 'Practice & Learn!',
        onBack: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildFilter() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 56,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          itemCount: _grades.length,
          itemBuilder: (_, i) {
            final grade = _grades[i];
            final selected = _selectedGrade == grade;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BouncyButton(
                onTap: () => setState(() => _selectedGrade = grade),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [AppColors.primaryDeep, AppColors.secondary])
                        : null,
                    color: selected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    grade,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          selected ? Colors.white : AppColors.primaryDeep,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStats(AppProvider provider) {
    final done = provider.worksheets.where((w) => w.isCompleted).length;
    final total = provider.worksheets.length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryDeep.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primaryDeep.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.primaryDeep, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$done of $total worksheets completed',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : done / total,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.primaryDeep),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, AppProvider provider, List<WorksheetModel> worksheets) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: AnimationLimiter(
        child: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              return AnimationConfiguration.staggeredList(
                position: i,
                duration: const Duration(milliseconds: 350),
                child: SlideAnimation(
                  verticalOffset: 20,
                  child: FadeInAnimation(
                    child: _WorksheetCard(
                      worksheet: worksheets[i],
                      onMarkDone: () =>
                          _markDone(context, provider, worksheets[i].id!),
                    ),
                  ),
                ),
              );
            },
            childCount: worksheets.length,
          ),
        ),
      ),
    );
  }
}

class _WorksheetCard extends StatelessWidget {
  final WorksheetModel worksheet;
  final VoidCallback onMarkDone;

  const _WorksheetCard({
    required this.worksheet,
    required this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: worksheet.isCompleted
            ? Border.all(color: AppColors.success.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: worksheet.isCompleted
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.primaryDeep.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: worksheet.isCompleted
                  ? const Icon(Icons.check_rounded, color: AppColors.success, size: 28)
                  : Text(
                      worksheet.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worksheet.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: worksheet.isCompleted
                        ? AppColors.textMuted
                        : AppColors.textDark,
                    decoration: worksheet.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _tag(worksheet.subject, AppColors.primaryDeep),
                    const SizedBox(width: 6),
                    _tag(worksheet.grade, AppColors.blue),
                  ],
                ),
              ],
            ),
          ),
          if (!worksheet.isCompleted)
            BouncyButton(
              onTap: onMarkDone,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDeep, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 28),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
