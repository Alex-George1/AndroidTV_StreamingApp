import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../models/video_item.dart';

/// ViewModel for the Video Player Screen.
/// Manages video playback state: play, pause, seek, buffering, and controls visibility.
class PlayerViewModel extends ChangeNotifier {
  VideoPlayerController? _controller;
  final VideoItem videoItem;

  bool _isInitialized = false;
  bool _isBuffering = false;
  bool _showControls = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Throttle position updates to avoid excessive rebuilds
  Timer? _positionTimer;
  Duration _lastPosition = Duration.zero;

  PlayerViewModel({required this.videoItem});

  // --- Getters ---

  VideoPlayerController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _controller?.value.isPlaying ?? false;
  bool get isBuffering => _isBuffering;
  bool get showControls => _showControls;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  Duration get position => _controller?.value.position ?? Duration.zero;
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  double get bufferedPercent {
    if (_controller == null || !_isInitialized) return 0.0;
    final ranges = _controller!.value.buffered;
    if (ranges.isEmpty) return 0.0;
    final totalDuration = duration.inMilliseconds;
    if (totalDuration == 0) return 0.0;
    return ranges.last.end.inMilliseconds / totalDuration;
  }

  double get playbackPercent {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  // --- Lifecycle ---

  /// Initialize the video player controller and start playback.
  Future<void> initialize() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(videoItem.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      _controller!.addListener(_onPlayerUpdate);

      await _controller!.initialize();
      _isInitialized = true;
      _hasError = false;
      notifyListeners();

      // Start periodic position updates (every 500ms instead of every frame)
      _positionTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => _updatePosition(),
      );

      // Auto-play on initialization
      await _controller!.play();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load video: $e';
      notifyListeners();
    }
  }

  void _onPlayerUpdate() {
    if (_controller == null) return;

    final newBuffering = _controller!.value.isBuffering;
    if (newBuffering != _isBuffering) {
      _isBuffering = newBuffering;
      notifyListeners();
    }

    // Check for errors
    if (_controller!.value.hasError) {
      _hasError = true;
      _errorMessage = _controller!.value.errorDescription ?? 'Playback error';
      notifyListeners();
    }

    // Position updates are handled by _positionTimer to avoid
    // calling notifyListeners() 30-60 times per second.
  }

  /// Called by timer to update position at a controlled rate.
  void _updatePosition() {
    if (_controller == null || !_isInitialized) return;
    final currentPos = _controller!.value.position;
    if (currentPos != _lastPosition) {
      _lastPosition = currentPos;
      notifyListeners();
    }
  }

  // --- Playback Controls ---

  Future<void> playPause() async {
    if (_controller == null || !_isInitialized) return;

    if (_controller!.value.isPlaying) {
      await _controller!.pause();
    } else {
      await _controller!.play();
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (_controller == null || !_isInitialized) return;
    await _controller!.play();
    notifyListeners();
  }

  Future<void> pause() async {
    if (_controller == null || !_isInitialized) return;
    await _controller!.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    if (_controller == null || !_isInitialized) return;
    await _controller!.pause();
    await _controller!.seekTo(Duration.zero);
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    if (_controller == null || !_isInitialized) return;
    await _controller!.seekTo(position);
    notifyListeners();
  }

  Future<void> seekForward({int seconds = 10}) async {
    if (_controller == null || !_isInitialized) return;
    final newPosition = position + Duration(seconds: seconds);
    final clampedPosition =
        newPosition > duration ? duration : newPosition;
    await _controller!.seekTo(clampedPosition);
  }

  Future<void> seekBackward({int seconds = 10}) async {
    if (_controller == null || !_isInitialized) return;
    final newPosition = position - Duration(seconds: seconds);
    final clampedPosition =
        newPosition < Duration.zero ? Duration.zero : newPosition;
    await _controller!.seekTo(clampedPosition);
  }

  /// Toggle controls visibility (auto-hide after a period of inactivity).
  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  void setControlsVisible(bool visible) {
    if (_showControls != visible) {
      _showControls = visible;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
