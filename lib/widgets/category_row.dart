import 'package:flutter/material.dart';

import '../models/video_category.dart';
import '../models/video_item.dart';
import 'video_card.dart';

/// A horizontal scrollable row of video cards for a single category.
/// Designed for D-pad navigation on Android TV.
class CategoryRow extends StatelessWidget {
  final VideoCategory category;
  final ValueChanged<VideoItem> onVideoSelected;
  final ValueChanged<VideoItem>? onVideoFocused;
  final bool autofocusFirst;

  const CategoryRow({
    super.key,
    required this.category,
    required this.onVideoSelected,
    this.onVideoFocused,
    this.autofocusFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            category.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Horizontal list of video cards
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: category.videos.length,
            itemBuilder: (context, index) {
              final video = category.videos[index];
              return VideoCard(
                video: video,
                autofocus: autofocusFirst && index == 0,
                onSelect: () => onVideoSelected(video),
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    onVideoFocused?.call(video);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
