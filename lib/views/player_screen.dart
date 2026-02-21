import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/video_item.dart';
import '../viewmodels/player_viewmodel.dart';

/// Full-screen video player screen with overlay controls.
/// Supports D-pad / remote control: play/pause (center), seek (left/right), back.
class PlayerScreen extends StatelessWidget {
  final VideoItem video;

  const PlayerScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerViewModel(videoItem: video)..initialize(),
      child: const _PlayerScreenBody(),
    );
  }
}

class _PlayerScreenBody extends StatefulWidget {
  const _PlayerScreenBody();

  @override
  State<_PlayerScreenBody> createState() => _PlayerScreenBodyState();
}

class _PlayerScreenBodyState extends State<_PlayerScreenBody> {
  Timer? _hideControlsTimer;
  final FocusNode _playerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-hide controls after 4 seconds
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _playerFocusNode.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        context.read<PlayerViewModel>().setControlsVisible(false);
      }
    });
  }

  void _showControlsTemporarily() {
    final vm = context.read<PlayerViewModel>();
    vm.setControlsVisible(true);
    _startHideTimer();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final vm = context.read<PlayerViewModel>();
    _showControlsTemporarily();

    // Handle D-pad and remote control keys
    switch (event.logicalKey) {
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        vm.playPause();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowRight:
        vm.seekForward(seconds: 10);
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowLeft:
        vm.seekBackward(seconds: 10);
        return KeyEventResult.handled;

      case LogicalKeyboardKey.mediaPlayPause:
        vm.playPause();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.mediaPlay:
        vm.play();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.mediaPause:
        vm.pause();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.mediaStop:
        vm.stop();
        return KeyEventResult.handled;

      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
        Navigator.of(context).pop();
        return KeyEventResult.handled;

      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _playerFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: _showControlsTemporarily,
          behavior: HitTestBehavior.opaque,
          child: Consumer<PlayerViewModel>(
            builder: (context, vm, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Video player
                  _buildVideoPlayer(vm),
                  // Buffering indicator
                  if (vm.isBuffering)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  // Error overlay
                  if (vm.hasError) _buildErrorOverlay(vm),
                  // Playback controls overlay
                  if (vm.showControls && !vm.hasError)
                    _buildControlsOverlay(vm),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(PlayerViewModel vm) {
    if (!vm.isInitialized || vm.controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: vm.controller!.value.aspectRatio,
        child: VideoPlayer(vm.controller!),
      ),
    );
  }

  Widget _buildErrorOverlay(PlayerViewModel vm) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(PlayerViewModel vm) {
    return AnimatedOpacity(
      opacity: vm.showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
              Colors.transparent,
              Colors.black87,
            ],
            stops: [0.0, 0.2, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Top bar: video title and back button
            _buildTopBar(vm),
            const Spacer(),
            // Center play/pause button
            _buildCenterControls(vm),
            const Spacer(),
            // Bottom bar: progress and time
            _buildBottomBar(vm),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(PlayerViewModel vm) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                vm.videoItem.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls(PlayerViewModel vm) {
    if (!vm.isInitialized) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Seek backward
        IconButton(
          iconSize: 40,
          icon: const Icon(Icons.replay_10, color: Colors.white),
          onPressed: () {
            vm.seekBackward(seconds: 10);
            _showControlsTemporarily();
          },
        ),
        const SizedBox(width: 32),
        // Play / Pause
        IconButton(
          iconSize: 64,
          icon: Icon(
            vm.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            color: Colors.white,
          ),
          onPressed: () {
            vm.playPause();
            _showControlsTemporarily();
          },
        ),
        const SizedBox(width: 32),
        // Seek forward
        IconButton(
          iconSize: 40,
          icon: const Icon(Icons.forward_10, color: Colors.white),
          onPressed: () {
            vm.seekForward(seconds: 10);
            _showControlsTemporarily();
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(PlayerViewModel vm) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.deepPurpleAccent,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.deepPurpleAccent,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                trackHeight: 3,
              ),
              child: Slider(
                value: vm.playbackPercent.clamp(0.0, 1.0),
                onChanged: (value) {
                  final newPosition = Duration(
                    milliseconds:
                        (value * vm.duration.inMilliseconds).round(),
                  );
                  vm.seekTo(newPosition);
                  _showControlsTemporarily();
                },
              ),
            ),
            // Time labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(vm.position),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    _formatDuration(vm.duration),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
