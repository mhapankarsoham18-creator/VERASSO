// ignore_for_file: must_be_immutable
import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:mockito/mockito.dart';
import 'package:pinenacl/ed25519.dart' as pinenacl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/auth/secure_auth_service.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/core/security/audit_log_service.dart';
import 'package:verasso/core/security/biometric_auth_service.dart';
import 'package:verasso/core/security/encryption_service.dart'
    as verasso_encryption;
import 'package:verasso/core/security/moderation_service.dart';
import 'package:verasso/core/security/offline_security_service.dart';
import 'package:verasso/core/security/session_timeout_service.dart';
import 'package:verasso/core/security/token_storage_service.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/services/content_recommendation_service.dart';
import 'package:verasso/core/services/mastery_signature_service.dart';
import 'package:verasso/core/services/network_connectivity_service.dart';
import 'package:verasso/core/services/offline_storage_service.dart';
import 'package:verasso/core/services/rate_limit_service.dart'
    as verasso_rate_limit;
import 'package:verasso/features/auth/data/auth_repository.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';
import 'package:verasso/features/auth/domain/mfa_models.dart';
import 'package:verasso/features/gamification/data/gamification_repository.dart';
import 'package:verasso/features/gamification/models/badge_model.dart';
import 'package:verasso/features/gamification/services/gamification_event_bus.dart';
import 'package:verasso/features/learning/data/collaboration_models.dart';
import 'package:verasso/features/learning/data/collaboration_repository.dart';
import 'package:verasso/features/learning/data/course_models.dart';
import 'package:verasso/features/learning/data/course_repository.dart';
import 'package:verasso/features/learning/data/transaction_service.dart';
import 'package:verasso/features/messaging/data/message_repository.dart';
import 'package:verasso/features/messaging/models/message_model.dart';
import 'package:verasso/features/messaging/services/encryption_service.dart'
    as msg_enc;
import 'package:verasso/features/news/data/mesh_news_service.dart';
import 'package:verasso/features/news/data/news_repository.dart';
import 'package:verasso/features/news/data/news_service.dart';
import 'package:verasso/features/news/domain/news_model.dart';
import 'package:verasso/features/notifications/data/notification_service.dart';
import 'package:verasso/features/notifications/models/notification_model.dart';
import 'package:verasso/features/profile/data/profile_model.dart';
import 'package:verasso/features/profile/data/profile_repository.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';
import 'package:verasso/features/settings/presentation/privacy_settings_controller.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/features/social/data/collection_model.dart';
import 'package:verasso/features/social/data/comment_model.dart';
import 'package:verasso/features/social/data/comment_repository.dart';
import 'package:verasso/features/social/data/community_model.dart';
import 'package:verasso/features/social/data/community_repository.dart';
import 'package:verasso/features/social/data/feed_repository.dart';
import 'package:verasso/features/social/data/post_model.dart';
import 'package:verasso/features/social/data/saved_post_repository.dart';
import 'package:verasso/features/social/data/story_model.dart';
import 'package:verasso/features/social/data/story_repository.dart';
import 'package:verasso/features/talent/data/analytics_repository.dart';
import 'package:verasso/features/talent/data/job_model.dart';
import 'package:verasso/features/talent/data/job_repository.dart';
import 'package:verasso/features/talent/data/talent_model.dart';
import 'package:verasso/features/talent/data/talent_profile_model.dart';
import 'package:verasso/features/talent/data/talent_profile_repository.dart';
import 'package:verasso/features/talent/data/talent_repository.dart';

// Awaitable Fake
class AwaitablePostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  final T _response;
  AwaitablePostgrestFilterBuilder(this._response);

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    return Future.value(_response).then(onValue, onError: onError);
  }
}

class FakeAuthMFAEnrollResponse extends Fake implements AuthMFAEnrollResponse {
  @override
  final String id;
  @override
  final FactorType type;
  @override
  final TOTPEnrollment? totp;

  FakeAuthMFAEnrollResponse({
    this.id = 'fake-factor-id',
    this.type = FactorType.totp,
    this.totp,
  });
}

class FakeAuthMFAUnenrollResponse extends Fake
    implements AuthMFAUnenrollResponse {}

class FakeAuthMFAVerifyResponse extends Fake implements AuthMFAVerifyResponse {
  @override
  final String accessToken;

  FakeAuthMFAVerifyResponse({this.accessToken = 'fake-access-token'});
}

class FakeSession extends Fake implements Session {
  @override
  String get accessToken => 'fake-access-token';
  @override
  int get expiresIn => 3600;
  @override
  String get refreshToken => 'fake-refresh-token';
  @override
  User get user => TestSupabaseUser();
}

class FakeSupabaseStorageFileApi extends Fake implements StorageFileApi {
  @override
  String getPublicUrl(
    String path, {
    TransformOptions? transform,
  }) {
    final transformQuery = transform != null ? '?transform=true' : '';
    return 'https://fake.url/$path$transformQuery';
  }

  @override
  Future<String> upload(
    String path,
    File file, {
    FileOptions? fileOptions,
    int? retryAttempts,
    StorageRetryController? retryController,
  }) async =>
      path;
}

class MockAnalyticsRepository extends Fake implements AnalyticsRepository {
  Future<void> Function({
    required String eventType,
    required String targetType,
    required String targetId,
  })? trackEventStub;

  @override
  Future<void> trackEvent({
    required String eventType,
    required String targetType,
    required String targetId,
  }) async {
    await trackEventStub?.call(
      eventType: eventType,
      targetType: targetType,
      targetId: targetId,
    );
  }
}

class MockAuditLogService extends Fake implements AuditLogService {
  Future<void> Function({
    required String type,
    required String action,
    required String severity,
    Map<String, dynamic>? metadata,
  })? logEventStub;

  @override
  Future<void> logEvent({
    required String type,
    required String action,
    required String severity,
    Map<String, dynamic>? metadata,
  }) async {
    if (logEventStub != null) {
      await logEventStub!(
        type: type,
        action: action,
        severity: severity,
        metadata: metadata,
      );
    }
  }
}

class MockAuthRepository extends Fake implements AuthRepository {
  DomainAuthUser? _currentUser;

  @override
  Stream<DomainAuthUser?> get authStateChanges => Stream.value(_currentUser);

  @override
  DomainAuthUser? get currentUser => _currentUser;

  @override
  SupabaseClient get supabaseClient => MockSupabaseClient();

  @override
  Future<void> challengeAndVerify(
      {required String factorId, required String code}) async {}

  @override
  Future<MfaChallenge> challengeMFA({required String factorId}) async =>
      MfaChallenge(id: 'test-challenge-id');

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<MfaEnrollment?> enrollMFA() async => MfaEnrollment(
        id: 'test-factor-id',
        type: 'totp',
      );

  @override
  Future<List<dynamic>> listFactors() async => [];

  @override
  Future<void> resetPasswordForEmail({required String email}) async {}

  void setMockUser(DomainAuthUser? user) {
    _currentUser = user;
    if (user != null) {
      // Also update auth state stream
    }
  }

  @override
  Future<AuthResult> signInWithEmail(
          {required String email, required String password}) async =>
      AuthResult(
          user: DomainAuthUser(
        id: 'test-user-id',
        email: email,
      ));

  @override
  Future<void> signInWithOtp(
      {required String email, bool isWeb = false}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    Map<String, dynamic>? data,
  }) async =>
      AuthResult(user: DomainAuthUser(id: 'test-new-user', email: email));

  @override
  Future<void> unenrollMFA({required String factorId}) async {}

  @override
  Future<void> updateUserPassword({required String password}) async {}

  @override
  Future<AuthResult?> verifyMFA({
    required String factorId,
    required String challengeId,
    required String code,
  }) async =>
      AuthResult(user: DomainAuthUser(id: 'test-user-id'));

  @override
  Future<AuthResult?> verifyOtp({
    required String token,
    required dynamic type,
    String? email,
    String? phone,
  }) async =>
      AuthResult(user: DomainAuthUser(id: 'test-otp-user', email: email));
}

class MockBiometricAuthService extends Fake implements BiometricAuthService {
  bool _isAvailable = true;
  bool _isEnabled = false;
  String _biometricType = 'Face ID';

  @override
  Future<BiometricAuthResult> authenticate({
    String reason = 'Please authenticate to access your account',
  }) async {
    return BiometricAuthResult.success();
  }

  @override
  Future<void> disableBiometric() async {
    _isEnabled = false;
  }

  @override
  Future<bool> enableBiometric() async {
    _isEnabled = true;
    return true;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return [BiometricType.face];
  }

  @override
  Future<String> getBiometricTypeString() async {
    return _biometricType;
  }

  @override
  Future<bool> isBiometricAvailable() async {
    return _isAvailable;
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return _isEnabled;
  }

  void setAvailable(bool value) => _isAvailable = value;

  void setBiometricType(String value) => _biometricType = value;

  void setEnabled(bool value) => _isEnabled = value;

  @override
  Future<void> stopAuthentication() async {}
}

class MockBluetoothMeshService extends Fake implements BluetoothMeshService {
  bool _isMeshActive = false;
  final List<Map<String, dynamic>> broadcastPacketCalls = [];

  @override
  bool get isMeshActive => _isMeshActive;

  MeshPayloadType? get lastBroadcastType => broadcastPacketCalls.isNotEmpty
      ? broadcastPacketCalls.last['type']
      : null;

  @override
  Stream<MeshPacket> get meshStream => Stream.empty();

  @override
  Future<void> broadcastPacket(
    MeshPayloadType type,
    Map<String, dynamic> data, {
    MeshPriority? priority,
    String? targetSubject,
  }) async {
    broadcastPacketCalls.add({
      'type': type,
      'data': data,
      'priority': priority,
      'targetSubject': targetSubject,
    });
  }

  void setIsMeshActive(bool value) => _isMeshActive = value;
}

class MockCollaborationRepository extends Fake
    implements CollaborationRepository {
  Future<List<DailyChallenge>> Function()? getActiveChallengesStub;

  @override
  Future<List<DailyChallenge>> getActiveChallenges() async {
    if (getActiveChallengesStub != null) {
      return getActiveChallengesStub!();
    }
    return [];
  }
}

class MockCommentRepository extends Fake implements CommentRepository {
  final List<String> addCommentCalls = [];
  Future<List<Comment>> Function(String postId)? getCommentsStub;
  Future<Comment> Function({required String postId, required String content})?
      addCommentStub;
  RealtimeChannel Function(String postId, void Function(Comment) onNewComment)?
      subscribeToCommentsStub;

  @override
  Future<Comment> addComment({
    required String postId,
    required String content,
    String? userId,
  }) {
    addCommentCalls.add(content);
    return addCommentStub?.call(postId: postId, content: content) ??
        Future.value(Comment(
          id: 'new',
          postId: postId,
          userId: 'current-user',
          content: content,
          createdAt: DateTime.now(),
          authorName: 'Current User',
        ));
  }

  @override
  Future<List<Comment>> getComments(String postId) =>
      getCommentsStub?.call(postId) ?? Future.value([]);

  @override
  RealtimeChannel subscribeToComments(
          String postId, void Function(Comment) onNewComment) =>
      subscribeToCommentsStub?.call(postId, onNewComment) ??
      MockRealtimeChannel();
}

class MockCommunityRepository extends Fake implements CommunityRepository {
  Future<List<Community>> Function()? getRecommendedCommunitiesStub;
  Future<List<Community>> Function(String)? searchCommunitiesStub;

  Future<List<Community>> getCommunitiesByUser(String userId) async => [];

  Future<List<Community>> getJoinedCommunities() async => [];

  @override
  Future<List<Community>> getRecommendedCommunities() async {
    if (getRecommendedCommunitiesStub != null) {
      return getRecommendedCommunitiesStub!();
    }
    return [];
  }

  @override
  Future<void> joinCommunity(String communityId, String userId) async {}

  Future<void> leaveCommunity(String communityId, String userId) async {}

  @override
  Future<List<Community>> searchCommunities(String query) async {
    if (searchCommunitiesStub != null) {
      return searchCommunitiesStub!(query);
    }
    return [];
  }
}

class MockContentRecommendationService extends ContentRecommendationService {
  MockContentRecommendationService() : super(MockCourseRepository());

  @override
  Future<List<SimulationRecommendation>> recommendSimulations({
    required String userId,
    required List<String> completedSimulations,
    required Map<String, int> categoryProgress,
    required List<String> interests,
    int limit = 5,
  }) async =>
      [];
}

class MockCourseRepository extends Fake implements CourseRepository {
  Future<List<Enrollment>> Function()? getMyEnrollmentsStub;
  Future<List<Course>> Function()? getPublishedCoursesStub;

  @override
  Future<List<Enrollment>> getMyEnrollments() async {
    if (getMyEnrollmentsStub != null) {
      return getMyEnrollmentsStub!();
    }
    return [];
  }

  @override
  Future<List<Course>> getPublishedCourses() async {
    if (getPublishedCoursesStub != null) {
      return getPublishedCoursesStub!();
    }
    return [];
  }
}

// Core Encryption Service Mock (core/security)
class MockEncryptionService extends Fake
    implements verasso_encryption.EncryptionService {
  String? encryptResult;
  String? decryptResult;
  Exception? encryptThrow;
  Exception? decryptThrow;

  @override
  Future<String> decrypt(String encryptedText) async {
    if (decryptThrow != null) throw decryptThrow!;
    return decryptResult ?? encryptedText.replaceAll('encrypted_', '');
  }

  @override
  Future<String> encrypt(String plaintext) async {
    if (encryptThrow != null) throw encryptThrow!;
    return encryptResult ?? 'encrypted_$plaintext';
  }

  @override
  Future<void> initialize() async {}
  void setDecryptResult(String r) => decryptResult = r;

  void setDecryptThrow(Exception e) => decryptThrow = e;

  void setEncryptResult(String r) => encryptResult = r;

  void setEncryptThrow(Exception e) => encryptThrow = e;
}

class MockFeedRepository extends Fake implements FeedRepository {
  Future<List<Post>> Function(
      {List<String> userInterests, int limit, int offset})? getFeedStub;
  Future<List<Post>> Function({String? userId})? getFollowingFeedStub;
  Stream<List<Post>> Function()? watchFeedStub;
  Future<void> Function(String postId)? likePostStub;

  @override
  Future<void> createComment(String postId, String content) async {}

  @override
  Future<void> createPost({
    required String userId,
    String? content,
    List<File> images = const [],
    File? audio,
    List<String> tags = const [],
    List<String>? mediaUrls,
    bool isPersonal = false,
  }) async {}

  Future<void> deleteComment(String commentId) async {}
  @override
  Future<void> deletePost(String postId) async {}
  @override
  Future<List<Post>> getFeed({
    List<String> userInterests = const [],
    int limit = 20,
    int offset = 0,
  }) =>
      getFeedStub?.call(
          userInterests: userInterests, limit: limit, offset: offset) ??
      Future.value([]);
  // Legacy or renamed methods
  @override
  Future<List<Post>> getFeedPosts({
    int limit = 20,
    int offset = 0,
    List<String> userInterests = const [],
  }) =>
      getFeed(limit: limit, offset: offset, userInterests: userInterests);
  @override
  Future<List<Post>> getFollowingFeed({String? userId}) =>
      getFollowingFeedStub?.call(userId: userId) ?? Future.value([]);

  @override
  Future<Post> getPostById(String postId) async =>
      Post.fromJson({'id': postId});

  @override
  Future<List<Post>> getUserPosts(String userId) async => [];

  @override
  Future<void> likePost(String postId) =>
      likePostStub?.call(postId) ?? Future.value();

  @override
  Future<List<Post>> searchPosts(String query) async => [];

  @override
  Future<void> sharePost(Post post) async {}

  @override
  Future<void> unlikePost(String postId) async {}

  @override
  Future<void> updatePost(
    String postId, [
    String? content,
  ]) async {}

  @override
  Stream<List<Post>> watchFeed() => watchFeedStub?.call() ?? Stream.value([]);
}

class MockFirebaseMessaging extends Fake implements FirebaseMessaging {
  @override
  Stream<String> get onTokenRefresh => Stream.value('fake-fcm-token');

  @override
  Future<String?> getToken({String? vapidKey}) async => 'fake-fcm-token';

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool providesAppNotificationSettings = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    return const NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.disabled,
      authorizationStatus: AuthorizationStatus.authorized,
    );
  }
}

class MockFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }
}

class MockGamificationEventBus extends Fake implements GamificationEventBus {
  final List<GamificationEvent> emittedEvents = [];

  final _controller = StreamController<GamificationEvent>.broadcast();

  @override
  Stream<GamificationEvent> get stream => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }

  @override
  void emit(GamificationEvent event) {
    emittedEvents.add(event);
    _controller.add(event);
  }

  @override
  void track(GamificationAction action, String userId,
      {Map<String, dynamic> metadata = const {}}) {
    emit(GamificationEvent(action: action, userId: userId, metadata: metadata));
  }
}

class MockGamificationRepository extends Fake
    implements GamificationRepository {
  Future<List<UserStats>> Function()? getLeaderboardStub;
  Future<UserStats?> Function()? getUserStatsStub;

  @override
  Future<List<UserStats>> getLeaderboard() async {
    return getLeaderboardStub?.call() ?? Future.value([]);
  }

  @override
  Future<UserStats?> getUserStats() async {
    return getUserStatsStub?.call() ?? Future.value(null);
  }

  @override
  Future<void> recordActivity() async {}

  @override
  Future<void> unlockBadge(String badgeId, {int xpReward = 0}) async {}

  @override
  Future<void> updateXP(int additionalXP) async {}

  @override
  Stream<List<UserStats>> watchLeaderboard() => Stream.value([]);
}

class MockGoTrueClient extends Fake implements GoTrueClient {
  @override
  final GoTrueMFAApi mfa;
  User? _currentUser;

  MockGoTrueClient({GoTrueMFAApi? mfa}) : mfa = mfa ?? MockGoTrueMFAApi();
  @override
  User? get currentUser => _currentUser;

  @override
  Future<OAuthResponse> getOAuthSignInUrl({
    required OAuthProvider provider,
    String? redirectTo,
    String? scopes,
    Map<String, String>? queryParams,
  }) async =>
      OAuthResponse(provider: provider, url: 'https://fake.url/oauth');

  void setCurrentUser(User? user) => _currentUser = user;

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    String? emailRedirectTo,
    bool? shouldCreateUser,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel? channel,
  }) async {}
  @override
  Future<AuthResponse> verifyOTP({
    String? email,
    String? phone,
    required OtpType type,
    String? token,
    String? tokenHash,
    String? redirectTo,
    String? captchaToken,
  }) async =>
      AuthResponse(user: TestSupabaseUser());
}

class MockGoTrueMFAApi extends Fake implements GoTrueMFAApi {
  @override
  Future<AuthMFAChallengeResponse> challenge({String? factorId}) async =>
      AuthMFAChallengeResponse(id: 'test-challenge', expiresAt: DateTime.now());

  @override
  Future<AuthMFAEnrollResponse> enroll({
    FactorType? factorType,
    String? friendlyName,
    String? issuer,
    String? phone,
  }) async =>
      FakeAuthMFAEnrollResponse();

  @override
  Future<AuthMFAListFactorsResponse> listFactors() async =>
      AuthMFAListFactorsResponse(all: [], totp: [], phone: []);

  @override
  Future<AuthMFAUnenrollResponse> unenroll(String factorId) async =>
      FakeAuthMFAUnenrollResponse();

  @override
  Future<AuthMFAVerifyResponse> verify({
    String? factorId,
    String? challengeId,
    String? code,
  }) async =>
      FakeAuthMFAVerifyResponse();
}

class MockJobRepository extends Fake implements JobRepository {
  Future<List<JobRequest>> Function({int limit, int offset})?
      getJobRequestsStub;
  Future<void> Function(String jobId, String userId, String message)?
      applyForJobStub;

  @override
  Future<void> applyForJob(String jobId, String userId, String message) async {
    await applyForJobStub?.call(jobId, userId, message);
  }

  @override
  Future<List<JobRequest>> getJobRequests(
      {int limit = 20, int offset = 0}) async {
    return getJobRequestsStub?.call(limit: limit, offset: offset) ??
        Future.value([]);
  }
}

class MockLocalAuthentication extends Fake implements LocalAuthentication {
  bool canCheck = true;
  bool isSupported = true;
  bool authenticated = true;
  List<BiometricType> biometrics = [BiometricType.face];

  @override
  Future<bool> get canCheckBiometrics async => canCheck;
  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const [],
    bool biometricOnly = false,
    bool persistAcrossBackgrounding = true,
    bool sensitiveTransaction = true,
  }) async =>
      authenticated;
  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => biometrics;
  @override
  Future<bool> isDeviceSupported() async => isSupported;
  @override
  Future<bool> stopAuthentication() async => true;
}

class MockMasterySignatureService extends Fake
    implements MasterySignatureService {
  @override
  String generateSignedTranscript({
    required String userId,
    required Map<String, double> skills,
    required pinenacl.SigningKey signingKey,
  }) {
    // Return a longer string to avoid RangeError in UI substring(0, 50)
    return 'mock_signed_transcript_for_$userId${'A' * 50}';
  }

  @override
  Future<pinenacl.SigningKey?> getGlobalSigningKey() async {
    return pinenacl.SigningKey.generate();
  }

  @override
  bool verifyTranscript(String transcriptJson) {
    return true;
  }
}

class MockMeshNewsService extends StateNotifier<List<NewsArticle>>
    implements MeshNewsService {
  Future<void> Function(NewsArticle article)? broadcastArticleStub;

  MockMeshNewsService([super.initial = const []]);

  @override
  Future<void> broadcastArticle(NewsArticle article) async {
    await broadcastArticleStub?.call(article);
  }

  @override
  // ignore: must_call_super
  void dispose() {}
}

class MockMessageRepository extends Fake implements MessageRepository {
  Future<List<Message>> Function(String)? getMessagesListStub;
  Future<void> Function(
      {required String senderId,
      required String receiverId,
      required String content})? sendMessageStub;
  Future<void> Function(String)? markAsReadStub;
  Future<int> Function(String?)? getUnreadCountStub;
  Future<List<Message>> Function(
      {String? conversationId, required String query})? searchMessagesStub;
  Future<void> Function(String)? archiveConversationStub;
  Future<void> Function(String)? unarchiveConversationStub;

  @override
  Future<void> archiveConversation(String conversationId) async {
    await archiveConversationStub?.call(conversationId);
  }

  @override
  Future<List<Message>> getMessagesList(String conversationId) async {
    return getMessagesListStub?.call(conversationId) ?? Future.value([]);
  }

  @override
  Future<int> getUnreadCount([String? userId]) async {
    final result = await getUnreadCountStub?.call(userId);
    return result ?? 0;
  }

  @override
  Future<void> markAsRead(String messageId) async {
    await markAsReadStub?.call(messageId);
  }

  @override
  Future<List<Message>> searchMessages(
      {String? conversationId, required String query}) async {
    return searchMessagesStub?.call(
            conversationId: conversationId, query: query) ??
        Future.value([]);
  }

  @override
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    String? recipientId,
    required String content,
    String? conversationId,
    String mediaType = 'text',
  }) async {
    await sendMessageStub?.call(
      senderId: senderId,
      receiverId: recipientId ?? receiverId,
      content: content,
    );
  }

  @override
  Future<void> unarchiveConversation(String conversationId) async {
    await unarchiveConversationStub?.call(conversationId);
  }
}

// Messaging Encryption Service Mocks (features/messaging)
class MockMessagingEncryptionService extends Fake
    implements msg_enc.EncryptionService {
  String? encryptResult;
  String? decryptResult;
  Exception? encryptThrow;
  Exception? decryptThrow;

  @override
  Future<String> decryptMessage(Map<String, dynamic> messageRow,
      {bool isGroup = false}) async {
    if (decryptThrow != null) throw decryptThrow!;
    return decryptResult ?? 'decrypted_content';
  }

  @override
  Future<Map<String, dynamic>> encryptGroupMessage(
      String content, List<String> receiverIds) async {
    if (encryptThrow != null) throw encryptThrow!;
    return {
      'content': encryptResult ?? 'encrypted_$content',
      'iv': 'fake_iv',
      'keys_per_user': {for (var id in receiverIds) id: 'fake_key'},
      'key_sender': 'fake_key_s',
    };
  }

  @override
  Future<Map<String, String>> encryptMessage(
      String content, String receiverId) async {
    if (encryptThrow != null) throw encryptThrow!;
    return {
      'content': encryptResult ?? 'encrypted_content',
      'iv': 'fake',
      'key_receiver': 'fake',
      'key_sender': 'fake',
    };
  }

  @override
  Future<void> initializeKeys() async {}

  void setDecryptResult(String r) => decryptResult = r;

  void setDecryptThrow(Exception e) => decryptThrow = e;

  void setEncryptResult(String r) => encryptResult = r;

  void setEncryptThrow(Exception e) => encryptThrow = e;
}

class MockModerationService extends Fake implements ModerationService {
  Future<List<String>> Function(String userId)? getMutedUserIdsStub;

  // Legacy/Extra methods sometimes used in tests
  Future<bool> containsInappropriateContent(String content) async => false;

  @override
  Future<List<String>> getMutedUserIds(String userId) =>
      getMutedUserIdsStub?.call(userId) ?? Future.value([]);

  Future<String> moderateText(String text) async => text;

  @override
  Future<void> muteUser({
    required String userId,
    required String mutedUserId,
  }) async {}

  @override
  Future<void> reportContent({
    required String reporterId,
    required String targetId,
    required String targetType,
    required String reason,
  }) async {}
  @override
  Future<void> unmuteUser({
    required String userId,
    required String mutedUserId,
  }) async {}
}

class MockNetworkConnectivityService extends Fake
    implements NetworkConnectivityService {
  bool _isConnected = true;
  final _controller = StreamController<NetworkStatus>.broadcast();

  @override
  Future<bool> get isConnected async => _isConnected;

  @override
  Stream<NetworkStatus> get statusStream => _controller.stream;

  void setIsConnected(bool value) {
    _isConnected = value;
    _controller.add(value ? NetworkStatus.online : NetworkStatus.offline);
  }
}

class MockNewsRepository extends Fake implements NewsRepository {
  Future<void> Function(String articleId, String content, {String? parentId})?
      addCommentStub;
  Future<NewsArticle> Function(String articleId)? getArticleByIdStub;
  Future<List<NewsArticle>> Function({String? subject, bool featuredOnly})?
      getArticlesStub;
  Future<void> Function(NewsArticle article)? publishArticleStub;
  Future<void> Function(String articleId)? upvoteArticleStub;
  Future<void> Function(String articleId)? vouchArticleStub;
  Stream<List<NewsArticle>> Function({String? subject, bool featuredOnly})?
      watchArticlesStub;

  @override
  Future<void> addComment(String articleId, String content,
          {String? parentId}) =>
      addCommentStub?.call(articleId, content, parentId: parentId) ??
      Future.value();

  @override
  Future<NewsArticle> getArticleById(String articleId) async {
    if (getArticleByIdStub != null) {
      return getArticleByIdStub!(articleId);
    }
    throw Exception('MockNewsRepository.getArticleByIdStub not implemented');
  }

  @override
  Future<List<NewsArticle>> getArticles(
          {String? subject, bool featuredOnly = false}) =>
      getArticlesStub?.call(subject: subject, featuredOnly: featuredOnly) ??
      Future.value([]);

  @override
  Future<void> publishArticle(NewsArticle article) =>
      publishArticleStub?.call(article) ?? Future.value();

  @override
  Future<void> upvoteArticle(String articleId) =>
      upvoteArticleStub?.call(articleId) ?? Future.value();

  @override
  Future<void> vouchArticle(String articleId) =>
      vouchArticleStub?.call(articleId) ?? Future.value();

  @override
  Stream<List<NewsArticle>> watchArticles(
          {String? subject, bool featuredOnly = false}) =>
      watchArticlesStub?.call(subject: subject, featuredOnly: featuredOnly) ??
      Stream.value([]);
}

class MockNewsService extends Fake implements NewsService {
  Future<List<NewsArticle>> Function()? fetchHistoricalEventsStub;
  Future<List<NewsArticle>> Function({required String category})? fetchNewsStub;

  @override
  Future<List<NewsArticle>> fetchHistoricalEvents() =>
      fetchHistoricalEventsStub?.call() ?? Future.value([]);

  @override
  Future<List<NewsArticle>> fetchNews({required String category}) =>
      fetchNewsStub?.call(category: category) ?? Future.value([]);
}

class MockNotificationService extends Fake implements NotificationService {
  Future<void> Function({
    required String targetUserId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  })? createNotificationStub;

  @override
  Future<void> createNotification({
    required String targetUserId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await createNotificationStub?.call(
      targetUserId: targetUserId,
      type: type,
      title: title,
      body: body,
      data: data,
    );
  }
}

class MockOfflineSecurityService extends Fake
    implements OfflineSecurityService {
  @override
  Future<void> clearIdentityHint() async {}
  @override
  Future<String?> getLastKnownEmail() async => 'test@example.com';
  @override
  Future<bool> hasIdentityHint() async => true;
  @override
  Future<void> setIdentityHint(String email) async {}
}

class MockOfflineStorageService extends Fake implements OfflineStorageService {
  final List<Map<String, dynamic>> queueActionRawCalls = [];
  dynamic Function(String, {Duration? expiration})? getCachedDataStub;

  @override
  Future<void> cacheData(String key, dynamic value) async {}

  @override
  dynamic getCachedData(String key, {Duration? expiration}) {
    if (getCachedDataStub != null) {
      return getCachedDataStub!(key, expiration: expiration);
    }
    return null;
  }

  @override
  Future<void> initialize(
      verasso_encryption.EncryptionService encryptionService) async {}

  @override
  Future<void> queueAction(String actionType, Map<String, dynamic> data,
      {String? id}) async {
    queueActionRawCalls.add({'actionType': actionType, 'data': data, 'id': id});
  }
}

class MockPostgrestFilterBuilder<T> extends Fake
    implements PostgrestFilterBuilder<T> {
  bool _isCountCalled = false;
  bool shouldThrow = false;
  T? _response;
  int _count = 0;

  @override
  ResponsePostgrestBuilder<PostgrestResponse<T>, T, T> count(
      [CountOption count = CountOption.exact]) {
    _isCountCalled = true;
    return this as dynamic;
  }

  PostgrestFilterBuilder<T> delete(
          {bool returning = true, bool count = false}) =>
      this;

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> filter(
          String column, String operator, Object? value) =>
      this;

  @override
  PostgrestFilterBuilder<T> gt(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<T> gte(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<T> ilike(String column, String pattern) => this;
  @override
  PostgrestFilterBuilder<T> inFilter(String column, List<dynamic> values) =>
      this;
  @override
  PostgrestFilterBuilder<T> isFilter(String column, Object? value) => this;
  @override
  PostgrestTransformBuilder<T> limit(int count, {String? referencedTable}) =>
      this;
  @override
  PostgrestFilterBuilder<T> lt(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<T> lte(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<T> match(Map<String, Object> query) => this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    final builder = MockPostgrestFilterBuilder<Map<String, dynamic>?>();
    builder.shouldThrow = shouldThrow;
    if (_response is List && (_response as List).isNotEmpty) {
      builder.setResponse((_response as List).first as Map<String, dynamic>);
    } else {
      builder.setResponse(null);
    }
    return builder;
  }

  @override
  PostgrestFilterBuilder<T> not(
          String column, String operator, Object? value) =>
      this;

  @override
  PostgrestFilterBuilder<T> or(String filters,
          {String? foreignTable, String? referencedTable}) =>
      this;

  @override
  PostgrestTransformBuilder<T> order(String column,
          {bool? ascending, bool? nullsFirst, String? referencedTable}) =>
      this;

  @override
  PostgrestTransformBuilder<T> range(int from, int to,
          {String? referencedTable}) =>
      this;
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    final builder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    builder.shouldThrow = shouldThrow;
    if (_response is Map) {
      builder.setResponse([_response as Map<String, dynamic>]);
    } else if (_response is List) {
      builder.setResponse(_response as List<Map<String, dynamic>>);
    }
    builder.setCount(_count);
    return builder;
  }

  void setCount(int count) {
    _count = count;
  }

  void setResponse(T response) {
    _response = response;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    final builder = MockPostgrestFilterBuilder<Map<String, dynamic>>();
    builder.shouldThrow = shouldThrow;
    if (_response is List && (_response as List).isNotEmpty) {
      builder.setResponse((_response as List).first as Map<String, dynamic>);
    } else {
      builder.setResponse({});
    }
    return builder;
  }

  @override
  PostgrestFilterBuilder<T> textSearch(String column, String query,
          {String? config, TextSearchType? type}) =>
      this;

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    if (shouldThrow) {
      return Future<R>.error(PostgrestException(message: 'Mock Error'))
          .then((_) => null as dynamic, onError: onError);
    }

    if (_isCountCalled) {
      return Future.value(
              PostgrestResponse<T>(data: _response as T, count: _count))
          .then(onValue as dynamic, onError: onError);
    }

    final T res = _response as T;
    return Future<T>.value(res).then<R>(onValue, onError: onError);
  }
}

class MockPostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final T? response;
  final bool shouldThrow;

  MockPostgrestTransformBuilder({this.response, this.shouldThrow = false});

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    if (shouldThrow) {
      return Future<R>.error(Exception('Mock Error'))
          .then((_) => null as dynamic, onError: onError);
    }
    return Future<T>.value(response as T).then<R>(onValue, onError: onError);
  }
}

class MockPrivacySettingsNotifier extends StateNotifier<PrivacySettings>
    implements PrivacySettingsNotifier {
  MockPrivacySettingsNotifier() : super(PrivacySettings());

  @override
  void setAllowFriendRequestsFromAnyone(bool value) {}
  @override
  void setAllowTagging(bool value) {}
  @override
  void setAutoBlurInBackground(bool value) {}
  @override
  void setAutoShieldChats(bool value) {}
  @override
  void setMaskEmail(bool value) {}
  @override
  void setMaskFullName(bool value) {}
  @override
  void setMeshOnlyMode(bool value) {}
  @override
  void setNotifyEnabled(bool value) {}
  @override
  void setPrivateProfile(bool value) {}
  @override
  void setRequireBiometric(bool value) {}
  @override
  void setSessionTimeout(Duration duration) {}
  @override
  void setShowLastSeen(bool value) {}
  @override
  void setShowOnlineStatus(bool value) {}
  @override
  void setTrustScoreNotifications(bool value) {}
}

class MockProfileController extends StateNotifier<AsyncValue<void>>
    implements ProfileController {
  MockProfileController() : super(const AsyncData(null));

  Stream<Profile?> get profileStream => const Stream.empty();

  @override
  Future<void> followUser(String targetId) async {}
  @override
  Future<void> simulateVerification() async {}
  @override
  Future<void> togglePrivacy(bool isPrivate) async {}
  @override
  Future<void> unfollowUser(String targetId) async {}
  @override
  Future<void> updateDefaultPersonalVisibility(bool allows) async {}
  @override
  Future<void> updateProfile({
    String? fullName,
    String? bio,
    String? website,
    String? username,
    List<String>? interests,
  }) async {}
}

class MockProfileRepository extends Fake implements ProfileRepository {
  Future<Profile?> Function(String userId)? getProfileStub;
  Future<bool> Function(String followerId, String followingId)? isFollowingStub;

  @override
  Future<Profile?> getProfile(String userId) =>
      getProfileStub?.call(userId) ?? Future.value(null);

  @override
  Future<bool> isFollowing(String followerId, String followingId) =>
      isFollowingStub?.call(followerId, followingId) ?? Future.value(false);

  @override
  Future<bool> isUsernameAvailable(String username) async => true;
}

class MockRateLimitService extends Fake
    implements verasso_rate_limit.RateLimitService {
  bool _isLimited = false;
  final List<Map<String, dynamic>> loggedAttempts = [];

  @override
  Future<bool> isLimited(
          String key, verasso_rate_limit.RateLimitType type) async =>
      _isLimited;

  @override
  Future<void> logAttempt({
    required String email,
    required String action,
    String? ip,
    required bool success,
  }) async {
    loggedAttempts.add({
      'email': email,
      'action': action,
      'ip': ip,
      'success': success,
    });
  }

  void setLimited(bool value) => _isLimited = value;
}

class MockRealtimeChannel extends Fake implements RealtimeChannel {
  @override
  RealtimeChannel onPostgresChanges(
          {required PostgresChangeEvent event,
          String? schema,
          String? table,
          PostgresChangeFilter? filter,
          required void Function(PostgresChangePayload payload) callback}) =>
      this;

  @override
  RealtimeChannel subscribe(
          [void Function(RealtimeSubscribeStatus status, Object? error)?
              callback,
          Duration? timeout]) =>
      this;

  @override
  Future<String> unsubscribe([Duration? timeout]) async => 'unsubscribed';
}

class MockSavedPostRepository extends Fake implements SavedPostRepository {
  Future<List<Post>> Function()? getSavedPostsStub;
  Future<bool> Function(String postId)? isSavedStub;
  Stream<List<Collection>> Function()? watchCollectionsStub;

  @override
  Future<List<Post>> getSavedPosts() =>
      getSavedPostsStub?.call() ?? Future.value([]);

  @override
  Future<bool> isSaved(String postId) =>
      isSavedStub?.call(postId) ?? Future.value(false);

  @override
  Stream<List<Collection>> watchCollections() =>
      watchCollectionsStub?.call() ?? Stream.value([]);
}

class MockSecureAuthService extends Fake implements SecureAuthService {
  Future<AuthResponse> Function({
    required String email,
    required String password,
  })? signInWithPasswordStub;

  Future<AuthResponse> Function({
    required String email,
    required String password,
    required String username,
    String? fullName,
    Map<String, dynamic>? metadata,
  })? signUpWithPasswordStub;

  Future<void> Function(String email)? resetPasswordForEmailStub;
  Future<void> Function(String newPassword)? setNewPasswordStub;
  Future<void> Function(String email)? signInWithOtpStub;

  Future<AuthResponse> Function({
    required String email,
    required String token,
    required OtpType type,
  })? verifyOTPStub;

  Future<void> Function()? signOutStub;

  @override
  Future<void> resetPasswordForEmail(String email) async {
    if (resetPasswordForEmailStub != null) {
      await resetPasswordForEmailStub!(email);
    }
  }

  @override
  Future<void> setNewPassword(String newPassword) async {
    if (setNewPasswordStub != null) {
      await setNewPasswordStub!(newPassword);
    }
  }

  @override
  Future<void> signInWithOtp(String email) async {
    if (signInWithOtpStub != null) {
      await signInWithOtpStub!(email);
    }
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (signInWithPasswordStub != null) {
      return signInWithPasswordStub!(email: email, password: password);
    }
    return AuthResponse(user: TestSupabaseUser());
  }

  @override
  Future<void> signOut() async {
    if (signOutStub != null) {
      await signOutStub!();
    }
  }

  @override
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    required String username,
    String? fullName,
    Map<String, dynamic>? metadata,
  }) async {
    if (signUpWithPasswordStub != null) {
      return signUpWithPasswordStub!(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
        metadata: metadata,
      );
    }
    return AuthResponse(user: TestSupabaseUser());
  }

  @override
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    if (verifyOTPStub != null) {
      return verifyOTPStub!(email: email, token: token, type: type);
    }
    return AuthResponse(user: TestSupabaseUser());
  }
}

class MockSessionTimeoutService extends Fake implements SessionTimeoutService {
  @override
  bool get isLocked => false;
  @override
  void resetTimer() {}
  @override
  void setOnTimeoutCallback(void Function() callback) {}
  @override
  void setOnWarningCallback(void Function() callback) {}
  @override
  void setTimeoutDuration(Duration duration) {}
  @override
  void start() {}
  @override
  void stop() {}
}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockStoryRepository extends Fake implements StoryRepository {
  Future<List<Story>> Function()? getActiveStoriesStub;

  @override
  Future<void> archiveExpiredStories() async {}

  @override
  Future<void> createStory({
    required String userId,
    File? file,
    String? content,
    String mediaType = 'image',
  }) async {}

  @override
  Future<void> deleteStory(String storyId) async {}

  @override
  Future<List<Story>> getActiveStories() =>
      getActiveStoriesStub?.call() ?? Future.value([]);

  @override
  Future<List<Story>> getStories() => getActiveStories();

  @override
  Future<List<Story>> getStoriesForUser(String userId) async => [];

  @override
  Future<List<Map<String, dynamic>>> getStoryReactions(String storyId) async =>
      [];

  @override
  Future<List<Map<String, dynamic>>> getStoryViews(String storyId) async => [];

  @override
  Future<void> markStoryAsViewed(String storyId, [String? viewerId]) async {}

  @override
  Future<void> reactToStory({
    required String storyId,
    String? userId,
    String? reaction,
    String? emoji,
  }) async {}

  @override
  Future<void> viewStory(String storyId, [String? viewerId]) async {}
}

class MockSupabaseClient extends Mock implements SupabaseClient {
  GoTrueClient _auth;

  final SupabaseStorageClient _storage = MockSupabaseStorageClient();

  final Map<String, SupabaseQueryBuilder> _overrides = {};
  final Map<String, dynamic> _rpcOverrides = {};
  final Map<String, bool> _rpcShouldThrow = {};
  SupabaseQueryBuilder Function(String table)? _fromStub;
  String? lastInsertTable;
  String? lastUpdateTable;
  String? lastDeleteTable;
  String? lastRpcName;

  final Map<String, Stream<List<Map<String, dynamic>>>> _streamOverrides = {};

  MockSupabaseClient({GoTrueClient? auth}) : _auth = auth ?? MockGoTrueClient();

  @override
  GoTrueClient get auth => _auth;

  set fromStub(SupabaseQueryBuilder Function(String table)? stub) {
    _fromStub = stub;
  }

  @override
  SupabaseStorageClient get storage => _storage;

  @override
  SupabaseQueryBuilder from(String table) {
    if (_overrides.containsKey(table)) return _overrides[table]!;
    if (_fromStub != null) return _fromStub!(table);
    return MockSupabaseQueryBuilder(table: table, client: this);
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(String fn,
      {dynamic get, Map<String, dynamic>? params}) {
    lastRpcName = fn;
    final builder = MockPostgrestFilterBuilder<T>();
    if (_rpcShouldThrow[fn] == true) {
      builder.shouldThrow = true;
    }
    if (_rpcOverrides.containsKey(fn)) {
      builder.setResponse(_rpcOverrides[fn] as T);
    }
    return builder;
  }

  void setAuth(GoTrueClient authClient) {
    _auth = authClient;
  }

  void setQueryBuilder(String table, SupabaseQueryBuilder builder) {
    if (builder is MockSupabaseQueryBuilder) {
      builder.table = table;
      builder.client = this;
    }
    _overrides[table] = builder;
  }

  void setRpcResponse(String fn, dynamic response, {bool shouldThrow = false}) {
    _rpcOverrides[fn] = response;
    if (shouldThrow) _rpcShouldThrow[fn] = true;
  }

  void setRpcResult(String fn, dynamic result, {bool shouldThrow = false}) {
    _rpcOverrides[fn] = result;
    if (shouldThrow) _rpcShouldThrow[fn] = true;
  }

  void setStorageBucket(String bucket, MockSupabaseStorageBucket bucketMock) {
    (_storage as MockSupabaseStorageClient).setBucket(bucket, bucketMock);
  }

  void setStreamResponse(
      String table, Stream<List<Map<String, dynamic>>> stream) {
    _streamOverrides[table] = stream;
  }
}

class MockSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  String? table;
  MockSupabaseClient? client;
  final List<Map<String, dynamic>> _selectResponse;
  final Map<String, PostgrestFilterBuilder> _stubs;

  final bool shouldThrow;

  final int countResponse;

  MockSupabaseQueryBuilder({
    this.table,
    this.client,
    dynamic selectResponse,
    Map<String, PostgrestFilterBuilder>? stubs,
    this.shouldThrow = false,
    this.countResponse = 0,
  })  : _selectResponse = (selectResponse is Map)
            ? [Map<String, dynamic>.from(selectResponse)]
            : (selectResponse as List?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ??
                [],
        _stubs = stubs ?? {};

  @override
  PostgrestFilterBuilder delete({bool returning = true, bool count = false}) {
    if (client != null && table != null) client!.lastDeleteTable = table;
    if (_stubs.containsKey('delete')) return _stubs['delete']!;
    final builder = MockPostgrestFilterBuilder();
    builder.shouldThrow = shouldThrow;
    builder.setResponse(_selectResponse);
    return builder;
  }

  @override
  PostgrestFilterBuilder insert(Object values,
      {Object? count, String? defaultTo, bool defaultToNull = false}) {
    if (client != null && table != null) client!.lastInsertTable = table;
    if (_stubs.containsKey('insert')) return _stubs['insert']!;
    final builder = MockPostgrestFilterBuilder();
    builder.shouldThrow = shouldThrow;
    builder.setResponse(_selectResponse);
    return builder;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    if (_stubs.containsKey('select')) {
      return _stubs['select']!
          as PostgrestFilterBuilder<List<Map<String, dynamic>>>;
    }
    final builder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
    builder.shouldThrow = shouldThrow;
    builder.setResponse(_selectResponse);
    builder.setCount(countResponse);
    return builder;
  }

  void setResponse(dynamic response) {
    // Basic mock implementation
  }

  void setSelectResponse(dynamic response) {
    // Adapter for selectResponse
  }

  @override
  SupabaseStreamFilterBuilder stream({required List<String> primaryKey}) {
    if (client != null && client!._streamOverrides.containsKey(table)) {
      return MockSupabaseStreamFilterBuilder(
          streamOverride: client!._streamOverrides[table]);
    }
    return MockSupabaseStreamFilterBuilder(
        streamOverride: Stream.value(_selectResponse));
  }

  @override
  PostgrestFilterBuilder update(Map values) {
    if (client != null && table != null) client!.lastUpdateTable = table;
    if (_stubs.containsKey('update')) return _stubs['update']!;
    final builder = MockPostgrestFilterBuilder();
    builder.shouldThrow = shouldThrow;
    builder.setResponse(_selectResponse);
    return builder;
  }

  @override
  PostgrestFilterBuilder upsert(Object values,
      {String? onConflict,
      bool ignoreDuplicates = false,
      Object? count,
      String? defaultTo,
      bool defaultToNull = false}) {
    if (client != null && table != null) {
      client!.lastInsertTable = table;
      client!.lastUpdateTable = table;
    }
    if (_stubs.containsKey('upsert')) return _stubs['upsert']!;
    final builder = MockPostgrestFilterBuilder();
    builder.shouldThrow = shouldThrow;
    builder.setResponse(_selectResponse);
    return builder;
  }
}

class MockSupabaseStorageBucket extends Fake implements StorageFileApi {
  @override
  String getPublicUrl(String path, {TransformOptions? transform}) =>
      'https://fake-storage.com/$path';

  @override
  Future<String> upload(
    String path,
    File file, {
    FileOptions? fileOptions,
    int? retryAttempts,
    StorageRetryController? retryController,
  }) async =>
      'https://fake-storage.com/$path';
}

class MockSupabaseStorageClient extends Fake implements SupabaseStorageClient {
  final Map<String, MockSupabaseStorageBucket> _buckets = {};

  @override
  StorageFileApi from(String id) => _buckets[id] ?? MockSupabaseStorageBucket();

  void setBucket(String bucket, MockSupabaseStorageBucket bucketMock) {
    _buckets[bucket] = bucketMock;
  }
}

class MockSupabaseStreamBuilder extends Fake implements SupabaseStreamBuilder {
  final Stream<List<Map<String, dynamic>>>? _streamOverride;
  MockSupabaseStreamBuilder(
      {Stream<List<Map<String, dynamic>>>? streamOverride})
      : _streamOverride = streamOverride;

  @override
  Stream<S> asyncMap<S>(
          FutureOr<S> Function(List<Map<String, dynamic>> event) convert) =>
      (_streamOverride ?? Stream.value(<Map<String, dynamic>>[]))
          .asyncMap(convert);

  @override
  StreamSubscription<List<Map<String, dynamic>>> listen(
          void Function(List<Map<String, dynamic>> event)? onData,
          {Function? onError,
          void Function()? onDone,
          bool? cancelOnError}) =>
      (_streamOverride ?? Stream.value(<Map<String, dynamic>>[])).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  Stream<S> map<S>(S Function(List<Map<String, dynamic>> event) convert) {
    final stream = _streamOverride ?? Stream.value(<Map<String, dynamic>>[]);
    return stream.map((event) => convert(event));
  }
}

class MockSupabaseStreamFilterBuilder extends Fake
    implements SupabaseStreamFilterBuilder {
  final Stream<List<Map<String, dynamic>>>? _streamOverride;
  MockSupabaseStreamFilterBuilder(
      {Stream<List<Map<String, dynamic>>>? streamOverride})
      : _streamOverride = streamOverride;

  @override
  Stream<S> asyncMap<S>(
          FutureOr<S> Function(List<Map<String, dynamic>> event) convert) =>
      (_streamOverride ?? Stream.value(<Map<String, dynamic>>[]))
          .asyncMap(convert);
  @override
  SupabaseStreamBuilder eq(String column, Object value) =>
      MockSupabaseStreamBuilder(streamOverride: _streamOverride);
  @override
  SupabaseStreamBuilder limit(int count) =>
      MockSupabaseStreamBuilder(streamOverride: _streamOverride);

  @override
  StreamSubscription<List<Map<String, dynamic>>> listen(
          void Function(List<Map<String, dynamic>> event)? onData,
          {Function? onError,
          void Function()? onDone,
          bool? cancelOnError}) =>
      (_streamOverride ?? Stream.value(<Map<String, dynamic>>[])).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  SupabaseStreamBuilder order(String column, {bool ascending = true}) =>
      MockSupabaseStreamBuilder(streamOverride: _streamOverride);
}

class MockTalentProfileRepository extends Fake
    implements TalentProfileRepository {
  Future<List<TalentProfile>> Function(String)? searchMentorsStub;

  @override
  Future<List<TalentProfile>> searchMentors(String query) async {
    return [];
  }
}

class MockTalentRepository extends Fake implements TalentRepository {
  Future<List<TalentPost>> Function({int limit, int offset})? getTalentsStub;

  @override
  Future<List<TalentPost>> getTalents({int limit = 20, int offset = 0}) async {
    return getTalentsStub?.call(limit: limit, offset: offset) ??
        Future.value([]);
  }
}

class MockThemeController extends StateNotifier<AppThemeState>
    implements ThemeController {
  MockThemeController([AppThemeState? initialState])
      : super(initialState ??
            AppThemeState(
              mode: ThemeMode.dark,
              primaryColor: const Color(0xFF9D50BB),
              accentColor: const Color(0xFFE91E63),
              isPowerSaveMode: true, // Disable animations for tests
            ));

  @override
  bool get hasListeners => false;
  @override
  Future<void> setAccentColor(Color color) async {}
  @override
  Future<void> setLocale(Locale locale) async {}
  @override
  Future<void> setPrimaryColor(Color color) async {}
  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
  @override
  Future<void> setThemeStyle(ThemeStyle style) async {}

  @override
  Future<void> togglePowerSaveMode(bool active) async {}
}

class MockTokenStorageService extends Fake implements TokenStorageService {
  @override
  Future<void> clearTokens() async {}

  @override
  Future<String?> getRefreshToken() async => 'fake-token';

  @override
  Future<bool> isSessionValid() async => true;

  @override
  Future<AuthResponse?> refreshSession(SupabaseClient client) async => null;

  @override
  Future<void> saveRefreshToken(String token) async {}

  @override
  Future<void> saveSessionExpiry(DateTime expiry) async {}

  @override
  Future<void> saveUserEmail(String email) async {}

  @override
  Future<void> saveUserId(String userId) async {}
}

class MockTransactionService extends Fake implements TransactionService {
  Future<bool> Function(String userId, String courseId, double price)?
      processCoursePurchaseStub;

  @override
  Future<bool> processCoursePurchase(
      String userId, String courseId, double price) async {
    return processCoursePurchaseStub?.call(userId, courseId, price) ??
        Future.value(true);
  }
}

class TestSupabaseUser extends Fake implements User {
  @override
  final String id;
  @override
  final String? email;
  @override
  final Map<String, dynamic> userMetadata;
  @override
  final String? emailConfirmedAt;
  @override
  final List<Factor> factors;

  TestSupabaseUser({
    this.id = 'test-user-id',
    this.email,
    this.userMetadata = const {},
    this.emailConfirmedAt,
    this.factors = const [],
  });
}
