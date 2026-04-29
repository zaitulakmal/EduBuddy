class WorksheetModel {
  final int? id;
  final String title;
  final String titleMs;
  final String subject;
  final int categoryId;
  final String ageGroup;
  final String grade;
  final String emoji;
  bool isCompleted;

  WorksheetModel({
    this.id,
    required this.title,
    required this.titleMs,
    required this.subject,
    required this.categoryId,
    required this.ageGroup,
    required this.grade,
    required this.emoji,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'title_ms': titleMs,
        'subject': subject,
        'category_id': categoryId,
        'age_group': ageGroup,
        'grade': grade,
        'emoji': emoji,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory WorksheetModel.fromMap(Map<String, dynamic> map) => WorksheetModel(
        id: map['id'],
        title: map['title'],
        titleMs: map['title_ms'],
        subject: map['subject'],
        categoryId: map['category_id'],
        ageGroup: map['age_group'],
        grade: map['grade'],
        emoji: map['emoji'],
        isCompleted: map['is_completed'] == 1,
      );
}
