import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../models/quiz_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bouncy_button.dart';

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

  late AnimationController _cardCtrl;
  late Animation<double> _cardScale;
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _cardScale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.elasticOut));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 0), weight: 1),
    ]).animate(_shakeCtrl);
    _confettiCtrl =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions =
        await widget.provider.loadQuizQuestions(widget.quiz.id!);
    setState(() => _questions = questions);
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _shakeCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    final correct = _questions[_currentIndex].correctIndex == index;

    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (correct) _score++;
    });

    if (correct) {
      _confettiCtrl.play();
    } else {
      _shakeCtrl.forward(from: 0);
    }

    Future.delayed(const Duration(milliseconds: 1500), _next);
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
      _cardCtrl.forward(from: 0);
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    widget.provider.saveQuizScore(widget.quiz.id!, _score);
    setState(() => _quizDone = true);
    _confettiCtrl.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _quizDone ? _buildResult() : _buildQuiz(),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.teal,
                AppColors.purple,
                AppColors.pink,
              ],
              numberOfParticles: 40,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                BouncyButton(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.purple, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_currentIndex + 1} / ${_questions.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.secondary, size: 18),
                              Text(
                                ' $_score',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.secondary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.purple),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Question card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ScaleTransition(
                scale: _cardScale,
                child: AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(_shake.value, 0),
                    child: child,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.quiz.emoji,
                            style: const TextStyle(fontSize: 60)),
                        const SizedBox(height: 16),
                        Text(
                          q.question,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Answer options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(q.options.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AnswerOption(
                    text: q.options[i],
                    index: i,
                    selectedIndex: _selectedAnswer,
                    correctIndex: q.correctIndex,
                    answered: _answered,
                    onTap: () => _selectAnswer(i),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final total = _questions.length;
    final percent = _score / total;
    String emoji;
    String message;
    if (percent == 1.0) {
      emoji = '🏆';
      message = 'Perfect Score! You\'re Amazing!';
    } else if (percent >= 0.6) {
      emoji = '⭐';
      message = 'Great Job! Keep it up!';
    } else {
      emoji = '💪';
      message = 'Good Try! Practice more!';
    }

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)]),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Score',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_score / $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '⭐ Stars earned!',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: BouncyButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: AppColors.purple.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '← Back',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: BouncyButton(
                      onTap: () {
                        setState(() {
                          _currentIndex = 0;
                          _selectedAnswer = null;
                          _answered = false;
                          _score = 0;
                          _quizDone = false;
                        });
                        _cardCtrl.forward(from: 0);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '🔄 Try Again',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
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

class _AnswerOption extends StatelessWidget {
  final String text;
  final int index;
  final int? selectedIndex;
  final int correctIndex;
  final bool answered;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.text,
    required this.index,
    required this.selectedIndex,
    required this.correctIndex,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade200;
    Color textColor = AppColors.textDark;
    Widget? trailingIcon;

    if (answered) {
      if (index == correctIndex) {
        bgColor = AppColors.success.withOpacity(0.12);
        borderColor = AppColors.success;
        textColor = AppColors.success;
        trailingIcon = const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 24);
      } else if (index == selectedIndex && index != correctIndex) {
        bgColor = AppColors.error.withOpacity(0.12);
        borderColor = AppColors.error;
        textColor = AppColors.error;
        trailingIcon = const Icon(Icons.cancel_rounded,
            color: AppColors.error, size: 24);
      }
    }

    final letters = ['A', 'B', 'C', 'D'];

    return BouncyButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text(
                  letters[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }
}
