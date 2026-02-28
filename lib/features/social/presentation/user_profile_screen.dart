import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/cached_image.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/list_skeleton.dart';
import 'package:verasso/core/ui/shimmers/profile_skeleton.dart';

import '../../messaging/presentation/chat_screen.dart';
import '../../profile/data/profile_model.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../stories/presentation/widgets/highlights_bar.dart';
import '../data/feed_repository.dart';
import '../data/post_model.dart';
import 'post_detail_screen.dart';
import 'relationship_controller.dart';

/// Provider family to fetch a user profile by [userId].
final otherUserProfileProvider =
    FutureProvider.family<Profile?, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile(userId);
});

// Need to import the provider from ProfileScreen or move it to a shared file.
// For now, let's redefine valid provider scope or use repo directly.
// Better: Move stats provider to Controller or use here if visible.
// I'll define a local provider for stats matching otherUserProfileProvider structure.

/// Provider family to fetch profile statistics (friends, posts, etc.) for a [userId].
final otherUserStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfileStats(userId);
});

/// Provider family to fetch all posts created by a specific [userId].
final userPostsProvider =
    FutureProvider.family<List<Post>, String>((ref, userId) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.getUserPosts(userId);
});

/// Detailed profile view for other users, including bio, stats, and post grid.
class UserProfileScreen extends ConsumerWidget {
  /// The ID of the user whose profile is being viewed.
  final String userId;

  /// Creates a [UserProfileScreen] instance.
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(otherUserProfileProvider(userId));
    final relationAsync = ref.watch(relationshipStatusProvider(userId));
    final statsAsync = ref.watch(otherUserStatsProvider(userId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Block Option
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(children: [
                  Icon(LucideIcons.ban, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Block')
                ]),
              )
            ],
            onSelected: (val) {
              if (val == 'block') {
                ref
                    .read(relationshipControllerProvider.notifier)
                    .blockUser(userId);
              }
            },
          )
        ],
      ),
      body: LiquidBackground(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('User not found'));
            }

            return relationAsync.when(
              data: (status) {
                final isMe = status == 'self';
                final isFriend = status == 'friends';
                final isBlockedByMe = status == 'blocked_by_me';

                // Privacy Check
                final canViewContent = isMe || !profile.isPrivate || isFriend;

                return ListView(
                  padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
                  children: [
                    // Profile Header
                    GlassContainer(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: ClipOval(
                              child: profile.avatarUrl != null
                                  ? CachedImage(
                                      imageUrl: profile.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: const Icon(LucideIcons.user,
                                          size: 40),
                                    )
                                  : const Icon(LucideIcons.user, size: 40),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(profile.fullName ?? 'Unknown',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('@${profile.username ?? "user"}',
                              style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 16),
                          if (!isMe) ...[
                            _buildActionButton(
                                ref, status, userId, context, profile),
                            const SizedBox(height: 8),
                            _buildFollowButton(ref, userId),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('Trust Score', '${profile.trustScore}'),
                        statsAsync.when(
                          data: (stats) => _buildStatItem(
                              'Friends', '${stats['friends_count'] ?? 0}'),
                          loading: () => _buildStatItem('Friends', '...'),
                          error: (_, __) => _buildStatItem('Friends', '0'),
                        ),
                        _buildStatItem(
                            'Following', '${profile.followingCount}'),
                        _buildStatItem(
                            'Followers', '${profile.followersCount}'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isBlockedByMe)
                      const Center(
                          child: Text('You have blocked this user.',
                              style: TextStyle(color: Colors.red))),

                    if (!canViewContent && !isBlockedByMe) ...[
                      const SizedBox(height: 40),
                      const Icon(LucideIcons.lock,
                          size: 60, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Center(
                          child: Text('This account is private',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold))),
                      const Center(
                          child: Text('Follow to see their photos and videos.',
                              style: TextStyle(color: Colors.white70))),
                    ] else if (!isBlockedByMe) ...[
                      // CONTENT (Bio, Interests, Posts)
                      GlassContainer(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.bio ?? 'No bio.',
                              style: const TextStyle(color: Colors.white)),
                          const SizedBox(height: 10),
                          Wrap(
                              spacing: 8,
                              children: profile.interests
                                  .map((i) => Chip(label: Text(i)))
                                  .toList())
                        ],
                      )),
                      const SizedBox(height: 16),
                      HighlightsBar(userId: userId, isOwner: isMe),
                      const SizedBox(height: 20),
                      _buildUserPostsGrid(ref, userId),
                      const SizedBox(height: 40),
                    ]
                  ],
                );
              },
              loading: () => const ProfileSkeleton(),
              error: (e, s) => AppErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(relationshipStatusProvider(userId)),
              ),
            );
          },
          loading: () => const ProfileSkeleton(),
          error: (e, s) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(otherUserProfileProvider(userId)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(WidgetRef ref, String status, String targetId,
      BuildContext context, Profile profile) {
    if (status == 'friends') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.messageCircle),
            label: const Text('Message'),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatScreen(
                      targetUserId: targetId,
                      targetUserName: profile.fullName ?? 'User')));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              _showUnfriendDialog(context, ref, targetId);
            },
            child: const Icon(LucideIcons.userCheck),
          ),
        ],
      );
    } else if (status == 'pending_sent') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
        onPressed: () {
          HapticFeedback.selectionClick();
          ref
              .read(relationshipControllerProvider.notifier)
              .unfriendOrCancel(targetId);
        },
        child: const Text('Requested'),
      );
    } else if (status == 'pending_received') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () =>
                _showFriendActionDialog(context, ref, targetId, isAccept: true),
            child: const Text('Accept'),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => ref
                .read(relationshipControllerProvider.notifier)
                .unfriendOrCancel(targetId),
            child: const Text('Decline'),
          )
        ],
      );
    } else if (status == 'blocked_by_me') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () => ref
            .read(relationshipControllerProvider.notifier)
            .unfriendOrCancel(
                targetId), // Unfriend acts as unblock in current repo logic or add specific unblock
        child: const Text('Unblock'),
      );
    } else {
      // None
      return ElevatedButton.icon(
        icon: const Icon(LucideIcons.userPlus),
        label: const Text('Add Friend'),
        onPressed: () {
          HapticFeedback.lightImpact();
          _showFriendActionDialog(context, ref, targetId, isAccept: false);
        },
      );
    }
  }

  Widget _buildFollowButton(WidgetRef ref, String targetId) {
    final isFollowingAsync = ref.watch(isFollowingProvider(targetId));

    return isFollowingAsync.when(
      data: (isFollowing) => OutlinedButton.icon(
        icon: Icon(isFollowing ? LucideIcons.userMinus : LucideIcons.userPlus),
        label: Text(isFollowing ? 'Unfollow' : 'Follow'),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (isFollowing) {
            ref.read(profileControllerProvider.notifier).unfollowUser(targetId);
          } else {
            ref.read(profileControllerProvider.notifier).followUser(targetId);
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: isFollowing ? Colors.white70 : Colors.blue,
          side: BorderSide(color: isFollowing ? Colors.white24 : Colors.blue),
        ),
      ),
      loading: () => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPostThumbnail(Post post) {
    if (post.mediaUrls.isNotEmpty) {
      return CachedImage(
        imageUrl: post.mediaUrls.first,
        fit: BoxFit.cover,
        errorWidget: Container(
            color: Colors.white10,
            child:
                const Icon(LucideIcons.alertTriangle, color: Colors.white24)),
      );
    } else {
      // Text-only post visualization
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.white10,
        child: Center(
          child: Text(
            post.content ?? '',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildUserPostsGrid(WidgetRef ref, String userId) {
    final postsAsync = ref.watch(userPostsProvider(userId));

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.cameraOff,
                        size: 48, color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  const SizedBox(height: 16),
                  const Text('No moments shared yet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                      'Capture your first breakthrough and share it with the community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ),
          );
        }

        return MasonryGridView.count(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: post)));
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildPostThumbnail(post),
              ),
            );
          },
        );
      },
      loading: () => const ListSkeleton(itemCount: 6, showAvatar: false),
      error: (e, _) => AppErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(userPostsProvider(userId)),
      ),
    );
  }

  void _showFriendActionDialog(
      BuildContext context, WidgetRef ref, String targetId,
      {required bool isAccept}) {
    bool allowsPersonal =
        ref.read(userProfileProvider).value?.defaultPersonalVisibility ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:
              Text(isAccept ? 'Accept Friend Request' : 'Send Friend Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Would you like to let this friend see your personal posts?'),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Allow Personal Posts'),
                value: allowsPersonal,
                onChanged: (val) => setDialogState(() => allowsPersonal = val),
                activeThumbColor: Colors.orange,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (isAccept) {
                  ref
                      .read(relationshipControllerProvider.notifier)
                      .acceptRequest(targetId, allowsPersonal: allowsPersonal);
                } else {
                  ref
                      .read(relationshipControllerProvider.notifier)
                      .sendRequest(targetId, allowsPersonal: allowsPersonal);
                }
                Navigator.pop(ctx);
              },
              child: Text(isAccept ? 'Accept' : 'Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnfriendDialog(
      BuildContext context, WidgetRef ref, String targetId) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Unfriend?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      ref
                          .read(relationshipControllerProvider.notifier)
                          .unfriendOrCancel(targetId);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Unfriend',
                        style: TextStyle(color: Colors.red))),
              ],
            ));
  }
}
