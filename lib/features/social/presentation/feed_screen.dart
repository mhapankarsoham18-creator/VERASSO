import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/security/moderation_service.dart';
import 'package:verasso/core/services/pagination_service.dart';
import 'package:verasso/core/services/tutorial_service.dart';
import 'package:verasso/core/theme/app_colors.dart';
import 'package:verasso/core/theme/design_system.dart';
import 'package:verasso/core/ui/cached_image.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/premium_empty_state.dart';
import 'package:verasso/core/ui/shimmers/feed_skeleton.dart';
import 'package:verasso/core/ui/tutorial_overlay.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/social/data/collection_model.dart';

import '../../../core/exceptions/user_friendly_error_handler.dart';
import '../../../core/ui/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/post_model.dart';
import 'enhanced_create_post_screen.dart';
import 'feed_controller.dart';
import 'feed_tutorial_steps.dart';
import 'post_detail_screen.dart';
import 'saved_posts_controller.dart';
import 'story_widgets.dart';
import 'user_profile_screen.dart';
import 'widgets/video_post_card.dart';

/// Main social feed experience for browsing, saving, and creating posts.
///
/// Integrates with [FeedController], saved posts, collections, and an
/// onboarding tutorial to guide new users through the feed features.
class FeedScreen extends ConsumerStatefulWidget {
  /// Creates a [FeedScreen] instance.
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

/// Card widget that renders a single social [Post] within the feed.
class PostCard extends ConsumerWidget {
  /// The post data to display.
  final Post post;

  /// Creates a [PostCard] instance.
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isSavedAsync = ref.watch(isPostSavedProvider(post.id));
    final collectionsAsync = ref.watch(collectionsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: post.userId)));
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: ClipOval(
                      child: post.authorAvatar != null
                          ? CachedImage(
                              imageUrl: post.authorAvatar!,
                              fit: BoxFit.cover,
                              errorWidget:
                                  const Icon(LucideIcons.user, size: 20),
                            )
                          : const Icon(LucideIcons.user, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName ?? l10n.defaultUsername,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        DateFormat.yMMMd().format(post.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showModerationOptions(context, ref, l10n),
                    icon: const Icon(LucideIcons.moreHorizontal,
                        size: 20, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Content
            if (post.content != null) ...[
              Text(post.content!),
              const SizedBox(height: 10),
            ],
            // Image
            if (post.mediaUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedImage(
                  imageUrl: post.mediaUrls.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                _PostAction(
                  icon: LucideIcons.heart,
                  label: '${post.likesCount}',
                  color: AppColors.accent,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(feedProvider.notifier).toggleLike(post.id);
                  },
                )
                    .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true))
                    .shimmer(
                        delay: 5.seconds, duration: DesignSystem.durationSlow),
                const SizedBox(width: 20),
                _PostAction(
                  icon: LucideIcons.messageCircle,
                  label: '${post.commentsCount}',
                  color: AppColors.etherealCyan,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: post)));
                  },
                ),
                _PostAction(
                  icon: LucideIcons.share2,
                  label: l10n.share,
                  color: Colors.white70,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(feedProvider.notifier).sharePost(post);
                  },
                ),
                const Spacer(),
                // Save Button
                IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref
                        .read(savedPostsControllerProvider.notifier)
                        .toggleSave(post.id);
                  },
                  icon: isSavedAsync.when(
                    data: (saved) => Icon(
                      saved ? LucideIcons.bookmark : LucideIcons.bookmark,
                      size: 22,
                      color: saved ? AppColors.etherealCyan : Colors.white70,
                    ).animate(target: saved ? 1 : 0).scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        curve: DesignSystem.easingStandard,
                        duration: DesignSystem.durationFast),
                    loading: () => const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const Icon(LucideIcons.bookmark,
                        size: 22, color: Colors.white70),
                  ),
                ),
                // Collection Picker Button
                IconButton(
                  onPressed: () {
                    _showCollectionPicker(context, ref, collectionsAsync, l10n);
                  },
                  icon: const Icon(LucideIcons.folderPlus,
                      size: 22, color: Colors.white70),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// Opens a bottom sheet to choose a collection or collaboration to save
  /// the current post into.
  void _showCollectionPicker(BuildContext context, WidgetRef ref,
      AsyncValue<List<Collection>> collectionsAsync, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(l10n.saveToCollection,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            collectionsAsync.when(
              data: (collections) => Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final coll = collections[index];
                    return ListTile(
                      leading: Icon(coll.isCollaboration
                          ? LucideIcons.users
                          : LucideIcons.folder),
                      title: Text(coll.name),
                      subtitle: Text(coll.isCollaboration
                          ? l10n.collaboration
                          : l10n.privateCollection),
                      onTap: () {
                        ref
                            .read(savedPostsControllerProvider.notifier)
                            .saveToCollection(coll.id, post.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(l10n.savedToCollection(coll.name))));
                      },
                    );
                  },
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                  child: Text(
                      '${AppLocalizations.of(context)!.failedLoadSettings}: $err')),
            ),
            ListTile(
              leading: const Icon(LucideIcons.plus, color: Colors.blue),
              title: Text(l10n.createNewCollection,
                  style: const TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.pop(context);
                _showCreateCollectionDialog(context, ref, l10n);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Displays a dialog for creating a new collection used to group posts.
  void _showCreateCollectionDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newCollection),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: l10n.collectionName),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref
                    .read(savedPostsControllerProvider.notifier)
                    .createCollection(nameController.text);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.submit),
          ),
        ],
      ),
    );
  }

  void _showModerationOptions(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.flag, color: Colors.orangeAccent),
              title: Text(l10n.reportPost),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context, ref, l10n);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.userX, color: Colors.redAccent),
              title:
                  Text(l10n.muteUser(post.authorName ?? l10n.defaultUsername)),
              onTap: () async {
                final myId = ref.read(currentUserProvider)?.id;
                if (myId != null) {
                  await ref.read(moderationServiceProvider).muteUser(
                        userId: myId,
                        mutedUserId: post.userId,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(feedProvider);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l10n.userMuted(
                            post.authorName ?? l10n.defaultUsername))));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reportPost),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(hintText: l10n.reportReasonHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final myId = ref.read(currentUserProvider)?.id;
              if (myId != null && reasonController.text.isNotEmpty) {
                await ref.read(moderationServiceProvider).reportContent(
                      reporterId: myId,
                      targetId: post.id,
                      targetType: 'post',
                      reason: reasonController.text,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.reportSubmitted)));
                }
              }
            },
            child: Text(l10n.report),
          ),
        ],
      ),
    );
  }
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedAsync = ref.watch(feedProvider);
    final feedType = ref.watch(feedTypeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: GlassContainer(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTab(l10n.feedGlobal, FeedType.global, feedType),
              _buildTab(l10n.feedFollowing, FeedType.following, feedType),
              _buildTab(l10n.feedLabs, FeedType.global, feedType,
                  isVideo: true),
            ],
          ),
        ),
      ),
      body: LiquidBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(feedProvider);
            await ref.read(feedProvider.notifier).loadInitialFeed();
          },
          child: feedAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return PremiumEmptyState(
                  title: l10n.emptyFeedTitle,
                  message: l10n.emptyFeedMessage,
                  icon: LucideIcons.rss,
                );
              }

              final isVideoFeed = ref.watch(isVideoFeedProvider);

              if (isVideoFeed) {
                return PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    if (post.mediaUrls.isNotEmpty &&
                        (post.mediaUrls.first.endsWith('.mp4') ||
                            post.mediaUrls.first.endsWith('.mov'))) {
                      return VideoPostCard(post: post);
                    }
                    return PostCard(post: post); // Fallback for mixed content
                  },
                );
              }

              final pagination = ref.watch(feedPaginationProvider);
              final itemCount = posts.length + (pagination.hasMore ? 1 : 0);

              return ListView.builder(
                padding: const EdgeInsets.only(
                    top: 100, bottom: 80, left: 16, right: 16),
                cacheExtent: 1000,
                itemCount: itemCount + 1, // +1 for StoryCarousel
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: StoryCarousel(),
                    );
                  }
                  final postIndex = index - 1;
                  if (postIndex == posts.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref.read(feedProvider.notifier).loadNextPage();
                          },
                          icon: const Icon(LucideIcons.chevronDown),
                          label: Text(l10n.loadMorePosts),
                        ),
                      ),
                    );
                  }
                  return PostCard(post: posts[postIndex])
                      .animate()
                      .fadeIn(
                          duration: DesignSystem.durationMedium,
                          delay: (postIndex * 50).ms,
                          curve: DesignSystem.easingStandard)
                      .slideY(
                          begin: 0.05,
                          end: 0,
                          curve: DesignSystem.easingDecelerate);
                },
              );
            },
            loading: () => const FeedSkeleton(),
            error: (err, stack) => ErrorView(
              message: UserFriendlyErrorHandler.getDisplayMessage(err),
              onRetry: () {
                ref.invalidate(feedProvider);
                ref.read(feedProvider.notifier).loadInitialFeed();
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const EnhancedCreatePostScreen()));
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorial(context);
    });
  }

  /// Builds a single tab pill for switching between feed variants.
  Widget _buildTab(String label, FeedType type, FeedType activeType,
      {bool isVideo = false}) {
    final isVideoTabActive = ref.watch(isVideoFeedProvider);
    final isActive = (isVideo == isVideoTabActive) &&
        (isVideo || (type == activeType && !isVideoTabActive));

    return GestureDetector(
      onTap: () {
        ref.read(isVideoFeedProvider.notifier).state = isVideo;
        if (!isVideo && type != activeType) {
          ref.read(feedTypeProvider.notifier).state = type;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  /// Shows the feed feature tutorial overlay for first-time users.
  void _checkTutorial(BuildContext context) async {
    final isCompleted =
        await TutorialService.isTutorialCompleted(TutorialIds.feedFeature);
    if (!isCompleted && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => TutorialOverlay(
          steps: feedTutorialSteps,
          onComplete: () =>
              TutorialService.markTutorialCompleted(TutorialIds.feedFeature),
          onSkip: () =>
              TutorialService.markTutorialCompleted(TutorialIds.feedFeature),
        ),
      );
    }
  }
}

/// Small button-style widget for displaying like/comment actions.
class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  const _PostAction(
      {required this.icon, required this.label, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label ${icon == LucideIcons.heart ? "likes" : "comments"}',
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.white70),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color ?? Colors.white70)),
          ],
        ),
      ),
    );
  }
}
