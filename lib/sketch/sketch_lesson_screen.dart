import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'pencil.dart';
import 'share_image.dart';
import 'sketch_data.dart';
import 'sketch_lang.dart';
import 'sketch_painters.dart';
import 'sketch_score.dart';
import 'sketch_store.dart';
import 'sketch_widgets.dart';

// Port of SketchStep's LessonScreen: trace each step, shade, get scored.
// Every change is saved as a draft so a lesson can be continued later.

const _ink = Color(0xFF330D81);
const _inkDeep = Color(0xFF240862);
const _sun = Color(0xFFFFD220);
const _sunEdge = Color(0xFFC9A200);
const _lilac = Color(0xFFC9B8FF);

class _Done {
  final Uint8List png;
  final int score, stars;
  _Done(this.png, this.score, this.stars);
}

class SketchLessonScreen extends StatefulWidget {
  final SketchLesson lesson;
  const SketchLessonScreen({super.key, required this.lesson});

  @override
  State<SketchLessonScreen> createState() => _SketchLessonScreenState();
}

class _SketchLessonScreenState extends State<SketchLessonScreen> with SingleTickerProviderStateMixin {
  final _lang = SketchLang.instance;
  final _strokes = <PencilStroke>[];
  final _repaint = ValueNotifier(0);
  late final AnimationController _guide = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final List<StepTargets> _targets = widget.lesson.steps.map(stepTargets).toList();

  PencilStroke? _live;
  int? _pointer;
  bool _penSeen = false;
  ui.Image? _cache;
  double _cacheSide = 0;

  int _step = 0;
  PencilTool _tool = PencilTool.b2;
  bool _showGuide = true;
  List<int> _scores = [];
  bool _nudge = false;
  bool _loaded = false;
  int? _feedback;
  int _feedbackKey = 0;
  _Done? _done;
  Future<void> _saving = Future.value();

  SketchLesson get lesson => widget.lesson;
  SketchStep get current => lesson.steps[_step];
  bool get isLast => _step == lesson.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _lang.addListener(_onLang);
    PencilTexture.ensure().then((_) => _invalidate());
    SketchStore.instance.draft(lesson.id).then((d) {
      if (!mounted) return;
      setState(() {
        if (d != null) {
          _strokes.addAll(d.strokes);
          _step = d.step.clamp(0, lesson.steps.length - 1);
          _scores = d.scores;
        }
        _loaded = true;
      });
      _invalidate();
      _guide.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _lang.removeListener(_onLang);
    _guide.dispose();
    _repaint.dispose();
    _cache?.dispose();
    super.dispose();
  }

  void _onLang() => setState(() {});

  // ------------------------------------------------------------ Drawing

  void _invalidate() {
    _cache?.dispose();
    _cache = null;
    _repaint.value++;
  }

  ui.Image? _cacheFor(double side) {
    if (_cache != null && _cacheSide == side) return _cache;
    _cache?.dispose();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    _cacheSide = side;
    _cache = renderStrokes(_strokes, side * dpr, side / kSketchSpace);
    return _cache;
  }

  PencilPoint _toLesson(PointerEvent e, double side) {
    final s = kSketchSpace / side;
    final p = e.kind == PointerDeviceKind.stylus ? e.pressure.clamp(0.05, 1.0) : 0.5;
    return PencilPoint(e.localPosition.dx * s, e.localPosition.dy * s, p);
  }

  void _down(PointerDownEvent e, double side) {
    if (e.kind == PointerDeviceKind.stylus) _penSeen = true;
    // Palm rejection: once a stylus is used, ignore fingers on the paper.
    if (e.kind == PointerDeviceKind.touch && _penSeen) return;
    if (_pointer != null || _done != null || !_loaded) return;
    _pointer = e.pointer;
    _live = PencilStroke(_tool, _step, [_toLesson(e, side)]);
    if (_nudge) setState(() => _nudge = false);
    _repaint.value++;
  }

  void _move(PointerMoveEvent e, double side) {
    final s = _live;
    if (s == null || e.pointer != _pointer) return;
    final pt = _toLesson(e, side);
    final last = s.pts.last;
    if ((Offset(pt.x, pt.y) - Offset(last.x, last.y)).distance < 0.6) return;
    s.pts.add(pt);
    _repaint.value++;
  }

  void _up(PointerEvent e) {
    if (e.pointer != _pointer) return;
    final s = _live;
    _pointer = null;
    _live = null;
    if (s == null) return;
    _strokes.add(s);
    _invalidate();
    setState(() {});
    _autosave();
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    _invalidate();
    setState(() {});
    _autosave();
  }

  // ------------------------------------------------------------ Saving

  // Saves run one after another so a slow write can't overwrite a newer one.
  void _autosave() {
    if (_done != null) return;
    final strokes = List<PencilStroke>.of(_strokes);
    final step = _step;
    final scores = List<int>.of(_scores);
    _saving = _saving.then((_) async {
      if (strokes.isEmpty) return SketchStore.instance.deleteDraft(lesson.id);
      final preview = await exportPng(strokes, size: 400);
      await SketchStore.instance.saveDraft(lesson.id, step, scores, strokes, preview);
    }).catchError((_) {});
  }

  Future<void> _advance({bool force = false}) async {
    final mine = _strokes.where((s) => s.step == _step).toList();
    if (!force && !mine.any((s) => s.tool != PencilTool.eraser)) {
      setState(() => _nudge = true);
      return;
    }
    final guidesSoFar = [
      for (final t in _targets.take(_step + 1))
        if (t.kind == StepKind.line) ...t.pts,
    ];
    final score = scoreStep(_targets[_step], mine, guidesSoFar);
    final all = [..._scores, score];
    setState(() {
      _nudge = false;
      _scores = all;
      _feedback = score;
      _feedbackKey++;
    });

    if (!isLast) {
      setState(() {
        if (current.kind == StepKind.line && lesson.steps[_step + 1].kind == StepKind.shade && _tool == PencilTool.hb) {
          _tool = PencilTool.b2;
        }
        _step++;
      });
      _guide.forward(from: 0);
      _autosave();
      return;
    }

    final total = (all.reduce((a, b) => a + b) / all.length).round();
    final stars = starsFor(total);
    final png = await exportPng(_strokes);
    if (!mounted) return;
    setState(() => _done = _Done(png, total, stars));
    _saving = _saving.then((_) async {
      await SketchStore.instance.deleteDraft(lesson.id);
      await SketchStore.instance.saveDrawing(lesson.id, total, stars, png);
      await SketchStore.instance.recordProgress(lesson.id, total, stars);
    }).catchError((_) {});
  }

  void _restart() {
    _strokes.clear();
    _invalidate();
    setState(() {
      _scores = [];
      _step = 0;
      _done = null;
      _feedback = null;
    });
    _guide.forward(from: 0);
    _autosave();
  }

  // ------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final t = _lang.t;
    final lang = _lang.value;
    return Scaffold(
      backgroundColor: _ink,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _header(t, lang),
                _tip(t, lang),
                Expanded(child: _stage(t)),
                _dock(t),
              ],
            ),
            if (_done != null) _doneOverlay(t, lang),
          ],
        ),
      ),
    );
  }

  Widget _header(String Function(String) t, String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: paperColor),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title.of(lang),
                        style: const TextStyle(color: paperColor, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('${t('step')} ${_step + 1} ${t('of')} ${lesson.steps.length}',
                        style: const TextStyle(color: _lilac, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Row(
              children: [
                for (var i = 0; i < lesson.steps.length; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < _step ? _sun : paperColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(3),
                        gradient: i == _step
                            ? LinearGradient(colors: [_sun, _sun, paperColor.withValues(alpha: 0.16)], stops: const [0, 0.35, 0.35])
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(String Function(String) t, String lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(current.kind == StepKind.shade ? t('shadeHint') : t('traceHint'),
                style: const TextStyle(color: _sun, fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                current.tip.of(lang),
                key: ValueKey('$_step$lang'),
                style: const TextStyle(color: paperColor, fontSize: 16, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stage(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(builder: (context, box) {
        final side = box.biggest.shortestSide;
        return Center(
          child: SizedBox.square(
            dimension: side,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: paperColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [BoxShadow(color: Color(0xCC0A0028), blurRadius: 60, offset: Offset(0, 30), spreadRadius: -24)],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Listener(
                    key: const Key('sketch-paper'),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _down(e, side),
                    onPointerMove: (e) => _move(e, side),
                    onPointerUp: _up,
                    onPointerCancel: _up,
                    child: CustomPaint(
                      painter: _StrokesPainter(this, side),
                      child: AnimatedBuilder(
                        animation: _guide,
                        builder: (_, _) => CustomPaint(
                          painter: GuidePainter(lesson: lesson, step: _step, progress: _guide.value, visible: _showGuide),
                          size: Size.square(side),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_feedback != null)
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(child: Center(child: _ScoreChip(key: ValueKey(_feedbackKey), score: _feedback!, label: t('onTarget')))),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _dock(String Function(String) t) {
    Widget tool(PencilTool tl, Widget icon, String label) => _ToolButton(
          selected: _tool == tl,
          lift: tl != PencilTool.eraser,
          onTap: () => setState(() => _tool = tl),
          icon: icon,
          label: label,
        );
    return Container(
      decoration: BoxDecoration(color: _inkDeep, border: Border(top: BorderSide(color: paperColor.withValues(alpha: 0.16)))),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              tool(PencilTool.hb, const PencilIcon(lead: Color(0xFF8C8799)), 'HB'),
              tool(PencilTool.b2, const PencilIcon(lead: Color(0xFF565065)), '2B'),
              tool(PencilTool.b6, const PencilIcon(lead: Color(0xFF1F1B29)), '6B'),
              tool(PencilTool.eraser, const EraserIcon(), t('eraser')),
              _ToolButton(
                selected: false,
                enabled: _strokes.isNotEmpty,
                onTap: _undo,
                icon: const Icon(Icons.undo_rounded, color: _lilac),
                label: t('undo'),
              ),
              _ToolButton(
                selected: _showGuide,
                onTap: () => setState(() => _showGuide = !_showGuide),
                icon: Icon(_showGuide ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _lilac),
                label: t('guide'),
              ),
            ],
          ),
          if (_nudge)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${t('emptyStep')} ', style: const TextStyle(color: _lilac, fontSize: 13)),
                  GestureDetector(
                    onTap: () => _advance(force: true),
                    child: Text(t('skip'),
                        style: const TextStyle(color: _sun, fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline, decorationColor: _sun)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SunButton(label: isLast ? t('finish') : t('next'), onPressed: () => _advance()),
        ],
      ),
    );
  }

  Widget _doneOverlay(String Function(String) t, String lang) {
    final d = _done!;
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xC0140438),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(color: paperColor, borderRadius: BorderRadius.circular(24)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(aspectRatio: 1, child: Image.memory(d.png, fit: BoxFit.cover)),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(t('doneTitle'), style: const TextStyle(color: _ink, fontSize: 26, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Align(alignment: Alignment.centerLeft, child: SketchStars(count: d.stars, size: 34, animate: true, emptyColor: _ink.withValues(alpha: 0.14))),
                          const SizedBox(height: 10),
                          Text.rich(TextSpan(children: [
                            TextSpan(text: '${t('accuracy')} '),
                            TextSpan(text: '${d.score}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                          ]), style: const TextStyle(color: _ink, fontSize: 16)),
                          Text(t('savedNote'), style: const TextStyle(color: Color(0xFF5B4A86), fontSize: 13)),
                          const SizedBox(height: 18),
                          Builder(
                            builder: (btn) => SunButton(
                              label: t('saveImage'),
                              onPressed: () => shareImage(btn, d.png, 'sketchstep-${lesson.id}.png'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GhostButton(label: t('drawAgain'), onPressed: _restart),
                          const SizedBox(height: 10),
                          GhostButton(label: t('back'), onPressed: () => Navigator.of(context).pop()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrokesPainter extends CustomPainter {
  final _SketchLessonScreenState s;
  final double side;
  _StrokesPainter(this.s, this.side) : super(repaint: s._repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final cache = s._cacheFor(side);
    final unit = side / kSketchSpace;
    canvas.save();
    canvas.scale(unit);
    // One layer so a live eraser stroke can clear the committed graphite underneath.
    canvas.saveLayer(const Rect.fromLTWH(0, 0, kSketchSpace, kSketchSpace), Paint());
    if (cache != null) {
      canvas.drawImageRect(
        cache,
        Rect.fromLTWH(0, 0, cache.width.toDouble(), cache.height.toDouble()),
        const Rect.fromLTWH(0, 0, kSketchSpace, kSketchSpace),
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    final live = s._live;
    if (live != null) PencilPainter(unit).stroke(canvas, live);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StrokesPainter old) => true;
}

class _ToolButton extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final bool lift;
  final VoidCallback onTap;
  final Widget icon;
  final String label;

  const _ToolButton({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.label,
    this.enabled = true,
    this.lift = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, selected && lift ? -5 : 0, 0),
            padding: const EdgeInsets.symmetric(vertical: 6),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: selected ? paperColor.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Opacity(
              opacity: enabled ? 1 : 0.35,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 34, child: Center(child: icon)),
                  const SizedBox(height: 2),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: selected ? paperColor : _lilac, fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatefulWidget {
  final int score;
  final String label;
  const _ScoreChip({super.key, required this.score, required this.label});

  @override
  State<_ScoreChip> createState() => _ScoreChipState();
}

class _ScoreChipState extends State<_ScoreChip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final v = _c.value;
        final opacity = v < 0.15 ? v / 0.15 : v > 0.8 ? (1 - v) / 0.2 : 1.0;
        return Opacity(opacity: opacity.clamp(0, 1), child: Transform.translate(offset: Offset(0, v < 0.15 ? 8 * (1 - v / 0.15) : 0), child: child));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(99)),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '${widget.score}% ', style: const TextStyle(color: _sun, fontWeight: FontWeight.w900, fontSize: 17)),
          TextSpan(text: widget.label, style: const TextStyle(color: paperColor, fontSize: 14)),
        ])),
      ),
    );
  }
}

/// Yellow pill button with a pressed-in bottom edge, as in SketchStep.
class SunButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const SunButton({super.key, required this.label, required this.onPressed});

  @override
  State<SunButton> createState() => _SunButtonState();
}

class _SunButtonState extends State<SunButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: _sun,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [BoxShadow(color: _sunEdge, offset: Offset(0, _down ? 1 : 5))],
          ),
          child: Text(widget.label,
              textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const GhostButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _ink,
        side: BorderSide(color: _ink.withValues(alpha: 0.2), width: 2),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      child: Text(label),
    );
  }
}
