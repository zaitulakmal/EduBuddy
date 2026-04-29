class BadgeModel {
  final int? id;
  final String name;
  final String nameMs;
  final String description;
  final String emoji;
  final String requirement;
  final int requiredCount;
  bool isEarned;
  String? earnedDate;

  BadgeModel({
    this.id,
    required this.name,
    required this.nameMs,
    required this.description,
    required this.emoji,
    required this.requirement,
    required this.requiredCount,
    this.isEarned = false,
    this.earnedDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'name_ms': nameMs,
        'description': description,
        'emoji': emoji,
        'requirement': requirement,
        'required_count': requiredCount,
        'is_earned': isEarned ? 1 : 0,
        'earned_date': earnedDate,
      };

  factory BadgeModel.fromMap(Map<String, dynamic> map) => BadgeModel(
        id: map['id'],
        name: map['name'],
        nameMs: map['name_ms'],
        description: map['description'],
        emoji: map['emoji'],
        requirement: map['requirement'],
        requiredCount: map['required_count'],
        isEarned: map['is_earned'] == 1,
        earnedDate: map['earned_date'],
      );
}
