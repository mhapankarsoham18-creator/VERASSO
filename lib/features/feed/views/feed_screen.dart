import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'create_post_screen.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../repositories/feed_repository.dart';
import '../repositories/sync_engine.dart';
import '../../../features/notifications/views/notifications_screen.dart';
import '../../../features/doubts/views/doubts_list_screen.dart';
import '../../../features/messaging/views/conversation_list_screen.dart';
import '../../../features/education/views/simulations_directory.dart';
import '../../../features/sidequests/views/quest_board_screen.dart';

// Uses the new Offline-First repository stream
final feedStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(feedRepositoryProvider).getFeedStream();
});

// Caches author profiles to prevent database spam
final authorProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, authorId) async {
  final res = await Supabase.instance.client.from('profiles').select().eq('id', authorId).maybeSingle();
  return res;
});

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure sync engine is awake
    ref.watch(syncEngineProvider);
    final feedStream = ref.watch(feedStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('HOME', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationListScreen()));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.neutralBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawer Header — retro pixel brand
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.blockEdge, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('▣ VERASSO', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 26, letterSpacing: 3)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('P2P KNOWLEDGE GRID', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                  ],
                ),
              ),
              // Scrollable nav items — prevents overflow
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 12),
                  children: [
                    // Main nav — functional
                    _pixelTile(context, '🏠', 'Home', () {
                      Navigator.pop(context);
                    }),
                    _pixelTile(context, '🔍', 'Discovery', () {
                      Navigator.pop(context);
                      context.go('/shell/discovery');
                    }),
                    _pixelTile(context, '🎒', 'Study Tools', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SimulationsDirectory()));
                    }),
                    _pixelTile(context, '⚔️', 'Sidequests', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestBoardScreen()));
                    }),
                    _pixelTile(context, '🌌', 'Astro Hub', () {
                      Navigator.pop(context);
                      // User will implement Astro here later
                    }),
                    _pixelTile(context, '❓', 'Doubts', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DoubtsListScreen()));
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(height: 2, color: AppColors.blockEdge),
                    ),
                    _pixelTile(context, '💬', 'Messages', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ConversationListScreen()));
                    }),
                    _pixelTile(context, '🔔', 'Notifications', () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                    }),
                    _pixelTile(context, '👤', 'Profile', () {
                      Navigator.pop(context);
                      context.go('/shell/profile');
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(height: 2, color: AppColors.blockEdge),
                    ),
                    _pixelTile(context, '⚙️', 'Settings', () {
                      Navigator.pop(context);
                      context.push('/settings');
                    }),
                    _pixelTile(context, 'ℹ️', 'About', () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppColors.neutralBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.blockEdge, width: 3)),
                          title: const Text('▣ VERASSO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                          content: const Text('A decentralized peer-to-peer knowledge grid for the next generation of explorers.\n\nPhase 2 — Social Feed Active\nv1.0.0', style: TextStyle(color: AppColors.textSecondary, height: 1.6)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.shadowDark, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('v1.0.0 ▪ Phase 2', style: TextStyle(color: AppColors.textSecondary.withAlpha(140), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: feedStream.when(
        data: (posts) {
          return CustomScrollView(
            slivers: [
              // Stories Bar
              SliverToBoxAdapter(child: _StoriesBar()),
              
              // Feed Content
              if (posts.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('The grid is quiet. Be the first to broadcast.')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _PostCard(post: posts[index]),
                      childCount: posts.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Signal Lost: $err', style: const TextStyle(color: AppColors.error))),
      ),
      floatingActionButton: NeoPixelBox(
        padding: 16,
        isButton: true,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
        },
        child: const Icon(Icons.add, color: AppColors.primary),
      ),
    );
  }

  Widget _pixelTile(BuildContext context, String emoji, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 14),
              Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary, letterSpacing: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// Provider: mutual follows (both users follow each other, status = accepted)
final mutualFollowsProvider = FutureProvider<List<String>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return [];

  final me = await Supabase.instance.client
      .from('profiles').select('id').eq('firebase_uid', uid).maybeSingle();
  if (me == null) return [];
  final myId = me['id'] as String;

  // People I follow (accepted)
  final iFollow = await Supabase.instance.client
      .from('follows').select('following_id')
      .eq('follower_id', myId).eq('status', 'accepted');
  final iFollowIds = iFollow.map<String>((r) => r['following_id'] as String).toSet();

  // People who follow me (accepted)
  final followMe = await Supabase.instance.client
      .from('follows').select('follower_id')
      .eq('following_id', myId).eq('status', 'accepted');
  final followMeIds = followMe.map<String>((r) => r['follower_id'] as String).toSet();

  // Intersection = mutual follows
  return iFollowIds.intersection(followMeIds).toList();
});

// Instagram-style Stories Bar — only shows mutual follows
class _StoriesBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutuals = ref.watch(mutualFollowsProvider);

    return Container(
      height: 110,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.shadowDark, width: 2)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "Your Story" add button
          _StoryAvatar(
            label: 'You',
            isAddStory: true,
            avatarUrl: null,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stories broadcasting coming in Phase 3.')),
              );
            },
          ),
          // Only mutual follows appear in stories
          ...mutuals.when(
            data: (ids) => ids.take(10).map((id) => _AuthorStoryAvatar(authorId: id)).toList(),
            loading: () => <Widget>[],
            error: (_, _) => <Widget>[],
          ),
        ],
      ),
    );
  }
}

class _AuthorStoryAvatar extends ConsumerWidget {
  final String authorId;
  const _AuthorStoryAvatar({required this.authorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorAsync = ref.watch(authorProfileProvider(authorId));
    return authorAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return _StoryAvatar(
          label: (profile['display_name'] ?? profile['username'] ?? '?').toString().split(' ').first,
          isAddStory: false,
          avatarUrl: profile['avatar_url'],
          onTap: () {},
        );
      },
      loading: () => const SizedBox(width: 80),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String label;
  final bool isAddStory;
  final String? avatarUrl;
  final VoidCallback onTap;

  const _StoryAvatar({
    required this.label,
    required this.isAddStory,
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAddStory ? AppColors.shadowDark : AppColors.primary,
                  width: 2.5,
                ),
              ),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.shadowDark,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                      ? Icon(
                          isAddStory ? Icons.add : Icons.person,
                          color: isAddStory ? AppColors.primary : AppColors.neutralBg,
                          size: 28,
                        )
                      : null,
                  ),
                  if (isAddStory)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.neutralBg, width: 2),
                        ),
                        child: const Icon(Icons.add, size: 12, color: AppColors.neutralBg),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


class _PostCard extends ConsumerWidget {
  final Map<String, dynamic> post;
  
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorId = post['author_id'] as String?;
    final authorAsync = authorId != null ? ref.watch(authorProfileProvider(authorId)) : null;

    final type = post['type'] ?? 'text';
    final content = post['content'] ?? '';
    final mediaUrl = post['media_url'];
    final isPending = post['_is_pending_sync'] == true;
    final postId = post['id'];
    final likes = post['likes'] ?? 0;
    final hasMath = post['has_math'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: NeoPixelBox(
        padding: 16,
        backgroundColor: type == 'sidequest' ? const Color(0xFFE8D5A3) : AppColors.neutralBg, // Parchment for sidequests
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Head: Author Block
            if (authorAsync != null)
              authorAsync.when(
                data: (profile) {
                  if (profile == null) return const SizedBox.shrink();
                  final name = profile['display_name'] ?? profile['username'] ?? 'Anonymous Node';
                  final avatarUrl = profile['avatar_url'];
                  final role = profile['role'] ?? 'student';

                  return Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.blockEdge,
                          shape: BoxShape.rectangle,
                          border: Border.all(color: AppColors.blockEdge, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: avatarUrl != null 
                          ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover)
                          : const Icon(Icons.person, color: AppColors.neutralBg),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(role.toString().toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 40, child: Align(alignment: Alignment.centerLeft, child: Text('Resolving Identity...'))),
                error: (err, stack) => const SizedBox.shrink(),
              ),

            const SizedBox(height: 16),

            // Body: Content Block
            if (content.toString().isNotEmpty)
              hasMath
                ? Math.tex(content, textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: type == 'sidequest' ? Colors.black87 : null,
                  ))
                : Text(
                    content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: type == 'sidequest' ? Colors.black87 : null,
                      fontWeight: type == 'sidequest' ? FontWeight.bold : null,
                    ),
                  ),
            
            // Media Block (Images / Gifs / Video)
            if (mediaUrl != null) ...[
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.blockEdge, width: 4),
                ),
                child: type == 'video'
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Icon(Icons.play_circle_fill, size: 56, color: AppColors.primary)))
                  : CachedNetworkImage(imageUrl: mediaUrl, fit: BoxFit.cover, width: double.infinity, placeholder: (context, url) => const SizedBox(), errorWidget: (context, url, error)=>const Icon(Icons.error)),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(color: AppColors.shadowDark, thickness: 3),
            const SizedBox(height: 8),

            // Footer: Interactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(Icons.bolt, '$likes Volts${isPending ? ' ⏳' : ''}', () {
                   ref.read(syncEngineProvider).queueLike(postId, likes);
                }, isPending),
                _buildActionButton(Icons.comment, 'Connect', () {
                   // Comment Logic
                }, false),
                _buildActionButton(Icons.share, 'Relay', () {
                   // Share Logic
                }, false),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, bool highlight) {
    return NeoPixelBox(
      padding: 8,
      enableTilt: false,
      isButton: highlight,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: highlight ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: highlight ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
