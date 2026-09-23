import 'package:flutter/material.dart';
import '../../models/reader_content.dart';
import '../../widgets/reader_kit.dart';
import 'reader_run.dart';

/// Endless-Reader-style spelling game: drag talking letters into a word's
/// outline, then watch the word come alive. Sentences live in their own game,
/// [SentenceScreen].
class BuddyReaderScreen extends StatelessWidget {
  const BuddyReaderScreen({super.key});

  static const gameKey = 'reader';

  @override
  Widget build(BuildContext context) {
    return ReaderRun(
      gameKey: gameKey,
      unit: ('words', 'perkataan'),
      buildStep: (context, key, step) => _SpellStep(key: key, step: step),
    );
  }
}

class _SpellStep extends StatefulWidget {
  final ReaderStep step;
  const _SpellStep({super.key, required this.step});

  @override
  State<_SpellStep> createState() => _SpellStepState();
}

class _SpellStepState extends State<_SpellStep> {
  bool _solved = false;

  ReaderStep get _step => widget.step;
  ReaderWord get _word =>
      readerWordFor(_step.ms ? readerWordsMs : readerWordsEn, _step.chapter, _step.slot);

  @override
  void initState() {
    super.initState();
    readerAfterFrame(() {
      if (!mounted) return;
      _step.say(_step.t('Build "${_word.word}"!', 'Bina "${_word.word}"!'));
    });
  }

  Future<void> _onBuilt() async {
    if (!mounted) return;
    setState(() => _solved = true);
    // A beat to admire the finished word before moving on.
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) _step.onSolved();
  }

  @override
  Widget build(BuildContext context) {
    final word = _word;
    return Stack(
      children: [
        Positioned.fill(
          child: ReaderDragBoard(
            mode: ReaderBoardMode.letters,
            tokens: word.word.split(''),
            locked: _step.locked,
            onRight: _step.onRight,
            onWrong: _step.onWrong,
            onComplete: _onBuilt,
          ),
        ),
        if (_solved)
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.sizeOf(context).height * 0.3,
            child: Center(child: ReaderMeaning(pic: word.pic)),
          ),
      ],
    );
  }
}
