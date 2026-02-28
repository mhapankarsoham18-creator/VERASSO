import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verasso/core/theme/design_system.dart';
import 'package:verasso/core/ui/cached_image.dart';
import 'package:verasso/core/ui/shimmers/shimmer_loading.dart';
import 'package:verasso/features/stories/data/stories_provider.dart';
import 'package:verasso/services/stories_service.dart';

import 'story_creation_screen.dart';
import 'widgets/story_viewer_widget.dart';

/// Story feed widget for home screen
/// Shows horizontal scrollable list of story circles
/// Main screen or widget for viewing the story feed.
class StoryFeedScreen extends ConsumerStatefulWidget {
  /// Creates a [StoryFeedScreen].
  const StoryFeedScreen({super.key});

  @override
  ConsumerState<StoryFeedScreen> createState() => _StoryFeedScreenState();
}

class _StoryFeedScreenState extends ConsumerState<StoryFeedScreen> {
  late final StoriesService _storiesService;
  List<StoryModel> _myStories = [];
  Map<String, List<StoryModel>> _groupedStories = {};
  bool _isLoading = true;
  final Set<String> _viewedStoryIds = {};

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: 6,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ShimmerLoading(
              child: SkeletonBox(width: 70, height: 70, radius: 35),
            ),
          ),
        ),
      );
    }

    if (_groupedStories.isEmpty && _myStories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No stories available. Be the first to share!',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _groupedStories.length + 1, // +1 for "Your Story"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Your Story" button
            return _buildYourStoryButton();
          }

          final userId = _groupedStories.keys.elementAt(index - 1);
          final userStories = _groupedStories[userId]!;
          final firstStory = userStories.first;
          final hasNewStory = userStories.any((s) {
            // Story is "new" if created in last 24 hours and not viewed by current user
            final isRecent =
                DateTime.now().difference(s.createdAt).inHours < 24;
            return isRecent && !_viewedStoryIds.contains(s.id);
          });

          return _buildStoryCircle(
            username: firstStory.username ?? 'Unknown',
            avatarUrl: firstStory.avatarUrl,
            hasNewStory: hasNewStory,
            storyCount: userStories.length,
            onTap: () => _openStoryViewer(userId, 0),
          )
              .animate()
              .fadeIn(
                  delay: (index * 50).ms,
                  duration: DesignSystem.durationMedium,
                  curve: DesignSystem.easingStandard)
              .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: DesignSystem.easingStandard);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _storiesService = ref.read(storiesServiceProvider);
    _loadStories();
  }

  Widget _buildStoryCircle({
    required String username,
    String? avatarUrl,
    required bool hasNewStory,
    required int storyCount,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasNewStory
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFF58529),
                              Color(0xFFDD2A7B),
                              Color(0xFF8134AF),
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            stops: [0.0, 0.5, 1.0],
                          )
                        : null,
                    border: !hasNewStory
                        ? Border.all(color: Colors.grey.shade300, width: 2)
                        : null,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null
                          ? CachedImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              errorWidget: const Icon(LucideIcons.user),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                ),
                if (storyCount > 1)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$storyCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                username,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourStoryButton() {
    final hasMyStory = _myStories.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: hasMyStory
            ? () => _openStoryViewer(_myStories.first.userId, 0)
            : _openStoryCreation,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasMyStory ? Colors.purple : Colors.grey.shade300,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: hasMyStory && _myStories.first.avatarUrl != null
                        ? CachedImage(
                            imageUrl: _myStories.first.avatarUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                if (!hasMyStory)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                hasMyStory ? 'Your Story' : 'Add Story',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    try {
      final allStories = await _storiesService.getActiveStories();
      final myStories = await _storiesService.getMyStories();
      final prefs = await SharedPreferences.getInstance();
      final viewed = prefs.getStringList('viewed_stories') ?? [];

      // Group stories by user
      final Map<String, List<StoryModel>> grouped = {};
      for (var story in allStories) {
        final key = story.userId;
        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(story);
      }

      setState(() {
        _myStories = myStories;
        _groupedStories = grouped;
        _viewedStoryIds.addAll(viewed);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stories: $e')),
        );
      }
    }
  }

  void _openStoryCreation() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryCreationScreen(),
      ),
    );

    if (result == true) {
      // Story was created, reload
      _loadStories();
    }
  }

  void _openStoryViewer(String userId, int initialIndex) async {
    final userStories = _groupedStories[userId] ?? [];
    if (userStories.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerWidget(
          stories: userStories,
          initialIndex: initialIndex,
          onComplete: () => Navigator.pop(context),
        ),
        fullscreenDialog: true,
      ),
    );

    // Mark current new stories as viewed
    final newIds = userStories
        .where((s) =>
            DateTime.now().difference(s.createdAt).inHours < 24 &&
            !_viewedStoryIds.contains(s.id))
        .map((s) => s.id)
        .toList();

    if (newIds.isNotEmpty) {
      setState(() {
        _viewedStoryIds.addAll(newIds);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('viewed_stories', _viewedStoryIds.toList());
    }
  }
}
