import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/empty_state_widget.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/feed_skeleton.dart';
import 'package:verasso/core/ui/shimmers/grid_skeleton.dart';

import 'feed_screen.dart'; // Reuse PostCard
import 'saved_posts_controller.dart';

/// Screen for viewing bookmarked posts and managing curated collections.
class SavedPostsScreen extends ConsumerStatefulWidget {
  /// Creates a [SavedPostsScreen] instance.
  const SavedPostsScreen({super.key});

  @override
  ConsumerState<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends ConsumerState<SavedPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    final savedPostsAsync = ref.watch(savedPostsProvider);
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Content'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Posts'),
            Tab(text: 'Collections'),
          ],
        ),
      ),
      body: LiquidBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsList(savedPostsAsync),
            _buildCollectionsGrid(collectionsAsync),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget _buildCollectionsGrid(AsyncValue<List<dynamic>> collectionsAsync) {
    return collectionsAsync.when(
      loading: () => const GridSkeleton(),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (collections) {
        if (collections.isEmpty) {
          return const EmptyStateWidget(
            title: 'No Collections Yet',
            message: 'Organize your saved posts into custom collections.',
            icon: LucideIcons.folderPlus,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(collectionsProvider);
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final coll = collections[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to specific collection posts screen
                },
                child: GlassContainer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        coll.isCollaboration
                            ? LucideIcons.users
                            : LucideIcons.folder,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        coll.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${coll.postIds.length} posts',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPostsList(AsyncValue<List<dynamic>> postsAsync) {
    return postsAsync.when(
      loading: () => const FeedSkeleton(),
      data: (posts) {
        if (posts.isEmpty) {
          return const EmptyStateWidget(
            title: 'No Saved Posts Yet',
            message: 'Tap the bookmark icon on posts to save them here.',
            icon: LucideIcons.bookmark,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(savedPostsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) => PostCard(post: posts[index]),
          ),
        );
      },
      error: (err, _) => AppErrorView(
        message: err.toString(),
        onRetry: () {
          ref.invalidate(savedPostsProvider);
          ref.invalidate(collectionsProvider);
        },
      ),
    );
  }
}
