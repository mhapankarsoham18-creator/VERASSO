import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/data/user_profile_model.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../finance/presentation/finance_dashboard_screen.dart';
import '../../messaging/presentation/chat_detail_screen.dart';
import '../../notifications/data/notification_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/data/profile_model.dart';
import '../data/analytics_repository.dart';
import '../data/job_model.dart';
import '../data/job_repository.dart';
import '../data/talent_model.dart';
import '../data/talent_repository.dart';
import 'analytics_dashboard_screen.dart';
import 'create_job_request_screen.dart';
import 'create_talent_screen.dart';
import 'mentor_directory_screen.dart';
import 'my_jobs_screen.dart';
import 'professional_profile_screen.dart';
import 'verification_gate_dialog.dart';

/// Provider for the paginated [JobRequest] list.
final jobsProvider =
    StateNotifierProvider<JobsNotifier, PaginatedState<JobRequest>>((ref) {
  return JobsNotifier(ref.watch(jobRepositoryProvider));
});

/// Free-text query used to filter both jobs and talents by skill or title.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Whether the marketplace view should show only mentor-created talent offers.
final showMentorsOnlyProvider = StateProvider<bool>((ref) => false);

/// Provider for the paginated [TalentPost] list.
final talentsProvider =
    StateNotifierProvider<TalentsNotifier, PaginatedState<TalentPost>>((ref) {
  return TalentsNotifier(ref.watch(talentRepositoryProvider));
});

/// Card widget that displays a single [JobRequest] in the job board.
class JobRequestCard extends ConsumerWidget {
  /// The job request data to display.
  final JobRequest job;

  /// Creates a [JobRequestCard] instance.
  const JobRequestCard({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsRepositoryProvider).trackEvent(
            eventType: 'impression',
            targetType: 'job_request',
            targetId: job.id,
          );
    });

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.isFeatured)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.award, size: 10, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('FEATURED POST',
                          style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 9)),
                    ],
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${job.budget} ${job.currency}',
                  style: const TextStyle(
                      color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.description ?? '',
              style: const TextStyle(color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: job.requiredSkills
                  .map((skill) => Chip(
                        label:
                            Text(skill, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white10,
                      ))
                  .toList(),
            ),
            const Divider(color: Colors.white10, height: 24),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                ref.read(analyticsRepositoryProvider).trackEvent(
                      eventType: 'view',
                      targetType: 'job_request',
                      targetId: job.id,
                    );
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProfessionalProfileScreen(userId: job.clientId)));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: job.clientAvatar != null
                          ? NetworkImage(job.clientAvatar!)
                          : null,
                      child: job.clientAvatar == null
                          ? const Icon(LucideIcons.user, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(job.clientName ?? 'Client',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showApplyDialog(context, ref, job),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Apply Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final profile = ref.read(userProfileProvider).value;
                      if (profile?.isAgeVerified == true) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              conversationId: job.id,
                              otherUserId: job.clientId,
                            ),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => const VerificationGateDialog(),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Negotiate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyDialog(BuildContext context, WidgetRef ref, JobRequest job) {
    final messageC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Apply for ${job.title}',
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: messageC,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Introduce yourself...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final myProfile = ref.read(userProfileProvider).value;
              if (myProfile?.isAgeVerified != true) {
                Navigator.pop(context);
                showDialog(
                    context: context,
                    builder: (_) => const VerificationGateDialog());
                return;
              }

              final user = ref.read(currentUserProvider);
              if (user == null) return;

              await ref
                  .read(jobRepositoryProvider)
                  .applyForJob(job.id, user.id, messageC.text);

              await ref.read(notificationServiceProvider).createNotification(
                targetUserId: job.clientId,
                title: 'New Application',
                body:
                    '${myProfile?.fullName ?? "A talent"} applied for: ${job.title}',
                type: NotificationType.job,
                data: {'jobId': job.id},
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Application sent successfully!')),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.submit),
          ),
        ],
      ),
    );
  }
}

/// Notifier for the paginated job list.
class JobsNotifier extends StateNotifier<PaginatedState<JobRequest>> {
  final JobRepository _repo;

  /// Creates a [JobsNotifier] and triggers initial load.
  JobsNotifier(this._repo) : super(PaginatedState()) {
    loadNextPage();
  }

  /// Fetches the next page of job requests and appends to state.
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final newJobs =
          await _repo.getJobRequests(limit: 10, offset: state.items.length);
      state = state.copyWith(
        items: [...state.items, ...newJobs],
        isLoading: false,
        hasMore: newJobs.length == 10,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Resets the job list and reloads from the first page.
  Future<void> refresh() async {
    state = PaginatedState();
    await loadNextPage();
  }
}

/// State for a paginated list of items.
class PaginatedState<T> {
  /// The list of items on current page.
  final List<T> items;

  /// Whether a page is currently being loaded.
  final bool isLoading;

  /// Whether there are more items to load.
  final bool hasMore;

  /// Any error message from the last load.
  final String? error;

  /// Creates a [PaginatedState] with default or provided values.
  PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  /// Creates a copy of this state with the provided fields replaced.
  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Grid card widget that showcases a single [TalentPost] in the marketplace.
class TalentCard extends ConsumerWidget {
  /// The talent post data to display.
  final TalentPost talent;

  /// Creates a [TalentCard] instance.
  const TalentCard({super.key, required this.talent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsRepositoryProvider).trackEvent(
            eventType: 'impression',
            targetType: 'talent',
            targetId: talent.id,
          );
    });

    return GlassContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: talent.mediaUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: Image.network(talent.mediaUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image,
                                      size: 40, color: Colors.white24)),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            color: Colors.white10,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: const Icon(LucideIcons.image,
                              color: Colors.white24, size: 40),
                        ),
                ),
                if (talent.isFeatured)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.sparkles,
                              size: 8, color: Colors.black),
                          SizedBox(width: 2),
                          Text('PRIORITY',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  talent.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${talent.price} ${talent.currency}',
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref.read(analyticsRepositoryProvider).trackEvent(
                          eventType: 'view',
                          targetType: 'talent',
                          targetId: talent.id,
                        );
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProfessionalProfileScreen(
                                userId: talent.userId)));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: talent.authorAvatar != null
                              ? NetworkImage(talent.authorAvatar!)
                              : null,
                          child: talent.authorAvatar == null
                              ? const Icon(LucideIcons.user, size: 12)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            talent.authorName ?? 'User',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Main dashboard screen for talent discovery, marketplace browsing, and analytics.
class TalentDashboard extends ConsumerStatefulWidget {
  /// Creates a [TalentDashboard] instance.
  const TalentDashboard({super.key});

  @override
  ConsumerState<TalentDashboard> createState() => _TalentDashboardState();
}

/// Notifier for the paginated talent list.
class TalentsNotifier extends StateNotifier<PaginatedState<TalentPost>> {
  final TalentRepository _repo;

  /// Creates a [TalentsNotifier] and triggers initial load.
  TalentsNotifier(this._repo) : super(PaginatedState()) {
    loadNextPage();
  }

  /// Fetches the next page of talent posts and appends to state.
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final newTalents =
          await _repo.getTalents(limit: 10, offset: state.items.length);
      state = state.copyWith(
        items: [...state.items, ...newTalents],
        isLoading: false,
        hasMore: newTalents.length == 10,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Resets the talent list and reloads from the first page.
  Future<void> refresh() async {
    state = PaginatedState();
    await loadNextPage();
  }
}

class _TalentDashboardState extends ConsumerState<TalentDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _jobsScrollController = ScrollController();
  final ScrollController _talentsScrollController = ScrollController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) =>
                      ref.read(searchQueryProvider.notifier).state = val,
                )
              : Text(AppLocalizations.of(context)!.talentEcosystem),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? LucideIcons.x : LucideIcons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  }
                });
              },
            ),
            if (profileAsync.value != null) ...[
              IconButton(
                icon: const Icon(LucideIcons.listTodo),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyJobsScreen())),
              ),
              IconButton(
                icon: const Icon(LucideIcons.bell),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
              ),
              IconButton(
                icon: const Icon(LucideIcons.barChart),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AnalyticsDashboardScreen())),
              ),
            ],
            IconButton(
              icon: const Icon(LucideIcons.users),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MentorDirectoryScreen())),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Showcase', icon: Icon(LucideIcons.palette, size: 20)),
              Tab(
                  text: 'Job Board',
                  icon: Icon(LucideIcons.briefcase, size: 20)),
            ],
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
          ),
        ),
        body: LiquidBackground(
          child: profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text('Please log in'));
              }
              return TabBarView(
                children: [
                  _buildMarketplace(context, ref, searchQuery),
                  Column(
                    children: [
                      _buildActionCard(
                        context,
                        title: 'Financial Hub',
                        subtitle: 'Earnings & Analytics',
                        icon: LucideIcons.wallet,
                        color: Colors.greenAccent,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const FinanceDashboardScreen())),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                          child: _buildJobBoard(context, ref, searchQuery)),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppErrorView(
              title: 'Error',
              message: e.toString(),
              onRetry: () => ref.invalidate(userProfileProvider),
            ),
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () {
              final index = DefaultTabController.of(context).index;
              final destination = index == 0
                  ? const CreateTalentScreen()
                  : const CreateJobRequestScreen();
              _checkVerificationAndNavigate(
                  context, profileAsync.value, destination);
            },
            label: Text(DefaultTabController.of(context).index == 0
                ? 'Post Talent'
                : 'Post Job'),
            icon: const Icon(LucideIcons.plus),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _jobsScrollController.dispose();
    _talentsScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _jobsScrollController.addListener(_onJobsScroll);
    _talentsScrollController.addListener(_onTalentsScroll);
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildJobBoard(BuildContext context, WidgetRef ref, String query) {
    final state = ref.watch(jobsProvider);
    if (state.error != null && state.items.isEmpty) {
      return AppErrorView(
          title: 'Error',
          message: state.error!,
          onRetry: () => ref.read(jobsProvider.notifier).refresh());
    }

    final filtered = state.items.where((j) {
      final q = query.toLowerCase();
      return j.title.toLowerCase().contains(q) ||
          (j.description?.toLowerCase().contains(q) ?? false);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(jobsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _jobsScrollController,
        padding: const EdgeInsets.fromLTRB(16, 160, 16, 100),
        itemCount: filtered.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filtered.length) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator()));
          }
          return JobRequestCard(job: filtered[index]);
        },
      ),
    );
  }

  Widget _buildMarketplace(BuildContext context, WidgetRef ref, String query) {
    final state = ref.watch(talentsProvider);
    if (state.error != null && state.items.isEmpty) {
      return AppErrorView(
        title: 'Error',
        message: state.error!,
        onRetry: () => ref.read(talentsProvider.notifier).refresh(),
      );
    }
    final showMentorsOnly = ref.watch(showMentorsOnlyProvider);

    final filtered = state.items.where((t) {
      final q = query.toLowerCase();
      final matchesQuery = t.title.toLowerCase().contains(q);
      return showMentorsOnly
          ? (matchesQuery && t.authorIsMentor)
          : matchesQuery;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label:
                    const Text('Mentors Only', style: TextStyle(fontSize: 12)),
                selected: showMentorsOnly,
                onSelected: (val) =>
                    ref.read(showMentorsOnlyProvider.notifier).state = val,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(talentsProvider.notifier).refresh(),
            child: GridView.builder(
              controller: _talentsScrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75),
              itemCount: filtered.length + (state.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filtered.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TalentCard(talent: filtered[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _checkVerificationAndNavigate(
      BuildContext context, Profile? profile, Widget destination) {
    if (profile?.isAgeVerified == true) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
    } else {
      showDialog(
          context: context,
          builder: (context) => const VerificationGateDialog());
    }
  }

  void _onJobsScroll() {
    if (_jobsScrollController.position.pixels >=
        _jobsScrollController.position.maxScrollExtent - 200) {
      ref.read(jobsProvider.notifier).loadNextPage();
    }
  }

  void _onTalentsScroll() {
    if (_talentsScrollController.position.pixels >=
        _talentsScrollController.position.maxScrollExtent - 200) {
      ref.read(talentsProvider.notifier).loadNextPage();
    }
  }
}
