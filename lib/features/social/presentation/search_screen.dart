import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/theme/design_system.dart';
import 'package:verasso/core/ui/empty_state_widget.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/list_skeleton.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../learning/data/course_models.dart';
import '../../learning/data/course_repository.dart';
import '../../learning/presentation/marketplace/course_player_screen.dart';
import '../../news/presentation/news_screen.dart';
import '../../talent/data/talent_profile_model.dart';
import '../../talent/presentation/professional_profile_screen.dart';
import '../data/community_model.dart';
import '../data/community_repository.dart';
import '../data/post_model.dart';
import '../presentation/feed_controller.dart';
import 'discovery_widgets.dart';
import 'search_controller.dart'
    as sc; // Alias to avoid clash with Flutter's SearchController if needed
import 'user_profile_screen.dart';

/// Social discovery and search hub for people, posts, courses, and mentors.
///
/// Combines a global discovery feed, facet filters, and a tabbed search
/// experience over communities, posts, learning content, and mentors.
class DiscoverScreen extends ConsumerStatefulWidget {
  /// Creates a [DiscoverScreen] instance.
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchFieldController = TextEditingController();
  String _selectedCategory = 'All';
  bool _filterOnlyFree = false;
  bool _filterTopRated = false;

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(sc.searchControllerProvider);
    final isSearching = _searchFieldController.text.isNotEmpty;
    // For explore feed, we can reuse feedProvider or create a specialized 'exploreProvider'
    // For now, let's reuse feedProvider which returns recommended posts
    final exploreAsync = ref.watch(feedProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: LiquidBackground(
        child: SafeArea(
          // Use SafeArea roughly or custom padding
          child: Column(
            children: [
              // News Ticker
              const NewsTicker(),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Search for people, posts, courses, or mentors',
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchFieldController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Discover people & ideas...',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                              icon: Icon(LucideIcons.compass,
                                  color: Colors.white54),
                            ),
                            onChanged: (val) {
                              ref
                                  .read(sc.searchControllerProvider.notifier)
                                  .search(val);
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(LucideIcons.sliders,
                          color: (_filterOnlyFree || _filterTopRated)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white54),
                      onPressed: () => _showFilterModal(),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isSearching
                    ? _buildSearchResults(searchState)
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(feedProvider);
                          ref.invalidate(sc.searchControllerProvider);
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryPills(),
                              FutureBuilder<List<Community>>(
                                future: ref
                                    .read(communityRepositoryProvider)
                                    .getRecommendedCommunities(),
                                builder: (context, snapshot) =>
                                    _buildCommunityCarousel(
                                        snapshot.data ?? []),
                              ),
                              FutureBuilder<List<Course>>(
                                future: ref
                                    .read(courseRepositoryProvider)
                                    .getPublishedCourses(),
                                builder: (context, snapshot) => snapshot
                                            .hasData &&
                                        snapshot.data!.isNotEmpty
                                    ? TrendingCarousel(courses: snapshot.data!)
                                    : const SizedBox.shrink(),
                              ),
                              _buildRecommendedUsers(exploreAsync),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                child: Text('Explore Community',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              _buildExploreGrid(ref, exploreAsync),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Horizontal list of category chips used to filter explore posts.
  Widget _buildCategoryPills() {
    return SizedBox(
      height: 50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _buildPill('All'),
          _buildPill('Coding'),
          _buildPill('Science'),
          _buildPill('Business'),
          _buildPill('Arts'),
          // Special News Pill
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              label: 'Global Pulse News',
              button: true,
              child: ActionChip(
                avatar: const Icon(LucideIcons.newspaper,
                    size: 14, color: Colors.orangeAccent),
                label: const Text('Global Pulse'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NewsScreen()));
                },
                backgroundColor: Colors.orangeAccent.withValues(alpha: 0.1),
                labelStyle:
                    const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: Colors.orangeAccent.withValues(alpha: 0.3))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Carousel of matching [Community] cards for the current search.
  Widget _buildCommunityCarousel(List<Community> communities) {
    if (communities.isEmpty) {
      // Show empty state or recommended communities if search is empty
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(LucideIcons.users, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context)!.subjectCommunities,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: Semantics(
                  label:
                      'Community: ${community.name}. ${community.description}. ${community.memberCount} members.',
                  button: true,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(community.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(community.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white70)),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${community.memberCount} nodes',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.cyanAccent)),
                            Text(community.subject,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.white54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// List view of community search results.
  Widget _buildCommunityResults(List<Community> results) {
    if (results.isEmpty) {
      return const EmptyStateWidget(
        title: 'Network Echo',
        message: 'No communities found matching your query.',
        icon: LucideIcons.users,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final community = results[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.users, color: Colors.cyanAccent),
          ),
          title: Text(community.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle:
              Text('${community.subject} • ${community.memberCount} nodes'),
          onTap: () {
            HapticFeedback.selectionClick();
            // Go to community detail view
          },
        );
      },
    );
  }

  /// List view of course search results with free/top-rated filters applied.
  Widget _buildCourseResults(List<Course> results) {
    var filtered = results;
    if (_filterOnlyFree) {
      filtered = filtered.where((c) => c.price == 0).toList();
    }
    // Rating logic if added to Course model later, for now placeholder

    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        title: 'Library is Quiet',
        message: 'No matching courses found.',
        icon: LucideIcons.bookOpen,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final course = filtered[index];
        return ListTile(
          leading: Icon(LucideIcons.bookOpen,
              color: Theme.of(context).colorScheme.primary),
          title: Text(course.title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
              '${course.price > 0 ? "\$${course.price.toStringAsFixed(0)}" : "FREE"} • Expert Course'),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CoursePlayerScreen(course: course))),
        );
      },
    );
  }

  /// Grid of explore posts driven by the social feed provider.
  Widget _buildExploreGrid(WidgetRef ref, AsyncValue<List<Post>> exploreAsync) {
    return exploreAsync.when(
      data: (posts) {
        final filtered = _selectedCategory == 'All'
            ? posts
            : posts
                .where((p) =>
                    p.content
                        ?.toLowerCase()
                        .contains(_selectedCategory.toLowerCase()) ??
                    false)
                .toList();

        if (filtered.isEmpty) {
          return const EmptyStateWidget(
            title: 'Uncharted Territory',
            message: 'No posts in this category yet.',
            icon: LucideIcons.map,
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final post = filtered[index];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => UserProfileScreen(userId: post.userId))),
              child: GlassContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: post.mediaUrls.isNotEmpty
                            ? Image.network(post.mediaUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image,
                                        size: 40, color: Colors.white24))
                            : Container(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.05),
                                padding: const EdgeInsets.all(12),
                                child: Text(post.content ?? '',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white70),
                                    overflow: TextOverflow.fade),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundImage: post.authorAvatar != null
                                ? NetworkImage(post.authorAvatar!)
                                : null,
                            child: post.authorAvatar == null
                                ? const Icon(LucideIcons.user, size: 10)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              post.authorName ?? 'User',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(
                    delay: (index * 30).ms,
                    duration: DesignSystem.durationMedium,
                    curve: DesignSystem.easingStandard)
                .slideY(
                    begin: 0.05, end: 0, curve: DesignSystem.easingDecelerate);
          },
        );
      },
      loading: () => const ListSkeleton(itemCount: 10),
      error: (e, s) => AppErrorView(
        title: 'Could not load explore',
        message: e.toString(),
        onRetry: () => ref.invalidate(feedProvider),
      ),
    );
  }

  /// List view of mentor profile results from the talent search.
  Widget _buildMentorResults(List<TalentProfile> results) {
    var filtered = results;
    // If we have rating field in TalentProfile, we could filter here
    // if (_filterTopRated) filtered = filtered.where((m) => m.rating >= 4.5).toList();

    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Pioneers Found',
        message: 'No matching mentors found.',
        icon: LucideIcons.graduationCap,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final mentor = filtered[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: mentor.avatarUrl != null
                ? NetworkImage(mentor.avatarUrl!)
                : null,
            child: mentor.avatarUrl == null
                ? const Icon(LucideIcons.graduationCap)
                : null,
          ),
          title: Text(mentor.fullName ?? 'Mentor',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(mentor.headline ?? 'Expert Professional'),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ProfessionalProfileScreen(userId: mentor.id))),
        );
      },
    );
  }

  /// Single selectable category pill.
  Widget _buildPill(String cat) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(cat),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedCategory = cat),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        selectedColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white70,
            fontSize: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white12)),
      ),
    );
  }

  /// List view of post search results.
  Widget _buildPostResults(List<Post> results) {
    if (results.isEmpty) {
      return const EmptyStateWidget(
        title: 'Archive Empty',
        message: 'No content found.',
        icon: LucideIcons.fileX,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final post = results[index];
        return ListTile(
          leading: post.mediaUrls.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(post.mediaUrls.first,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.broken_image,
                          size: 20,
                          color: Colors.white24)),
                )
              : const Icon(LucideIcons.fileText, color: Colors.white24),
          title: Text(post.content ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14)),
          subtitle: Text('by ${post.authorName ?? "User"}',
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
          onTap: () {
            HapticFeedback.selectionClick();
            // Typically would go to post detail, but for now we follow the existing pattern
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: post.userId)));
          },
        );
      },
    );
  }

  /// Horizontally scrollable list of suggested user accounts to follow.
  Widget _buildRecommendedUsers(AsyncValue<List<Post>> exploreAsync) {
    return exploreAsync.when(
      data: (posts) {
        final authors = <String, Post>{};
        for (var p in posts) {
          if (!authors.containsKey(p.userId)) authors[p.userId] = p;
        }
        final recommended = authors.values.toList();

        if (recommended.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(AppLocalizations.of(context)!.suggestedForYou,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: recommended.length,
                itemBuilder: (context, index) {
                  final user = recommended[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(userId: user.userId)));
                    },
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: user.authorAvatar != null
                                ? NetworkImage(user.authorAvatar!)
                                : null,
                            child: user.authorAvatar == null
                                ? const Icon(LucideIcons.user, size: 30)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.authorName ?? 'User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 120),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Tabbed view that renders search results across multiple entity types.
  Widget _buildSearchResults(sc.SearchState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.userResults.isEmpty && state.postResults.isEmpty) {
      return const EmptyStateWidget(
        title: 'No Signals Detected',
        message: 'No results found for your query.',
        icon: LucideIcons.searchX,
      );
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: 'Communities'),
              Tab(text: 'Posts'),
              Tab(text: 'Courses'),
              Tab(text: 'Mentors'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCommunityResults(state.communityResults),
                _buildPostResults(state.postResults),
                _buildCourseResults(state.courseResults),
                _buildMentorResults(state.mentorResults),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet for advanced discovery filters (price, rating).
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Advanced Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Only Free Content',
                    style: TextStyle(fontSize: 14)),
                value: _filterOnlyFree,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  setModalState(() => _filterOnlyFree = val);
                  setState(() => _filterOnlyFree = val);
                },
              ),
              SwitchListTile(
                title: const Text('Top Rated Only (4.5+)',
                    style: TextStyle(fontSize: 14)),
                value: _filterTopRated,
                activeThumbColor: Colors.blueAccent,
                onChanged: (val) {
                  setModalState(() => _filterTopRated = val);
                  setState(() => _filterTopRated = val);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
