import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../models/video_category.dart';
import '../models/video_item.dart';
import '../services/video_service.dart';

/// ViewModel for the Home Screen.
/// Manages video categories, loading state, focused item tracking,
/// and auto-play preview (Netflix-style).
class HomeViewModel extends ChangeNotifier {
  final VideoService _videoService;

  List<VideoCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  VideoItem? _focusedItem;

  // --- Auto-play preview state ---
  VideoPlayerController? _previewController;
  Timer? _previewTimer;
  bool _isPreviewPlaying = false;
  bool _isPreviewInitialized = false;

  /// Delay before auto-playing a preview when a card is focused.
  static const Duration _previewDelay = Duration(seconds: 2);

  HomeViewModel({VideoService? videoService})
      : _videoService = videoService ?? VideoService();

  // --- Getters ---

  List<VideoCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  VideoItem? get focusedItem => _focusedItem;
  VideoPlayerController? get previewController => _previewController;
  bool get isPreviewPlaying => _isPreviewPlaying;
  bool get isPreviewInitialized => _isPreviewInitialized;

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

  /// Track the currently focused video item and trigger auto-play preview.
  void setFocusedItem(VideoItem? item) {
    if (_focusedItem == item) return;
    _focusedItem = item;

    // Cancel any pending preview
    _previewTimer?.cancel();
    _stopPreview();

    if (item != null) {
      // Start a timer — if the user stays focused for 2 seconds, auto-play
      _previewTimer = Timer(_previewDelay, () {
        _startPreview(item);
      });
    }

    notifyListeners();
  }

  /// Start playing a silent video preview for the focused item.
  Future<void> _startPreview(VideoItem item) async {
    // Don't preview if focus changed while we were waiting
    if (_focusedItem != item) return;

    try {
      _previewController = VideoPlayerController.networkUrl(
        Uri.parse(item.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await _previewController!.initialize();

      // Double-check focus hasn't changed during async initialization
      if (_focusedItem != item) {
        _previewController?.dispose();
        _previewController = null;
        return;
      }

      await _previewController!.setVolume(0); // Muted preview
      await _previewController!.setLooping(true);
      await _previewController!.play();

      _isPreviewInitialized = true;
      _isPreviewPlaying = true;
      notifyListeners();
    } catch (e) {
      // Preview failed — that's okay, just show the static thumbnail
      _previewController?.dispose();
      _previewController = null;
      _isPreviewInitialized = false;
      _isPreviewPlaying = false;
    }
  }

  /// Stop and dispose the current preview player.
  void _stopPreview() {
    _isPreviewPlaying = false;
    _isPreviewInitialized = false;
    _previewController?.dispose();
    _previewController = null;
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _stopPreview();
    _videoService.dispose();
    _categories = [];
    super.dispose();
  }
}
