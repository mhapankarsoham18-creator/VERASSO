import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';
import 'package:verasso/features/auth/domain/mfa_models.dart';

void main() {
  late MockAuthService authService;

  setUp(() {
    authService = MockAuthService();
  });

  tearDown(() {
    authService.dispose();
  });

  group('AuthService — Sign In', () {
    test('signInWithEmail returns user and session', () async {
      final result = await authService.signInWithEmail(
        email: 'test@verasso.app',
        password: 'Pass123!',
      );

      expect(result.user, isNotNull);
      expect(result.user!.email, 'test@verasso.app');
      expect(result.session, isNotNull);
      expect(result.session!.accessToken, 'mock-token');
      expect(authService.currentUser, isNotNull);
    });

    test('signInWithEmail throws on failure', () async {
      authService.shouldThrow = true;

      expect(
        () => authService.signInWithEmail(
          email: 'test@verasso.app',
          password: 'wrong',
        ),
        throwsException,
      );
    });

    test('authStateChanges emits user on login', () async {
      expectLater(
        authService.authStateChanges,
        emits(isA<DomainAuthUser>()),
      );

      await authService.signInWithEmail(
        email: 'test@verasso.app',
        password: 'Pass123!',
      );
    });
  });

  group('AuthService — Sign Up', () {
    test('signUpWithEmail creates user with metadata', () async {
      final result = await authService.signUpWithEmail(
        email: 'new@verasso.app',
        password: 'NewPass123!',
        username: 'newuser',
        data: {'display_name': 'New User'},
      );

      expect(result.user, isNotNull);
      expect(result.user!.id, 'new-user-1');
      expect(result.user!.email, 'new@verasso.app');
      expect(result.user!.userMetadata['display_name'], 'New User');
    });

    test('signUpWithEmail throws on failure', () async {
      authService.shouldThrow = true;

      expect(
        () => authService.signUpWithEmail(
          email: 'test@verasso.app',
          password: 'Pass123!',
        ),
        throwsException,
      );
    });
  });

  group('AuthService — Sign Out', () {
    test('signOut clears current user', () async {
      await authService.signInWithEmail(
        email: 'test@verasso.app',
        password: 'Pass123!',
      );
      expect(authService.currentUser, isNotNull);

      await authService.signOut();
      expect(authService.currentUser, isNull);
    });

    test('authStateChanges emits null on signout', () async {
      await authService.signInWithEmail(
        email: 'test@verasso.app',
        password: 'Pass123!',
      );

      expectLater(
        authService.authStateChanges,
        emits(isNull),
      );

      await authService.signOut();
      expect(authService.currentUser, isNull);
    });

    test('deleteAccount clears current user', () async {
      await authService.signInWithEmail(
        email: 'test@verasso.app',
        password: 'Pass123!',
      );
      expect(authService.currentUser, isNotNull);

      await authService.deleteAccount();
      expect(authService.currentUser, isNull);
    });
  });

  group('AuthService — Password Reset', () {
    test('resetPasswordForEmail completes normally', () async {
      await expectLater(
        authService.resetPasswordForEmail(email: 'test@verasso.app'),
        completes,
      );
    });

    test('resetPasswordForEmail throws on failure', () async {
      authService.shouldThrow = true;
      expect(
        () => authService.resetPasswordForEmail(email: 'test@verasso.app'),
        throwsException,
      );
    });
  });

  group('AuthService — MFA', () {
    test('enrollMFA returns enrollment with id and type', () async {
      final enrollment = await authService.enrollMFA();
      expect(enrollment, isNotNull);
      expect(enrollment!.id, 'test-factor-id');
      expect(enrollment.type, 'totp');
    });

    test('challengeMFA returns challenge with id', () async {
      final challenge = await authService.challengeMFA(factorId: 'factor-1');
      expect(challenge.id, 'test-challenge-id');
    });

    test('listFactors returns empty list', () async {
      final factors = await authService.listFactors();
      expect(factors, isEmpty);
    });

    test('verifyMFA returns session', () async {
      authService.setMockUser(
        DomainAuthUser(id: 'user-1', email: 'test@verasso.app'),
      );

      final result = await authService.verifyMFA(
        factorId: 'factor-1',
        challengeId: 'challenge-1',
        code: '123456',
      );

      expect(result, isNotNull);
      expect(result!.session!.accessToken, 'mfa-token');
    });

    test('unenrollMFA completes without error', () async {
      await expectLater(
        authService.unenrollMFA(factorId: 'factor-1'),
        completes,
      );
    });
  });

  group('DomainAuthUser', () {
    test('creates user with all fields', () {
      final user = DomainAuthUser(
        id: 'user-1',
        email: 'test@verasso.app',
        userMetadata: {'name': 'Test'},
        emailConfirmedAt: '2026-01-01T00:00:00Z',
        factors: [
          DomainAuthFactor(id: 'f1', status: 'verified', type: 'totp'),
        ],
      );

      expect(user.id, 'user-1');
      expect(user.email, 'test@verasso.app');
      expect(user.factors.length, 1);
      expect(user.emailConfirmedAt, isNotNull);
    });

    test('creates user with defaults', () {
      final user = DomainAuthUser(id: 'user-1');
      expect(user.email, isNull);
      expect(user.userMetadata, isEmpty);
      expect(user.factors, isEmpty);
    });
  });

  group('AuthResult', () {
    test('creates empty result', () {
      final result = AuthResult();
      expect(result.user, isNull);
      expect(result.session, isNull);
    });

    test('creates result with user and session', () {
      final user = DomainAuthUser(id: 'u1');
      final session = DomainAuthSession(accessToken: 'tok');
      final result = AuthResult(user: user, session: session);
      expect(result.user!.id, 'u1');
      expect(result.session!.accessToken, 'tok');
    });
  });
}

/// A mock AuthService implementation for unit testing.
class MockAuthService extends AuthService {
  DomainAuthUser? _mockUser;
  bool shouldThrow = false;
  final _authStreamController = StreamController<DomainAuthUser?>.broadcast();

  @override
  Stream<DomainAuthUser?> get authStateChanges => _authStreamController.stream;

  @override
  DomainAuthUser? get currentUser => _mockUser;

  @override
  Future<void> challengeAndVerify({
    required String factorId,
    required String code,
  }) async {
    if (shouldThrow) throw Exception('MFA challenge failed');
  }

  @override
  Future<MfaChallenge> challengeMFA({required String factorId}) async {
    if (shouldThrow) throw Exception('MFA challenge failed');
    return MfaChallenge(id: 'test-challenge-id');
  }

  @override
  Future<void> deleteAccount() async {
    if (shouldThrow) throw Exception('Delete account failed');
    _mockUser = null;
    _authStreamController.add(null);
  }

  void dispose() {
    _authStreamController.close();
  }

  @override
  Future<MfaEnrollment?> enrollMFA() async {
    if (shouldThrow) throw Exception('MFA enroll failed');
    return MfaEnrollment(id: 'test-factor-id', type: 'totp');
  }

  @override
  Future<List<dynamic>> listFactors() async {
    if (shouldThrow) throw Exception('List factors failed');
    return [];
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    if (shouldThrow) throw Exception('Reset failed');
  }

  void setMockUser(DomainAuthUser? user) {
    _mockUser = user;
    _authStreamController.add(user);
  }

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (shouldThrow) throw Exception('Login failed');
    final user = DomainAuthUser(id: 'user-1', email: email);
    _mockUser = user;
    _authStreamController.add(user);
    return AuthResult(
      user: user,
      session: DomainAuthSession(accessToken: 'mock-token', user: user),
    );
  }

  @override
  Future<void> signInWithOtp({required String email}) async {
    if (shouldThrow) throw Exception('OTP failed');
  }

  @override
  Future<void> signOut() async {
    if (shouldThrow) throw Exception('Signout failed');
    _mockUser = null;
    _authStreamController.add(null);
  }

  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    Map<String, dynamic>? data,
  }) async {
    if (shouldThrow) throw Exception('Signup failed');
    final user = DomainAuthUser(
      id: 'new-user-1',
      email: email,
      userMetadata: data ?? {},
    );
    _mockUser = user;
    return AuthResult(
      user: user,
      session: DomainAuthSession(accessToken: 'new-mock-token', user: user),
    );
  }

  @override
  Future<void> unenrollMFA({required String factorId}) async {
    if (shouldThrow) throw Exception('Unenroll failed');
  }

  @override
  Future<void> updateUserPassword({required String password}) async {
    if (shouldThrow) throw Exception('Password update failed');
  }

  @override
  Future<AuthResult?> verifyMFA({
    required String factorId,
    required String challengeId,
    required String code,
  }) async {
    if (shouldThrow) throw Exception('Verify MFA failed');
    return AuthResult(
      user: _mockUser,
      session: DomainAuthSession(accessToken: 'mfa-token'),
    );
  }

  @override
  Future<AuthResult?> verifyOtp({
    required String token,
    required dynamic type,
    String? email,
  }) async {
    if (shouldThrow) throw Exception('Verify OTP failed');
    return AuthResult(
      user: _mockUser,
      session: DomainAuthSession(accessToken: 'otp-token'),
    );
  }
}
