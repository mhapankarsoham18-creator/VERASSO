import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/profile_repository.dart';

// Provider for getting one's own profile ID
final myProfileIdProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getMyProfileId();
});

// A family provider to fetch a profile by ID
final profileDataProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, profileId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getProfileById(profileId);
});

// A family provider to fetch posts for a given author ID
final profilePostsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, authorId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getPostsByAuthorId(authorId);
});

// Provides counts [followers, following]
final followCountsProvider = FutureProvider.family<List<int>, String>((ref, profileId) async {
  final repo = ref.watch(profileRepositoryProvider);
  final followers = await repo.getFollowersCount(profileId);
  final following = await repo.getFollowingCount(profileId);
  return [followers, following];
});

// FutureProvider for follow status
final followStatusProvider = FutureProvider.family<String, String>((ref, targetId) async {
  final repo = ref.watch(profileRepositoryProvider);
  final myId = ref.watch(myProfileIdProvider).value ?? 'unknown';
  if (myId == 'unknown') return 'none';
  return await repo.getFollowStatus(myId, targetId);
});
