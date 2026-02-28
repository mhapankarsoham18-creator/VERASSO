import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/ui/glass_container.dart';
import '../../../core/ui/liquid_background.dart';
import '../models/search_results.dart';
import 'search_controller.dart';

/// Screen for performing and displaying searches across various content types.
class SearchScreen extends ConsumerStatefulWidget {
  /// Creates a [SearchScreen].
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search users, posts, groups...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      icon: Icon(LucideIcons.search, color: Colors.white70),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                onTap: (_) => _onSearchChanged(),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'People'),
                  Tab(text: 'Posts'),
                  Tab(text: 'Groups'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: LiquidBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAllTab(searchState),
            _buildUsersTab(searchState),
            _buildPostsTab(searchState),
            _buildGroupsTab(searchState),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  Widget _buildAllTab(AsyncValue<SearchResults> state) {
    return state.when(
      data: (results) {
        if (_searchController.text.isEmpty) {
          return _buildEmptyState('Start typing to search');
        }
        if (results.isEmpty) {
          return _buildEmptyState('No results found');
        }

        return ListView(
          padding:
              const EdgeInsets.only(top: 180, left: 16, right: 16, bottom: 20),
          children: [
            if (results.users.isNotEmpty) ...[
              _buildSectionHeader('People', results.users.length),
              ...results.users.take(3).map((user) => _buildUserTile(user)),
              if (results.users.length > 3)
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('See all people'),
                ),
              const SizedBox(height: 16),
            ],
            if (results.posts.isNotEmpty) ...[
              _buildSectionHeader('Posts', results.posts.length),
              ...results.posts.take(3).map((post) => _buildPostTile(post)),
              if (results.posts.length > 3)
                TextButton(
                  onPressed: () => _tabController.animateTo(2),
                  child: const Text('See all posts'),
                ),
              const SizedBox(height: 16),
            ],
            if (results.groups.isNotEmpty) ...[
              _buildSectionHeader('Groups', results.groups.length),
              ...results.groups.take(3).map((group) => _buildGroupTile(group)),
              if (results.groups.length > 3)
                TextButton(
                  onPressed: () => _tabController.animateTo(3),
                  child: const Text('See all groups'),
                ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.search, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildGroupsTab(AsyncValue<SearchResults> state) {
    return state.when(
      data: (results) {
        if (_searchController.text.isEmpty) {
          return _buildEmptyState('Search for groups');
        }
        if (results.groups.isEmpty) {
          return _buildEmptyState('No groups found');
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(top: 180, left: 16, right: 16, bottom: 20),
          itemCount: results.groups.length,
          itemBuilder: (context, index) =>
              _buildGroupTile(results.groups[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildGroupTile(GroupSearchResult group) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                group.avatarUrl != null ? NetworkImage(group.avatarUrl!) : null,
            child:
                group.avatarUrl == null ? const Icon(LucideIcons.users) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (group.description != null)
                  Text(
                    group.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  '${group.memberCount} members',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(AsyncValue<SearchResults> state) {
    return state.when(
      data: (results) {
        if (_searchController.text.isEmpty) {
          return _buildEmptyState('Search for posts');
        }
        if (results.posts.isEmpty) {
          return _buildEmptyState('No posts found');
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(top: 180, left: 16, right: 16, bottom: 20),
          itemCount: results.posts.length,
          itemBuilder: (context, index) => _buildPostTile(results.posts[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildPostTile(PostSearchResult post) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: post.authorAvatar != null
                    ? NetworkImage(post.authorAvatar!)
                    : null,
                child: post.authorAvatar == null
                    ? Text((post.authorName ?? 'U')[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                post.authorName ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.content,
            style: const TextStyle(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUsersTab(AsyncValue<SearchResults> state) {
    return state.when(
      data: (results) {
        if (_searchController.text.isEmpty) {
          return _buildEmptyState('Search for people');
        }
        if (results.users.isEmpty) {
          return _buildEmptyState('No users found');
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(top: 180, left: 16, right: 16, bottom: 20),
          itemCount: results.users.length,
          itemBuilder: (context, index) => _buildUserTile(results.users[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildUserTile(UserSearchResult user) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(user.fullName[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (user.bio != null)
                  Text(
                    user.bio!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text;
      if (query.isEmpty) {
        ref.read(searchControllerProvider.notifier).clear();
        return;
      }

      switch (_tabController.index) {
        case 0:
          ref.read(searchControllerProvider.notifier).search(query);
          break;
        case 1:
          ref.read(searchControllerProvider.notifier).searchUsers(query);
          break;
        case 2:
          ref.read(searchControllerProvider.notifier).searchPosts(query);
          break;
        case 3:
          ref.read(searchControllerProvider.notifier).searchGroups(query);
          break;
      }
    });
  }
}
