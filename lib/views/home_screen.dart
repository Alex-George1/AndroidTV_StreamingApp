import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/video_item.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/category_row.dart';
import 'player_screen.dart';

/// Home screen displaying categorized video content in a TV-style layout.
/// Features a Netflix-style hero preview banner that auto-plays on focus.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load videos when the screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadVideos();
    });
  }

  void _onVideoSelected(VideoItem video) {
    // Stop any preview before navigating to full player
    context.read<HomeViewModel>().setFocusedItem(null);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(video: video),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            );
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.error!,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => viewModel.loadVideos(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero preview banner
                _HeroPreviewBanner(
                  viewModel: viewModel,
                  onPlay: () {
                    if (viewModel.focusedItem != null) {
                      _onVideoSelected(viewModel.focusedItem!);
                    }
                  },
                ),
                // Category rows
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: viewModel.categories.length,
                    itemBuilder: (context, index) {
                      return CategoryRow(
                        category: viewModel.categories[index],
                        autofocusFirst: index == 0,
                        onVideoSelected: _onVideoSelected,
                        onVideoFocused: (video) {
                          viewModel.setFocusedItem(video);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Netflix-style hero banner that shows the focused video's info
/// and auto-plays a muted preview after a 2-second focus delay.
class _HeroPreviewBanner extends StatelessWidget {
  final HomeViewModel viewModel;
  final VoidCallback onPlay;

  const _HeroPreviewBanner({
    required this.viewModel,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final focused = viewModel.focusedItem;

    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: viewModel.isPreviewPlaying
              ? Colors.deepPurpleAccent
              : Colors.grey[800]!,
          width: 2,
        ),
        boxShadow: viewModel.isPreviewPlaying
            ? [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: focused == null ? _buildEmpty() : _buildPreview(context, focused),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.live_tv, color: Colors.grey[600], size: 36),
          const SizedBox(width: 16),
          Text(
            'TV Streaming',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, VideoItem video) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: video preview or thumbnail
        if (viewModel.isPreviewInitialized && viewModel.previewController != null)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: viewModel.previewController!.value.size.width,
              height: viewModel.previewController!.value.size.height,
              child: VideoPlayer(viewModel.previewController!),
            ),
          )
        else
          // Show thumbnail while waiting for preview
          Image.network(
            video.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[800],
              child: Icon(Icons.movie, color: Colors.grey[600], size: 60),
            ),
          ),

        // Gradient overlay for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.7],
            ),
          ),
        ),

        // Video info overlay
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // "Now Previewing" badge
              if (viewModel.isPreviewPlaying)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NOW PREVIEWING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              // Title
              Text(
                video.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Description
              SizedBox(
                width: 350,
                child: Text(
                  video.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
              // Category + duration
              Row(
                children: [
                  _buildTag(video.category),
                  const SizedBox(width: 8),
                  _buildTag(_formatDuration(video.duration)),
                  if (viewModel.isPreviewPlaying) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.volume_off,
                        color: Colors.white38, size: 16),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
