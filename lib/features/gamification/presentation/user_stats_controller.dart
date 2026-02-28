import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../services/achievements_service.dart';
import '../data/gamification_repository.dart';
import '../models/badge_model.dart';

// Provider for repo
/// Provider for the [GamificationRepository].
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository();
});

/// Provider for the [UserStatsController].
final userStatsProvider =
    StateNotifierProvider<UserStatsController, UserStatsState>((ref) {
  final repo = ref.watch(gamificationRepositoryProvider);
  final achievementsService = ref.watch(achievementsServiceProvider);
  return UserStatsController(repo, achievementsService);
});

/// Controller that manages the user's gamification statistics state.
class UserStatsController extends StateNotifier<UserStatsState> {
  final GamificationRepository _repo;
  final AchievementsService _achievementsService;

  /// Creates a [UserStatsController] instance and refreshes stats.
  UserStatsController(this._repo, this._achievementsService)
      : super(UserStatsState.loading()) {
    refreshStats();
  }

  // Method to simulate adding XP (for testing animations)
  /// Method to simulate adding XP (for testing animations).
  Future<void> addXP(int amount) async {
    try {
      await _repo.updateXP(amount);
      await refreshStats(); // Refresh to get new level

      // Auto-check if any achievements were unlocked
      try {
        final newlyEarned = await _achievementsService.checkAchievements();
        if (newlyEarned.isNotEmpty) {
          AppLogger.info(
              'Unlocked ${newlyEarned.length} achievement(s): ${newlyEarned.map((a) => a.name).join(', ')}');
        }
      } catch (e) {
        AppLogger.info('Failed to check achievements after XP update: $e');
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Refreshes the user's statistics from the repository.
  Future<void> refreshStats() async {
    try {
      final stats = await _repo.getUserStats();
      if (stats != null) {
        state = UserStatsState.data(stats);
      } else {
        state = UserStatsState.error('User stats not found');
      }
    } catch (e) {
      state = UserStatsState.error(e.toString());
    }
  }
}

// State for UserStats
/// State representing the user's statistics, including loading and error states.
class UserStatsState {
  /// The current user statistics, if available.
  final UserStats? stats;

  /// Whether the statistics are currently being loaded.
  final bool isLoading;

  /// An error message if something went wrong during loading.
  final String? error;

  /// Creates a [UserStatsState] instance.
  UserStatsState({this.stats, this.isLoading = false, this.error});

  /// Creates a [UserStatsState] with the provided data.
  factory UserStatsState.data(UserStats stats) => UserStatsState(stats: stats);

  /// Creates a [UserStatsState] with an error message.
  factory UserStatsState.error(String err) => UserStatsState(error: err);

  /// Creates a [UserStatsState] in the loading state.
  factory UserStatsState.loading() => UserStatsState(isLoading: true);
}
