import 'package:flutter/material.dart';

import '../models/progression.dart';
import '../widgets/buddy_mascot.dart';
import '../widgets/score_monster.dart';

/// Debug-only gallery of every Buddy and score-monster option.
///
///   flutter run -t lib/debug/monster_gallery_main.dart
///
/// Not reachable from the real app; delete this file when no longer needed.
void main() => runApp(const MonsterGalleryApp());

class MonsterGalleryApp extends StatelessWidget {
  const MonsterGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF7C5CFF),
        scaffoldBackgroundColor: const Color(0xFFFCF7EC),
      ),
      home: const _GalleryScreen(),
    );
  }
}

class _GalleryScreen extends StatelessWidget {
  const _GalleryScreen();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monster Gallery'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Variants'),
              Tab(text: 'Reactions'),
              Tab(text: 'Styles'),
              Tab(text: 'Wearables'),
              Tab(text: 'Score monster'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Grid([
              for (final v in BuddyVariant.values)
                _Tile(v.name, BuddyMascot(variant: v, animation: BuddyAnim.bounce)),
            ]),
            _Grid([
              for (final e in BuddyExpression.values)
                _Tile(e.name, BuddyMascot(expression: e, animation: BuddyAnim.idle)),
              for (final m in BuddyMood.values)
                _Tile('mood: ${m.name}', BuddyMascot(mood: m, animation: BuddyAnim.idle)),
              for (final e in BuddyExpression.values)
                _Tile('zap ${e.name}',
                    BuddyMascot(variant: BuddyVariant.zap, expression: e, animation: BuddyAnim.idle)),
            ]),
            _Grid([
              for (final s in BuddyStyle.values)
                _Tile(s.name, BuddyMascot(variant: BuddyVariant.lumi, style: s, animation: BuddyAnim.hop)),
            ]),
            _Grid([
              for (final h in BuddyHat.values)
                _Tile('hat: ${h.name}', BuddyMascot(variant: BuddyVariant.pip, hat: h, animation: BuddyAnim.idle)),
              for (final a in BuddyAccessory.values)
                _Tile(a.name, BuddyMascot(variant: BuddyVariant.tako, accessory: a, animation: BuddyAnim.idle)),
            ]),
            _Grid([
              for (final c in ScoreMonsterColor.values)
                _Tile(c.name, ScoreMonster(size: 88, color: c)),
              for (final s in ScoreMonsterStyle.values)
                _Tile(s.name, ScoreMonster(size: 88, style: s)),
              for (final m in ScoreMonsterMood.values)
                _Tile(m.name, ScoreMonster(size: 88, mood: m)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Widget> children;
  const _Grid(this.children);

  @override
  Widget build(BuildContext context) {
    return GridView.extent(
      maxCrossAxisExtent: 130,
      padding: const EdgeInsets.all(12),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.8,
      children: children,
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final Widget child;
  const _Tile(this.label, this.child);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Center(child: child)),
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
