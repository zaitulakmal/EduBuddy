import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../models/badge_model.dart';
import '../../models/progression.dart';
import '../../providers/app_provider.dart';
import '../../services/sound_service.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/buddy_mascot.dart';
import '../../widgets/page_theme.dart';
import '../../widgets/reward_overlay.dart';

const _kBg = Color(0xFFFFF4E0);
const _kRed = Color(0xFFE85B5B);

/// Arithmetic practice for ages 5-10. Early levels show countable emoji
/// (3 apples + 2 apples); later levels move to plain numbers, subtraction,
/// then times tables. 5 questions per level, 3 lives.
class MathBlastScreen extends StatefulWidget {
  const MathBlastScreen({super.key});

  @override
  State<MathBlastScreen> createState() => _MathBlastScreenState();
}

class _Question {
  final int a;
  final int b;
  final String op; // '+', '−', '×'
  final int answer;
  final String emoji;
  _Question(this.a, this.b, this.op, this.answer, this.emoji);

  String get text => '$a $op $b = ?';
}

class _MathBlastScreenState extends State<MathBlastScreen>
    with TickerProviderStateMixin {
  final _rand = Random();
  late ConfettiController _confetti;
  late AnimationController _shakeCtrl;

  /// Key this game is stored under. Progress is keyed by game so each one
  /// resumes independently.
  static const _gameKey = 'math';

  int _level = 1;
  int _score = 0;
  int _lives = 3;
  int _solvedInLevel = 0;
  bool _gameOver = false;
  bool _celebrating = false;
  bool _answered = false;

  /// Until the stored level has been read, showing level 1 would flash the
  /// wrong number at a child who is really on level 9.
  bool _loadingProgress = true;

  _Question? _q;
  List<int> _options = [];
  int? _wrongTap;
  String? _lastQuestionText;

  static const _emojis = ['🍎', '🍌', '🍓', '⭐', '🎈', '🍪', '🐤', '🌸', '🚗', '⚽'];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _shakeCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _db = context.read<AppProvider>();
    SoundService.instance.playMusic('playful');
    _restoreProgress();
  }

  /// Picks up where the child left off. Before this existed the level reset to
  /// 1 on every launch, so a child who had reached level 9 lost all of it by
  /// closing the app — the fastest way to make them stop coming back.
  Future<void> _restoreProgress() async {
    var resume = 1;
    try {
      final stats = await context.read<AppProvider>().gameStats(_gameKey);
      resume = stats.resumeLevel.clamp(1, 99);
    } catch (_) {
      // Storage unavailable. Starting at level 1 is a worse experience than
      // resuming, but it is far better than refusing to open the game.
    }
    if (!mounted) return;
    setState(() {
      _level = resume;
      _loadingProgress = false;
    });
    _newQuestion();
  }

  @override
  void dispose() {
    // Most runs end by walking away rather than by finishing a level, so the
    // checkpoint is written on the way out too.
    _db.saveGameCheckpoint(_gameKey, level: _level, score: _score).catchError(
        (_) {});
    _confetti.dispose();
    _shakeCtrl.dispose();
    SoundService.instance.playMusic('calm');
    super.dispose();
  }

  /// Captured in [initState]: `context` cannot be read from [dispose], and a
  /// lazy `late final` would first evaluate there — too late.
  late final AppProvider _db;

  // ── Question generation ─────────────────────────────────────────────────────

  _Question _generate() {
    int a, b;
    switch (_level) {
      case 1: // addition, visual, sum <= 6
        a = 1 + _rand.nextInt(3);
        b = 1 + _rand.nextInt(3);
        return _Question(a, b, '+', a + b, _emojis[_rand.nextInt(_emojis.length)]);
      case 2: // addition, visual, sum <= 10
        a = 2 + _rand.nextInt(4);
        b = 1 + _rand.nextInt(5);
        return _Question(a, b, '+', a + b, _emojis[_rand.nextInt(_emojis.length)]);
      case 3: // subtraction, visual, within 8
        a = 3 + _rand.nextInt(6);
        b = 1 + _rand.nextInt(a - 1);
        return _Question(a, b, '−', a - b, _emojis[_rand.nextInt(_emojis.length)]);
      case 4: // addition to 20, numbers
        a = 5 + _rand.nextInt(10); // 5..14
        b = 3 + _rand.nextInt(18 - a); // sum capped at 20
        return _Question(a, b, '+', a + b, '');
      case 5: // subtraction within 20, numbers
        a = 8 + _rand.nextInt(12);
        b = 2 + _rand.nextInt(a - 3);
        return _Question(a, b, '−', a - b, '');
      case 6: // addition to 50
        a = 10 + _rand.nextInt(30); // 10..39
        b = 5 + _rand.nextInt(46 - a); // sum capped at 50
        return _Question(a, b, '+', a + b, '');
      case 7: // times tables 2,3,4,5
        a = [2, 3, 4, 5][_rand.nextInt(4)];
        b = 1 + _rand.nextInt(9);
        return _Question(a, b, '×', a * b, '');
      case 8: // times tables up to 7
        a = 2 + _rand.nextInt(6);
        b = 2 + _rand.nextInt(9);
        return _Question(a, b, '×', a * b, '');
      default: // mixed hard
        final pick = _rand.nextInt(3);
        if (pick == 0) {
          a = 15 + _rand.nextInt(60);
          b = 10 + _rand.nextInt(30);
          return _Question(a, b, '+', a + b, '');
        } else if (pick == 1) {
          a = 20 + _rand.nextInt(60);
          b = 5 + _rand.nextInt(a - 10);
          return _Question(a, b, '−', a - b, '');
        }
        a = 3 + _rand.nextInt(7);
        b = 3 + _rand.nextInt(10);
        return _Question(a, b, '×', a * b, '');
    }
  }

  void _newQuestion() {
    _Question q;
    var guard = 0;
    do {
      q = _generate();
      guard++;
    } while (q.text == _lastQuestionText && guard < 10);
    _lastQuestionText = q.text;
    _q = q;
    _answered = false;
    _wrongTap = null;

    // 4 unique options: the answer + close distractors (never negative)
    final opts = <int>{q.answer};
    final near = <int>[
      q.answer + 1, q.answer - 1, q.answer + 2, q.answer - 2,
      q.answer + 10, q.answer - 10, q.a, q.b, q.a + q.b, (q.a - q.b).abs(),
    ]..shuffle(_rand);
    for (final n in near) {
      if (opts.length >= 4) break;
      if (n >= 0 && !opts.contains(n)) opts.add(n);
    }
    while (opts.length < 4) {
      final n = q.answer + 3 + _rand.nextInt(7);
      opts.add(n);
    }
    _options = opts.toList()..shuffle(_rand);
    setState(() {});
  }

  void _onAnswer(int value) {
    if (_gameOver || _celebrating || _answered || _q == null) return;
    if (value == _q!.answer) {
      _answered = true;
      _score += 10 * _level;
      _solvedInLevel++;
      if (_solvedInLevel >= 5) {
        SoundService.instance.win();
        _confetti.play();
        setState(() => _celebrating = true);
        _completeLevel();
      } else {
        SoundService.instance.correct();
        setState(() {});
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) _newQuestion();
        });
      }
    } else {
      // Re-tapping the already-marked wrong tile must not drain more lives
      // (kids double-tap a lot).
      if (value == _wrongTap) return;
      SoundService.instance.wrong();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _wrongTap = value;
        _lives--;
        if (_lives <= 0) _gameOver = true;
      });
    }
  }

  /// Banks a cleared level: records it, pays the stars it earned, and shows the
  /// celebration when there is something new to celebrate.
  Future<void> _completeLevel() async {
    final provider = context.read<AppProvider>();
    final cleared = _level;

    // Lives run across the whole session, so arriving at a level end with all
    // three means an unbroken run — that is what the perfect bonus pays for.
    GameReward? reward;
    var newBadges = <BadgeModel>[];
    try {
      reward = await provider.recordGameLevel(
        gameKey: _gameKey,
        level: cleared,
        rating: _lives,
        perfect: _lives >= 3,
        score: _score,
      );
      newBadges = List.of(provider.newlyEarnedBadges);
    } catch (_) {
      // Never let a storage failure strand a child on the celebration screen.
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() {
      _level = cleared + 1;
      _solvedInLevel = 0;
      _celebrating = false;
    });
    _newQuestion();
    unawaited(provider
        .saveGameCheckpoint(_gameKey, level: _level, score: _score)
        .catchError((_) {}));

    if (!mounted) return;
    // Replaying a level already beaten pays nothing, and a modal with nothing
    // in it is just an interruption — so only celebrate a real reward.
    if ((reward?.paid ?? false) || newBadges.isNotEmpty) {
      final t = provider.t;
      await showRewardSheet(
        context,
        title: t('Level $cleared complete!', 'Tahap $cleared selesai!'),
        subtitle: (reward?.perfectStars ?? 0) > 0
            ? t('No lives lost — perfect!', 'Tiada nyawa hilang — sempurna!')
            : null,
        stars: reward?.total ?? 0,
        badges: newBadges,
        buddy: buddyVariantFromId(provider.userAvatar),
        hat: provider.buddyHat,
        accessory: provider.buddyAccessory,
      );
    }
  }

  void _restart() {
    setState(() {
      // Retry the level they were on rather than sending them back to the
      // start — the levels they already cleared stay cleared.
      _score = 0;
      _lives = 3;
      _solvedInLevel = 0;
      _gameOver = false;
      _lastQuestionText = null;
    });
    _newQuestion();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppProvider>().t;
    if (_loadingProgress) {
      // The stored level is read asynchronously; painting the board first
      // would flash level 1 at a child who is really on level 9.
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(t),
                _buildPrompt(t),
                Expanded(child: _buildQuestion()),
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
                colors: const [_kRed, Color(0xFF7B6EC8), Color(0xFF6BBF6F), Color(0xFFF5C842)],
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
          if (Navigator.of(context).canPop())
            BouncyButton(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, color: _kRed, size: 22),
              ),
            ),
          BuddyMascot(size: 42, variant: PagePalette.mathBlast.buddy, animation: PagePalette.mathBlast.anim),
          Expanded(
            child: Text(
              t('Level $_level', 'Tahap $_level'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: _kRed),
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
              gradient: const LinearGradient(colors: [_kRed, Color(0xFFF4A44A)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: Colors.white, size: 15),
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
        gradient: const LinearGradient(colors: [_kRed, Color(0xFFF4A44A)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _kRed.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Text(
            t('Solve it!', 'Kira!'),
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            t('$_solvedInLevel/5 this level', '$_solvedInLevel/5 tahap ini'),
            style: const TextStyle(
                color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  /// One emoji per unit, wrapped, so kids can count them.
  Widget _emojiGroup(int count, String emoji, {int crossedOut = 0}) {
    return SizedBox(
      width: count > 3 ? 132 : 44.0 * count,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: List.generate(count, (i) {
          final crossed = i >= count - crossedOut;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: crossed ? 0.35 : 1,
                child: Text(emoji, style: const TextStyle(fontSize: 34)),
              ),
              if (crossed)
                const Text('✖',
                    style: TextStyle(
                        fontSize: 26,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w900)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _q;
    if (q == null) return const SizedBox();
    final visual = q.emoji.isNotEmpty && q.a <= 8 && q.b <= 8;

    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        final dx = sin(_shakeCtrl.value * pi * 5) * 8 * (1 - _shakeCtrl.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (visual && q.op == '+') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _emojiGroup(q.a, q.emoji),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('+',
                        style: TextStyle(
                            fontSize: 40, fontWeight: FontWeight.w900, color: _kRed)),
                  ),
                  _emojiGroup(q.b, q.emoji),
                ],
              ),
              const SizedBox(height: 20),
            ] else if (visual && q.op == '−') ...[
              // show a items with b crossed out
              _emojiGroup(q.a, q.emoji, crossedOut: q.b),
              const SizedBox(height: 20),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  q.text,
                  style: TextStyle(
                    fontSize: visual ? 34 : 52,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4A4A5A),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: LayoutBuilder(builder: (context, c) {
        // Deliberate 2x2 grid: two big buttons per row — easy targets for kids
        final btnW = (c.maxWidth - 14) / 2;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: _options.map((n) {
            final isWrong = _wrongTap == n;
            final isRight = _answered && n == _q?.answer;
            return BouncyButton(
              onTap: () => _onAnswer(n),
              child: Container(
                width: btnW,
                height: 64,
              decoration: BoxDecoration(
                gradient: isWrong
                    ? const LinearGradient(colors: [Colors.redAccent, Colors.red])
                    : isRight
                        ? const LinearGradient(
                            colors: [Color(0xFF6BBF6F), Color(0xFF43A047)])
                        : const LinearGradient(
                            colors: [Color(0xFF7B6EC8), Color(0xFF5B4DA8)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF5B4DA8).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4)),
                ],
              ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$n',
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
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
              const Icon(Icons.sentiment_very_satisfied_rounded, color: _kRed, size: 56),
              const SizedBox(height: 8),
              Text(t('Good try!', 'Cubaan yang baik!'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: _kRed)),
              const SizedBox(height: 8),
              Text(
                t('Score: $_score  •  Level $_level', 'Skor: $_score  •  Tahap $_level'),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
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
                                  fontWeight: FontWeight.w800, color: _kRed)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: BouncyButton(
                      onTap: _restart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_kRed, Color(0xFFF4A44A)]),
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
