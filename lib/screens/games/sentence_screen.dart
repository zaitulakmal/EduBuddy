import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/sentence_content.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/reader_kit.dart';
import '../../widgets/reader_pictures.dart';
import 'reader_run.dart';

/// The Sentences game (Bina Ayat): the same endless chapter loop as Buddy
/// Reader, with three kinds of sentence question taking turns.
class SentenceScreen extends StatelessWidget {
  const SentenceScreen({super.key});

  static const gameKey = 'sentence';

  @override
  Widget build(BuildContext context) {
    return ReaderRun(
      gameKey: gameKey,
      unit: ('sentences', 'ayat'),
      buildStep: (context, key, step) {
        final items = step.ms ? sentenceItemsMs : sentenceItemsEn;
        final item = sentenceItemFor(items, step.chapter, step.slot);
        return switch (sentenceQuestionFor(step.chapter, step.slot)) {
          SentenceQuestion.build => _BuildStep(
            key: key,
            step: step,
            item: item,
          ),
          SentenceQuestion.fill => _FillStep(key: key, step: step, item: item),
          SentenceQuestion.match => _MatchStep(
            key: key,
            step: step,
            item: item,
            decoys: sentenceMatchDecoys(items, item),
          ),
        };
      },
    );
  }
}

/// A beat to read the finished sentence before moving on.
Future<void> _pause() => Future.delayed(const Duration(milliseconds: 1200));

/// The item's picture, gently bobbing, above the sentence.
class _Clue extends StatelessWidget {
  final ReaderPic pic;
  const _Clue(this.pic);

  @override
  Widget build(BuildContext context) => ReaderMeaning(pic: pic, size: 92);
}

// ─── Build the sentence ───────────────────────────────────────────────────────

class _BuildStep extends StatefulWidget {
  final ReaderStep step;
  final SentenceItem item;
  const _BuildStep({super.key, required this.step, required this.item});

  @override
  State<_BuildStep> createState() => _BuildStepState();
}

class _BuildStepState extends State<_BuildStep> {
  @override
  void initState() {
    super.initState();
    readerAfterFrame(() {
      if (!mounted) return;
      widget.step.say(
        widget.step.t(
          'Put the words in order!',
          'Susun perkataan ikut turutan!',
        ),
      );
    });
  }

  Future<void> _done() async {
    await _pause();
    if (mounted) widget.step.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    return ReaderDragBoard(
      mode: ReaderBoardMode.words,
      tokens: widget.item.tokens,
      header: _Clue(widget.item.pic),
      locked: widget.step.locked,
      onRight: widget.step.onRight,
      onWrong: widget.step.onWrong,
      onComplete: _done,
    );
  }
}

// ─── Fill the missing word ────────────────────────────────────────────────────

class _FillStep extends StatefulWidget {
  final ReaderStep step;
  final SentenceItem item;
  const _FillStep({super.key, required this.step, required this.item});

  @override
  State<_FillStep> createState() => _FillStepState();
}

class _FillStepState extends State<_FillStep> {
  @override
  void initState() {
    super.initState();
    readerAfterFrame(() {
      if (!mounted) return;
      widget.step.say(
        widget.step.t('Which word fits?', 'Perkataan mana yang sesuai?'),
      );
    });
  }

  Future<void> _done() async {
    await _pause();
    if (mounted) widget.step.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tokens = item.tokens;
    final blank = item.blankIndex;
    // Wrong choices wear the same trailing punctuation as the right one, so
    // the full stop can't give the answer away.
    final suffix = RegExp(r'[^A-Za-z]*$').stringMatch(tokens[blank]) ?? '';
    return ReaderDragBoard(
      mode: ReaderBoardMode.words,
      tokens: tokens,
      blanks: {blank},
      extras: [for (final d in item.distractors) '$d$suffix'],
      header: _Clue(item.pic),
      locked: widget.step.locked,
      onRight: widget.step.onRight,
      onWrong: widget.step.onWrong,
      onComplete: _done,
    );
  }
}

// ─── Match the sentence to its picture ────────────────────────────────────────

class _MatchStep extends StatefulWidget {
  final ReaderStep step;
  final SentenceItem item;
  final List<ReaderPic> decoys;
  const _MatchStep({
    super.key,
    required this.step,
    required this.item,
    required this.decoys,
  });

  @override
  State<_MatchStep> createState() => _MatchStepState();
}

class _MatchStepState extends State<_MatchStep> {
  late final List<ReaderPic> _choices = [widget.item.pic, ...widget.decoys]
    ..shuffle(Random());
  final Set<ReaderPic> _ruledOut = {};
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    readerAfterFrame(() {
      if (!mounted) return;
      widget.step.say(
        widget.step.t('Which picture is it?', 'Gambar yang mana?'),
      );
    });
  }

  Future<void> _choose(ReaderPic pic) async {
    if (widget.step.locked || _solved || _ruledOut.contains(pic)) return;
    if (pic != widget.item.pic) {
      setState(() => _ruledOut.add(pic));
      widget.step.onWrong();
      return;
    }
    setState(() => _solved = true);
    widget.step.onRight();
    await _pause();
    if (mounted) widget.step.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
      child: Column(
        children: [
          // The sentence card.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            decoration: BoxDecoration(
              color: kReaderPaper,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: kReaderPaperEdge, offset: Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.sentence,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: kReaderInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                // Three cards in a row when there's room, otherwise a column.
                final side = min(c.maxWidth / 3 - 10, c.maxHeight - 10);
                final row = side >= 96;
                final cardSize = row
                    ? side
                    : min(c.maxHeight / 3 - 12, c.maxWidth * 0.6);
                final cards = [
                  for (var i = 0; i < _choices.length; i++)
                    _PictureCard(
                      key: ValueKey('match-${_choices[i].name}'),
                      pic: _choices[i],
                      size: cardSize,
                      state: _choices[i] == widget.item.pic && _solved
                          ? _CardState.right
                          : _ruledOut.contains(_choices[i])
                          ? _CardState.wrong
                          : _CardState.idle,
                      phase: i * 0.8,
                      onTap: () => _choose(_choices[i]),
                    ),
                ];
                return row
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: cards,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: cards,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _CardState { idle, right, wrong }

class _PictureCard extends StatefulWidget {
  final ReaderPic pic;
  final double size;
  final _CardState state;
  final double phase;
  final VoidCallback onTap;
  const _PictureCard({
    super.key,
    required this.pic,
    required this.size,
    required this.state,
    required this.phase,
    required this.onTap,
  });

  @override
  State<_PictureCard> createState() => _PictureCardState();
}

class _PictureCardState extends State<_PictureCard>
    with TickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant _PictureCard old) {
    super.didUpdateWidget(old);
    if (widget.state == _CardState.wrong && old.state != _CardState.wrong) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (border, fill) = switch (widget.state) {
      _CardState.right => (const Color(0xFF3FB36B), const Color(0xFFE4F7E9)),
      _CardState.wrong => (const Color(0xFFD9D2C3), const Color(0xFFEFE9DC)),
      _CardState.idle => (kReaderPaperEdge, kReaderPaper),
    };
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _shake]),
      builder: (_, child) {
        final bob = widget.state == _CardState.idle
            ? sin(_bob.value * 2 * pi + widget.phase) * 4
            : 0.0;
        final shake = sin(_shake.value * pi * 6) * 10 * (1 - _shake.value);
        return Transform.translate(offset: Offset(shake, bob), child: child);
      },
      child: AnimatedScale(
        scale: widget.state == _CardState.right ? 1.12 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: BouncyButton(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: widget.size,
            height: widget.size,
            padding: EdgeInsets.all(widget.size * 0.1),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border, width: 3),
              boxShadow: [BoxShadow(color: border, offset: const Offset(0, 5))],
            ),
            child: Opacity(
              opacity: widget.state == _CardState.wrong ? 0.35 : 1,
              child: ReaderPicture(widget.pic, size: widget.size * 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
