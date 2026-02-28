import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/theme/app_colors.dart';
import 'package:verasso/features/stories/presentation/story_creation_screen.dart';
import 'package:verasso/features/stories/presentation/story_feed_screen.dart';

import '../data/story_model.dart';
import 'stories_controller.dart';

/// A horizontally scrolling carousel that displays user stories.
class StoryCarousel extends ConsumerWidget {
  /// Creates a [StoryCarousel] instance.
  const StoryCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);

    return storiesAsync.when(
      data: (stories) {
        // Group stories by user for the carousel
        final Map<String, List<Story>> userStories = {};
        for (var story in stories) {
          userStories.putIfAbsent(story.userId, () => []).add(story);
        }

        final users = userStories.keys.toList();

        return SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: users.length + 1, // +1 for "Add Story"
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddStoryButton(context);
              }

              final userId = users[index - 1];
              final userStory = userStories[userId]!.first;

              return _StoryAvatar(
                imageUrl: userStory.authorAvatar,
                name: userStory.authorName ?? 'User',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StoryFeedScreen(),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 110),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const StoryCreationScreen(),
          ),
        );
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white12,
                  child: Icon(LucideIcons.user, color: Colors.white54),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.plus,
                        size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Your Story',
              style: TextStyle(fontSize: 10, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final VoidCallback onTap;

  const _StoryAvatar({
    required this.imageUrl,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent,
                    AppColors.primary,
                    Colors.purple.shade300,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.spaceIndigo,
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null ? const Icon(LucideIcons.user) : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 10, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
