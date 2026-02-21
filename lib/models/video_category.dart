import 'video_item.dart';

/// Model representing a category of videos.
class VideoCategory {
  final String name;
  final List<VideoItem> videos;

  const VideoCategory({
    required this.name,
    required this.videos,
  });

  factory VideoCategory.fromJson(Map<String, dynamic> json) {
    return VideoCategory(
      name: json['name'] as String,
      videos: (json['videos'] as List<dynamic>)
          .map((v) => VideoItem.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}
