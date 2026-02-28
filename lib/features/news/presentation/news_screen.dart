import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/cached_image.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../profile/data/profile_model.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/mesh_news_service.dart';
import '../data/news_repository.dart';
import '../domain/news_model.dart';
import 'article_detail_screen.dart';
import 'article_editor_screen.dart';
import 'widgets/badge_unlock_overlay.dart';

/// Provider for streaming news articles.
final newsStreamProvider =
    StreamProvider.family<List<NewsArticle>, bool>((ref, featuredOnly) {
  return ref.watch(newsRepositoryProvider).watchArticles(
        featuredOnly: featuredOnly,
      );
});

/// Main screen for browsing and discovering news articles, including P2P mesh content.
class NewsScreen extends ConsumerStatefulWidget {
  /// Creates a [NewsScreen].
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _MeshNewsFeedView extends ConsumerWidget {
  const _MeshNewsFeedView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(meshNewsServiceProvider);

    if (articles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.radio, size: 48, color: Colors.white24),
            SizedBox(height: 16),
            Text('No P2P articles discovered yet.',
                style: TextStyle(color: Colors.white54)),
            Text('Connect to neighbors to sync news.',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 120, 16, 80),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        return _NewsCard(article: articles[index])
            .animate()
            .fadeIn(delay: (index * 100).ms, duration: 400.ms)
            .slideX(begin: 0.1, end: 0);
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsArticle article;

  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ArticleDetailScreen(article: article)));
      },
      child: Semantics(
        label:
            'News article: ${article.title} by ${article.authorName ?? 'Anonymous'}. ${article.readingTime} minutes read.',
        button: true,
        child: GlassContainer(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl != null)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedImage(
                    imageUrl: article.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: ClipOval(
                            child: article.authorAvatar != null
                                ? CachedImage(
                                    imageUrl: article.authorAvatar!,
                                    fit: BoxFit.cover,
                                    errorWidget:
                                        const Icon(LucideIcons.user, size: 12),
                                  )
                                : const Icon(LucideIcons.user, size: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(article.authorName ?? 'Anonymous',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        if (article.authorBadge != null) ...[
                          const SizedBox(width: 4),
                          _buildBadgeIcon(article.authorBadge!),
                        ],
                        const Spacer(),
                        Text(article.subject.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.orangeAccent)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(article.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    if (article.description != null) ...[
                      const SizedBox(height: 8),
                      Text(article.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white70)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.heart,
                            size: 16, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text('${article.upvotesCount}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white38)),
                        const SizedBox(width: 16),
                        const Icon(LucideIcons.messageSquare,
                            size: 16, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text('${article.commentsCount}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white38)),
                        const Spacer(),
                        Consumer(builder: (context, ref, _) {
                          final meshArticles =
                              ref.watch(meshNewsServiceProvider);
                          final isMesh =
                              meshArticles.any((a) => a.id == article.id);
                          if (isMesh) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(LucideIcons.radio,
                                      size: 10, color: Colors.blueAccent),
                                  SizedBox(width: 4),
                                  Text('P2P',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.blueAccent,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        const SizedBox(width: 8),
                        Text('${article.readingTime} min read',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white24)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(String badge) {
    return const Icon(LucideIcons.award, size: 14, color: Colors.amber);
  }
}

class _NewsFeedView extends ConsumerWidget {
  final bool featuredOnly;

  const _NewsFeedView({required this.featuredOnly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsStreamProvider(featuredOnly));

    return newsAsync.when(
      data: (articles) {
        if (articles.isEmpty) {
          return const Center(
              child: Text('No articles found. Be the first to publish!'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 80),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            return _NewsCard(article: articles[index])
                .animate()
                .fadeIn(delay: (index * 100).ms, duration: 400.ms)
                .slideX(begin: 0.1, end: 0);
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent)),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }
}

class _NewsScreenState extends ConsumerState<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _newLevel;

  @override
  Widget build(BuildContext context) {
    // Listen for level up (Optimized: only triggers on level changes)
    ref.listen<AsyncValue<Profile?>>(
      userProfileProvider,
      (prev, next) {
        final prevLevel = prev?.value?.journalistLevel;
        final nextLevel = next.value?.journalistLevel;
        if (nextLevel != null && prevLevel != nextLevel && prevLevel != null) {
          setState(() => _newLevel = nextLevel);
        }
      },
    );

    return Stack(
      children: [
        Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Journalism'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.orangeAccent,
              onTap: (index) => HapticFeedback.selectionClick(),
              tabs: const [
                Tab(text: 'FEATURED'),
                Tab(text: 'RECENT'),
                Tab(text: 'FOLLOWING'),
                Tab(text: 'MESH'),
              ],
            ),
          ),
          body: LiquidBackground(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _NewsFeedView(featuredOnly: true),
                _NewsFeedView(featuredOnly: false),
                _NewsFeedView(featuredOnly: false),
                _MeshNewsFeedView(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ArticleEditorScreen()));
            },
            backgroundColor: Colors.orangeAccent,
            icon: const Icon(LucideIcons.penTool),
            label: const Text('Publish Article'),
          ).animate().scale(delay: 500.ms).fadeIn(),
        ),
        if (_newLevel != null)
          BadgeUnlockOverlay(
            level: _newLevel!,
            onDismiss: () => setState(() => _newLevel = null),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
}
