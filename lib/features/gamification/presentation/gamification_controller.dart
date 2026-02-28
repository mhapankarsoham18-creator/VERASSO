import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/gamification_repository.dart';
import '../models/badge_model.dart';

/// Provider for the [GamificationController] instance.
final gamificationControllerProvider =
    StateNotifierProvider<GamificationController, AsyncValue<void>>((ref) {
  return GamificationController(ref.watch(gamificationRepositoryProvider));
});

/// Provider for streaming the global leaderboard.
final globalLeaderboardProvider = StreamProvider<List<UserStats>>((ref) {
  return ref.watch(gamificationRepositoryProvider).watchLeaderboard();
});

/// Provider for fetching/streaming current user stats.
final userStatsProvider = StreamProvider<UserStats?>((ref) {
  final repo = ref.watch(gamificationRepositoryProvider);
  // We can also use a stream for a single user if needed
  // For now, let's stick to the repo's getUserStats or add a stream there
  return Stream.fromFuture(repo.getUserStats());
});

/// Controller for gamification actions.
class GamificationController extends StateNotifier<AsyncValue<void>> {
  final GamificationRepository _repository;

  /// Creates a [GamificationController] with the provided repository.
  GamificationController(this._repository) : super(const AsyncValue.data(null));

  /// Unlocks a badge for the current user.
  Future<void> unlockBadge(String badgeId) async {
    try {
      await _repository.unlockBadge(badgeId);
    } catch (e) {
      // Handle error
    }
  }

  /// Updates the user's XP by the provided [additionalXP].
  Future<void> updateXP(int additionalXP) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateXP(additionalXP);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
