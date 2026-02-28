import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/relationship_repository.dart';

/// Provider for the [RelationshipController].
final relationshipControllerProvider =
    StateNotifierProvider<RelationshipController, AsyncValue<void>>((ref) {
  return RelationshipController(ref.watch(relationshipRepositoryProvider), ref);
});

/// Provider family to fetch the relationship status with a specific user.
final relationshipStatusProvider =
    FutureProvider.family<String, String>((ref, otherUserId) async {
  final repo = ref.watch(relationshipRepositoryProvider);
  return repo.getRelationshipStatus(otherUserId);
});

/// Controller for managing user relationships and social connections.
class RelationshipController extends StateNotifier<AsyncValue<void>> {
  final RelationshipRepository _repo;
  final Ref _ref;

  /// Creates a [RelationshipController] instance.
  RelationshipController(this._repo, this._ref) : super(const AsyncData(null));

  /// Accepts a pending friend request and refreshes the status.
  Future<void> acceptRequest(String requesterId,
      {bool allowsPersonal = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.acceptFriendRequest(requesterId,
          allowsPersonal: allowsPersonal);
      _ref.invalidate(relationshipStatusProvider(requesterId));
    });
  }

  /// Blocks a user and refreshes the relationship status.
  Future<void> blockUser(String targetId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.blockUser(targetId);
      _ref.invalidate(relationshipStatusProvider(targetId));
    });
  }

  /// Sends a friend request and refreshes the status.
  Future<void> sendRequest(String targetId,
      {bool allowsPersonal = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.sendFriendRequest(targetId, allowsPersonal: allowsPersonal);
      _ref.invalidate(relationshipStatusProvider(targetId));
    });
  }

  /// Removes a friendship or cancels a request, then refreshes the status.
  Future<void> unfriendOrCancel(String otherId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.unfriendOrCancel(otherId);
      _ref.invalidate(relationshipStatusProvider(otherId));
    });
  }
}
