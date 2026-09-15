import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import 'bouncy_button.dart';
import 'reader_pictures.dart';

/// Building blocks shared by the Buddy Reader games (spelling and sentences):
/// the look, the drag-and-drop board with its googly-eyed pieces, and the
/// paper-style buttons.

// ─── Look ─────────────────────────────────────────────────────────────────────

const kReaderSkyBottom = Color(0xFFE4F6F2);
const kReaderInk = Color(0xFF3D3526);
const kReaderPaper = Color(0xFFFFFDF6);
const kReaderPaperEdge = Color(0xFFC9B98F);
const kReaderButter = Color(0xFFFFC93C);
const kReaderButterEdge = Color(0xFFD99A00);
const kReaderCoral = Color(0xFFFF6B35);
const kReaderMuted = Color(0xFF8A7F6A);
const kReaderHeart = Color(0xFFFF4D6D);
const kReaderLetterColors = [
  Color(0xFFFF6B35), Color(0xFF3FA7F5), Color(0xFFA4E02A), Color(0xFFFF5DA2),
  Color(0xFF8A4FFF), Color(0xFF00C2A8), Color(0xFFFFC93C),
];

// ─── Drag board ───────────────────────────────────────────────────────────────

enum ReaderBoardMode { letters, words }

class _Piece {
  final int id;
  final String label;
  final Color color;
  Offset home = Offset.zero;
  Offset pos = Offset.zero;
  bool dragging = false;
  int? slot; // token index once placed
  Offset look = Offset.zero; // pupil direction while dragged
  _Piece(this.id, this.label, this.color);
}

/// A line of [tokens] across the top; the ones listed in [blanks] are empty
/// outlines, and a piece for each of them (plus any [extras]) is scattered
/// below. A piece only sticks to an outline expecting the same label; anything
/// else springs back home and counts as a mistake.
///
/// Test keys: pieces are `reader-piece-<id>` (blanks in order, then extras);
/// outlines are `reader-slot-<token index>`.
class ReaderDragBoard extends StatefulWidget {
  final ReaderBoardMode mode;
  final List<String> tokens;
  final Set<int>? blanks; // null = every token is a blank
  final List<String> extras; // distractor pieces with no outline
  final String? keyToken; // highlighted word chip (bare, lower case)
  final Widget? header; // shown above the outlines
  final bool locked;
  final String Function(String label)? bare; // how a chip label compares to keyToken
  final VoidCallback onRight;
  final VoidCallback onWrong;
  final Future<void> Function() onComplete;

  const ReaderDragBoard({
    super.key,
    required this.mode,
    required this.tokens,
    this.blanks,
    this.extras = const [],
    this.keyToken,
    this.header,
    this.locked = false,
    this.bare,
    required this.onRight,
    required this.onWrong,
    required this.onComplete,
  });

  @override
  State<ReaderDragBoard> createState() => _ReaderDragBoardState();
}

class _ReaderDragBoardState extends State<ReaderDragBoard> with TickerProviderStateMixin {
  final _stackKey = GlobalKey();
  final _headerKey = GlobalKey();
  late final List<GlobalKey> _slotKeys = List.generate(widget.tokens.length, (_) => GlobalKey());
  late final Set<int> _blanks =
      widget.blanks ?? {for (var i = 0; i < widget.tokens.length; i++) i};
  late final List<_Piece> _pieces;
  final Set<int> _filled = {};
  Size? _laidOutFor;
  int? _singing; // token index currently "singing" in the read-back
  bool _finished = false;

  late final AnimationController _wiggle =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  bool get _letters => widget.mode == ReaderBoardMode.letters;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    final colorOffset = rand.nextInt(kReaderLetterColors.length);
    final labels = [
      for (final i in _blanks.toList()..sort()) widget.tokens[i],
      ...widget.extras,
    ];
    _pieces = [
      for (var i = 0; i < labels.length; i++)
        _Piece(i, labels[i], kReaderLetterColors[(colorOffset + i) % kReaderLetterColors.length]),
    ];
  }

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  /// Spreads pieces over the open area below the outlines, clear of Buddy.
  void _scatter(Size size) {
    const spots = [
      Offset(0.22, 0.10), Offset(0.78, 0.06), Offset(0.50, 0.32), Offset(0.24, 0.52),
      Offset(0.76, 0.48), Offset(0.52, 0.72), Offset(0.84, 0.92),
    ];
    final top = _scatterTop(size);
    final bottom = size.height * 0.84;
    final order = List.generate(spots.length, (i) => i)..shuffle(Random());
    for (var i = 0; i < _pieces.length; i++) {
      final s = spots[order[i % spots.length]];
      final p = _pieces[i];
      if (p.slot == null) {
        p.home = Offset(s.dx * size.width, top + s.dy * (bottom - top));
        p.pos = p.home;
      }
    }
    _laidOutFor = size;
  }

  /// Where the scatter area starts: under the outlines, however tall they are.
  double _scatterTop(Size size) {
    final lines = _letters ? 1 : (widget.tokens.length / 3).ceil();
    final slotsHeight = _letters ? _glyphSize(size) * 1.2 : lines * 62.0;
    final header = widget.header == null ? 0.0 : 112.0;
    return min(size.height * 0.62, size.height * 0.04 + header + slotsHeight + 70);
  }

  double _glyphSize(Size size) {
    final n = widget.tokens.length;
    return min(110.0, (size.width - 40) / n * 1.1);
  }

  Offset? _slotCenter(int index) {
    final slotBox = _slotKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (slotBox == null || stackBox == null || !slotBox.hasSize) return null;
    return stackBox.globalToLocal(slotBox.localToGlobal(slotBox.size.center(Offset.zero)));
  }

  void _onDragStart(_Piece p) {
    if (p.slot != null || _finished || widget.locked) return;
    setState(() => p.dragging = true);
    SoundService.instance.tap();
  }

  void _onDragUpdate(_Piece p, DragUpdateDetails d, Size size) {
    if (!p.dragging) return;
    setState(() {
      p.pos = Offset(
        (p.pos.dx + d.delta.dx).clamp(0, size.width),
        (p.pos.dy + d.delta.dy).clamp(0, size.height),
      );
      p.look = Offset((d.delta.dx / 6).clamp(-1, 1), (d.delta.dy / 6).clamp(-1, 1));
    });
  }

  void _onDragEnd(_Piece p, Size size) {
    if (!p.dragging) return;
    int? nearest;
    var best = double.infinity;
    for (final i in _blanks) {
      if (_filled.contains(i)) continue;
      final c = _slotCenter(i);
      if (c == null) continue;
      final d = (c - p.pos).distance;
      if (d < best) {
        best = d;
        nearest = i;
      }
    }
    final reach = size.width * 0.16;
    setState(() {
      p.dragging = false;
      p.look = Offset.zero;
    });
    if (nearest == null || best > reach || widget.locked) {
      // Let go in open space: no penalty, it just floats home.
      setState(() => p.pos = p.home);
      return;
    }
    if (widget.tokens[nearest] != p.label) {
      setState(() => p.pos = p.home);
      widget.onWrong();
      return;
    }
    setState(() {
      p.pos = _slotCenter(nearest!)!;
      p.slot = nearest;
      _filled.add(nearest);
    });
    widget.onRight();
    if (_filled.length == _blanks.length) _readBack();
  }

  /// Every placed piece sings in order, then the owner takes over.
  Future<void> _readBack() async {
    _finished = true;
    await Future.delayed(const Duration(milliseconds: 300));
    for (final i in _blanks.toList()..sort()) {
      if (!mounted) return;
      setState(() => _singing = i);
      await Future.delayed(Duration(milliseconds: _letters ? 420 : 320));
    }
    if (!mounted) return;
    setState(() => _singing = null);
    await widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      if (_laidOutFor != size) {
        _scatter(size);
        // Placed pieces follow their outlines after a resize or rotation.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            for (final p in _pieces) {
              if (p.slot != null) p.pos = _slotCenter(p.slot!) ?? p.pos;
            }
          });
        });
      }
      final glyph = _glyphSize(size);
      final unplaced = _pieces.where((p) => p.slot == null).toList();
      final placed = _pieces.where((p) => p.slot != null).toList();
      return Stack(
        key: _stackKey,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 12,
            right: 12,
            top: size.height * 0.04,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.header != null)
                  SizedBox(key: _headerKey, height: 100, child: Center(child: widget.header)),
                if (widget.header != null) const SizedBox(height: 12),
                _buildSlots(glyph),
              ],
            ),
          ),
          // Placed pieces under loose ones, so a dragged piece is never hidden.
          for (final p in placed) _buildPiece(p, size, glyph),
          for (final p in unplaced) _buildPiece(p, size, glyph),
        ],
      );
    });
  }

  Widget _buildSlots(double glyph) {
    if (_letters) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < widget.tokens.length; i++)
            KeyedSubtree(
              key: ValueKey('reader-slot-$i'),
              child: SizedBox(
                key: _slotKeys[i],
                width: glyph * 0.78,
                height: glyph * 1.2,
                child: Center(
                  child: Stack(children: [
                    Text(widget.tokens[i],
                        style: TextStyle(
                          fontSize: glyph,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4
                            ..strokeJoin = StrokeJoin.round
                            ..color = kReaderMuted.withValues(alpha: 0.7),
                        )),
                    Text(widget.tokens[i],
                        style: TextStyle(
                            fontSize: glyph,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            color: Colors.white.withValues(alpha: 0.5))),
                  ]),
                ),
              ),
            ),
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 12,
      children: [
        for (var i = 0; i < widget.tokens.length; i++)
          KeyedSubtree(
            key: ValueKey('reader-slot-$i'),
            child: _blanks.contains(i) ? _outline(i) : _fixedWord(i),
          ),
      ],
    );
  }

  Widget _outline(int i) => Container(
        key: _slotKeys[i],
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _filled.contains(i) ? 0 : 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _filled.contains(i) ? Colors.transparent : kReaderMuted,
            width: 2.5,
          ),
        ),
        // Invisible text sizes the outline exactly like the chip that fills it.
        child: Text(widget.tokens[i],
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: Colors.transparent)),
      );

  /// A word already in place (fill-in-the-blank): same size as a chip, calmer.
  Widget _fixedWord(int i) => Container(
        key: _slotKeys[i],
        padding: const EdgeInsets.symmetric(horizontal: 16.5, vertical: 8.5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(widget.tokens[i],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kReaderInk)),
      );

  Widget _buildPiece(_Piece p, Size size, double glyph) {
    final placed = p.slot != null;
    final singing = placed && _singing == p.slot;
    final bare = widget.bare ?? (s) => s.toLowerCase();
    final isKey = !_letters && widget.keyToken != null && bare(p.label) == widget.keyToken;
    final body = _letters
        ? ReaderLetterCreature(
            letter: p.label,
            color: p.color,
            size: glyph,
            look: p.look,
            wiggle: _wiggle,
            phase: p.id * 0.9,
            still: placed || p.dragging,
          )
        : ReaderWordChip(
            word: p.label,
            highlighted: isKey,
            look: p.look,
            wiggle: _wiggle,
            phase: p.id * 0.9,
            still: placed || p.dragging,
          );

    return AnimatedPositioned(
      key: ValueKey(p.id),
      duration: p.dragging ? Duration.zero : const Duration(milliseconds: 480),
      curve: Curves.elasticOut,
      left: p.pos.dx,
      top: p.pos.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          key: ValueKey('reader-piece-${p.id}'),
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => _onDragStart(p),
          onPanUpdate: (d) => _onDragUpdate(p, d, size),
          onPanEnd: (_) => _onDragEnd(p, size),
          onPanCancel: () => _onDragEnd(p, size),
          child: AnimatedSlide(
            offset: singing ? const Offset(0, -0.25) : Offset.zero,
            duration: const Duration(milliseconds: 180),
            child: AnimatedScale(
              scale: p.dragging ? 1.18 : (singing ? 1.2 : 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pieces ───────────────────────────────────────────────────────────────────

/// A chunky letter with googly eyes that wobbles while waiting to be picked.
class ReaderLetterCreature extends StatelessWidget {
  final String letter;
  final Color color;
  final double size;
  final Offset look;
  final Animation<double> wiggle;
  final double phase;
  final bool still;

  const ReaderLetterCreature({
    super.key,
    required this.letter,
    required this.color,
    required this.size,
    required this.look,
    required this.wiggle,
    required this.phase,
    required this.still,
  });

  @override
  Widget build(BuildContext context) {
    final eye = max(14.0, size * 0.2);
    return AnimatedBuilder(
      animation: wiggle,
      builder: (_, child) => Transform.rotate(
        angle: still ? 0 : sin(wiggle.value * 2 * pi + phase) * 0.06,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: SizedBox(
        width: size * 0.78,
        height: size * 1.2,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Text(letter,
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = size * 0.07
                    ..strokeJoin = StrokeJoin.round
                    ..color = kReaderInk,
                )),
            Text(letter,
                style: TextStyle(
                    fontSize: size, fontWeight: FontWeight.w900, height: 1.1, color: color)),
            Positioned(
              top: size * 0.42,
              child: ReaderEyes(size: eye, look: look, wiggle: wiggle, phase: phase),
            ),
          ],
        ),
      ),
    );
  }
}

class ReaderWordChip extends StatelessWidget {
  final String word;
  final bool highlighted;
  final Offset look;
  final Animation<double> wiggle;
  final double phase;
  final bool still;

  const ReaderWordChip({
    super.key,
    required this.word,
    required this.highlighted,
    required this.look,
    required this.wiggle,
    required this.phase,
    required this.still,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: wiggle,
      builder: (_, child) => Transform.rotate(
        angle: still ? 0 : sin(wiggle.value * 2 * pi + phase) * 0.04,
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            // Matches the outline: 14/6 padding plus its 2.5 border.
            padding: const EdgeInsets.symmetric(horizontal: 16.5, vertical: 8.5),
            decoration: BoxDecoration(
              color: highlighted ? kReaderButter : kReaderPaper,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: highlighted ? kReaderButterEdge : kReaderPaperEdge,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: Text(word,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: kReaderInk)),
          ),
          if (highlighted)
            Positioned(
              top: -14,
              child: ReaderEyes(size: 20, look: look, wiggle: wiggle, phase: phase),
            ),
        ],
      ),
    );
  }
}

class ReaderEyes extends StatelessWidget {
  final double size;
  final Offset look;
  final Animation<double> wiggle;
  final double phase;

  const ReaderEyes(
      {super.key, required this.size, required this.look, required this.wiggle, required this.phase});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: wiggle,
      builder: (_, _) {
        // A quick blink near the end of each wiggle cycle, staggered by phase.
        final cycle = (wiggle.value + phase / (2 * pi)) % 1.0;
        final open = cycle > 0.94 ? 0.15 : 1.0;
        Widget eye() => Container(
              width: size,
              height: size * open,
              margin: EdgeInsets.symmetric(horizontal: size * 0.08),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(size),
                border: Border.all(color: kReaderInk, width: max(1.5, size * 0.1)),
              ),
              alignment: Alignment(look.dx * 0.6, look.dy * 0.6),
              child: open < 1
                  ? null
                  : Container(
                      width: size * 0.45,
                      height: size * 0.45,
                      decoration: const BoxDecoration(color: kReaderInk, shape: BoxShape.circle),
                    ),
            );
        return SizedBox(
          height: size,
          child: Row(mainAxisSize: MainAxisSize.min, children: [eye(), eye()]),
        );
      },
    );
  }
}

/// A picture that pops in and keeps bouncing — the word "comes alive".
class ReaderMeaning extends StatefulWidget {
  final ReaderPic pic;
  final double size;
  const ReaderMeaning({super.key, required this.pic, this.size = 130});

  @override
  State<ReaderMeaning> createState() => _ReaderMeaningState();
}

class _ReaderMeaningState extends State<ReaderMeaning> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _in.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_in, _loop]),
        builder: (_, child) {
          final pop = Curves.elasticOut.transform(_in.value);
          final s = sin(_loop.value * 2 * pi);
          return Transform.translate(
            offset: Offset(0, -s.abs() * 18),
            child: Transform.rotate(
              angle: (1 - pop) * -0.4 + s * 0.08,
              child: Transform.scale(
                  scaleX: pop * (1 + s * 0.06), scaleY: pop * (1 - s * 0.06), child: child),
            ),
          );
        },
        child: ReaderPicture(widget.pic, size: widget.size),
      ),
    );
  }
}

// ─── Buttons ──────────────────────────────────────────────────────────────────

class ReaderPaperButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;

  const ReaderPaperButton(
      {super.key, required this.child, required this.semanticLabel, this.onTap});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: 48,
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kReaderPaper,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x383D3526), offset: Offset(0, 4))],
      ),
      child: child,
    );
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: onTap == null ? box : BouncyButton(onTap: onTap!, child: box),
    );
  }
}

class ReaderBigButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const ReaderBigButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: kReaderCoral,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0xFFC4481C), offset: Offset(0, 5))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.play_arrow_rounded, color: Colors.white),
        ]),
      ),
    );
  }
}

/// Runs [action] after the current frame — lets a step talk to the run from
/// its initState without calling setState during a build.
void readerAfterFrame(VoidCallback action) =>
    WidgetsBinding.instance.addPostFrameCallback((_) => scheduleMicrotask(action));
