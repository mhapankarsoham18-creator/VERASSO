import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/ui/cached_image.dart';
import 'package:verasso/services/stories_service.dart';
import 'package:video_player/video_player.dart';

/// Instagram-style fullscreen story viewer
/// Supports auto-advance, tap gestures, reactions
class StoryViewerWidget extends StatefulWidget {
  /// List of stories to display.
  final List<StoryModel> stories;

  /// Initial index of the story to start with.
  final int initialIndex;

  /// Callback when all stories have been viewed.
  final VoidCallback onComplete;

  /// Creates a [StoryViewerWidget].
  const StoryViewerWidget({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.onComplete,
  });

  @override
  State<StoryViewerWidget> createState() => _StoryViewerWidgetState();
}

class _StoryViewerWidgetState extends State<StoryViewerWidget>
    with SingleTickerProviderStateMixin {
  final _storiesService = StoriesService();
  late int _currentIndex;
  late AnimationController _progressController;
  bool _isPaused = false;
  bool _showReactions = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _handleTap,
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story content (image or video)
            _buildStoryContent(story),

            // Progress bars at top
            _buildProgressBars(),

            // Header with user info
            _buildHeader(story),

            // Reactions overlay
            if (_showReactions) _buildReactionsOverlay(),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Caption at bottom
            if (story.caption != null && story.caption!.isNotEmpty)
              _buildCaption(story.caption!),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.stories[_currentIndex].duration),
    );

    _startStory();
  }

  Widget _buildCaption(String caption) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          caption,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHeader(StoryModel story) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 8,
      right: 60,
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: story.avatarUrl != null
                  ? CachedImage(
                      imageUrl: story.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: const Icon(LucideIcons.user, size: 20),
                    )
                  : const Icon(LucideIcons.user, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story.username ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatTimestamp(story.createdAt),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // View Count
          Row(
            children: [
              const Icon(LucideIcons.eye, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                '${story.viewsCount}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
            onPressed: () {
              _pause();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.black87,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading:
                          const Icon(LucideIcons.share, color: Colors.white),
                      title: const Text('Share story',
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        AppLogger.info('Sharing story: ${story.id}');
                      },
                    ),
                    ListTile(
                      leading: const Icon(LucideIcons.alertTriangle,
                          color: Colors.red),
                      title: const Text('Report story',
                          style: TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        AppLogger.warning('Story reported: ${story.id}');
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ).then((_) => _resume());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBars() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 60,
      child: Row(
        children: List.generate(widget.stories.length, (index) {
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: LinearProgressIndicator(
                value: index < _currentIndex
                    ? 1.0
                    : index == _currentIndex
                        ? _progressController.value
                        : 0.0,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReactionButton(String emoji, String type) {
    return InkWell(
      onTap: () => _reactToStory(type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildReactionsOverlay() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildReactionButton('🔥', 'fire'),
            _buildReactionButton('❤️', 'heart'),
            _buildReactionButton('👏', 'clap'),
            _buildReactionButton('😮', 'wow'),
            _buildReactionButton('🤔', 'thinking'),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    if (story.mediaType == 'image') {
      return CachedImage(
        imageUrl: story.mediaUrl,
        fit: BoxFit.contain,
        errorWidget: const Center(
          child: Icon(LucideIcons.shield, color: Colors.red, size: 64),
        ),
      );
    } else {
      if (_videoController != null && _isVideoInitialized) {
        return Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _handleTap(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth / 3) {
      // Tap on left third - go back
      _previousStory();
    } else if (tapPosition > 2 * screenWidth / 3) {
      // Tap on right third - go forward
      _nextStory();
    } else {
      // Tap in middle - toggle reactions
      setState(() => _showReactions = !_showReactions);
    }
  }

  void _nextStory() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _progressController.duration =
            Duration(seconds: widget.stories[_currentIndex].duration);
      });
      _startStory();
    } else {
      widget.onComplete();
    }
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_isPaused) {
      _nextStory();
    }
  }

  void _pause() {
    setState(() => _isPaused = true);
    _progressController.stop();
  }

  void _previousStory() {
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progressController.duration =
            Duration(seconds: widget.stories[_currentIndex].duration);
      });
      _startStory();
    }
  }

  Future<void> _reactToStory(String reactionType) async {
    try {
      await _storiesService.reactToStory(
        storyId: widget.stories[_currentIndex].id,
        reactionType: reactionType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reacted with $reactionType'),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      setState(() => _showReactions = false);
    } catch (e) {
      AppLogger.warning('Failed to react', error: e);
    }
  }

  void _resume() {
    setState(() => _isPaused = false);
    _progressController.forward();
  }

  void _startStory() {
    final story = widget.stories[_currentIndex];
    _progressController.reset();

    if (story.mediaType == 'video') {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl))
            ..initialize().then((_) {
              if (!mounted) return;
              setState(() {
                _isVideoInitialized = true;
                _progressController.duration = _videoController!.value.duration;
                _videoController!.play();
                _progressController.forward();
              });
            }).catchError((e) {
              AppLogger.error('Failed to initialize video', error: e);
              _nextStory();
            });
    } else {
      _progressController.duration = Duration(seconds: story.duration);
      _progressController.forward();
    }

    _progressController.addStatusListener(_onProgressComplete);

    // Mark story as viewed
    _storiesService.viewStory(story.id);
  }
}
