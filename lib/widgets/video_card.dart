import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/video_item.dart';

/// A focusable video card widget designed for D-pad/remote navigation.
/// Shows a thumbnail and title, with scale + border animation on focus.
class VideoCard extends StatefulWidget {
  final VideoItem video;
  final bool autofocus;
  final VoidCallback onSelect;
  final ValueChanged<bool>? onFocusChange;

  const VideoCard({
    super.key,
    required this.video,
    required this.onSelect,
    this.autofocus = false,
    this.onFocusChange,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  bool _imageTimedOut = false;
  Timer? _timeoutTimer;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    // If the image hasn't loaded after 8 seconds, show error state
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _imageTimedOut = true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool hasFocus) {
    setState(() => _isFocused = hasFocus);
    if (hasFocus) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
    widget.onFocusChange?.call(hasFocus);
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 40,
            ),
            const SizedBox(height: 6),
            Text(
              'No Thumbnail',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Handle D-pad center / Enter / Space to select the card
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onSelect();
            return KeyEventResult.handled;
          }
        }
        // Let D-pad arrow keys pass through for navigation
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          child: _buildCardContent(context),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: _isFocused
            ? Border.all(color: Colors.white, width: 3)
            : Border.all(color: Colors.transparent, width: 3),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base layer: always-visible placeholder
                  _buildErrorPlaceholder(context),
                  // Top layer: network image (covers placeholder on success)
                  if (!_imageTimedOut)
                    _NetworkThumbnail(
                      url: widget.video.thumbnailUrl,
                      onLoaded: () => _timeoutTimer?.cancel(),
                    ),
                  // Duration badge
                  if (widget.video.duration > Duration.zero)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(widget.video.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Title
            Container(
              color: _isFocused ? Colors.deepPurple[700] : Colors.grey[900],
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              child: Text(
                widget.video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight:
                      _isFocused ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A ScaleTransition builder that avoids recreating child widgets.
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }
}

/// Attempts to load a network thumbnail image.
/// Shows the image on success, transparent on failure (so the
/// placeholder underneath remains visible).
class _NetworkThumbnail extends StatefulWidget {
  final String url;
  final VoidCallback onLoaded;

  const _NetworkThumbnail({required this.url, required this.onLoaded});

  @override
  State<_NetworkThumbnail> createState() => _NetworkThumbnailState();
}

class _NetworkThumbnailState extends State<_NetworkThumbnail> {
  bool _loaded = false;
  bool _errored = false;

  @override
  Widget build(BuildContext context) {
    if (_errored) return const SizedBox.shrink();

    return Image.network(
      widget.url,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          // Image has decoded at least one frame — it's ready
          if (!_loaded) {
            _loaded = true;
            widget.onLoaded();
          }
          return child;
        }
        // Still loading — show nothing (placeholder underneath is visible)
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) {
        // Mark errored so we don't retry
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_errored) {
            setState(() => _errored = true);
          }
        });
        return const SizedBox.shrink();
      },
    );
  }
}
