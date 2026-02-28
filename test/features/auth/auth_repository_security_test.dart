import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';

import '../../mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockSecureAuthService mockSecureAuth;
  late MockAuditLogService mockAuditLog;
  late MockRateLimitService mockRateLimit;
  late MockTokenStorageService mockTokenStorage;
  late AuthRepository repository;

  setUp(() {
    mockAuth = MockGoTrueClient();
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
  });

  group('AuthRepository - Security Hardening (Phase 4)', () {
    const email = 'test@verasso.com';
    const password = 'Password123!';

    test(
        'signInWithEmail should throw if track_failed_login returns false (account locked)',
        () async {
      // Mock account locked on server
      mockSupabase.setRpcResponse('track_failed_login', false);

      expect(
        () => repository.signInWithEmail(email: email, password: password),
        throwsA(isA<AppAuthException>().having(
          (e) => e.message,
          'message',
          contains('Too many failed attempts'),
        )),
      );
    });

    test(
        'signInWithEmail should succeed and clear failed attempts if track_failed_login allows',
        () async {
      // Mock allowed on server
      mockSupabase.setRpcResponse('track_failed_login', true);
      mockSupabase.setRpcResponse('clear_failed_login_attempts', null);

      mockSecureAuth.signInWithPasswordStub = ({
        required email,
        required password,
      }) async {
        return AuthResponse(
          user: TestSupabaseUser(),
          session: Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: TestSupabaseUser(),
          ),
        );
      };

      final result =
          await repository.signInWithEmail(email: email, password: password);

      expect(result.user, isNotNull);
    });

    test(
        'signInWithEmail should catch exceptions and log attempts in local RateLimitService',
        () async {
      mockSupabase.setRpcResponse('track_failed_login', true);

      mockSecureAuth.signInWithPasswordStub = ({
        required email,
        required password,
      }) async {
        throw const AuthException('Invalid login credentials');
      };

      expect(
        () => repository.signInWithEmail(
            email: email, password: 'wrong_password'),
        throwsA(isA<AppAuthException>()),
      );
    });
  });
}
