import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../services/achievements_service.dart';
import '../models/badge_model.dart';
import '../services/seasonal_challenge_service.dart';
import 'achievement_detail_dialog.dart';

/// Provider for fetching all available achievements.
final achievementsProvider = FutureProvider((ref) {
  final service = ref.watch(achievementsServiceProvider);
  return service.getAllAchievements();
});

/// Provider for fetching active seasonal events.
final activeEventsProvider = FutureProvider((ref) {
  final service = ref.watch(seasonalChallengeServiceProvider);
  return service.getActiveEvents();
});

/// Provider for the [SeasonalChallengeService].
final seasonalChallengeServiceProvider =
    Provider<SeasonalChallengeService>((ref) {
  return SeasonalChallengeService();
});

/// Provider for fetching the current user's earned achievements.
final userAchievementsProvider = FutureProvider((ref) {
  final service = ref.watch(achievementsServiceProvider);
  return service.getUserAchievements();
});

/// A screen that displays all available achievements, categorized by
/// earned and locked status, with search and sort functionality.
class AchievementsScreen extends ConsumerStatefulWidget {
  /// Creates an [AchievementsScreen] instance.
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _filters = ['All', 'Earned', 'Locked'];
  String _searchQuery = '';
  String _sortBy = 'Rarity'; // Rarity, Date, Name

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(achievementsProvider);
    final userAsync = ref.watch(userAchievementsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
        backgroundColor:
            Colors.transparent, // Glass effect covered by background
        elevation: 0,
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(110), // Increased height for search/filter
          child: Column(
            children: [
              // Search & Sort Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search achievements...',
                            border: InputBorder.none,
                            prefixIcon:
                                Icon(LucideIcons.search, color: Colors.white70),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort Dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          dropdownColor: Colors.black87,
                          icon: const Icon(Icons.sort, color: Colors.white70),
                          style: const TextStyle(color: Colors.white),
                          items: ['Rarity', 'Date', 'Name'].map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _sortBy = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: _filters.map((f) => Tab(text: f)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Seasonal Events Banner
            ref.watch(activeEventsProvider).when(
                  data: (events) {
                    if (events.isEmpty) return const SizedBox.shrink();
                    final event = events.first;
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orangeAccent, Colors.redAccent],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.sparkles,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.description ??
                                'Exclusive seasonal rewards available!',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, __) {
                    debugPrint('Events error: $e');
                    return const SizedBox.shrink();
                  },
                ),
            Expanded(
              child: allAsync.when(
                data: (allBadges) {
                  return userAsync.when(
                    data: (userBadges) {
                      // Map earned badge IDs
                      final earnedIds =
                          userBadges.map((ub) => ub.achievementId).toSet();
                      final Map<String, UserAchievementModel> earnedMap = {
                        for (var ub in userBadges) ub.achievementId: ub
                      };

                      // --- FILTERING LOGIC ---
                      var filtered = allBadges.where((b) {
                        final matchesSearch = b.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            b.description
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                        return matchesSearch;
                      }).toList();

                      // Split by tabs (filter logic per tab)
                      List<AchievementModel> getTabList(int tabIndex) {
                        switch (tabIndex) {
                          case 1: // Earned
                            return filtered
                                .where((b) => earnedIds.contains(b.id))
                                .toList();
                          case 2: // Locked
                            return filtered
                                .where((b) => !earnedIds.contains(b.id))
                                .toList();
                          default: // All
                            return filtered;
                        }
                      }

                      // Helper to build sorted list for a tab
                      Widget buildTab(int index) {
                        var list = getTabList(index);

                        // --- SORTING LOGIC ---
                        list.sort((a, b) {
                          switch (_sortBy) {
                            case 'Name':
                              return a.name.compareTo(b.name);
                            case 'Date':
                              final dateA = earnedMap[a.id]?.earnedAt;
                              final dateB = earnedMap[b.id]?.earnedAt;
                              if (dateA == null && dateB == null) return 0;
                              if (dateA == null) return 1; // Unearned last
                              if (dateB == null) return -1;
                              return dateB.compareTo(dateA); // Newest first
                            case 'Rarity':
                            default:
                              return _getRarityWeight(b.rarity)
                                  .compareTo(_getRarityWeight(a.rarity));
                          }
                        });

                        return _buildGrid(list, earnedIds, earnedMap);
                      }

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          buildTab(0), // All
                          buildTab(1), // Earned
                          buildTab(2), // Locked
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Error loading progress: $e')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error loading badges: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
  }

  Widget _buildBadgeCard(Badge badge, bool isUnlocked) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          SizedBox(
            height: 60,
            width: 60,
            child: isUnlocked
                ? Center(
                    child: Text(badge.icon,
                        style: const TextStyle(
                            fontSize:
                                40))) // Use simple icon for grid to save perf
                : Opacity(
                    opacity: 0.2,
                    child: Center(
                        child: Text(badge.icon,
                            style: const TextStyle(fontSize: 40)))),
          ),
          const SizedBox(height: 12),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.white : Colors.white38,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getRarityColor(badge.rarity).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge.rarity.name.toUpperCase(),
              style:
                  TextStyle(fontSize: 8, color: _getRarityColor(badge.rarity)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<AchievementModel> badges, Set<String> earnedIds,
      Map<String, UserAchievementModel> earnedMap) {
    if (badges.isEmpty) {
      return const Center(
          child:
              Text('No badges found', style: TextStyle(color: Colors.white54)));
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isUnlocked = earnedIds.contains(badge.id);
        final userBadge = isUnlocked ? earnedMap[badge.id] : null;

        // Convert AchievementModel to Badge for UI/Animation compatibility if needed
        // Assuming models are compatible or mapped manually.
        // For dialog, we construct a Badge object on the fly since we used different models.
        // Let's create an ad-hoc mapping or update Badge definitions.

        // MAPPING logic:
        final uiBadge = Badge(
            id: badge.id,
            name: badge.name,
            description: badge.description,
            icon: badge.iconUrl ?? '🏆', // Fallback icon
            rarity: _parseRarity(badge.rarity),
            category: BadgeCategory.special, // Default
            requiredPoints: badge.pointsReward);

        return GestureDetector(
          onTap: () {
            showDialog(
                context: context,
                builder: (_) => AchievementDetailDialog(
                      badge: uiBadge,
                      isUnlocked: isUnlocked,
                      unlockedAt: userBadge?.earnedAt,
                    ));
          },
          child: _buildBadgeCard(uiBadge, isUnlocked),
        );
      },
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.orange;
    }
  }

  int _getRarityWeight(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return 4;
      case 'epic':
        return 3;
      case 'rare':
        return 2;
      default:
        return 1;
    }
  }

  BadgeRarity _parseRarity(String rarityStr) {
    try {
      return BadgeRarity.values.firstWhere(
          (e) => e.name == rarityStr.toLowerCase(),
          orElse: () => BadgeRarity.common);
    } catch (_) {
      return BadgeRarity.common;
    }
  }
}
