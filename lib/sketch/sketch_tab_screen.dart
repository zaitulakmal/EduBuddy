import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

import '../theme/app_theme.dart';
import '../widgets/header_back_button.dart';
import 'sketch_data.dart';
import 'sketch_gallery_screen.dart';
import 'sketch_lang.dart';
import 'sketch_lesson_screen.dart';
import 'sketch_store.dart';
import 'sketch_widgets.dart';

/// The "Draw" tab: pick a path, pick a lesson, or continue an unfinished drawing.
class SketchTabScreen extends StatefulWidget {
  const SketchTabScreen({super.key});

  @override
  State<SketchTabScreen> createState() => _SketchTabScreenState();
}

class _SketchTabScreenState extends State<SketchTabScreen> {
  final _lang = SketchLang.instance;
  SketchLibrary? _library;
  String _pathId = 'animals';
  Map<String, int> _stars = {};
  SketchDraft? _latestDraft;

  @override
  void initState() {
    super.initState();
    _lang.attach(context.read<AppProvider>());
    _lang.addListener(_onLang);
    SketchLibrary.load().then((lib) {
      if (mounted) setState(() => _library = lib);
    });
    _refresh();
  }

  @override
  void dispose() {
    _lang.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() => setState(() {});

  Future<void> _refresh() async {
    final stars = await SketchStore.instance.stars();
    final drafts = await SketchStore.instance.drafts();
    if (!mounted) return;
    setState(() {
      _stars = stars;
      _latestDraft = drafts.isEmpty ? null : drafts.first;
    });
  }

  Future<void> _open(SketchLesson lesson) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SketchLessonScreen(lesson: lesson)));
    _refresh();
  }

  Future<void> _openGallery() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SketchGalleryScreen()));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final lib = _library;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: lib == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header()),
                  if (_latestDraft != null && lib.lesson(_latestDraft!.lessonId) != null)
                    SliverToBoxAdapter(child: _continueCard(lib.lesson(_latestDraft!.lessonId)!, _latestDraft!)),
                  SliverToBoxAdapter(child: _pathChips(lib)),
                  _grid(lib),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _header() {
    final t = _lang.t;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF330D81), Color(0xFF7700FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HeaderBackButton(),
                  const Text('✏️', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(t('tab'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  _langSwitch(),
                ],
              ),
              const SizedBox(height: 6),
              Text(t('heading'), style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: _openGallery,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🖼️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(t('myDrawings'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langSwitch() {
    Widget option(String code, String label) {
      final on = _lang.value == code;
      return Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          onTap: () => _lang.set(code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(99)),
            child: Text(label,
                style: TextStyle(color: on ? const Color(0xFF330D81) : Colors.white70, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(border: Border.all(color: Colors.white30, width: 2), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [option('en', 'EN'), option('ms', 'BM')]),
    );
  }

  Widget _continueCard(SketchLesson lesson, SketchDraft draft) {
    final t = _lang.t;
    final lang = _lang.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _open(lesson),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: draft.imagePath != null && File(draft.imagePath!).existsSync()
                        ? Image.file(File(draft.imagePath!), fit: BoxFit.cover)
                        : SketchThumb(lesson: lesson, radius: 0),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('unfinished'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(lesson.title.of(lang), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      Text('${t('step')} ${draft.step + 1} ${t('of')} ${lesson.steps.length}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => _open(lesson),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7700FA), shape: const StadiumBorder()),
                  child: Text(t('continue'), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pathChips(SketchLibrary lib) {
    final lang = _lang.value;
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        children: [
          for (final p in lib.paths)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(p.title.of(lang)),
                selected: _pathId == p.id,
                onSelected: (_) => setState(() => _pathId = p.id),
                showCheckmark: false,
                labelStyle: TextStyle(fontWeight: FontWeight.w800, color: _pathId == p.id ? Colors.white : AppColors.textDark),
                selectedColor: const Color(0xFF7700FA),
                backgroundColor: Colors.white,
                side: BorderSide(color: _pathId == p.id ? const Color(0xFF7700FA) : Colors.black12),
                shape: const StadiumBorder(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _grid(SketchLibrary lib) {
    final t = _lang.t;
    final lang = _lang.value;
    final lessons = lib.paths.firstWhere((p) => p.id == _pathId).lessons;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          mainAxisSpacing: 16,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final l = lessons[i];
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _open(l),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SketchThumb(lesson: l),
                      const SizedBox(height: 8),
                      Text('${i + 1}. ${l.title.of(lang)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text('${t(l.role)}  ·  ${l.steps.length} ${t('steps')}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      SketchStars(count: _stars[l.id] ?? 0, size: 18),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: lessons.length,
        ),
      ),
    );
  }
}
