import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/quiz_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/bouncy_button.dart';

// ── Reference-matched palette ─────────────────────────────────────────────────
const _kBgOrange    = Color(0xFFE8784A);
const _kHeaderGreen = Color(0xFF7B8C3A);
const _kProgressBar = Color(0xFF8B78C8);
const _kCream       = Color(0xFFF5E8C0);
const _kCreamDark   = Color(0xFFE8D4A0);
const _kBlobYellow  = Color(0xFFF5C842);
const _kBlobOrange  = Color(0xFFE8784A);
const _kBlobPurple  = Color(0xFF9B8BBF);
const _kBlobGreen   = Color(0xFF7B8C3A);
const _kCorrect     = Color(0xFF6BBF6F);
const _kWrong       = Color(0xFFE85A5A);

class QuizPlayScreen extends StatefulWidget {
  final QuizModel quiz;
  final AppProvider provider;

  const QuizPlayScreen({super.key, required this.quiz, required this.provider});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen>
    with TickerProviderStateMixin {
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _quizDone = false;
  int _streak = 0;
  int _maxStreak = 0;
  bool _timedOut = false;

  late AnimationController _cardCtrl;
  late Animation<double> _cardScale;
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;
  late AnimationController _timerCtrl;
  late AnimationController _scorePopCtrl;
  late Animation<double> _scorePop;
  late AnimationController _monsterBounce;
  late Animation<double> _monsterAnim;
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;
  late ConfettiController _confettiCtrl;

  static const _timerSeconds = 35;

  @override
  void initState() {
    super.initState();

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _cardScale = Tween<double>(begin: 0.82, end: 1.0).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut));

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 12), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 12, end: -12), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -12, end: 0), weight: 1),
    ]).animate(_shakeCtrl);

    _timerCtrl = AnimationController(vsync: this, duration: Duration(seconds: _timerSeconds));
    _timerCtrl.addStatusListener(_onTimerDone);

    _scorePopCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scorePop = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.4, end: 0).chain(CurveTween(curve: Curves.easeIn)), weight: 1),
    ]).animate(_scorePopCtrl);

    _monsterBounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _monsterAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
        CurvedAnimation(parent: _monsterBounce, curve: Curves.elasticOut));

    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final qs = await widget.provider.loadQuizQuestions(widget.quiz.id!);
    setState(() => _questions = qs);
    _cardCtrl.forward();
    _timerCtrl.forward(from: 0);
  }

  void _onTimerDone(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_answered) {
      setState(() { _answered = true; _timedOut = true; _streak = 0; });
      _shakeCtrl.forward(from: 0);
      _monsterBounce.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1800), _next);
    }
  }

  @override
  void dispose() {
    _cardCtrl.dispose(); _shakeCtrl.dispose(); _timerCtrl.dispose();
    _scorePopCtrl.dispose(); _monsterBounce.dispose(); _floatCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timerCtrl.stop();
    final correct = _questions[_currentIndex].correctIndex == index;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      _timedOut = false;
      if (correct) {
        _score++;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
      } else {
        _streak = 0;
      }
    });
    _monsterBounce.forward(from: 0);
    if (correct) {
      _confettiCtrl.play();
      _scorePopCtrl.forward(from: 0);
    } else {
      _shakeCtrl.forward(from: 0);
    }
    Future.delayed(const Duration(milliseconds: 1900), _next);
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
        _timedOut = false;
      });
      _cardCtrl.forward(from: 0);
      _timerCtrl.forward(from: 0);
    } else {
      _timerCtrl.stop();
      widget.provider.saveQuizScore(widget.quiz.id!, _score);
      setState(() => _quizDone = true);
      _confettiCtrl.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        backgroundColor: _kBgOrange,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: _kBgOrange,
      body: Stack(
        children: [
          _quizDone ? _buildResult() : _buildQuiz(),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [_kBlobYellow, _kBgOrange, _kBlobPurple, _kBlobGreen, Colors.white],
              numberOfParticles: 50,
              gravity: 0.28,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quiz Layout ──────────────────────────────────────────────────────────

  Widget _buildQuiz() {
    final q = _questions[_currentIndex];
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildProgressBar(),
          Expanded(child: _buildQuestionCard(q)),
          _buildAnswerGrid(q),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Olive-green top bar matching reference
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: _kHeaderGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          // Back button — white circle
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.quiz.title,
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Help button — white circle
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.question_mark_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentIndex + 1) / _questions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation(_kProgressBar),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Question ${_currentIndex + 1} of ${_questions.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion q) {
    final displayEmoji = q.emoji.isNotEmpty ? q.emoji : widget.quiz.emoji;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: ScaleTransition(
        scale: _cardScale,
        child: AnimatedBuilder(
          animation: _shake,
          builder: (_, child) => Transform.translate(offset: Offset(_shake.value, 0), child: child),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Question-relevant emoji graphic
                AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: child,
                  ),
                  child: ScaleTransition(
                    scale: _monsterAnim,
                    child: _QuestionGraphic(
                      emoji: _timedOut ? '⏰' : displayEmoji,
                      categoryId: widget.quiz.categoryId,
                      answered: _answered,
                      correct: _answered && !_timedOut && _selectedAnswer == q.correctIndex,
                      timedOut: _timedOut,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Question text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _timedOut
                      ? const Text(
                          '⏰ Time\'s up!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _kBgOrange),
                          textAlign: TextAlign.center,
                        )
                      : Text(
                          q.question,
                          style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: Color(0xFF3D3D3D), height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                // +1 star pop
                AnimatedBuilder(
                  animation: _scorePopCtrl,
                  builder: (_, _) {
                    if (_scorePop.value == 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.scale(
                        scale: _scorePop.value,
                        child: const Text('⭐ +1', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _kBlobYellow)),
                      ),
                    );
                  },
                ),
                // Streak badge
                if (_streak >= 3 && _answered)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kBgOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🔥 $_streak in a row!',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: _kBgOrange),
                      ),
                    ),
                  ),
                // Timer bar at bottom of card
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: AnimatedBuilder(
                    animation: _timerCtrl,
                    builder: (_, _) {
                      final remaining = 1.0 - _timerCtrl.value;
                      final Color c = remaining > 0.6 ? _kBlobGreen : remaining > 0.3 ? _kBlobYellow : _kWrong;
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: remaining,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFEEEEEE),
                              valueColor: AlwaysStoppedAnimation(c),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_timerSeconds * remaining).round()}s',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerGrid(QuizQuestion q) {
    final opts = q.options;
    final pairs = <List<int>>[];
    for (int i = 0; i < opts.length; i += 2) {
      pairs.add([i, if (i + 1 < opts.length) i + 1]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: pairs.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: row.map((i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: row.indexOf(i) == 0 ? 0 : 8),
                child: _AnswerPill(
                  text: opts[i],
                  index: i,
                  selectedIndex: _selectedAnswer,
                  correctIndex: q.correctIndex,
                  answered: _answered,
                  onTap: () => _selectAnswer(i),
                ),
              ),
            )).toList(),
          ),
        )).toList(),
      ),
    );
  }

  // ─── Score / Result Screen ────────────────────────────────────────────────

  Widget _buildResult() {
    final total = _questions.length;
    final percent = _score / total;
    final int stars = percent >= 0.8 ? 5 : percent >= 0.6 ? 4 : percent >= 0.4 ? 3 : percent >= 0.2 ? 2 : 1;

    return Stack(
      children: [
        // Blob background
        Positioned.fill(
          child: CustomPaint(painter: _BlobBackgroundPainter()),
        ),
        SafeArea(
          child: Column(
            children: [
              // Title bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Your Score',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.question_mark_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // White circle with monster + score
              Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          Icons.star_rounded,
                          color: i < stars ? const Color(0xFFFFCC00) : Colors.grey.shade200,
                          size: 22,
                        ),
                      )),
                    ),
                    const SizedBox(height: 8),
                    // Score monster (orange one-eyed)
                    SizedBox(
                      width: 80, height: 80,
                      child: CustomPaint(painter: _ScoreMonsterPainter()),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_score/$total',
                      style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF3D3D3D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Message
              Text(
                percent >= 0.8 ? 'Amazing! 🎉' : percent >= 0.5 ? 'Well done! 👍' : 'Keep trying! 💪',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              if (_maxStreak >= 3)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '🔥 Best streak: $_maxStreak',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              const Spacer(),
              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: BouncyButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                          ),
                          child: const Center(
                            child: Text('← Back', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: BouncyButton(
                        onTap: () {
                          setState(() {
                            _currentIndex = 0; _selectedAnswer = null;
                            _answered = false; _score = 0; _streak = 0;
                            _maxStreak = 0; _quizDone = false; _timedOut = false;
                          });
                          _cardCtrl.forward(from: 0);
                          _timerCtrl.forward(from: 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: Text('🔄 Try Again', style: TextStyle(color: _kBgOrange, fontSize: 16, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Answer Pill (cream, 2×2 grid style) ─────────────────────────────────────

class _AnswerPill extends StatelessWidget {
  final String text;
  final int index;
  final int? selectedIndex;
  final int correctIndex;
  final bool answered;
  final VoidCallback onTap;

  const _AnswerPill({
    required this.text, required this.index, required this.selectedIndex,
    required this.correctIndex, required this.answered, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = _kCream;
    Color textColor = const Color(0xFF5A4A2A);
    Color border = Colors.transparent;
    Widget? icon;

    if (answered) {
      if (index == correctIndex) {
        bg = _kCorrect;
        textColor = Colors.white;
        border = _kCorrect;
        icon = const Icon(Icons.check_rounded, color: Colors.white, size: 20);
      } else if (index == selectedIndex) {
        bg = _kWrong;
        textColor = Colors.white;
        border = _kWrong;
        icon = const Icon(Icons.close_rounded, color: Colors.white, size: 20);
      } else {
        bg = _kCreamDark;
        textColor = const Color(0xFF8A7A5A);
      }
    }

    return BouncyButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border, width: 2.5),
          boxShadow: answered
              ? []
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            if (icon != null) ...[const SizedBox(width: 4), icon],
          ],
        ),
      ),
    );
  }
}

// ─── Blob background painter (score screen) ───────────────────────────────────

class _BlobBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Base background — yellow-orange
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = _kBlobYellow,
    );

    // Orange blob top-right
    final topRight = Path();
    topRight.moveTo(w * 0.55, 0);
    topRight.cubicTo(w * 0.9, 0, w, h * 0.05, w, h * 0.3);
    topRight.cubicTo(w, h * 0.42, w * 0.85, h * 0.38, w * 0.72, h * 0.25);
    topRight.cubicTo(w * 0.62, h * 0.15, w * 0.5, h * 0.08, w * 0.55, 0);
    canvas.drawPath(topRight, Paint()..color = _kBlobOrange);

    // Purple blob bottom-left
    final botLeft = Path();
    botLeft.moveTo(0, h * 0.72);
    botLeft.cubicTo(0, h * 0.58, w * 0.18, h * 0.55, w * 0.3, h * 0.65);
    botLeft.cubicTo(w * 0.38, h * 0.72, w * 0.32, h * 0.88, w * 0.15, h * 0.95);
    botLeft.cubicTo(w * 0.05, h, 0, h, 0, h);
    botLeft.lineTo(0, h * 0.72);
    canvas.drawPath(botLeft, Paint()..color = _kBlobPurple);

    // Green blob bottom-right
    final botRight = Path();
    botRight.moveTo(w * 0.72, h);
    botRight.cubicTo(w * 0.85, h * 0.92, w, h * 0.88, w, h * 0.75);
    botRight.cubicTo(w, h * 0.65, w * 0.88, h * 0.68, w * 0.78, h * 0.78);
    botRight.cubicTo(w * 0.7, h * 0.86, w * 0.65, h * 0.95, w * 0.72, h);
    canvas.drawPath(botRight, Paint()..color = _kBlobGreen);
  }

  @override
  bool shouldRepaint(_BlobBackgroundPainter _) => false;
}

// ─── Question Graphic (emoji-based, relevant to question topic) ───────────────

class _QuestionGraphic extends StatelessWidget {
  final String emoji;
  final int categoryId;
  final bool answered;
  final bool correct;
  final bool timedOut;

  const _QuestionGraphic({
    required this.emoji,
    required this.categoryId,
    required this.answered,
    required this.correct,
    required this.timedOut,
  });

  static const _palette = [
    Color(0xFF7B8C3A), // olive green
    Color(0xFF5BA8E8), // sky blue
    Color(0xFF9B8BBF), // purple
    Color(0xFFE8784A), // orange
    Color(0xFF4ECDC4), // teal
    Color(0xFFE87A50), // red-orange
    Color(0xFF6BBF6F), // green
    Color(0xFFF5C842), // yellow
  ];

  Color get _bubbleColor {
    if (answered && !timedOut) return correct ? _kCorrect : _kWrong;
    return _palette[categoryId % _palette.length];
  }

  static String _emojiToAssetPath(String emoji) {
    final runes = emoji.runes
        .where((r) => r != 0xFE0F && r != 0x200D)
        .toList();
    if (runes.isEmpty) return '';
    final hex = runes.map((r) => r.toRadixString(16).toUpperCase()).join('-');
    return 'assets/images/openmoji/$hex.svg';
  }

  @override
  Widget build(BuildContext context) {
    final c = _bubbleColor;
    return SizedBox(
      width: 180, height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft background circle (like Pinterest style)
          Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: c.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          // Large flat illustration filling the circle
          Padding(
            padding: const EdgeInsets.all(24),
            child: SvgPicture.asset(
              _emojiToAssetPath(emoji),
              fit: BoxFit.contain,
              placeholderBuilder: (_) => Text(
                emoji,
                style: const TextStyle(fontSize: 60),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Feedback badge
          if (answered && !timedOut)
            Positioned(
              bottom: 6, right: 6,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: correct ? _kCorrect : _kWrong,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Icon(
                  correct ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white, size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Score screen monster (orange one-eyed winged) ────────────────────────────

class _ScoreMonsterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height * 0.52;
    final r = size.shortestSide * 0.42;

    // Wings
    final wingPaint = Paint()..color = const Color(0xFFFF9955);
    final leftWing = Path()
      ..moveTo(cx - r * 0.6, cy)
      ..cubicTo(cx - r * 1.6, cy - r * 0.5, cx - r * 1.5, cy + r * 0.5, cx - r * 0.6, cy + r * 0.3)
      ..close();
    final rightWing = Path()
      ..moveTo(cx + r * 0.6, cy)
      ..cubicTo(cx + r * 1.6, cy - r * 0.5, cx + r * 1.5, cy + r * 0.5, cx + r * 0.6, cy + r * 0.3)
      ..close();
    canvas.drawPath(leftWing, wingPaint);
    canvas.drawPath(rightWing, wingPaint);

    // Body — orange
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.6, height: r * 1.8),
        Paint()..color = const Color(0xFFE8784A));

    // Horn
    final horn = Path()
      ..moveTo(cx - r * 0.12, cy - r * 0.85)
      ..lineTo(cx, cy - r * 1.2)
      ..lineTo(cx + r * 0.12, cy - r * 0.85)
      ..close();
    canvas.drawPath(horn, Paint()..color = const Color(0xFFFF9955));

    // Single eye
    canvas.drawCircle(Offset(cx, cy - r * 0.1), r * 0.38, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx, cy - r * 0.1), r * 0.22, Paint()..color = const Color(0xFF222222));
    canvas.drawCircle(Offset(cx + r * 0.08, cy - r * 0.18), r * 0.08, Paint()..color = Colors.white);

    // Grinning mouth
    final mp = Path()
      ..moveTo(cx - r * 0.35, cy + r * 0.28)
      ..quadraticBezierTo(cx, cy + r * 0.55, cx + r * 0.35, cy + r * 0.28);
    canvas.drawPath(mp, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);

    // Tiny legs
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.25, cy + r * 0.94), width: r * 0.28, height: r * 0.2), Paint()..color = const Color(0xFFE8784A));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + r * 0.25, cy + r * 0.94), width: r * 0.28, height: r * 0.2), Paint()..color = const Color(0xFFE8784A));
  }

  @override
  bool shouldRepaint(_ScoreMonsterPainter _) => false;
}
