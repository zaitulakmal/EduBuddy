import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/progression.dart';
import '../../providers/app_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/header_back_button.dart';

/// The weekly summary for whoever installed the app.
///
/// Parents decide whether an app stays on the phone, so this is the retention
/// lever aimed at them rather than at the child: it shows what the week
/// actually contained instead of asking them to take it on trust.
class ParentReportScreen extends StatefulWidget {
  const ParentReportScreen({super.key});

  @override
  State<ParentReportScreen> createState() => _ParentReportScreenState();
}

class _ParentReportScreenState extends State<ParentReportScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: provider.themeSkin.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
              child: Row(
                children: [
                  const HeaderBackButton(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.t('For Parents', 'Untuk Ibu Bapa'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _unlocked
                  ? _Report(provider: provider)
                  : _ParentGate(
                      provider: provider,
                      onPass: () => setState(() => _unlocked = true),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small multiplication a young child is unlikely to solve, which is the
/// conventional way to keep a parents-only area out of a child's hands without
/// asking anyone to make an account.
class _ParentGate extends StatefulWidget {
  final AppProvider provider;
  final VoidCallback onPass;

  const _ParentGate({required this.provider, required this.onPass});

  @override
  State<_ParentGate> createState() => _ParentGateState();
}

class _ParentGateState extends State<_ParentGate> {
  late int _a;
  late int _b;
  late List<int> _options;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    final rand = Random();
    _a = 7 + rand.nextInt(6); // 7..12
    _b = 6 + rand.nextInt(7); // 6..12
    final answer = _a * _b;
    final opts = <int>{answer};
    while (opts.length < 4) {
      final delta = 1 + rand.nextInt(14);
      opts.add(rand.nextBool() ? answer + delta : max(1, answer - delta));
    }
    _options = opts.toList()..shuffle(rand);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.provider.t;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              t('Grown-ups only', 'Untuk orang dewasa sahaja'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t('What is $_a × $_b?', 'Berapakah $_a × $_b?'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final option in _options)
                  BouncyButton(
                    onTap: () {
                      if (option == _a * _b) {
                        widget.onPass();
                      } else {
                        setState(() {
                          _wrong = true;
                          _newQuestion();
                        });
                      }
                    },
                    child: Container(
                      width: 76,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$option',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_wrong) ...[
              const SizedBox(height: 16),
              Text(
                t('Not quite — here is another one.',
                    'Kurang tepat — ini satu lagi.'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Report extends StatelessWidget {
  final AppProvider provider;
  const _Report({required this.provider});

  static const _kindLabels = <String, (String, String, String)>{
    'quiz': ('🧠', 'Quizzes', 'Kuiz'),
    'story': ('📚', 'Stories', 'Cerita'),
    'worksheet': ('📝', 'Worksheets', 'Lembaran'),
    'math': ('➕', 'Math Blast', 'Math Blast'),
    'word': ('🔤', 'Word Builder', 'Bina Perkataan'),
    'memory': ('🃏', 'Memory Match', 'Padanan Ingatan'),
    'reader': ('🔤', 'Buddy Reader', 'Buddy Membaca'),
    'sentence': ('💬', 'Sentences', 'Bina Ayat'),
    'count': ('🔢', 'Counting', 'Mengira'),
    'coloring': ('🎨', 'Colouring', 'Mewarna'),
    'drawing': ('🖌️', 'Drawing', 'Melukis'),
    'tracing': ('✏️', 'Tracing', 'Menyurih'),
    'daily': ('🎯', 'Daily challenges', 'Cabaran harian'),
  };

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    return FutureBuilder<List<DayReport>>(
      future: provider.weeklyReport(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final week = snapshot.data!;
        final totalActivities = week.fold<int>(0, (a, d) => a + d.total);
        final totalStars = week.fold<int>(0, (a, d) => a + d.stars);
        final activeDays = week.where((d) => d.active).length;

        final byKind = <String, int>{};
        for (final day in week) {
          day.counts.forEach((k, v) => byKind[k] = (byKind[k] ?? 0) + v);
        }
        final ranked = byKind.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              t('This week', 'Minggu ini'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatBox(
                  value: '$totalActivities',
                  label: t('activities', 'aktiviti'),
                ),
                const SizedBox(width: 10),
                _StatBox(
                  value: '$activeDays/7',
                  label: t('days active', 'hari aktif'),
                ),
                const SizedBox(width: 10),
                _StatBox(
                  value: '$totalStars',
                  label: t('stars earned', 'bintang'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _WeekChart(week: week, provider: provider),
            const SizedBox(height: 24),
            Text(
              t('What they spent time on', 'Apa yang dibuat'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            if (ranked.isEmpty)
              Text(
                t('Nothing yet this week.', 'Belum ada apa-apa minggu ini.'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            for (final entry in ranked)
              _KindRow(
                entry: entry,
                total: totalActivities,
                provider: provider,
                label: _kindLabels[entry.key],
              ),
            const SizedBox(height: 24),
            _StreakCard(provider: provider),
            const SizedBox(height: 14),
            _ReminderCard(provider: provider),
          ],
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final List<DayReport> week;
  final AppProvider provider;
  const _WeekChart({required this.week, required this.provider});

  static const _en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _ms = ['Isn', 'Sel', 'Rab', 'Kha', 'Jum', 'Sab', 'Ahd'];

  @override
  Widget build(BuildContext context) {
    final peak = week.fold<int>(1, (a, d) => d.total > a ? d.total : a);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final day in week)
            Builder(builder: (context) {
              final weekday = DateTime.parse(day.day).weekday; // 1 = Monday
              final names = provider.selectedLanguage == 'ms' ? _ms : _en;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.total}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: day.active
                          ? AppColors.textDark
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 22,
                    height: 8 + (day.total / peak) * 76,
                    decoration: BoxDecoration(
                      color: day.active
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    names[weekday - 1],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _KindRow extends StatelessWidget {
  final MapEntry<String, int> entry;
  final int total;
  final AppProvider provider;
  final (String, String, String)? label;

  const _KindRow({
    required this.entry,
    required this.total,
    required this.provider,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final name = label == null
        ? entry.key
        : provider.t(label!.$2, label!.$3);
    final fraction = total == 0 ? 0.0 : entry.value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label?.$1 ?? '•', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          SizedBox(
            width: 108,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.teal),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${entry.value}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final AppProvider provider;
  const _StreakCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final t = provider.t;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('${provider.streakDays} day streak',
                      'Streak ${provider.streakDays} hari'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  t('Best ever: ${provider.bestStreak} days',
                      'Rekod terbaik: ${provider.bestStreak} hari'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The daily reminder control.
///
/// It lives behind the parent gate on purpose: a reminder is a decision for
/// whoever owns the phone, not something a child should be able to switch on
/// for themselves.
class _ReminderCard extends StatefulWidget {
  final AppProvider provider;
  const _ReminderCard({required this.provider});

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  bool _enabled = false;
  int _hour = NotificationService.defaultHour;
  int _minute = NotificationService.defaultMinute;
  bool _loading = true;
  bool _denied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = NotificationService.instance;
    final enabled = await service.isEnabled();
    final (hour, minute) = await service.reminderTime();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _hour = hour;
      _minute = minute;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    final on = await NotificationService.instance
        .setEnabled(value, hour: _hour, minute: _minute);
    if (!mounted) return;
    setState(() {
      _enabled = on;
      // Asked for but refused: say so, rather than showing a switch that is
      // on while nothing would ever arrive.
      _denied = value && !on;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
    if (_enabled) {
      await NotificationService.instance
          .setEnabled(true, hour: _hour, minute: _minute);
    }
  }

  String get _timeLabel =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = widget.provider.t;
    if (_loading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🔔', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('Daily reminder', 'Peringatan harian'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      t('One gentle nudge a day. Off by default.',
                          'Satu peringatan lembut sehari. Mati secara lalai.'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                onChanged: _toggle,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          if (_enabled) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t('Reminder time', 'Masa peringatan'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                BouncyButton(
                  onTap: _pickTime,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _timeLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_denied) ...[
            const SizedBox(height: 10),
            Text(
              t('Notifications are turned off for EduBuddy in your phone settings.',
                  'Notifikasi EduBuddy dimatikan dalam tetapan telefon anda.'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
