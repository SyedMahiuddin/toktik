class VideoModel {
  final String id;
  final String url;
  final String title;
  final String creator;
  final int likes;
  final int comments;
  final String thumbnailUrl;

  VideoModel({
    required this.id,
    required this.url,
    required this.title,
    required this.creator,
    this.likes = 0,
    this.comments = 0,
    this.thumbnailUrl = '',
  });

  VideoModel copyWith({
    String? id,
    String? url,
    String? title,
    String? creator,
    int? likes,
    int? comments,
    String? thumbnailUrl,
  }) {
    return VideoModel(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      creator: creator ?? this.creator,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}