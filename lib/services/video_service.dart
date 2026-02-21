import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/video_category.dart';
import '../models/video_item.dart';

/// Service responsible for loading video data from JSON assets.
/// Acts as the data layer in MVVM architecture.
class VideoService {
  static const String _assetPath = 'assets/data/videos.json';

  /// Loads video categories from the bundled JSON asset.
  Future<List<VideoCategory>> loadCategories() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final categoriesList = jsonData['categories'] as List<dynamic>;

      return categoriesList
          .map((c) => VideoCategory.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return default data if JSON loading fails
      return _defaultCategories();
    }
  }

  /// Returns all videos from all categories as a flat list.
  Future<List<VideoItem>> loadAllVideos() async {
    final categories = await loadCategories();
    return categories.expand((c) => c.videos).toList();
  }

  /// Fallback data if asset loading fails.
  List<VideoCategory> _defaultCategories() {
    return [
      VideoCategory(
        name: 'Trending',
        videos: [
          const VideoItem(
            id: 'v1',
            title: 'Big Buck Bunny',
            description: 'A large and lovable rabbit deals with three tiny bullies.',
            thumbnailUrl:
                'https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            category: 'Trending',
            duration: Duration(seconds: 596),
          ),
          const VideoItem(
            id: 'v2',
            title: 'Elephant Dream',
            description: 'The world\'s first open movie.',
            thumbnailUrl:
                'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            category: 'Trending',
            duration: Duration(seconds: 653),
          ),
        ],
      ),
      VideoCategory(
        name: 'Action',
        videos: [
          const VideoItem(
            id: 'v3',
            title: 'For Bigger Blazes',
            description: 'HBO GO now works with Chromecast.',
            thumbnailUrl:
                'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
            category: 'Action',
            duration: Duration(seconds: 15),
          ),
          const VideoItem(
            id: 'v4',
            title: 'For Bigger Escapes',
            description: 'The easiest way to enjoy entertainment.',
            thumbnailUrl:
                'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
            category: 'Action',
            duration: Duration(seconds: 15),
          ),
          const VideoItem(
            id: 'v5',
            title: 'For Bigger Fun',
            description: 'Introducing Chromecast.',
            thumbnailUrl:
                'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
            category: 'Action',
            duration: Duration(seconds: 60),
          ),
        ],
      ),
      VideoCategory(
        name: 'Comedy',
        videos: [
          const VideoItem(
            id: 'v6',
            title: 'For Bigger Joyrides',
            description: 'Introducing Chromecast.',
            thumbnailUrl:
                'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerJoyrides.jpg',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
            category: 'Comedy',
            duration: Duration(seconds: 15),
          ),
        ],
      ),
    ];
  }
}
