import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../messaging/services/messaging_service.dart';
import '../../../core/theme/colors.dart';
import 'package:verasso/core/utils/logger.dart';

class ViewStoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  const ViewStoryScreen({super.key, required this.stories, this.initialIndex = 0});

  @override
  State<ViewStoryScreen> createState() => _ViewStoryScreenState();
}

class _ViewStoryScreenState extends State<ViewStoryScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  final TextEditingController _replyController = TextEditingController();
  final MessagingService _messagingService = MessagingService();
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Each story lasts 5 seconds by default
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _likeStory(String storyId) async {
    if (_isLiking) return;
    setState(() => _isLiking = true);
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) return;
      final profile = await Supabase.instance.client.from('profiles').select('id').eq('firebase_uid', fbUser.uid).single();
      final myId = profile['id'];

      await Supabase.instance.client.from('story_likes').insert({
        'story_id': storyId,
        'profile_id': myId,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liked!')));
    } catch (e) {
      // Ignore if already liked
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Future<void> _sendReply(String storyId, String authorId, String text) async {
    if (text.trim().isEmpty) return;
    _replyController.clear();
    FocusScope.of(context).unfocus();
    _progressController.forward();
    
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply sent!')));
    try {
      await _messagingService.sendSecureMessage(authorId, "Replying to story: $text");
    } catch (e) {
      appLogger.d('Error sending reply: $e');
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      // If at the beginning, reset the current story
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _handleTap(TapUpDetails details, double screenWidth) {
    if (details.globalPosition.dx < screenWidth / 3) {
      _previousStory();
    } else {
      _nextStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) return Scaffold(body: Center(child: Text('No stories')));

    final story = widget.stories[_currentIndex];
    final mediaUrl = story['media_url'];
    final content = story['content'];
    final isVideo = story['media_type'] == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) => _handleTap(details, MediaQuery.of(context).size.width),
        onLongPressStart: (_) => _progressController.stop(),
        onLongPressEnd: (_) => _progressController.forward(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media
            if (mediaUrl != null)
              isVideo
                  ? Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white54)) // basic placeholder, ideally use video_player
                  : CachedNetworkImage(
                      imageUrl: mediaUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator(color: context.colors.primary)),
                    ),
            
            // Text overlay
            if (content != null)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // Top Progress Bars
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(
                  widget.stories.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: _buildProgressBar(index),
                    ),
                  ),
                ),
              ),
            ),
            
            // Close Button
            Positioned(
              top: 70,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            
            // Bottom Interaction Bar
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      style: TextStyle(color: Colors.white),
                      onTap: () => _progressController.stop(), // pause while typing
                      onSubmitted: (text) => _sendReply(story['id'], story['author_id'], text),
                      decoration: InputDecoration(
                        hintText: 'Reply...',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black45,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.favorite_border, color: Colors.white, size: 28),
                    onPressed: () => _likeStory(story['id']),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 28),
                    onPressed: () => _sendReply(story['id'], story['author_id'], _replyController.text),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: index < _currentIndex
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                )
              : index == _currentIndex
                  ? AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: constraints.maxWidth * _progressController.value,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        );
                      },
                    )
                  : const SizedBox.shrink(),
        );
      },
    );
  }
}

