import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/buddy_mascot.dart';
import '../../widgets/header_back_button.dart';
import '../coloring/coloring_screen.dart';
import '../counting/counting_screen.dart';
import '../drawing/drawing_studio_screen.dart';
import '../games/math_blast_screen.dart';
import '../games/memory_match_screen.dart';
import '../games/word_builder_screen.dart';
import '../quizzes/quizzes_screen.dart';
import '../storybooks/storybooks_screen.dart';
import '../tracing/tracing_screen.dart';
import '../worksheets/worksheets_screen.dart';

/// One step on the journey.
class _Stop {
  final String kind;
  final String emoji;
  final String en;
  final String ms;

  const _Stop(this.kind, this.emoji, this.en, this.ms);
}

/// The rotation the path is built from. Mixing the activity types means the
/// path pulls a child through the whole app rather than letting them stay in
/// the one corner they already like.
const List<_Stop> _rotation = [
  _Stop('quiz', '🧠', 'Quiz', 'Kuiz'),
  _Stop('math', '➕', 'Math Blast', 'Math Blast'),
  _Stop('story', '📚', 'Story', 'Cerita'),
  _Stop('coloring', '🎨', 'Colouring', 'Mewarna'),
  _Stop('word', '🔤', 'Word Builder', 'Bina Perkataan'),
  _Stop('worksheet', '📝', 'Worksheet', 'Lembaran'),
  _Stop('memory', '🃏', 'Memory Match', 'Padanan Ingatan'),
  _Stop('tracing', '✏️', 'Tracing', 'Menyurih'),
  _Stop('count', '🔢', 'Counting', 'Mengira'),
  _Stop('drawing', '🖌️', 'Drawing', 'Melukis'),
];

/// A winding path of stops, unlocked one at a time by finishing activities.
///
/// A flat grid of everything on offer tells a child what exists; a path tells
/// them what is *next*, and shows the one step they are standing on. That
/// single visible next step is what a home grid could never give.
class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  static const _stops = 30;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Everything the child has finished, whatever kind it was — so progress on
    // the path never depends on liking one particular activity.
    final done = provider.quizzesCompleted +
        provider.storiesRead +
        provider.worksheetsDone +
        provider.creativeDone +
        (provider.badgeProgress['game_levels'] ?? 0);

    return Scaffold(
      backgroundColor: provider.themeSkin.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(provider: provider, done: done, total: _stops),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                itemCount: _stops,
                itemBuilder: (context, i) {
                  final stop = _rotation[i % _rotation.length];
                  final state = done > i
                      ? _NodeState.done
                      : (done == i ? _NodeState.current : _NodeState.locked);
                  return _PathNode(
                    index: i,
                    stop: stop,
                    state: state,
                    provider: provider,
                    isLast: i == _stops - 1,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NodeState { done, current, locked }

class _Header extends StatelessWidget {
  final AppProvider provider;
  final int done;
  final int total;

  const _Header({
    required this.provider,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final capped = min(done, total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
      child: Row(
        children: [
          const HeaderBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.t('My Journey', 'Perjalanan Saya'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : capped / total,
                    minHeight: 8,
                    backgroundColor: AppColors.divider,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.t('$capped of $total stops',
                      '$capped daripada $total hentian'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _PathNode extends StatelessWidget {
  final int index;
  final _Stop stop;
  final _NodeState state;
  final AppProvider provider;
  final bool isLast;

  const _PathNode({
    required this.index,
    required this.stop,
    required this.state,
    required this.provider,
    required this.isLast,
  });

  /// Every fifth stop is a milestone, drawn larger so the path has landmarks
  /// rather than thirty identical circles.
  bool get _isMilestone => (index + 1) % 5 == 0;

  /// Winds the path left and right so it reads as a route rather than a list.
  double get _offset {
    const amplitude = 0.34;
    return sin(index * 0.9) * amplitude;
  }

  void _open(BuildContext context) {
    if (state == _NodeState.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(provider.t(
            'Finish the stop before this one first!',
            'Habiskan hentian sebelum ini dulu!',
          )),
        ),
      );
      return;
    }
    SoundService.instance.tap();
    final screen = switch (stop.kind) {
      'quiz' => const QuizzesScreen(),
      'story' => const StorybooksScreen(),
      'worksheet' => const WorksheetsScreen(),
      'math' => const MathBlastScreen(),
      'word' => const WordBuilderScreen(),
      'memory' => const MemoryMatchScreen(),
      'count' => const CountingScreen(),
      'coloring' => const ColoringScreen(),
      'drawing' => const DrawingStudioScreen(),
      'tracing' => const TracingScreen(),
      _ => const QuizzesScreen(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final size = _isMilestone ? 78.0 : 62.0;
    final locked = state == _NodeState.locked;
    final current = state == _NodeState.current;

    final Color fill = switch (state) {
      _NodeState.done => AppColors.success,
      _NodeState.current => AppColors.primary,
      _NodeState.locked => AppColors.divider,
    };

    return Align(
      alignment: Alignment(_offset, 0),
      child: Column(
        children: [
          if (current)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Column(
                children: [
                  BuddyMascot(
                    size: 46,
                    variant: buddyVariantFromId(provider.userAvatar),
                    hat: provider.buddyHat,
                    accessory: provider.buddyAccessory,
                    animation: BuddyAnim.hop,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      provider.t('YOU ARE HERE', 'KAU DI SINI'),
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          BouncyButton(
            onTap: () => _open(context),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: current ? AppColors.primaryDeep : Colors.transparent,
                  width: 4,
                ),
                boxShadow: locked
                    ? null
                    : [
                        BoxShadow(
                          color: fill.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Center(
                child: locked
                    ? const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 24)
                    : Text(
                        stop.emoji,
                        style: TextStyle(fontSize: _isMilestone ? 34 : 27),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.t(stop.en, stop.ms),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: locked ? AppColors.textMuted : AppColors.textDark,
            ),
          ),
          if (!isLast)
            Container(
              width: 4,
              height: 26,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: state == _NodeState.done
                    ? AppColors.success.withValues(alpha: 0.4)
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
