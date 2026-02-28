import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/leaderboard_skeleton.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

import '../../../l10n/app_localizations.dart';
import '../data/leaderboard_entry_model.dart';
import 'gamification_controller.dart';

/// A screen that displays global user rankings for Karma, Mentoring, and Challenges.
class LeaderboardScreen extends ConsumerStatefulWidget {
  /// Creates a [LeaderboardScreen] instance.
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.globalRankings),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.karmaKings),
            Tab(text: AppLocalizations.of(context)!.topMentors),
            Tab(text: AppLocalizations.of(context)!.champions),
          ],
        ),
      ),
      body: LiquidBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLeaderboardList(context, category: 'Karma'),
            _buildLeaderboardList(context, category: 'Mentors'),
            _buildLeaderboardList(context, category: 'Champions'),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Widget _buildLeaderboardList(BuildContext context,
      {required String category}) {
    final leaderboardAsync = ref.watch(globalLeaderboardProvider);

    return leaderboardAsync.when(
      data: (entriesData) {
        // Convert UserStats to LeaderboardEntry if necessary or use directly if they are compatible
        // The current LeaderboardScreen expects List<LeaderboardEntry>
        // Let's adapt UserStats to LeaderboardEntry
        final entries = entriesData.asMap().entries.map((item) {
          final stats = item.value;
          return LeaderboardEntry(
            userId: stats.userId,
            username: stats.displayName,
            avatarUrl: stats.avatarUrl,
            score: stats.totalXP,
            rank: item.key + 1,
          );
        }).toList();

        final top3 = entries.take(3).toList();
        final rest = entries.skip(3).toList();

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
                SliverToBoxAdapter(child: _buildPodium(top3, category)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = rest[index];
                        return _buildRankRow(entry);
                      },
                      childCount: rest.length,
                    ),
                  ),
                ),
              ],
            ),
            _buildPinnedUserRank(entries),
          ],
        );
      },
      loading: () => const LeaderboardSkeleton(),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPinnedUserRank(List<LeaderboardEntry> entries) {
    // For production: final myEntry = entries.firstWhere((e) => e.userId == currentUserId, orElse: () => null)
    final currentUser = ref.watch(currentUserProvider);
    final myEntryIndex = currentUser != null
        ? entries.indexWhere((e) => e.userId == currentUser.id)
        : -1;

    if (myEntryIndex == -1) return const SizedBox.shrink();

    final myEntry = entries[myEntryIndex];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          border: const Border(top: BorderSide(color: Colors.white24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              const Text(
                'You',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              Text(
                '#${myEntry.rank}',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              _buildTrendIndicator(0), // Stable for now
              const Spacer(),
              Text('${myEntry.score} pts',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3, String category) {
    if (top3.isEmpty) return const SizedBox.shrink();

    // Reorder for visual podium: 2nd (Left), 1st (Center/High), 3rd (Right)
    LeaderboardEntry? first = top3.isNotEmpty ? top3[0] : null;
    LeaderboardEntry? second = top3.length > 1 ? top3[1] : null;
    LeaderboardEntry? third = top3.length > 2 ? top3[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (second != null) _buildPodiumStep(second, 2, 140, Colors.grey),
        if (first != null) _buildPodiumStep(first, 1, 180, Colors.amber),
        if (third != null) _buildPodiumStep(third, 3, 110, Colors.brown),
      ],
    );
  }

  Widget _buildPodiumStep(
      LeaderboardEntry entry, int rank, double height, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: rank == 1 ? 30 : 24,
            backgroundImage:
                entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child:
                entry.avatarUrl == null ? const Icon(LucideIcons.user) : null,
          ).animate().scale(duration: 500.ms),
          const SizedBox(height: 8),
          Text(entry.displayName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text('${entry.score ?? 0}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: rank == 1 ? 100 : 80,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.8),
                  color.withValues(alpha: 0.3)
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ).animate().slideY(
              begin: 1.0, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  Widget _buildRankRow(LeaderboardEntry entry) {
    // In a real app, compare with previous rank.
    // Trend field not yet available in current UserStats/LeaderboardEntry
    const trend = 0; // default to stable

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text('#${entry.rank}',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white54,
                      fontWeight: FontWeight.bold)),
            ),
            _buildTrendIndicator(trend),
            const SizedBox(width: 12),
            CircleAvatar(
                radius: 18,
                backgroundImage: entry.avatarUrl != null
                    ? NetworkImage(entry.avatarUrl!)
                    : null,
                child: const Icon(LucideIcons.user, size: 14)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(entry.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
            Text('${entry.score ?? 0}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(int trend) {
    IconData icon;
    Color color;

    if (trend > 0) {
      icon = Icons.arrow_drop_up;
      color = Colors.greenAccent;
    } else if (trend < 0) {
      icon = Icons.arrow_drop_down;
      color = Colors.redAccent;
    } else {
      icon = Icons.remove;
      color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }
}
