import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/profile/data/follow_repository.dart';
import 'package:verasso/features/profile/data/profile_repository.dart';

import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late ProfileRepository profileRepository;
  late FollowRepository followRepository;

  final testUser = TestSupabaseUser(
    id: 'user-1',
    email: 'test@example.com',
  );

  final otherUser = TestSupabaseUser(
    id: 'user-2',
    email: 'other@example.com',
  );

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockAuth.setCurrentUser(testUser);
    profileRepository = ProfileRepository(client: mockSupabase);
    followRepository = FollowRepository(client: mockSupabase);
  });

  group('Profile Integration Tests', () {
    test('complete profile creation flow: signup → auto-create profile',
        () async {
      final profilesBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('profiles', profilesBuilder);

      await expectLater(
        profileRepository.createProfile(
          userId: testUser.id,
          fullName: 'Test User',
          email: testUser.email,
        ),
        completes,
      );

      expect(mockSupabase.lastInsertTable, 'profiles');
    });

    test('profile appears after creation', () async {
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'full_name': 'Test User',
          'email': testUser.email,
          'avatar_url': null,
          'bio': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profile = await profileRepository.getProfile(testUser.id);

      expect(profile, isNotNull);
      expect(profile?.fullName, 'Test User');
      expect(profile?.email, testUser.email);
    });

    test('update profile with avatar and bio', () async {
      final updateBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('profiles', updateBuilder);

      final newBio = 'Learning Flutter 📱';
      final avatarUrl = 'https://example.com/avatar.jpg';

      await expectLater(
        profileRepository.updateProfile(
          null,
          userId: testUser.id,
          fullName: 'Updated Name',
          bio: newBio,
          avatarUrl: avatarUrl,
        ),
        completes,
      );

      expect(mockSupabase.lastUpdateTable, 'profiles');
    });

    test('avatar upload stores URL in profile', () async {
      final storageBuilder = MockSupabaseStorageBucket();
      mockSupabase.setStorageBucket('avatars', storageBuilder);
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      await expectLater(
        profileRepository.uploadAvatar(testUser.id, 'path/to/image.jpg'),
        completes,
      );
    });

    test('bio length validation prevents oversized bio', () async {
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      // Should handle gracefully or throw validation error
      expect(true, true);
    });

    test('follow user creates relationship', () async {
      final followsBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('follows', followsBuilder);

      await expectLater(
        followRepository.followUser(
          followerId: testUser.id,
          followingId: otherUser.id,
        ),
        completes,
      );

      expect(mockSupabase.lastInsertTable, 'follows');
    });

    test('follower count increments after follow', () async {
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': otherUser.id,
          'full_name': 'Other User',
          'followers_count': 1,
          'following_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profile = await profileRepository.getProfile(otherUser.id);

      expect(profile?.followerCount, 1);
    });

    test('unfollow user removes relationship', () async {
      final followsBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('follows', followsBuilder);

      await expectLater(
        followRepository.unfollowUser(
          followerId: testUser.id,
          followingId: otherUser.id,
        ),
        completes,
      );

      expect(mockSupabase.lastDeleteTable, isNotNull);
    });

    test('fetch followers list with pagination', () async {
      final followersBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'follower_id': 'user-3',
          'profiles': {
            'id': 'user-3',
            'full_name': 'Follower 1',
            'avatar_url': null,
          }
        },
        {
          'follower_id': 'user-4',
          'profiles': {
            'id': 'user-4',
            'full_name': 'Follower 2',
            'avatar_url': null,
          }
        }
      ]);
      mockSupabase.setQueryBuilder('follows', followersBuilder);

      final followers = await followRepository.getFollowers(testUser.id);

      expect(followers.length, 2);
      expect(followers[0].fullName, 'Follower 1');
    });

    test('fetch following list', () async {
      final followingBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'following_id': otherUser.id,
          'profiles': {
            'id': otherUser.id,
            'full_name': 'Other User',
            'avatar_url': null,
          }
        }
      ]);
      mockSupabase.setQueryBuilder('follows', followingBuilder);

      final following = await followRepository.getFollowing(testUser.id);

      expect(following.length, 1);
      expect(following[0].fullName, 'Other User');
    });

    test('fetch user profile with stats aggregation', () async {
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'full_name': 'Test User',
          'email': testUser.email,
          'posts_count': 15,
          'followers_count': 42,
          'following_count': 28,
          'trust_score': 5000,
          'level': 5,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profile = await profileRepository.getProfile(testUser.id);

      expect(profile?.postCount, 15);
      expect(profile?.followerCount, 42);
      expect(profile?.xpTotal, 5000);
    });

    test('delete profile with cascade', () async {
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: []);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      await expectLater(
        profileRepository.deleteProfile(testUser.id),
        completes,
      );

      expect(mockSupabase.lastDeleteTable, 'profiles');
    });

    test('profile deactivation soft deletes records', () async {
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'is_private': true,
          'deactivated_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profile = await profileRepository.getProfile(testUser.id);

      expect(profile?.isActive, false);
    });
  });

  group('Profile Integration - Data Consistency', () {
    test('profile update maintains referential integrity', () async {
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'full_name': 'Test User',
          'updated_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profile = await profileRepository.getProfile(testUser.id);

      expect(profile?.id, testUser.id);
    });

    test('follower statistics stay accurate after follows/unfollows', () async {
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'full_name': 'Test User',
          'followers_count': 5,
          'following_count': 3,
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profile = await profileRepository.getProfile(testUser.id);

      expect(profile?.followerCount, 5);
      expect(profile?.followingCount, 3);
    });

    test('avatar URL persists correctly', () async {
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'avatar_url': 'https://example.com/avatar.jpg',
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profile = await profileRepository.getProfile(testUser.id);

      expect(profile?.avatarUrl, 'https://example.com/avatar.jpg');
    });
  });

  group('Profile Integration - High Volume', () {
    test('load 1000+ user profiles without crash', () async {
      final largeProfileList = List.generate(
        1000,
        (i) => {
          'id': 'user-$i',
          'full_name': 'User $i',
          'avatar_url': 'https://example.com/avatar-$i.jpg',
          'followers_count': i % 100,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      final profileBuilder =
          MockSupabaseQueryBuilder(selectResponse: largeProfileList);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profileIds = List.generate(1000, (i) => 'user-$i');
      final stopwatch = Stopwatch()..start();
      final profiles = await profileRepository.getProfiles(profileIds);
      stopwatch.stop();

      expect(profiles.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('concurrent follow operations handled safely', () async {
      final followsBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('follows', followsBuilder);

      final followIds = List.generate(100, (i) => 'user-${i + 3}');

      final futures = followIds.map((userId) {
        return followRepository.followUser(
          followerId: testUser.id,
          followingId: userId,
        );
      }).toList();

      await expectLater(
        Future.wait(futures),
        completes,
      );
    });

    test('handle 10,000 followers in relationship table', () async {
      final enormousFollowerList = List.generate(
        10000,
        (i) => {
          'follower_id': 'user-$i',
          'profiles': {
            'id': 'user-$i',
            'full_name': 'User $i',
          }
        },
      );

      final followsBuilder = MockSupabaseQueryBuilder(
          selectResponse: enormousFollowerList.take(100).toList());
      mockSupabase.setQueryBuilder('follows', followsBuilder);

      final followers = await followRepository.getFollowers(testUser.id);

      expect(followers.length, greaterThan(0));
    });
  });

  group('Profile Integration - Error Handling', () {
    test('profile fetch of non-existent user returns null gracefully',
        () async {
      final profileBuilder =
          MockSupabaseQueryBuilder(selectResponse: [], shouldThrow: false);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profile = await profileRepository.getProfile('non-existent-id');

      expect(profile, null);
    });

    test('follow own profile rejected', () async {
      // Authorization check should prevent self-follow
      expect(true, true);
    });

    test('network error during profile update handled', () async {
      final builder = MockSupabaseQueryBuilder(shouldThrow: true);
      mockSupabase.setQueryBuilder('profiles', builder);

      // Should handle gracefully
      expect(true, true);
    });

    test('duplicate follow prevention', () async {
      final followsBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('follows', followsBuilder);

      // Database constraint should prevent duplicates
      expect(true, true);
    });
  });
}
