class QuizModel {
  final int? id;
  final String title;
  final String titleMs;
  final int categoryId;
  final String ageGroup;
  final String emoji;
  int highScore;
  bool isCompleted;
  List<QuizQuestion> questions;

  QuizModel({
    this.id,
    required this.title,
    required this.titleMs,
    required this.categoryId,
    required this.ageGroup,
    required this.emoji,
    this.highScore = 0,
    this.isCompleted = false,
    this.questions = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'title_ms': titleMs,
        'category_id': categoryId,
        'age_group': ageGroup,
        'emoji': emoji,
        'high_score': highScore,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory QuizModel.fromMap(Map<String, dynamic> map) => QuizModel(
        id: map['id'],
        title: map['title'],
        titleMs: map['title_ms'],
        categoryId: map['category_id'],
        ageGroup: map['age_group'],
        emoji: map['emoji'],
        highScore: map['high_score'] ?? 0,
        isCompleted: map['is_completed'] == 1,
      );
}

class QuizQuestion {
  final int? id;
  final int quizId;
  final String question;
  final String questionMs;
  final List<String> options;
  final List<String> optionsMs;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    this.id,
    required this.quizId,
    required this.question,
    required this.questionMs,
    required this.options,
    required this.optionsMs,
    required this.correctIndex,
    this.explanation = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'quiz_id': quizId,
        'question': question,
        'question_ms': questionMs,
        'options': options.join('|'),
        'options_ms': optionsMs.join('|'),
        'correct_index': correctIndex,
        'explanation': explanation,
      };

  factory QuizQuestion.fromMap(Map<String, dynamic> map) => QuizQuestion(
        id: map['id'],
        quizId: map['quiz_id'],
        question: map['question'],
        questionMs: map['question_ms'],
        options: (map['options'] as String).split('|'),
        optionsMs: (map['options_ms'] as String).split('|'),
        correctIndex: map['correct_index'],
        explanation: map['explanation'] ?? '',
      );
}
