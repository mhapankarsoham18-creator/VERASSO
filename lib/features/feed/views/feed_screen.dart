import 'package:flutter/material.dart';
import 'package:verasso/core/widgets/verasso_snackbar.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:share_plus/share_plus.dart';
import 'create_post_screen.dart';
import 'comments_sheet.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../repositories/feed_repository.dart';
import '../repositories/sync_engine.dart';
// Unused imports from phase 4 router swap removed

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
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: context.colors.textPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text('HOME', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: context.colors.textPrimary),
            onPressed: () {
              context.push('/notifications');
            },
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: context.colors.textPrimary),
            onPressed: () {
              context.push('/messages');
            },
          ),
          SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        backgroundColor: context.colors.neutralBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawer Header — retro pixel brand
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: context.colors.blockEdge, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('▣ VERASSO', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 26, letterSpacing: 3)),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.colors.accent, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('P2P KNOWLEDGE GRID', style: TextStyle(color: context.colors.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                  ],
                ),
              ),
              // Scrollable nav items — prevents overflow
              Expanded(
                child: ListView(
                  padding: EdgeInsets.only(top: 12),
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
                      context.go('/shell/science');
                    }),
                    _pixelTile(context, '⚔️', 'Sidequests', () {
                      Navigator.pop(context);
                      context.push('/sidequests');
                    }),
                    _pixelTile(context, '🌌', 'Astro Hub', () {
                      Navigator.pop(context);
                      // User will implement Astro here later
                    }),
                    _pixelTile(context, '❓', 'Doubts', () {
                      Navigator.pop(context);
                      context.push('/doubts');
                    }),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(height: 2, color: context.colors.blockEdge),
                    ),
                    _pixelTile(context, '💬', 'Messages', () {
                      Navigator.pop(context);
                      context.push('/messages');
                    }),
                    _pixelTile(context, '🔔', 'Notifications', () {
                      Navigator.pop(context);
                      context.push('/notifications');
                    }),
                    _pixelTile(context, '👤', 'Profile', () {
                      Navigator.pop(context);
                      context.go('/shell/profile');
                    }),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(height: 2, color: context.colors.blockEdge),
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
                          backgroundColor: context.colors.neutralBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: context.colors.blockEdge, width: 3)),
                          title: Text('▣ VERASSO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                          content: Text('A decentralized peer-to-peer knowledge grid for the next generation of explorers.\n\nPhase 2 — Social Feed Active\nv1.0.0', style: TextStyle(color: context.colors.textSecondary, height: 1.6)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text('CLOSE', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.colors.shadowDark, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: context.colors.accent, shape: BoxShape.circle)),
                      SizedBox(width: 8),
                      Text('v1.0.0 ▪ Phase 2', style: TextStyle(color: context.colors.textSecondary.withAlpha(140), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                SliverFillRemaining(
                  child: Center(child: Text('The grid is quiet. Be the first to broadcast.')),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.all(16),
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
        loading: () => Center(child: VerassoLoading()),
        error: (err, stack) => Center(child: Text('Signal Lost: $err', style: TextStyle(color: context.colors.error))),
      ),
      floatingActionButton: NeoPixelBox(
        padding: 16,
        isButton: true,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatePostScreen()));
        },
        child: Icon(Icons.add, color: context.colors.primary),
      ),
    );
  }

  Widget _pixelTile(BuildContext context, String emoji, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 18)),
              SizedBox(width: 14),
              Text(label.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.colors.textPrimary, letterSpacing: 1.5)),
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
      padding: EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.shadowDark, width: 2)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "Your Story" add button
          _StoryAvatar(
            label: 'You',
            isAddStory: true,
            avatarUrl: null,
            onTap: () {
              VerassoSnackbar.show(context, message: 'Stories broadcasting coming in Phase 3.');
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
        if (profile == null) return SizedBox.shrink();
        return _StoryAvatar(
          label: (profile['display_name'] ?? profile['username'] ?? '?').toString().split(' ').first,
          isAddStory: false,
          avatarUrl: profile['avatar_url'],
          onTap: () {},
        );
      },
      loading: () => SizedBox(width: 80),
      error: (_, _) => SizedBox.shrink(),
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
        padding: EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAddStory ? context.colors.shadowDark : context.colors.primary,
                  width: 2.5,
                ),
              ),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: context.colors.shadowDark,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                      ? Icon(
                          isAddStory ? Icons.add : Icons.person,
                          color: isAddStory ? context.colors.primary : context.colors.neutralBg,
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
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.neutralBg, width: 2),
                        ),
                        child: Icon(Icons.add, size: 12, color: context.colors.neutralBg),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.colors.textSecondary),
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
      padding: EdgeInsets.only(bottom: 24.0),
      child: NeoPixelBox(
        padding: 16,
        backgroundColor: type == 'sidequest' ? Color(0xFFE8D5A3) : context.colors.neutralBg, // Parchment for sidequests
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Head: Author Block
            if (authorAsync != null)
              authorAsync.when(
                data: (profile) {
                  if (profile == null) return SizedBox.shrink();
                  final name = profile['display_name'] ?? profile['username'] ?? 'Anonymous Node';
                  final avatarUrl = profile['avatar_url'];
                  final role = profile['role'] ?? 'student';

                  return Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colors.blockEdge,
                          shape: BoxShape.rectangle,
                          border: Border.all(color: context.colors.blockEdge, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: avatarUrl != null 
                          ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover, memCacheWidth: 200, memCacheHeight: 200)
                          : Icon(Icons.person, color: context.colors.neutralBg),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                            SizedBox(height: 4),
                            Text(role.toString().toUpperCase(), style: TextStyle(fontSize: 10, color: context.colors.accent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => SizedBox(height: 40, child: Align(alignment: Alignment.centerLeft, child: Text('Resolving Identity...'))),
                error: (err, stack) => SizedBox.shrink(),
              ),

            SizedBox(height: 16),

            // Body: Content Block
            if (content.toString().isNotEmpty)
              hasMath
                ? Math.tex(content, textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: type == 'sidequest' ? context.colors.neutralBg : null,
                  ))
                : Text(
                    content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: type == 'sidequest' ? context.colors.neutralBg : null,
                      fontWeight: type == 'sidequest' ? FontWeight.bold : null,
                    ),
                  ),
            
            // Media Block (Images / Gifs / Video)
            if (mediaUrl != null) ...[
              SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  border: Border.all(color: context.colors.blockEdge, width: 4),
                ),
                child: type == 'video'
                  ? Center(child: Padding(padding: EdgeInsets.all(24), child: Icon(Icons.play_circle_fill, size: 56, color: context.colors.primary)))
                  : CachedNetworkImage(imageUrl: mediaUrl, fit: BoxFit.cover, width: double.infinity, placeholder: (context, url) => SizedBox(), errorWidget: (context, url, error)=>Icon(Icons.error)),
              ),
            ],

            SizedBox(height: 16),
            Divider(color: context.colors.shadowDark, thickness: 3),
            SizedBox(height: 8),

            // Footer: Interactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(context, Icons.bolt, '$likes Volts${isPending ? ' ⏳' : ''}', () {
                   ref.read(syncEngineProvider).queueLike(postId, likes);
                }, isPending),
                _buildActionButton(context, Icons.comment, 'Connect', () {
                   showModalBottomSheet(
                     context: context,
                     isScrollControlled: true,
                     backgroundColor: Colors.transparent,
                     builder: (context) => CommentsSheet(postId: postId),
                   );
                }, false),
                _buildActionButton(context, Icons.bookmark_border, 'Save', () async {
                   final user = FirebaseAuth.instance.currentUser;
                   if (user != null) {
                     try {
                       await Supabase.instance.client.from('post_saves').upsert({
                         'user_id': user.uid,
                         'post_id': postId,
                       });
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to your vault.')));
                       }
                     } catch (e) {
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save.')));
                       }
                     }
                   } else {
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please log in.')));
                     }
                   }
                }, false),
                _buildActionButton(context, Icons.share, 'Relay', () {
                   final shareText = 'Check out this transmission on Verasso! verasso://post/$postId\n\n"${content.toString().length > 50 ? '${content.toString().substring(0, 50)}...' : content}"';
                   SharePlus.instance.share(ShareParams(text: shareText));
                }, false),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap, bool highlight) {
    return NeoPixelBox(
      padding: 8,
      enableTilt: false,
      isButton: highlight,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: highlight ? context.colors.primary : context.colors.textSecondary),
          SizedBox(width: 4),
          Text(label, style: TextStyle(color: highlight ? context.colors.primary : context.colors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
