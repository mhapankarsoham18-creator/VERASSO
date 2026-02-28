import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/features/social/data/post_model.dart';
import 'package:video_player/video_player.dart';

/// A specialized card for rendering full-screen or feed-based video [Post]s.
class VideoPostCard extends StatefulWidget {
  /// The video post to display.
  final Post post;

  /// Creates a [VideoPostCard] instance.
  const VideoPostCard({super.key, required this.post});

  @override
  State<VideoPostCard> createState() => _VideoPostCardState();
}

class _VideoOverlay extends StatelessWidget {
  final Post post;
  final VideoPlayerController controller;
  const _VideoOverlay({required this.post, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.authorName ?? 'Researcher',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(post.content ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _VideoPostCardState extends State<VideoPostCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: AspectRatio(
        aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (_isInitialized)
              VideoPlayer(_controller)
            else
              const Center(child: CircularProgressIndicator()),
            _VideoOverlay(post: widget.post, controller: _controller),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.post.mediaUrls.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.post.mediaUrls.first))
        ..initialize().then((_) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
        });
    }
  }
}
