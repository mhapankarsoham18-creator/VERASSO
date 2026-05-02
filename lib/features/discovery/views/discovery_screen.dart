import 'package:flutter/material.dart';
import 'dart:async';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../profile/views/user_profile_screen.dart';
import '../../feed/views/post_detail_screen.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/services/profile_lookup_service.dart';
import 'package:verasso/core/utils/logger.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _userResults = [];
  List<Map<String, dynamic>> _postResults = [];
  List<Map<String, dynamic>> _suggestions = [];
  // Maps targetId -> status (pending, accepted, none)
  Map<String, String> _followStatuses = {};
  String? _myProfileId;
  bool _isSearching = false;
  String _activeTab = 'suggested';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
  }

  Future<void> _loadMyProfile() async {
    try {
      _myProfileId = await ref.read(profileLookupProvider).getMyProfileId();
      if (mounted) {
        await _loadFollowStatuses();
        await _loadSuggestions();
      }
    } catch (e) {
      appLogger.d('Not logged in or profile missing.');
    }
  }

  Future<void> _loadFollowStatuses() async {
    if (_myProfileId == null) return;
    final rows = await Supabase.instance.client
        .from('follows')
        .select('following_id, status')
        .eq('follower_id', _myProfileId!);
    if (mounted) {
      setState(() {
        _followStatuses = {
          for (final r in rows) r['following_id'] as String: r['status'] as String,
        };
      });
    }
  }

  Future<void> _loadSuggestions() async {
    if (_myProfileId == null) return;

    try {
      final List<dynamic> rpcResults = await Supabase.instance.client
          .rpc('get_friend_suggestions', params: {'viewer_id': _myProfileId});

      if (mounted) {
        setState(() {
          _suggestions = List<Map<String, dynamic>>.from(rpcResults.map((r) => {
                'id': r['id'],
                'username': r['username'],
                'display_name': r['display_name'],
                'avatar_url': r['avatar_url'],
                'bio': r['bio'],
                '_mutual_count': r['mutual_count'] ?? 0,
              }));
        });
      }
    } catch (e) {
      appLogger.d('Error loading suggestions RPC: $e');
    }
  }

  Future<void> _sendFollowRequest(String targetId) async {
    if (_myProfileId == null) return;
    try {
      await ref.read(followServiceProvider).sendFollowRequest(targetId);
      setState(() => _followStatuses[targetId] = 'pending');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _cancelOrUnfollow(String targetId) async {
    if (_myProfileId == null) return;
    try {
      await ref.read(followServiceProvider).cancelOrUnfollow(targetId);
      setState(() => _followStatuses.remove(targetId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _openProfile(String profileId) {
    // Don't open own profile
    if (profileId == _myProfileId) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfileScreen(profileId: profileId)),
    );
  }

  void _search(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.trim().isEmpty) {
      setState(() { _userResults = []; _postResults = []; _isSearching = false; });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);

      try {
        // Optimized RPC search for 2B+ users
        final List<dynamic> users = await Supabase.instance.client
            .rpc('search_profiles', params: {'search_query': query, 'limit_val': 20});

        // Filter out self from user results
        final filteredUsers = List<Map<String, dynamic>>.from(users)
          ..removeWhere((u) => u['id'] == _myProfileId);

        // Posts still use ilike for now, but also limited
        final posts = await Supabase.instance.client
            .from('posts')
            .select()
            .ilike('content', '%$query%')
            .order('created_at', ascending: false)
            .limit(20);

        if (mounted) {
          setState(() {
            _userResults = filteredUsers;
            _postResults = List<Map<String, dynamic>>.from(posts);
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('DISCOVERY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: NeoPixelBox(
              padding: 8,
              enableTilt: false,
              child: TextField(
                controller: _searchCtrl,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Search users or posts...',
                  prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Tab Toggle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _tabButton('Suggested', 'suggested'),
                SizedBox(width: 8),
                _tabButton('Users', 'users'),
                SizedBox(width: 8),
                _tabButton('Posts', 'posts'),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Results
          Expanded(
            child: _isSearching
                ? Center(child: VerassoLoading())
                : _activeTab == 'suggested'
                    ? _buildSuggestions()
                    : _searchCtrl.text.isEmpty
                        ? Center(child: Text('Start typing to discover users and posts.', style: TextStyle(color: context.colors.textSecondary)))
                        : _activeTab == 'users'
                            ? _buildUserResults()
                            : _buildPostResults(),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, String tab) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: NeoPixelBox(
        padding: 10,
        isButton: true,
        onTap: () => setState(() => _activeTab = tab),
        child: Center(
          child: Text(label, style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12,
            color: isActive ? context.colors.primary : context.colors.textSecondary,
          )),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['display_name'] ?? user['username'] ?? 'Unknown';
    final avatarUrl = user['avatar_url'];
    final role = user['role'] ?? 'student';
    final userId = user['id'] as String;
    final status = _followStatuses[userId]; // null = not following, 'pending', 'accepted'

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _openProfile(userId),
        child: NeoPixelBox(
          padding: 12,
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: context.colors.blockEdge,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.blockEdge, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarUrl != null
                    ? Image.network(avatarUrl, fit: BoxFit.cover)
                    : Icon(Icons.person, color: context.colors.neutralBg),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text(role.toString().toUpperCase(), style: TextStyle(fontSize: 11, color: context.colors.accent, fontWeight: FontWeight.bold)),
                    if (user['_mutual_count'] != null && (user['_mutual_count'] as int) > 0)
                      Text('${user['_mutual_count']} mutual(s)', style: TextStyle(fontSize: 10, color: context.colors.textSecondary)),
                  ],
                ),
              ),
              NeoPixelBox(
                padding: 8,
                isButton: true,
                onTap: () {
                  if (status == null) {
                    _sendFollowRequest(userId);
                  } else {
                    _cancelOrUnfollow(userId);
                  }
                },
                child: Text(
                  status == 'accepted' ? 'FOLLOWING' : status == 'pending' ? 'REQUESTED' : 'FOLLOW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: status == null ? context.colors.primary : context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserResults() {
    if (_userResults.isEmpty) {
      return Center(child: Text('No users found.', style: TextStyle(color: context.colors.textSecondary)));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _userResults.length,
      itemBuilder: (context, index) => _buildUserCard(_userResults[index]),
    );
  }

  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) {
      return Center(child: Text('No suggestions yet. Follow some people first!', style: TextStyle(color: context.colors.textSecondary)));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) => _buildUserCard(_suggestions[index]),
    );
  }

  Widget _buildPostResults() {
    if (_postResults.isEmpty) {
      return Center(child: Text('No posts found.', style: TextStyle(color: context.colors.textSecondary)));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _postResults.length,
      itemBuilder: (context, index) {
        final post = _postResults[index];
        final content = post['content'] ?? '';
        final type = post['type'] ?? 'text';

        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(post: post))),
            child: NeoPixelBox(
              padding: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        type == 'audio' ? Icons.mic : type == 'video' ? Icons.videocam : type == 'image' ? Icons.image : Icons.text_fields,
                        size: 16, color: context.colors.accent,
                      ),
                      SizedBox(width: 8),
                      Text(type.toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.colors.accent)),
                      Spacer(),
                      Icon(Icons.open_in_new, size: 14, color: context.colors.textSecondary),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.colors.textPrimary)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

