class StorybookModel {
  final int? id;
  final String title;
  final String titleMs;
  final String description;
  final String coverEmoji;
  final int categoryId;
  final String ageGroup;
  final int pageCount;
  bool isRead;
  List<StorybookPage> pages;

  StorybookModel({
    this.id,
    required this.title,
    required this.titleMs,
    required this.description,
    required this.coverEmoji,
    required this.categoryId,
    required this.ageGroup,
    required this.pageCount,
    this.isRead = false,
    this.pages = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'title_ms': titleMs,
        'description': description,
        'cover_emoji': coverEmoji,
        'category_id': categoryId,
        'age_group': ageGroup,
        'page_count': pageCount,
        'is_read': isRead ? 1 : 0,
      };

  factory StorybookModel.fromMap(Map<String, dynamic> map) => StorybookModel(
        id: map['id'],
        title: map['title'],
        titleMs: map['title_ms'],
        description: map['description'],
        coverEmoji: map['cover_emoji'],
        categoryId: map['category_id'],
        ageGroup: map['age_group'],
        pageCount: map['page_count'],
        isRead: map['is_read'] == 1,
      );
}

class StorybookPage {
  final int? id;
  final int storybookId;
  final int pageNumber;
  final String text;
  final String textMs;
  final String backgroundEmoji;
  final String backgroundColor;

  const StorybookPage({
    this.id,
    required this.storybookId,
    required this.pageNumber,
    required this.text,
    required this.textMs,
    required this.backgroundEmoji,
    required this.backgroundColor,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'storybook_id': storybookId,
        'page_number': pageNumber,
        'text': text,
        'text_ms': textMs,
        'background_emoji': backgroundEmoji,
        'background_color': backgroundColor,
      };

  factory StorybookPage.fromMap(Map<String, dynamic> map) => StorybookPage(
        id: map['id'],
        storybookId: map['storybook_id'],
        pageNumber: map['page_number'],
        text: map['text'],
        textMs: map['text_ms'],
        backgroundEmoji: map['background_emoji'],
        backgroundColor: map['background_color'],
      );
}
