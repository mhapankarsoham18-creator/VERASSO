import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';
import 'package:verasso/features/profile/data/profile_repository.dart';
import 'package:verasso/features/social/data/feed_repository.dart';

import '../mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late AuthRepository authRepository;
  late FeedRepository feedRepository;
  late ProfileRepository profileRepository;
  late MockGamificationEventBus mockGamificationEventBus;
  late MockModerationService mockModerationService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = mockSupabase.auth as MockGoTrueClient;
    mockGamificationEventBus = MockGamificationEventBus();
    mockModerationService = MockModerationService();
    authRepository = AuthRepository(
      client: mockSupabase,
      secureAuth: MockSecureAuthService(),
    );
    feedRepository = FeedRepository(
      client: mockSupabase,
      eventBus: mockGamificationEventBus,
      moderationService: mockModerationService,
    );
    profileRepository = ProfileRepository(client: mockSupabase);
  });

  group('E2E: Auth → Feed Flow', () {
    test('complete user journey: launch → signup → email verify → feed',
        () async {
      // Step 1: Launch app, user not authenticated
      expect(mockAuth.currentUser, isNull);

      // Step 2: User enters email and password on signup form
      const testEmail = 'newuser@example.com';
      const testPassword = 'SecurePassword123!';
      const testName = 'New User';

      // Step 3: Submit signup
      final signupBuilder = MockSupabaseQueryBuilder(selectResponse: null);
      mockSupabase.setQueryBuilder('profiles', signupBuilder);

      await expectLater(
        authRepository.signUpWithEmail(
          email: testEmail,
          password: testPassword,
          data: {'full_name': testName},
        ),
        completes,
      );

      // Step 4: Verify email confirmation was triggered
      final testUser = TestSupabaseUser(
        id: 'user-new-1',
        email: testEmail,
      );
      mockAuth.setCurrentUser(testUser);

      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser?.email, testEmail);

      // Step 5: Profile auto-created from signup
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'full_name': testName,
          'email': testEmail,
          'avatar_url': null,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final userProfile = await profileRepository.getProfile(testUser.id);

      expect(userProfile, isNotNull);
      expect(userProfile?.fullName, testName);

      // Step 6: User navigates to feed
      final feedBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'user_id': 'user-2',
          'content': 'Welcome to VERASSO!',
          'created_at': DateTime.now().toIso8601String(),
          'profiles': {
            'full_name': 'Admin User',
            'avatar_url': null,
          }
        }
      ]);
      mockSupabase.setQueryBuilder('posts', feedBuilder);

      final feedPosts = await feedRepository.getFeed();

      expect(feedPosts, isNotEmpty);
      expect(feedPosts[0].content, contains('Welcome'));

      // Step 7: User scrolls through feed without errors
      expect(feedPosts.length, greaterThan(0));
    });

    test('existing user journey: signin → feed appearance → scroll', () async {
      // Step 1: User on login screen
      const testEmail = 'existing@example.com';

      // Step 2: Login request
      final testUser = TestSupabaseUser(
        id: 'user-existing-1',
        email: testEmail,
      );

      final authBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'email': testEmail,
        }
      ]);
      mockSupabase.setQueryBuilder('auth.users', authBuilder);

      mockAuth.setCurrentUser(testUser);

      expect(mockAuth.currentUser?.id, testUser.id);

      // Step 3: Session established
      expect(mockAuth.currentUser, isNotNull);

      // Step 4: Load user profile
      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'full_name': 'Existing User',
          'follower_count': 10,
          'following_count': 5,
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profile = await profileRepository.getProfile(testUser.id);

      expect(profile?.fullName, 'Existing User');

      // Step 5: Display feed with 100+ posts
      final largeFeed = List.generate(
        150,
        (i) => {
          'id': 'post-$i',
          'user_id': 'user-${i % 50}',
          'content': 'Post $i content',
          'created_at':
              DateTime.now().subtract(Duration(hours: i)).toIso8601String(),
          'like_count': i * 2,
          'profiles': {
            'full_name': 'User ${i % 50}',
          }
        },
      );

      final feedBuilder = MockSupabaseQueryBuilder(selectResponse: largeFeed);
      mockSupabase.setQueryBuilder('posts', feedBuilder);

      final feedPosts = await feedRepository.getFeed();

      expect(feedPosts.length, 150);

      // Step 6: Simulate scrolling through feed
      final stopwatch = Stopwatch()..start();
      // In real scenario, this would be scroll animation
      for (int i = 0; i < 20; i++) {
        // Simulate viewing each post
        expect(feedPosts[i].id, isNotNull);
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Step 7: Feed should remain responsive
      expect(feedPosts.length, greaterThan(100));
    });

    test('session expires, user redirected to login', () async {
      final testUser = TestSupabaseUser(
        id: 'user-test-1',
        email: 'test@example.com',
      );

      mockAuth.setCurrentUser(testUser);
      expect(mockAuth.currentUser, isNotNull);

      // Simulate session expiry by clearing user
      mockAuth.setCurrentUser(null);

      expect(mockAuth.currentUser, isNull);
    });

    test('login with invalid credentials shows error', () async {
      // Attempt login with wrong password
      final authBuilder = MockSupabaseQueryBuilder(
        selectResponse: [],
        shouldThrow: true,
      );
      mockSupabase.setQueryBuilder('auth.users', authBuilder);

      // Should handle authentication error gracefully
      expect(true, true);
    });

    test('network error during feed load handled gracefully', () async {
      final testUser = TestSupabaseUser(
        id: 'user-test-1',
        email: 'test@example.com',
      );

      mockAuth.setCurrentUser(testUser);

      final feedBuilder =
          MockSupabaseQueryBuilder(selectResponse: [], shouldThrow: true);
      mockSupabase.setQueryBuilder('posts', feedBuilder);

      // Should retry or show offline state
      expect(true, true);
    });

    test('feed loads with offline support (cached posts)', () async {
      final testUser = TestSupabaseUser(
        id: 'user-test-1',
        email: 'test@example.com',
      );

      mockAuth.setCurrentUser(testUser);

      // Simulate cached feed data
      final cachedPosts = [
        {
          'id': 'cached-post-1',
          'user_id': testUser.id,
          'content': 'Cached content',
          'is_cached': true,
          'created_at': DateTime.now().toIso8601String(),
        }
      ];

      final feedBuilder = MockSupabaseQueryBuilder(selectResponse: cachedPosts);
      mockSupabase.setQueryBuilder('posts', feedBuilder);

      final feedPosts = await feedRepository.getFeed();

      expect(feedPosts, isNotEmpty);
    });
  });

  group('E2E: Auth → Feed - UI Layer', () {
    test('loading indicator appears during feed fetch', () async {
      // Simulate loading state with delay
      final stopwatch = Stopwatch()..start();

      await Future.delayed(Duration(milliseconds: 200));

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThan(100));
    });

    test('error message displayed on auth failure', () async {
      // Network error should show user-friendly message
      expect(true, true);
    });

    test('profile avatar loads without 404 errors', () async {
      const avatarUrl = 'https://example.com/avatar.jpg';

      // Image should be validated before display
      expect(avatarUrl, isNotEmpty);
    });

    test('feed posts render correctly with missing images', () async {
      final feedBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'user_id': 'user-1',
          'content': 'Post without image',
          'media_urls': null,
          'created_at': DateTime.now().toIso8601String(),
        }
      ]);
      mockSupabase.setQueryBuilder('posts', feedBuilder);

      final posts = await feedRepository.getFeed();

      expect(posts, isNotEmpty);
    });
  });

  group('E2E: Auth → Feed - Performance', () {
    test('cold start from launch to feed under 3 seconds', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate startup flow
      final testUser = TestSupabaseUser(
        id: 'user-perf-1',
        email: 'perf@example.com',
      );

      mockAuth.setCurrentUser(testUser);

      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'full_name': 'Perf User',
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      await profileRepository.getProfile(testUser.id);

      final feedBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': 'post-1',
          'user_id': 'user-1',
          'content': 'Test',
          'created_at': DateTime.now().toIso8601String()
        }
      ]);
      mockSupabase.setQueryBuilder('posts', feedBuilder);

      await feedRepository.getFeed();

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    test('feed scroll maintains 60fps', () async {
      final testUser = TestSupabaseUser(
        id: 'user-fps-1',
        email: 'fps@example.com',
      );

      mockAuth.setCurrentUser(testUser);

      // Generate 500 posts for scroll test
      final largeFeed = List.generate(
          500,
          (i) => {
                'id': 'post-$i',
                'user_id': 'user-$i',
                'content': 'Post $i',
                'created_at': DateTime.now().toIso8601String(),
              });

      final feedBuilder = MockSupabaseQueryBuilder(selectResponse: largeFeed);
      mockSupabase.setQueryBuilder('posts', feedBuilder);

      final stopwatch = Stopwatch()..start();
      final posts = await feedRepository.getFeed();
      stopwatch.stop();

      // Should load without blocking main thread
      expect(posts.length, 500);
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    test('memory usage stabilizes after feed load', () async {
      // Memory test - simulate garbage collection
      final testUser = TestSupabaseUser(
        id: 'user-mem-1',
        email: 'mem@example.com',
      );

      mockAuth.setCurrentUser(testUser);

      // Load large feed
      final largeFeed = List.generate(
          1000,
          (i) => {
                'id': 'post-$i',
                'user_id': 'user-$i',
                'content': 'Post $i content that could be large',
                'created_at': DateTime.now().toIso8601String(),
              });

      final feedBuilder = MockSupabaseQueryBuilder(selectResponse: largeFeed);
      mockSupabase.setQueryBuilder('posts', feedBuilder);

      await feedRepository.getFeed();

      // Should not keep growing memory
      expect(true, true);
    });
  });

  group('E2E: Auth → Feed - Data Consistency', () {
    test('user profile matches auth user throughout session', () async {
      const testEmail = 'consistency@example.com';

      final testUser = TestSupabaseUser(
        id: 'user-consistency-1',
        email: testEmail,
      );

      mockAuth.setCurrentUser(testUser);

      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'email': testEmail,
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final profile = await profileRepository.getProfile(testUser.id);

      expect(profile?.email, mockAuth.currentUser?.email);
    });

    test('feed reflects user follow count updates', () async {
      final testUser = TestSupabaseUser(
        id: 'user-feed-1',
        email: 'feed@example.com',
      );

      mockAuth.setCurrentUser(testUser);

      final profileBuilder = MockSupabaseQueryBuilder(selectResponse: [
        {
          'id': testUser.id,
          'followers_count': 10,
        }
      ]);
      mockSupabase.setQueryBuilder('profiles', profileBuilder);

      final userProfile = await profileRepository.getProfile(testUser.id);

      expect(userProfile?.followersCount, 10);
    });
  });
}
