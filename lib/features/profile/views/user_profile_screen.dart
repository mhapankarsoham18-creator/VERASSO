import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../feed/views/post_detail_screen.dart';
import '../../messaging/views/chat_screen.dart';

/// Screen for viewing another user's profile
class UserProfileScreen extends StatefulWidget {
  final String profileId;
  const UserProfileScreen({super.key, required this.profileId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _posts = [];
  String? _myProfileId;
  String _followStatus = 'none'; // none, pending, accepted
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Get my profile id
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final me = await Supabase.instance.client
          .from('profiles').select('id').eq('firebase_uid', uid).maybeSingle();
      _myProfileId = me?['id'];
    }

    // Fetch target profile
    final profile = await Supabase.instance.client
        .from('profiles').select().eq('id', widget.profileId).maybeSingle();

    // Fetch their posts
    final posts = await Supabase.instance.client
        .from('posts').select().eq('author_id', widget.profileId)
        .order('created_at', ascending: false);

    // Fetch follow counts
    final followers = await Supabase.instance.client
        .from('follows').select('id')
        .eq('following_id', widget.profileId).eq('status', 'accepted');
    final following = await Supabase.instance.client
        .from('follows').select('id')
        .eq('follower_id', widget.profileId).eq('status', 'accepted');

    // Check follow status
    if (_myProfileId != null) {
      final follow = await Supabase.instance.client
          .from('follows')
          .select('status')
          .eq('follower_id', _myProfileId!)
          .eq('following_id', widget.profileId)
          .maybeSingle();
      if (follow != null) {
        _followStatus = follow['status'] ?? 'pending';
      }
    }

    if (mounted) {
      setState(() {
        _profile = profile;
        _posts = List<Map<String, dynamic>>.from(posts);
        _followersCount = followers.length;
        _followingCount = following.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFollowRequest() async {
    if (_myProfileId == null) return;
    try {
      await Supabase.instance.client.from('follows').insert({
        'follower_id': _myProfileId!,
        'following_id': widget.profileId,
        'status': 'pending',
      });
      setState(() => _followStatus = 'pending');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _unfollow() async {
    if (_myProfileId == null) return;
    await Supabase.instance.client.from('follows')
        .delete().eq('follower_id', _myProfileId!).eq('following_id', widget.profileId);
    setState(() {
      _followStatus = 'none';
      _followersCount = (_followersCount - 1).clamp(0, 999999);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final name = _profile?['display_name'] ?? _profile?['username'] ?? 'Unknown';
    final role = _profile?['role'] ?? 'explorer';
    final institution = _profile?['institution'] ?? 'Independent';
    final avatarUrl = _profile?['avatar_url'];
    final isSelf = _myProfileId == widget.profileId;

    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(title: Text(name.toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2))),
      body: CustomScrollView(
        slivers: [
          // Avatar + Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 44, backgroundColor: AppColors.accent,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? const Icon(Icons.person, size: 44, color: AppColors.neutralBg) : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.toString().toUpperCase(), style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 20, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(role.toString().toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(institution.toString().toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: NeoPixelBox(
                padding: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCol('$_followersCount', 'Followers'),
                    Container(width: 1, height: 30, color: AppColors.shadowDark),
                    _statCol('$_followingCount', 'Following'),
                    Container(width: 1, height: 30, color: AppColors.shadowDark),
                    _statCol('${_posts.length}', 'Posts'),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          if (!isSelf)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: NeoPixelBox(
                        padding: 14, isButton: true,
                        onTap: () {
                          if (_followStatus == 'none') {
                            _sendFollowRequest();
                          } else {
                            _unfollow();
                          }
                        },
                        child: Center(
                          child: Text(
                            _followStatus == 'accepted' ? '✓ FOLLOWING' : _followStatus == 'pending' ? '⏳ REQUESTED' : '+ FOLLOW',
                            style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1,
                              color: _followStatus == 'none' ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: NeoPixelBox(
                        padding: 14, isButton: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                peerId: widget.profileId,
                                peerName: name.toString(),
                              ),
                            ),
                          );
                        },
                        child: const Center(
                          child: Text(
                            'MESSAGE',
                            style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Posts header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('POSTS', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Posts list (tappable)
          if (_posts.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: NeoPixelBox(padding: 24, child: Center(child: Text('No posts yet.', style: TextStyle(color: AppColors.textSecondary)))),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = _posts[index];
                    final content = post['content'] ?? '';
                    final type = post['type'] ?? 'text';
                    final mediaUrl = post['media_url'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
                        child: NeoPixelBox(
                          padding: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(type == 'audio' ? Icons.mic : type == 'video' ? Icons.videocam : type == 'image' ? Icons.image : Icons.text_fields, size: 16, color: AppColors.accent),
                                const SizedBox(width: 6),
                                Text(type.toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent)),
                                const Spacer(),
                                const Icon(Icons.open_in_new, size: 14, color: AppColors.textSecondary),
                              ]),
                              if (mediaUrl != null) ...[
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: type == 'image'
                                      ? Image.network(mediaUrl, height: 160, width: double.infinity, fit: BoxFit.cover)
                                      : Container(
                                          height: 80, width: double.infinity,
                                          color: AppColors.shadowDark,
                                          child: Icon(type == 'audio' ? Icons.graphic_eq : Icons.play_circle_fill, size: 36, color: AppColors.accent),
                                        ),
                                ),
                              ],
                              if (content.toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary)),
                              ],
                              const SizedBox(height: 8),
                              Text('${post['likes'] ?? 0} Volts', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _posts.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _statCol(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
      ],
    );
  }
}
