import 'package:flutter/material.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';

import '../../feed/views/post_detail_screen.dart';
import '../../messaging/views/chat_screen.dart';
import '../../feed/views/view_story_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/follow_service.dart';

final profileHighlightsProvider = FutureProvider.family<Map<String, List<Map<String, dynamic>>>, String>((ref, profileId) async {
  final data = await Supabase.instance.client
      .from('story_highlights')
      .select('title, stories(*)')
      .eq('profile_id', profileId);

  final Map<String, List<Map<String, dynamic>>> grouped = {};
  for (final row in data) {
    final title = row['title'] as String;
    if (row['stories'] != null) {
      grouped.putIfAbsent(title, () => []).add(row['stories']);
    }
  }
  return grouped;
});

/// Screen for viewing another user's profile
class UserProfileScreen extends ConsumerStatefulWidget {
  final String profileId;
  const UserProfileScreen({super.key, required this.profileId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileDataProvider(widget.profileId));
    final postsAsync = ref.watch(profilePostsProvider(widget.profileId));
    final followCountsAsync = ref.watch(followCountsProvider(widget.profileId));
    final followStatusAsync = ref.watch(followStatusProvider(widget.profileId));
    final highlightsAsync = ref.watch(profileHighlightsProvider(widget.profileId));
    final myId = ref.watch(myProfileIdProvider).asData?.value;

    if (profileAsync.isLoading || postsAsync.isLoading || followCountsAsync.isLoading) {
      return Scaffold(body: Center(child: VerassoLoading()));
    }
    
    if (profileAsync.hasError) {
      return Scaffold(body: Center(child: Text("Error loading profile", style: TextStyle(color: context.colors.error))));
    }

    final profile = profileAsync.value;
    final posts = postsAsync.value ?? [];
    final counts = followCountsAsync.value ?? [0, 0];
    final followersCount = counts[0];
    final followingCount = counts[1];
    
    final followStatus = followStatusAsync.value ?? 'none';
    final isSelf = myId != null && myId == widget.profileId;

    final name = profile?['display_name'] ?? profile?['username'] ?? 'Unknown';
    final role = profile?['role'] ?? 'explorer';
    final institution = profile?['institution'] ?? 'Independent';
    final avatarUrl = profile?['avatar_url'];


    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(title: Text(name.toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2))),
      body: CustomScrollView(
        slivers: [
          // Avatar + Info
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 44, backgroundColor: context.colors.accent,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Icon(Icons.person, size: 44, color: context.colors.neutralBg) : null,
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.toString().toUpperCase(), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 32, color: context.colors.primary)),
                        SizedBox(height: 4),
                        Text(role.toString().toUpperCase(), style: TextStyle(fontSize: 12, color: context.colors.accent, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text(institution.toString().toUpperCase(), style: TextStyle(fontSize: 14, color: context.colors.textSecondary)),
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
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: NeoPixelBox(
                padding: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCol('$followersCount', 'Followers'),
                    Container(width: 1, height: 30, color: context.colors.shadowDark),
                    _statCol('$followingCount', 'Following'),
                    Container(width: 1, height: 30, color: context.colors.shadowDark),
                    _statCol('${posts.length}', 'Posts'),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16)),

          if (!isSelf)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: NeoPixelBox(
                        padding: 14, isButton: true,
                        onTap: () async {
                          final followSvc = ref.read(followServiceProvider);
                          if (followStatus == 'none') {
                            await followSvc.sendFollowRequest(widget.profileId);
                          } else {
                            await followSvc.cancelOrUnfollow(widget.profileId);
                          }
                          ref.invalidate(followStatusProvider(widget.profileId));
                        },
                        child: Center(
                          child: Text(
                            followStatus == 'accepted' ? '✓ FOLLOWING' : followStatus == 'pending' ? '⏳ REQUESTED' : '+ FOLLOW',
                            style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1,
                              color: followStatus == 'none' ? context.colors.primary : context.colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 16),
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
                        child: Center(
                          child: Text(
                            'MESSAGE',
                            style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Highlights Section
          highlightsAsync.when(
            data: (highlights) {
              if (highlights.isEmpty) return SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('HIGHLIGHTS', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: highlights.keys.length,
                        itemBuilder: (context, index) {
                          final title = highlights.keys.elementAt(index);
                          final stories = highlights[title]!;
                          final coverUrl = stories.isNotEmpty ? stories.first['media_url'] : null;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ViewStoryScreen(stories: stories)));
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: context.colors.primary, width: 2),
                                      image: coverUrl != null ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover) : null,
                                      color: context.colors.shadowDark,
                                    ),
                                    child: coverUrl == null ? Icon(Icons.bookmark, color: context.colors.primary) : null,
                                  ),
                                  SizedBox(height: 6),
                                  Text(title, style: TextStyle(color: context.colors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              );
            },
            loading: () => SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (err, stack) => SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // Posts header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('POSTS', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Posts list (tappable)
          if (posts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: NeoPixelBox(padding: 24, child: Center(child: Text('No posts yet.', style: TextStyle(color: context.colors.textSecondary)))),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    final content = post['content'] ?? '';
                    final type = post['type'] ?? 'text';
                    final mediaUrl = post['media_url'];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
                        child: NeoPixelBox(
                          padding: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(type == 'audio' ? Icons.mic : type == 'video' ? Icons.videocam : type == 'image' ? Icons.image : Icons.text_fields, size: 16, color: context.colors.accent),
                                SizedBox(width: 6),
                                Text(type.toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.colors.accent)),
                                Spacer(),
                                Icon(Icons.open_in_new, size: 14, color: context.colors.textSecondary),
                              ]),
                              if (mediaUrl != null) ...[
                                SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: type == 'image'
                                      ? Image.network(mediaUrl, height: 160, width: double.infinity, fit: BoxFit.cover)
                                      : Container(
                                          height: 80, width: double.infinity,
                                          color: context.colors.shadowDark,
                                          child: Icon(type == 'audio' ? Icons.graphic_eq : Icons.play_circle_fill, size: 36, color: context.colors.accent),
                                        ),
                                ),
                              ],
                              if (content.toString().isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.colors.textPrimary)),
                              ],
                              SizedBox(height: 8),
                              Text('${post['likes'] ?? 0} Volts', style: TextStyle(fontSize: 11, color: context.colors.textSecondary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: posts.length,
                ),
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _statCol(String count, String label) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: context.colors.textPrimary)),
        SizedBox(height: 2),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.colors.textSecondary, letterSpacing: 1)),
      ],
    );
  }
}
