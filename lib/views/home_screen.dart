import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/video_item.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/category_row.dart';
import 'player_screen.dart';

/// Home screen displaying categorized video content in a TV-style layout.
/// Uses horizontal rows per category, optimized for D-pad navigation.
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
                // App title bar
                _buildHeader(viewModel),
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

  Widget _buildHeader(HomeViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          const Icon(Icons.live_tv, color: Colors.deepPurpleAccent, size: 32),
          const SizedBox(width: 12),
          const Text(
            'TV Streaming',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Show focused item info
          if (viewModel.focusedItem != null)
            Flexible(
              child: Text(
                viewModel.focusedItem!.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
