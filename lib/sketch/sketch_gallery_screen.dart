import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'share_image.dart';
import 'sketch_data.dart';
import 'sketch_lang.dart';
import 'sketch_lesson_screen.dart';
import 'sketch_store.dart';
import 'sketch_widgets.dart';

/// "My drawings": unfinished drawings to continue, then finished ones to keep or share.
class SketchGalleryScreen extends StatefulWidget {
  const SketchGalleryScreen({super.key});

  @override
  State<SketchGalleryScreen> createState() => _SketchGalleryScreenState();
}

class _SketchGalleryScreenState extends State<SketchGalleryScreen> {
  final _lang = SketchLang.instance;
  SketchLibrary? _library;
  List<SketchDraft> _drafts = [];
  List<SketchDrawing>? _drawings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lib = await SketchLibrary.load();
    final drafts = await SketchStore.instance.drafts();
    final drawings = await SketchStore.instance.drawings();
    if (!mounted) return;
    setState(() {
      _library = lib;
      _drafts = drafts;
      _drawings = drawings;
    });
  }

  Future<bool> _confirm() async {
    final t = _lang.t;
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            content: Text(t('deleteQ')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(t('cancel'))),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(t('delete')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _continue(SketchLesson lesson) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SketchLessonScreen(lesson: lesson)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = _lang.t;
    final lang = _lang.value;
    String date(DateTime d) => '${d.day}/${d.month}/${d.year}';
    final lib = _library;
    final drawings = _drawings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(t('myDrawings'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: lib == null || drawings == null
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty && drawings.isEmpty
              ? _empty(t)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    if (_drafts.isNotEmpty) ...[
                      _heading(t('unfinished')),
                      _grid([
                        for (final d in _drafts)
                          if (lib.lesson(d.lessonId) case final lesson?)
                            _Tile(
                              image: d.imagePath,
                              title: lesson.title.of(lang),
                              subtitle: '${t('step')} ${d.step + 1} ${t('of')} ${lesson.steps.length}',
                              dashed: true,
                              onTap: () => _continue(lesson),
                              actions: [
                                FilledButton(
                                  onPressed: () => _continue(lesson),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF7700FA),
                                    shape: const StadiumBorder(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Text(t('continue'), style: const TextStyle(fontWeight: FontWeight.w800)),
                                ),
                                IconButton(
                                  tooltip: t('delete'),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  onPressed: () async {
                                    if (!await _confirm()) return;
                                    await SketchStore.instance.deleteDraft(d.lessonId);
                                    _load();
                                  },
                                ),
                              ],
                            ),
                      ]),
                      const SizedBox(height: 24),
                    ],
                    if (drawings.isNotEmpty) ...[
                      if (_drafts.isNotEmpty) _heading(t('finished')),
                      _grid([
                        for (final d in drawings)
                          _Tile(
                            image: d.imagePath,
                            title: lib.lesson(d.lessonId)?.title.of(lang) ?? d.lessonId,
                            subtitle: '${date(d.createdAt)}, ${d.score}%',
                            stars: d.stars,
                            actions: [
                              Builder(
                                builder: (btn) => IconButton(
                                  tooltip: t('saveImage'),
                                  icon: const Icon(Icons.ios_share_rounded),
                                  onPressed: () async {
                                    final bytes = await File(d.imagePath).readAsBytes();
                                    if (btn.mounted) await shareImage(btn, bytes, 'sketchstep-${d.lessonId}.png');
                                  },
                                ),
                              ),
                              IconButton(
                                tooltip: t('delete'),
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () async {
                                  if (!await _confirm()) return;
                                  await SketchStore.instance.deleteDrawing(d);
                                  _load();
                                },
                              ),
                            ],
                          ),
                      ]),
                    ],
                  ],
                ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
      );

  Widget _grid(List<Widget> tiles) => LayoutBuilder(builder: (context, box) {
        final cols = box.maxWidth > 520 ? 3 : 2;
        final w = (box.maxWidth - (cols - 1) * 14) / cols;
        return Wrap(spacing: 14, runSpacing: 18, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
      });

  Widget _empty(String Function(String) t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🖼️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(t('emptyTitle'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(t('emptyBody'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
          ]),
        ),
      );
}

class _Tile extends StatelessWidget {
  final String? image;
  final String title;
  final String subtitle;
  final int? stars;
  final bool dashed;
  final VoidCallback? onTap;
  final List<Widget> actions;

  const _Tile({required this.image, required this.title, required this.subtitle, required this.actions, this.stars, this.dashed = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final file = image == null ? null : File(image!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: dashed ? Border.all(color: const Color(0xFFB388FF), width: 2) : null,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: file != null && file.existsSync()
                    ? Image.file(file, fit: BoxFit.cover)
                    : const ColoredBox(color: Color(0xFFF4F1DE)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textDark)),
        Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        if (stars != null) SketchStars(count: stars!, size: 16),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: actions),
      ],
    );
  }
}
