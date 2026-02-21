import 'package:flutter/foundation.dart';

import '../models/video_category.dart';
import '../models/video_item.dart';
import '../services/video_service.dart';

/// ViewModel for the Home Screen.
/// Manages video categories, loading state, and focused item tracking.
class HomeViewModel extends ChangeNotifier {
  final VideoService _videoService;

  List<VideoCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  VideoItem? _focusedItem;

  HomeViewModel({VideoService? videoService})
      : _videoService = videoService ?? VideoService();

  // --- Getters ---

  List<VideoCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  VideoItem? get focusedItem => _focusedItem;

  /// All videos across all categories (flat list).
  List<VideoItem> get allVideos =>
      _categories.expand((c) => c.videos).toList();

  // --- Actions ---

  /// Load video categories from the data service.
  Future<void> loadVideos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _videoService.loadCategories();
      _error = null;
    } catch (e) {
      _error = 'Failed to load videos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Track the currently focused video item (for preview feature).
  void setFocusedItem(VideoItem? item) {
    if (_focusedItem != item) {
      _focusedItem = item;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _categories = [];
    super.dispose();
  }
}
