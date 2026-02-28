import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';

import '../../mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AuthRepository - Authentication Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockSecureAuthService mockSecureAuth;
    late MockAuditLogService mockAuditLog;
    late MockRateLimitService mockRateLimitService;
    late MockTokenStorageService mockTokenStorage;
    late AuthRepository authRepository;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockSecureAuth = MockSecureAuthService();
      mockAuditLog = MockAuditLogService();
      mockRateLimitService = MockRateLimitService();
      mockTokenStorage = MockTokenStorageService();

      authRepository = AuthRepository(
        client: mockSupabaseClient,
        secureAuth: mockSecureAuth,
        auditLog: mockAuditLog,
        rateLimitService: mockRateLimitService,
        tokenStorage: mockTokenStorage,
      );
    });

    // ============================================================
    // SIGN UP TESTS
    // ============================================================

    group('Sign Up Flow', () {
      test('signUpWithEmail should succeed with valid credentials', () async {
        const email = 'test@example.com';
        const password = 'SecurePassword123!';
        const username = 'testuser';

        final mockUser = User(
          id: 'user123',
          aud: 'authenticated',
          role: 'authenticated',
          email: email,
          emailConfirmedAt: DateTime.now().toIso8601String(),
          phone: '',
          confirmationSentAt: DateTime.now().toIso8601String(),
          recoverySentAt: null,
          lastSignInAt: DateTime.now().toIso8601String(),
          appMetadata: {},
          userMetadata: {'username': username},
          identities: [],
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          isAnonymous: false,
        );

        final mockSession = Session(
          accessToken: 'access_token_123',
          tokenType: 'bearer',
          expiresIn: 3600,
          refreshToken: 'refresh_token_123',
          user: mockUser,
        );

        final mockAuthResponse = AuthResponse(
          user: mockUser,
          session: mockSession,
        );

        mockSecureAuth.signUpWithPasswordStub = ({
          required email,
          required password,
          required username,
          fullName,
          metadata,
        }) async =>
            mockAuthResponse;

        mockAuditLog.logEventStub = ({
          required type,
          required action,
          required severity,
          metadata,
        }) async {};

        final result = await authRepository.signUpWithEmail(
          email: email,
          password: password,
          username: username,
        );

        expect(result.user?.id, equals('user123'));
        expect(result.session?.accessToken, equals('access_token_123'));
        expect(result.user?.email, equals(email));
      });

      test('signUpWithEmail should fail with invalid email', () async {
        const email = 'invalid-email';
        const password = 'SecurePassword123!';
        const username = 'testuser';

        mockSecureAuth.signUpWithPasswordStub = ({
          required email,
          required password,
          required username,
          fullName,
          metadata,
        }) async {
          throw const AuthException('Invalid email format');
        };

        mockAuditLog.logEventStub = ({
          required type,
          required action,
          required severity,
          metadata,
        }) async {};

        expect(
          () => authRepository.signUpWithEmail(
            email: email,
            password: password,
            username: username,
          ),
          throwsA(isA<AppAuthException>()),
        );
      });

      test('signUpWithEmail should fail with weak password', () async {
        const email = 'test@example.com';
        const password = '123'; // Too weak
        const username = 'testuser';

        mockSecureAuth.signUpWithPasswordStub = ({
          required email,
          required password,
          required username,
          fullName,
          metadata,
        }) async {
          throw const AuthException(
              'Password does not meet strength requirements');
        };

        mockAuditLog.logEventStub = ({
          required type,
          required action,
          required severity,
          metadata,
        }) async {};

        expect(
          () => authRepository.signUpWithEmail(
            email: email,
            password: password,
            username: username,
          ),
          throwsA(isA<AppAuthException>()),
        );
      });

      test('signUpWithEmail should handle duplicate email', () async {
        const email = 'existing@example.com';
        const password = 'SecurePassword123!';
        const username = 'newuser';

        mockSecureAuth.signUpWithPasswordStub = ({
          required email,
          required password,
          required username,
          fullName,
          metadata,
        }) async {
          throw const AuthException('User already exists');
        };

        mockAuditLog.logEventStub = ({
          required type,
          required action,
          required severity,
          metadata,
        }) async {};

        expect(
          () => authRepository.signUpWithEmail(
            email: email,
            password: password,
            username: username,
          ),
          throwsA(isA<AppAuthException>()),
        );
      });
    });

    // ============================================================
    // SIGN IN TESTS
    // ============================================================

    group('Sign In Flow', () {
      test('signInWithEmail should succeed with valid credentials', () async {
        const email = 'test@example.com';
        const password = 'SecurePassword123!';

        final mockUser = User(
          id: 'user123',
          aud: 'authenticated',
          role: 'authenticated',
          email: email,
          emailConfirmedAt: DateTime.now().toIso8601String(),
          phone: '',
          confirmationSentAt: DateTime.now().toIso8601String(),
          recoverySentAt: null,
          lastSignInAt: DateTime.now().toIso8601String(),
          appMetadata: {},
          userMetadata: {'username': 'testuser'},
          identities: [],
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          isAnonymous: false,
        );

        final mockSession = Session(
          accessToken: 'access_token_456',
          tokenType: 'bearer',
          expiresIn: 3600,
          refreshToken: 'refresh_token_456',
          user: mockUser,
        );

        final mockAuthResponse = AuthResponse(
          user: mockUser,
          session: mockSession,
        );

        mockSecureAuth.signInWithPasswordStub = ({
          required email,
          required password,
        }) async =>
            mockAuthResponse;

        mockAuditLog.logEventStub = ({
          required type,
          required action,
          required severity,
          metadata,
        }) async {};

        final result = await authRepository.signInWithEmail(
          email: email,
          password: password,
        );

        expect(result.user?.id, equals('user123'));
        expect(result.session?.accessToken, equals('access_token_456'));
      });

      test('signInWithEmail should fail with incorrect password', () async {
        const email = 'test@example.com';
        const wrongPassword = 'WrongPassword123!';

        mockSecureAuth.signInWithPasswordStub = ({
          required email,
          required password,
        }) async {
          throw const AuthException('Invalid credentials');
        };

        mockAuditLog.logEventStub = ({
          required type,
          required action,
          required severity,
          metadata,
        }) async {};

        expect(
          () => authRepository.signInWithEmail(
            email: email,
            password: wrongPassword,
          ),
          throwsA(isA<AppAuthException>()),
        );
      });

      test('signInWithEmail should fail with non-existent email', () async {
        const email = 'nonexistent@example.com';
        const password = 'SomePassword123!';

        mockSecureAuth.signInWithPasswordStub = ({
          required email,
          required password,
        }) async {
          throw const AuthException('User not found');
        };

        mockAuditLog.logEventStub = ({
          required type,
          required action,
          required severity,
          metadata,
        }) async {};

        expect(
          () => authRepository.signInWithEmail(
            email: email,
            password: password,
          ),
          throwsA(isA<AppAuthException>()),
        );
      });

      test('signInWithEmail should handle rate limiting', () async {
        const email = 'test@example.com';
        const password = 'WrongPassword';

        mockSecureAuth.signInWithPasswordStub = ({
          required email,
          required password,
        }) async {
          throw const AuthException(
              'Too many login attempts. Please try again later.');
        };

        mockAuditLog.logEventStub = ({
          required type,
          required action,
          required severity,
          metadata,
        }) async {};

        expect(
          () => authRepository.signInWithEmail(
            email: email,
            password: password,
          ),
          throwsA(isA<AppAuthException>()),
        );
      });
    });

    // ============================================================
    // PASSWORD RESET TESTS
    // ============================================================

    group('Password Reset Flow', () {
      test('resetPasswordForEmail should send reset email', () async {
        const email = 'test@example.com';

        mockSecureAuth.resetPasswordForEmailStub = (email) async {};

        await authRepository.resetPasswordForEmail(email: email);
      });

      test('resetPasswordForEmail should fail with non-existent email',
          () async {
        const email = 'nonexistent@example.com';

        mockSecureAuth.resetPasswordForEmailStub = (email) async {
          throw const AuthException('User not found');
        };

        expect(
          () => authRepository.resetPasswordForEmail(email: email),
          throwsA(isA<Exception>()),
        );
      });

      test('updateUserPassword should change password', () async {
        const newPassword = 'NewSecurePassword456!';

        mockSecureAuth.setNewPasswordStub = (password) async {};

        await authRepository.updateUserPassword(password: newPassword);
      });

      test('updateUserPassword should fail with weak password', () async {
        const weakPassword = '123';

        mockSecureAuth.setNewPasswordStub = (password) async {
          throw const AuthException(
              'Password does not meet strength requirements');
        };

        expect(
          () => authRepository.updateUserPassword(password: weakPassword),
          throwsA(isA<Exception>()),
        );
      });
    });

    // ============================================================
    // OTP (One-Time Password) TESTS
    // ============================================================

    group('OTP Flow', () {
      test('signInWithOtp should send OTP to email', () async {
        const email = 'test@example.com';

        mockSecureAuth.signInWithOtpStub = (email) async {};

        await authRepository.signInWithOtp(email: email);
      });

      test('verifyOtp should succeed with valid token', () async {
        const email = 'test@example.com';
        const token = '123456';

        final mockUser = User(
          id: 'user123',
          aud: 'authenticated',
          role: 'authenticated',
          email: email,
          emailConfirmedAt: DateTime.now().toIso8601String(),
          phone: '',
          confirmationSentAt: DateTime.now().toIso8601String(),
          recoverySentAt: null,
          lastSignInAt: DateTime.now().toIso8601String(),
          appMetadata: {},
          userMetadata: {},
          identities: [],
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          isAnonymous: false,
        );

        final mockSession = Session(
          accessToken: 'access_token_otp',
          tokenType: 'bearer',
          expiresIn: 3600,
          refreshToken: 'refresh_token_otp',
          user: mockUser,
        );

        final mockAuthResponse = AuthResponse(
          user: mockUser,
          session: mockSession,
        );

        mockSecureAuth.verifyOTPStub = ({
          required email,
          required token,
          required type,
        }) async =>
            mockAuthResponse;

        final result = await authRepository.verifyOtp(
          token: token,
          type: OtpType.magiclink,
          email: email,
        );

        expect(result?.user?.id, equals('user123'));
        expect(result?.session?.accessToken, equals('access_token_otp'));
      });

      test('verifyOtp should fail with invalid token', () async {
        const email = 'test@example.com';
        const invalidToken = '000000';

        mockSecureAuth.verifyOTPStub = ({
          required email,
          required token,
          required type,
        }) async {
          throw const AuthException('Invalid or expired OTP');
        };

        try {
          await authRepository.verifyOtp(
            token: invalidToken,
            type: OtpType.email,
            email: email,
          );
          fail('Should have thrown AppAuthException');
        } catch (e) {
          expect(e, isA<AppAuthException>());
        }
      });

      test('verifyOtp should fail with expired token', () async {
        const email = 'test@example.com';
        const expiredToken = '654321';

        mockSecureAuth.verifyOTPStub = ({
          required email,
          required token,
          required type,
        }) async {
          throw const AuthException('OTP has expired');
        };

        try {
          await authRepository.verifyOtp(
            token: expiredToken,
            type: OtpType.email,
            email: email,
          );
          fail('Should have thrown AppAuthException');
        } catch (e) {
          expect(e, isA<AppAuthException>());
        }
      });
    });

    // ============================================================
    // EDGE CASES & ERROR HANDLING
    // ============================================================

    group('Edge Cases & Error Handling', () {
      test('should handle network errors gracefully', () async {
        const email = 'test@example.com';
        const password = 'SecurePassword123!';

        mockSecureAuth.signInWithPasswordStub = ({
          required email,
          required password,
        }) async {
          throw const AuthException('Network error: Unable to reach server');
        };

        mockAuditLog.logEventStub = ({
          required type,
          required action,
          required severity,
          metadata,
        }) async {};

        expect(
          () => authRepository.signInWithEmail(
            email: email,
            password: password,
          ),
          throwsA(isA<AppAuthException>()),
        );
      });

      test('should handle empty email gracefully', () async {
        const email = '';
        const password = 'SecurePassword123!';
        const username = 'testuser';

        mockSecureAuth.signUpWithPasswordStub = ({
          required email,
          required password,
          required username,
          fullName,
          metadata,
        }) async {
          throw const AuthException('Email is required');
        };

        expect(
          () => authRepository.signUpWithEmail(
            email: email,
            password: password,
            username: username,
          ),
          throwsA(isA<AppAuthException>()),
        );
      });

      test('should handle server errors (5xx) gracefully', () async {
        const email = 'test@example.com';
        const password = 'SecurePassword123!';

        mockSecureAuth.signInWithPasswordStub = ({
          required email,
          required password,
        }) async {
          throw const AuthException('Server error: 500 Internal Server Error');
        };

        mockAuditLog.logEventStub = ({
          required type,
          required action,
          required severity,
          metadata,
        }) async {};

        expect(
          () => authRepository.signInWithEmail(
            email: email,
            password: password,
          ),
          throwsA(isA<AppAuthException>()),
        );
      });
    });
  });
}

// Helper function to create test Session object
Session createMockSession({
  required User user,
  String accessToken = 'access_token_test',
  String refreshToken = 'refresh_token_test',
}) {
  return Session(
    accessToken: accessToken,
    tokenType: 'bearer',
    expiresIn: 3600,
    refreshToken: refreshToken,
    user: user,
  );
}

// Helper function to create test User object
User createMockUser(
    {String id = 'user123', String email = 'test@example.com'}) {
  return User(
    id: id,
    aud: 'authenticated',
    role: 'authenticated',
    email: email,
    emailConfirmedAt: DateTime.now().toIso8601String(),
    phone: '',
    confirmationSentAt: DateTime.now().toIso8601String(),
    recoverySentAt: null,
    lastSignInAt: DateTime.now().toIso8601String(),
    appMetadata: {},
    userMetadata: {},
    identities: [],
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
    isAnonymous: false,
  );
}

// Local mocks removed in favor of central mocks.dart
