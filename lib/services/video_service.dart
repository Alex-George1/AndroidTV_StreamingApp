import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/video_category.dart';
import '../models/video_item.dart';

/// Service responsible for loading video data from remote API or local JSON.
/// Tries remote fetch first, falls back to bundled asset.
class VideoService {
  static const String _assetPath = 'assets/data/videos.json';

  /// Optional remote URL for dynamic video catalog.
  /// Set to null to use local-only mode.
  final String? remoteUrl;

  /// HTTP client (injectable for testing).
  final http.Client _httpClient;

  VideoService({this.remoteUrl, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Loads video categories: tries remote API first, falls back to local asset.
  Future<List<VideoCategory>> loadCategories() async {
    // Try remote fetch first
    if (remoteUrl != null) {
      try {
        final categories = await _fetchRemote(remoteUrl!);
        if (categories.isNotEmpty) return categories;
      } catch (_) {
        // Fall through to local loading
      }
    }

    // Fall back to local asset
    try {
      return await _loadFromAsset();
    } catch (e) {
      return _defaultCategories();
    }
  }

  /// Fetch video catalog from a remote URL.
  Future<List<VideoCategory>> _fetchRemote(String url) async {
    final response = await _httpClient
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return _parseJson(response.body);
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  /// Load video catalog from the bundled JSON asset.
  Future<List<VideoCategory>> _loadFromAsset() async {
    final jsonString = await rootBundle.loadString(_assetPath);
    return _parseJson(jsonString);
  }

  /// Parse JSON string into a list of VideoCategory.
  List<VideoCategory> _parseJson(String jsonString) {
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final categoriesList = jsonData['categories'] as List<dynamic>;
    return categoriesList
        .map((c) => VideoCategory.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Returns all videos from all categories as a flat list.
  Future<List<VideoItem>> loadAllVideos() async {
    final categories = await loadCategories();
    return categories.expand((c) => c.videos).toList();
  }

  /// Dispose the HTTP client when no longer needed.
  void dispose() {
    _httpClient.close();
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
