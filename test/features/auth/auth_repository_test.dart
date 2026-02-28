import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';

import '../../mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockGoTrueMFAApi mockMfa;
  late MockSecureAuthService mockSecureAuth;
  late MockAuditLogService mockAuditLog;
  late MockRateLimitService mockRateLimit;
  late MockTokenStorageService mockTokenStorage;
  late AuthRepository repository;

  setUp(() {
    mockMfa = MockGoTrueMFAApi();
    mockAuth = MockGoTrueClient(mfa: mockMfa);
    mockSupabase = MockSupabaseClient(auth: mockAuth);
    mockSecureAuth = MockSecureAuthService();
    mockAuditLog = MockAuditLogService();
    mockRateLimit = MockRateLimitService();
    mockTokenStorage = MockTokenStorageService();

    repository = AuthRepository(
      client: mockSupabase,
      secureAuth: mockSecureAuth,
      auditLog: mockAuditLog,
      rateLimitService: mockRateLimit,
      tokenStorage: mockTokenStorage,
    );

    // Mock url_launcher channel to prevent MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'launch') {
          return true;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      null,
    );
  });

  group('AuthRepository - SignUp', () {
    const email = 'test@verasso.com';
    const password = 'Password123!';
    const username = 'testuser';

    test('signUpWithEmail throws for weak password', () async {
      expect(
        () => repository.signUpWithEmail(email: email, password: '123'),
        throwsA(isA<AppAuthException>()),
      );
    });

    test('signUpWithEmail succeeds with strong password', () async {
      final mockUser = TestSupabaseUser();

      // Fake implementation returns AuthResponse(user: MockUser())

      final result = await repository.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );

      expect(result.user?.id, mockUser.id);
    });
  });

  group('AuthRepository - SignIn', () {
    test('signInWithOAuth initiates flow', () async {
      // Fake implementation returns true
      await repository.signInWithOAuth(OAuthProvider.google);
      // No failure implies success since method is void/Future<void> wrapping bool check
    });
  });

  group('AuthRepository - MFA', () {
    const code = '123456';

    test('enrollMFA initiates enrollment', () async {
      final mockUser = TestSupabaseUser(id: 'test-user');
      mockAuth.setCurrentUser(mockUser);

      final result = await repository.enrollMFA();
      expect(result?.id, 'fake-factor-id'); // ID from FakeAuthMFAEnrollResponse
    });

    test('challengeAndVerify flow', () async {
      final factorId2 = 'fake-factor-id'; // Using default ID from Fake

      // Fake implementations used automatically
      await repository.challengeAndVerify(factorId: factorId2, code: code);

      // Implicitly verified if no exception thrown
    });

    test('unenrollMFA calls supabase unenroll', () async {
      const factorId = 'test-factor-id';
      await repository.unenrollMFA(factorId: factorId);
      // Success if no exception
    });
  });

  group('AuthRepository - OTP', () {
    const email = 'test@verasso.com';
    const token = '123456';

    test('signInWithOtp calls secureAuth', () async {
      bool called = false;
      mockSecureAuth.signInWithOtpStub = (e) async {
        if (e == email) called = true;
      };

      await repository.signInWithOtp(email: email);
      expect(called, isTrue);
    });

    test('verifyOtp returns AuthResult for email', () async {
      final result = await repository.verifyOtp(
        email: email,
        token: token,
        type: OtpType.email,
      );

      expect(result?.user, isNotNull);
      expect(result?.user?.email, email);
    });

    test('verifyOtp returns AuthResult for phone', () async {
      const phone = '+1234567890';
      final result = await repository.verifyOtp(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );

      expect(result?.user, isNotNull);
    });

    test('signInWithPhone calls supabase signInWithOtp', () async {
      const phone = '+1234567890';
      await repository.signInWithPhone(phone: phone);
    });
  });

  group('AuthRepository - MFA Expanded', () {
    test('verifyMFA returns AuthResult', () async {
      mockAuth.setCurrentUser(TestSupabaseUser(id: 'test-user-id'));
      final result = await repository.verifyMFA(
        factorId: 'factor-id',
        challengeId: 'challenge-id',
        code: '123456',
      );

      expect(result?.user, isNotNull);
    });

    test('challengeMFA returns MfaChallenge', () async {
      final result = await repository.challengeMFA(factorId: 'factor-id');
      expect(result.id, isNotEmpty);
    });

    test('listFactors returns list', () async {
      final result = await repository.listFactors();
      expect(result, isA<List>());
    });
  });

  group('AuthRepository - Password', () {
    test('updateUserPassword calls secureAuth', () async {
      bool called = false;
      mockSecureAuth.setNewPasswordStub = (p) async {
        if (p == 'NewPassword123!') called = true;
      };

      await repository.updateUserPassword(password: 'NewPassword123!');
      expect(called, isTrue);
    });
  });

  group('AuthRepository - Rate Limiting', () {
    test('enrollMFA checks rate limit', () async {
      final mockUser = TestSupabaseUser(id: 'test-user');
      mockAuth.setCurrentUser(mockUser);
      mockSupabase.setRpcResult('check_rate_limit', false);

      expect(
        () => repository.enrollMFA(),
        throwsA(isA<AppAuthException>()),
      );
    });
  });
}
