import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/utils/sanitizer_utils.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

/// Provider to check if current user is following a target user.
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, targetId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return false;
  return ref
      .watch(profileRepositoryProvider)
      .isFollowing(currentUser.id, targetId);
});

/// Provider for the [ProfileController] which handles profile updates and privacy settings.
final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
  return ProfileController(ref.watch(profileRepositoryProvider), ref);
});

/// Future provider that fetches the [Profile] for the currently authenticated user.
final userProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile(user.id);
});

/// Controller that manages state and actions for the user's profile.
class ProfileController extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repo;
  final Ref _ref;

  /// Creates a [ProfileController].
  ProfileController(this._repo, this._ref) : super(const AsyncData(null));

  /// Follows a user and invalidates relevant providers.
  Future<void> followUser(String targetId) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return;

    await _repo.followUser(currentUser.id, targetId);
    _ref.invalidate(isFollowingProvider(targetId));
  }

  /// Simulates a profile verification process for testing purposes.
  Future<void> simulateVerification() async {
    final currentProfile = await _ref.read(userProfileProvider.future);
    if (currentProfile == null) return;

    final updatedProfile = Profile(
      id: currentProfile.id,
      username: currentProfile.username,
      fullName: currentProfile.fullName,
      bio: currentProfile.bio,
      website: currentProfile.website,
      interests: currentProfile.interests,
      avatarUrl: currentProfile.avatarUrl,
      role: currentProfile.role,
      trustScore: currentProfile.trustScore,
      isPrivate: currentProfile.isPrivate,
      defaultPersonalVisibility: currentProfile.defaultPersonalVisibility,
      isAgeVerified: true,
      verificationUrl: 'https://simulated-verification.com/doc.pdf',
      journalistLevel: currentProfile.journalistLevel,
    );

    await _repo.updateProfile(updatedProfile);
    _ref.invalidate(userProfileProvider);
  }

  /// Toggles the user's profile privacy status.
  Future<void> togglePrivacy(bool isPrivate) async {
    final currentProfile = await _ref.read(userProfileProvider.future);
    if (currentProfile == null) return;

    final updatedProfile = Profile(
      id: currentProfile.id,
      username: currentProfile.username,
      fullName: currentProfile.fullName,
      bio: currentProfile.bio,
      website: currentProfile.website,
      interests: currentProfile.interests,
      avatarUrl: currentProfile.avatarUrl,
      role: currentProfile.role,
      trustScore: currentProfile.trustScore,
      isPrivate: isPrivate,
      journalistLevel: currentProfile.journalistLevel,
    );

    await _repo.updateProfile(updatedProfile);
    _ref.invalidate(userProfileProvider);
  }

  /// Unfollows a user and invalidates relevant providers.
  Future<void> unfollowUser(String targetId) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return;

    await _repo.unfollowUser(currentUser.id, targetId);
    _ref.invalidate(isFollowingProvider(targetId));
  }

  /// Updates the default visibility for personal data.
  Future<void> updateDefaultPersonalVisibility(bool allows) async {
    final currentProfile = await _ref.read(userProfileProvider.future);
    if (currentProfile == null) return;

    final updatedProfile = Profile(
      id: currentProfile.id,
      username: currentProfile.username,
      fullName: currentProfile.fullName,
      bio: currentProfile.bio,
      website: currentProfile.website,
      interests: currentProfile.interests,
      avatarUrl: currentProfile.avatarUrl,
      role: currentProfile.role,
      trustScore: currentProfile.trustScore,
      isPrivate: currentProfile.isPrivate,
      defaultPersonalVisibility: allows,
      isAgeVerified: currentProfile.isAgeVerified,
      verificationUrl: currentProfile.verificationUrl,
      journalistLevel: currentProfile.journalistLevel,
    );

    await _repo.updateProfile(updatedProfile);
    _ref.invalidate(userProfileProvider);
  }

  /// Updates the user's profile with the provided information.
  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? website,
    String? username,
    List<String>? interests,
  }) async {
    state = const AsyncLoading();

    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return;

    final currentProfile = await _ref.read(userProfileProvider.future);

    // 4.1 — Apply input sanitization to user-provided fields
    final sanitizedFullName =
        fullName != null ? SanitizerUtils.sanitizeString(fullName) : null;
    final sanitizedBio =
        bio != null ? SanitizerUtils.sanitizeString(bio) : null;
    final sanitizedWebsite =
        website != null ? SanitizerUtils.sanitizeString(website) : null;
    final sanitizedUsername =
        username != null ? SanitizerUtils.sanitizeUsername(username) : null;

    // Create updated profile object
    final updatedProfile = Profile(
      id: currentUser.id,
      username: sanitizedUsername ?? currentProfile?.username,
      fullName: sanitizedFullName ?? currentProfile?.fullName,
      bio: sanitizedBio ?? currentProfile?.bio,
      website: sanitizedWebsite ?? currentProfile?.website,
      interests: interests ?? currentProfile?.interests ?? [],
      avatarUrl: currentProfile?.avatarUrl,
      role: currentProfile?.role ?? 'student',
      trustScore: currentProfile?.trustScore ?? 0,
      isPrivate: currentProfile?.isPrivate ?? false,
      isAgeVerified: currentProfile?.isAgeVerified ?? false,
      verificationUrl: currentProfile?.verificationUrl,
      journalistLevel: currentProfile?.journalistLevel,
    );

    state = await AsyncValue.guard(() async {
      await _repo.updateProfile(updatedProfile);
      // Invalidate the provider to refetch data
      _ref.invalidate(userProfileProvider);
    });
  }
}
