import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../feed/views/create_post_screen.dart';
import '../../notifications/views/notifications_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _myPosts = [];
  int _followersCount = 0;
  int _followingCount = 0;
  int _pendingRequestsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('firebase_uid', user.uid)
            .maybeSingle();
        if (mounted) setState(() => _profileData = data);

        // Fetch user's posts and follow counts
        if (data != null) {
          final myId = data['id'] as String;

          final posts = await Supabase.instance.client
              .from('posts')
              .select()
              .eq('author_id', myId)
              .order('created_at', ascending: false);

          final followers = await Supabase.instance.client
              .from('follows').select('id')
              .eq('following_id', myId).eq('status', 'accepted');

          final following = await Supabase.instance.client
              .from('follows').select('id')
              .eq('follower_id', myId).eq('status', 'accepted');

          final pendingReqs = await Supabase.instance.client
              .from('follows').select('id')
              .eq('following_id', myId).eq('status', 'pending');

          if (mounted) {
            setState(() {
              _myPosts = List<Map<String, dynamic>>.from(posts);
              _followersCount = followers.length;
              _followingCount = following.length;
              _pendingRequestsCount = pendingReqs.length;
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }



  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.neutralBg,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.blockEdge, width: 2),
        ),
        title: const Text('DELETE POST?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('posts').delete().eq('id', postId);
        setState(() => _myPosts.removeWhere((p) => p['id'] == postId));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _statBlock(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
      ],
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final name = _profileData?['username'] ?? _profileData?['display_name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Unknown Explorer';
    final role = _profileData?['role'] ?? 'explorer';
    final institution = _profileData?['institute'] ?? 'Independent';
    final List<dynamic> badges = _profileData?['badges'] ?? [];
    final avatarUrl = _profileData?['avatar_url'];
    final questTitle = _profileData?['sidequest_title'] ?? 'Wanderer';
    final questStreak = _profileData?['sidequest_streak'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Banner + Avatar + Menu
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.shadowDark,
                      border: const Border(bottom: BorderSide(color: AppColors.blockEdge, width: 2)),
                    ),
                    child: Image.asset(
                      'assets/images/role_$role.gif',
                      fit: BoxFit.cover, width: double.infinity, height: 180,
                      errorBuilder: (ctx, err, stack) => Container(
                        color: AppColors.primary.withAlpha(30),
                        child: const Center(child: Icon(Icons.public, size: 48, color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.neutralBg.withAlpha(180),
                        border: Border.all(color: AppColors.blockEdge, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                        onPressed: () => context.push('/settings'),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -44, left: 24,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.neutralBg, shape: BoxShape.circle,
                        border: Border.all(color: AppColors.blockEdge, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 44, backgroundColor: AppColors.accent,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null ? const Icon(Icons.person, size: 44, color: AppColors.neutralBg) : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 54)),

            // Name + Post button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.toString().toUpperCase(), style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 22, color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Text(institution.toString().toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.blockEdge),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('⚔️ ${questTitle.toString().toUpperCase()}', style: const TextStyle(fontSize: 10, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              if (questStreak > 0)
                                Row(
                                  children: [
                                    const Text('🔥 ', style: TextStyle(fontSize: 12)),
                                    Text('$questStreak', style: const TextStyle(fontSize: 12, color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    NeoPixelBox(
                      isButton: true, padding: 12,
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
                        _fetchProfile(); // Refresh posts after creating
                      },
                      child: const Row(children: [
                        Icon(Icons.edit, size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('POST', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Stats Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _statBlock('$_followersCount', 'Followers'),
                    const SizedBox(width: 16),
                    _statBlock('$_followingCount', 'Following'),
                    const SizedBox(width: 16),
                    _statBlock('${_myPosts.length}', 'Posts'),
                    if (_pendingRequestsCount > 0) ...[
                      const Spacer(),
                      NeoPixelBox(
                        padding: 10, isButton: true,
                        onTap: () => _openNotifications(),
                        child: Row(children: [
                          const Icon(Icons.person_add, size: 16, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text('$_pendingRequestsCount', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Badges
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BADGES', style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 12),
                    NeoPixelBox(
                      padding: 16,
                      child: badges.isEmpty
                          ? const Text('No badges earned yet.', style: TextStyle(color: AppColors.textSecondary))
                          : Wrap(
                              spacing: 8, runSpacing: 8,
                              children: badges.map((b) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: AppColors.accent, border: Border.all(color: AppColors.blockEdge, width: 2)),
                                child: Text(b.toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              )).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // My Posts Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('MY POSTS', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // My Posts List
            if (_myPosts.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: NeoPixelBox(
                    padding: 24,
                    child: Center(child: Text('You haven\'t posted yet. Broadcast your first signal!', style: TextStyle(color: AppColors.textSecondary))),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = _myPosts[index];
                      final content = post['content'] ?? '';
                      final type = post['type'] ?? 'text';
                      final mediaUrl = post['media_url'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: NeoPixelBox(
                          padding: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Post type + actions row
                              Row(
                                children: [
                                  Icon(
                                    type == 'audio' ? Icons.mic : type == 'video' ? Icons.videocam : type == 'image' ? Icons.image : Icons.text_fields,
                                    size: 16, color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(type.toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                    onPressed: () => _deletePost(post['id']),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              if (content.toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(content, style: const TextStyle(color: AppColors.textPrimary)),
                              ],
                              if (mediaUrl != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.blockEdge, width: 2),
                                  ),
                                  child: type == 'image'
                                      ? Image.network(mediaUrl, fit: BoxFit.cover)
                                      : Center(child: Icon(type == 'audio' ? Icons.graphic_eq : Icons.play_circle, size: 40, color: AppColors.primary)),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text('${post['likes'] ?? 0} Volts', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _myPosts.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}
