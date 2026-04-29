class VideoModel {
  final int? id;
  final String title;
  final String titleMs;
  final String description;
  final int categoryId;
  final String ageGroup;
  final String duration;
  final String thumbnailEmoji;
  final String videoUrl;
  final bool isDownloaded;
  bool isWatched;

  VideoModel({
    this.id,
    required this.title,
    required this.titleMs,
    required this.description,
    required this.categoryId,
    required this.ageGroup,
    required this.duration,
    required this.thumbnailEmoji,
    required this.videoUrl,
    this.isDownloaded = false,
    this.isWatched = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'title_ms': titleMs,
        'description': description,
        'category_id': categoryId,
        'age_group': ageGroup,
        'duration': duration,
        'thumbnail_emoji': thumbnailEmoji,
        'video_url': videoUrl,
        'is_downloaded': isDownloaded ? 1 : 0,
        'is_watched': isWatched ? 1 : 0,
      };

  factory VideoModel.fromMap(Map<String, dynamic> map) => VideoModel(
        id: map['id'],
        title: map['title'],
        titleMs: map['title_ms'],
        description: map['description'],
        categoryId: map['category_id'],
        ageGroup: map['age_group'],
        duration: map['duration'],
        thumbnailEmoji: map['thumbnail_emoji'],
        videoUrl: map['video_url'],
        isDownloaded: map['is_downloaded'] == 1,
        isWatched: map['is_watched'] == 1,
      );
}
