import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/sound_service.dart';
import '../../widgets/bouncy_button.dart';

const _kBg = Color(0xFFFFF4E0);
const _kOrange = Color(0xFFE8784A);

// ─── Word banks (emoji, word) — tiered by length, EN & MS ─────────────────────

const _enWords = <int, List<(String, String)>>{
  3: [
    ('🐱', 'cat'), ('🐶', 'dog'), ('☀️', 'sun'), ('🚌', 'bus'), ('🎩', 'hat'),
    ('🐝', 'bee'), ('🐮', 'cow'), ('🥚', 'egg'), ('🦊', 'fox'), ('🦉', 'owl'),
    ('🐷', 'pig'), ('🚗', 'car'), ('🐜', 'ant'), ('🦇', 'bat'), ('🍵', 'cup'),
    ('🔑', 'key'), ('🖊️', 'pen'), ('🛏️', 'bed'), ('🍯', 'jam'), ('🦵', 'leg'),
  ],
  4: [
    ('🐟', 'fish'), ('🐸', 'frog'), ('⭐', 'star'), ('🎂', 'cake'), ('🐦', 'bird'),
    ('🦆', 'duck'), ('🦁', 'lion'), ('🌙', 'moon'), ('🌳', 'tree'), ('🚢', 'ship'),
    ('🐻', 'bear'), ('🌽', 'corn'), ('🥛', 'milk'), ('🌧️', 'rain'), ('👟', 'shoe'),
    ('🧦', 'sock'), ('🐐', 'goat'), ('🍐', 'pear'), ('🔔', 'bell'), ('🪁', 'kite'),
  ],
  5: [
    ('🍎', 'apple'), ('🏠', 'house'), ('🐭', 'mouse'), ('🐍', 'snake'), ('🐯', 'tiger'),
    ('🐳', 'whale'), ('🍞', 'bread'), ('🕐', 'clock'), ('❤️', 'heart'), ('🍕', 'pizza'),
    ('🤖', 'robot'), ('🚂', 'train'), ('🐴', 'horse'), ('🍇', 'grape'), ('🐑', 'sheep'),
  ],
};

const _msWords = <int, List<(String, String)>>{
  3: [
    ('🚌', 'bas'), ('🔥', 'api'), ('🍠', 'ubi'), ('🎂', 'kek'), ('🍜', 'mee'),
    ('👩', 'ibu'),
  ],
  4: [
    ('⚽', 'bola'), ('🐟', 'ikan'), ('👕', 'baju'), ('📖', 'buku'), ('🍞', 'roti'),
    ('🥛', 'susu'), ('🍚', 'nasi'), ('🐔', 'ayam'), ('🦆', 'itik'), ('🍃', 'daun'),
    ('👁️', 'mata'), ('🍎', 'epal'), ('🎩', 'topi'), ('🦶', 'kaki'),
  ],
  5: [
    ('🐘', 'gajah'), ('🌸', 'bunga'), ('💡', 'lampu'), ('🚢', 'kapal'), ('🌳', 'pokok'),
    ('🪣', 'baldi'), ('🚪', 'pintu'), ('🐄', 'lembu'), ('🏠', 'rumah'), ('🐯', 'rimau'),
    ('🥚', 'telur'), ('🐝', 'lebah'), ('🌙', 'bulan'), ('🐜', 'semut'),
  ],
};

class WordBuilderScreen extends StatefulWidget {
  const WordBuilderScreen({super.key});

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends State<WordBuilderScreen>
    with TickerProviderStateMixin {
  final _rand = Random();
  late ConfettiController _confetti;
  late AnimationController _shakeCtrl;

  int _level = 1;
  int _score = 0;
  int _lives = 3;
  int _solvedInLevel = 0;
  bool _gameOver = false;
  bool _celebrating = false;

  String _emoji = '';
  String _word = '';
  late List<int> _hiddenIndexes; // positions the child must fill (in order)
  int _fillPointer = 0; // which hidden slot is being answered now
  late List<String?> _filled; // letters already placed
  List<String> _options = [];
  String? _wrongTapLetter;

  // words already used this session (avoid immediate repeats)
  final Set<String> _used = {};

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _shakeCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _newWord();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  int get _tier => _level <= 3 ? 3 : (_level <= 6 ? 4 : 5);
  int get _blanks => _level >= 9 ? 2 : 1;

  Map<int, List<(String, String)>> get _bank {
    final lang = context.read<AppProvider>().selectedLanguage;
    return lang == 'ms' ? _msWords : _enWords;
  }

  Set<String> get _allWords => {
        for (final tier in _enWords.values) ...tier.map((w) => w.$2),
        for (final tier in _msWords.values) ...tier.map((w) => w.$2),
      };

  void _newWord() {
    final list = List.of(_bank[_tier] ?? _bank[3]!);
    list.removeWhere((w) => _used.contains(w.$2));
    if (list.isEmpty) {
      _used.clear();
      list.addAll(_bank[_tier] ?? _bank[3]!);
    }
    final pick = list[_rand.nextInt(list.length)];
    _used.add(pick.$2);

    _emoji = pick.$1;
    _word = pick.$2;

    // choose hidden letter positions
    final idxs = List.generate(_word.length, (i) => i)..shuffle(_rand);
    _hiddenIndexes = idxs.take(min(_blanks, _word.length - 1)).toList()..sort();
    _fillPointer = 0;
    _filled = List<String?>.filled(_word.length, null);
    for (int i = 0; i < _word.length; i++) {
      if (!_hiddenIndexes.contains(i)) _filled[i] = _word[i];
    }
    _makeOptions();
    setState(() {});
  }

  void _makeOptions() {
    final correct = _word[_hiddenIndexes[_fillPointer]];
    final opts = <String>{correct};
    const alphabet = 'abcdefghijklmnopqrstuvwxyz';
    while (opts.length < 4) {
      final c = alphabet[_rand.nextInt(26)];
      if (opts.contains(c)) continue;
      // avoid a distractor that spells another real word (e.g. b_s: bus/bas)
      final chars = _word.split('');
      chars[_hiddenIndexes[_fillPointer]] = c;
      if (_allWords.contains(chars.join())) continue;
      opts.add(c);
    }
    _options = opts.toList()..shuffle(_rand);
  }

  void _onLetterTap(String letter) {
    if (_gameOver || _celebrating) return;
    final target = _word[_hiddenIndexes[_fillPointer]];
    if (letter == target) {
      SoundService.instance.star();
      setState(() {
        _filled[_hiddenIndexes[_fillPointer]] = letter;
        _wrongTapLetter = null;
      });
      if (_fillPointer < _hiddenIndexes.length - 1) {
        _fillPointer++;
        setState(_makeOptions);
        return;
      }
      // word complete
      _score += 10 * _level;
      _solvedInLevel++;
      if (_solvedInLevel >= 5) {
        SoundService.instance.win();
        _confetti.play();
        setState(() => _celebrating = true);
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (!mounted) return;
          setState(() {
            _level++;
            _solvedInLevel = 0;
            _celebrating = false;
          });
          _newWord();
        });
      } else {
        SoundService.instance.correct();
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) _newWord();
        });
      }
    } else {
      SoundService.instance.wrong();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _wrongTapLetter = letter;
        _lives--;
        if (_lives <= 0) _gameOver = true;
      });
    }
  }

  void _restart() {
    setState(() {
      _level = 1;
      _score = 0;
      _lives = 3;
      _solvedInLevel = 0;
      _gameOver = false;
      _used.clear();
    });
    _newWord();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppProvider>().t;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(t),
                _buildPrompt(t),
                Expanded(child: _buildWordArea()),
                _buildOptions(),
                const SizedBox(height: 24),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 25,
                colors: const [_kOrange, Color(0xFF7B6EC8), Color(0xFF6BBF6F), Color(0xFFF5C842)],
              ),
            ),
            if (_gameOver) _buildGameOver(t),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String Function(String, String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          BouncyButton(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: _kOrange.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_rounded, color: _kOrange, size: 22),
            ),
          ),
          Expanded(
            child: Text(
              t('Level $_level', 'Tahap $_level'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: _kOrange),
            ),
          ),
          ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(Icons.favorite_rounded,
                    color: i < _lives ? Colors.red : Colors.grey.shade300, size: 20),
              )),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kOrange, Color(0xFFF4A44A)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              const Text('⭐', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$_score',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt(String Function(String, String) t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFF4A44A)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _kOrange.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Text(
            t('Complete the word!', 'Lengkapkan perkataan!'),
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            t('$_solvedInLevel/5 words this level', '$_solvedInLevel/5 perkataan tahap ini'),
            style: const TextStyle(
                color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildWordArea() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        final dx = sin(_shakeCtrl.value * pi * 5) * 8 * (1 - _shakeCtrl.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 110)),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_word.length, (i) {
              final letter = _filled[i];
              final isActiveBlank =
                  letter == null && _hiddenIndexes[_fillPointer] == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 52,
                height: 62,
                decoration: BoxDecoration(
                  color: letter != null
                      ? Colors.white
                      : (isActiveBlank
                          ? _kOrange.withValues(alpha: 0.15)
                          : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActiveBlank ? _kOrange : Colors.grey.shade300,
                    width: isActiveBlank ? 3 : 2,
                  ),
                  boxShadow: [
                    if (letter != null)
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3)),
                  ],
                ),
                child: Center(
                  child: Text(
                    letter?.toUpperCase() ?? '_',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: letter != null ? _kOrange : Colors.grey.shade400,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _options.map((letter) {
          final isWrong = _wrongTapLetter == letter;
          return BouncyButton(
            onTap: () => _onLetterTap(letter),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: isWrong
                    ? const LinearGradient(colors: [Colors.redAccent, Colors.red])
                    : const LinearGradient(colors: [Color(0xFF7B6EC8), Color(0xFF5B4DA8)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF5B4DA8).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: Text(
                  letter.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGameOver(String Function(String, String) t) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.all(28),
          decoration:
              BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💪', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(t('Good try!', 'Cubaan yang baik!'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: _kOrange)),
              const SizedBox(height: 8),
              Text(
                t('Score: $_score  •  Level $_level', 'Skor: $_score  •  Tahap $_level'),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: BouncyButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFDEEE6),
                            borderRadius: BorderRadius.circular(16)),
                        child: Text(t('Exit', 'Keluar'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: _kOrange)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BouncyButton(
                      onTap: _restart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFF4A44A)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(t('Play Again', 'Main Lagi'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
