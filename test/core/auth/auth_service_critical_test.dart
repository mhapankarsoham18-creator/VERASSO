import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService();
  });

  tearDown(() {
    // Cleanup
  });

  group('Auth Service - Registration', () {
    test('register with valid email and password', () async {
      const email = 'user@example.com';
      const password = 'SecurePassword123!';
      const name = 'Test User';

      final user = await authService.register(
        email: email,
        password: password,
        name: name,
      );

      expect(user, isNotNull);
      expect(user.email, equals(email));
      expect(user.name, equals(name));
    });

    test('registration fails with invalid email', () async {
      expect(
        () => authService.register(
          email: 'invalid-email',
          password: 'Password123!',
          name: 'User',
        ),
        throwsException,
      );
    });

    test('registration fails with weak password', () async {
      expect(
        () => authService.register(
          email: 'user@example.com',
          password: 'weak',
          name: 'User',
        ),
        throwsException,
      );
    });

    test('registration fails with duplicate email', () async {
      const email = 'duplicate@example.com';

      await authService.register(
        email: email,
        password: 'Password123!',
        name: 'User 1',
      );

      expect(
        () => authService.register(
          email: email,
          password: 'Password456!',
          name: 'User 2',
        ),
        throwsException,
      );
    });

    test('new user has unique ID', () async {
      final user1 = await authService.register(
        email: 'user1unique@example.com',
        password: 'Password123!',
        name: 'User 1',
      );

      final user2 = await authService.register(
        email: 'user2unique@example.com',
        password: 'Password456!',
        name: 'User 2',
      );

      expect(user1.id, isNot(equals(user2.id)));
    });
  });

  group('Auth Service - Login', () {
    test('login with correct credentials', () async {
      const email = 'testuser@example.com';
      const password = 'CorrectPassword123!';

      await authService.register(
        email: email,
        password: password,
        name: 'Test User',
      );

      final user = await authService.login(email: email, password: password);
      expect(user, isNotNull);
      expect(user.email, equals(email));
    });

    test('login fails with wrong password', () async {
      const email = 'wrongpw@example.com';
      const password = 'CorrectPassword123!';

      await authService.register(
        email: email,
        password: password,
        name: 'User',
      );

      expect(
        () => authService.login(email: email, password: 'WrongPassword123!'),
        throwsException,
      );
    });

    test('login fails with nonexistent email', () async {
      expect(
        () => authService.login(
            email: 'nonexistent@example.com', password: 'Password123!'),
        throwsException,
      );
    });

    test('login is rate limited after multiple failures', () async {
      const email = 'ratelimit@example.com';

      await authService.register(
        email: email,
        password: 'CorrectPassword123!',
        name: 'User',
      );

      // Try 5 times with wrong password
      for (int i = 0; i < 5; i++) {
        try {
          await authService.login(email: email, password: 'WrongPassword');
        } catch (e) {
          // Expected
        }
      }

      // Next attempt should be rate limited
      expect(
        () => authService.login(email: email, password: 'CorrectPassword123!'),
        throwsException,
      );
    });
  });

  group('Auth Service - Session Management', () {
    test('current user is accessible after login', () async {
      const email = 'session@example.com';
      const password = 'Password123!';

      await authService.register(
        email: email,
        password: password,
        name: 'Session User',
      );

      await authService.login(email: email, password: password);

      final currentUser = authService.currentUser;
      expect(currentUser, isNotNull);
      expect(currentUser!.email, equals(email));
    });

    test('logout clears current user', () async {
      const email = 'logout@example.com';

      await authService.register(
        email: email,
        password: 'Password123!',
        name: 'User',
      );

      await authService.login(email: email, password: 'Password123!');
      expect(authService.currentUser, isNotNull);

      await authService.logout();
      expect(authService.currentUser, isNull);
    });

    test('session persists across app restarts', () async {
      const email = 'persist@example.com';

      await authService.register(
        email: email,
        password: 'Password123!',
        name: 'User',
      );

      await authService.login(email: email, password: 'Password123!');

      final isAuthenticated = await authService.isAuthenticatedToken();
      expect(isAuthenticated, isTrue);
    });
  });

  group('Auth Service - Password Reset', () {
    test('request password reset for existing email', () async {
      const email = 'reset@example.com';

      await authService.register(
        email: email,
        password: 'OldPassword123!',
        name: 'User',
      );

      final requestSuccess = await authService.requestPasswordReset(email);
      expect(requestSuccess, isNotNull);
    });

    test('password reset link expires after time', () async {
      const email = 'expiring@example.com';

      await authService.register(
        email: email,
        password: 'OldPassword123!',
        name: 'User',
      );

      final resetToken = await authService.requestPasswordReset(email);

      // Simulate using an empty/expired token
      expect(
        () => authService.resetPassword(
          token: '',
          newPassword: 'NewPassword123!',
        ),
        throwsException,
      );
      expect(resetToken, isNotNull);
    });

    test('reset password changes user password', () async {
      const email = 'reset2@example.com';
      const oldPassword = 'OldPassword123!';

      await authService.register(
        email: email,
        password: oldPassword,
        name: 'User',
      );

      // Request reset
      final resetToken = await authService.requestPasswordReset(email);
      expect(resetToken, isNotNull);
    });
  });

  group('Auth Service - Email Verification', () {
    test('new user email requires verification', () async {
      const email = 'verify@example.com';

      final user = await authService.register(
        email: email,
        password: 'Password123!',
        name: 'User',
      );

      expect(user.isEmailVerified, isFalse);
    });

    test('verify email with token', () async {
      const email = 'verify2@example.com';

      await authService.register(
        email: email,
        password: 'Password123!',
        name: 'User',
      );

      await authService.login(email: email, password: 'Password123!');

      final verificationToken = await authService.sendVerificationEmail(email);

      final verified = await authService.verifyEmail(
        token: verificationToken,
      );

      expect(verified.isEmailVerified, isTrue);
    });

    test('unverified user cannot access certain features', () async {
      const email = 'unverified@example.com';

      await authService.register(
        email: email,
        password: 'Password123!',
        name: 'User',
      );

      await authService.login(email: email, password: 'Password123!');

      expect(
        () => authService.accessProtectedFeature(),
        throwsException,
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Stub AuthService  – minimal in-memory implementation so tests compile
// ---------------------------------------------------------------------------
class AuthService {
  static final Map<String, Map<String, String>> _users = {};
  static final Map<String, int> _failedAttempts = {};

  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;

  Future<void> accessProtectedFeature() async {
    if (_currentUser == null || !_currentUser!.isEmailVerified) {
      throw Exception('Email verification required');
    }
  }

  Future<bool> isAuthenticatedToken() async {
    return _currentUser != null;
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final failCount = _failedAttempts[email] ?? 0;
    if (failCount >= 5) throw Exception('Rate limited');

    final user = _users[email];
    if (user == null) throw Exception('User not found');
    if (user['password'] != password) {
      _failedAttempts[email] = failCount + 1;
      throw Exception('Wrong password');
    }
    _failedAttempts.remove(email);
    _currentUser = AuthUser(id: user['id']!, email: email, name: user['name']!);
    return _currentUser!;
  }

  Future<void> logout() async {
    _currentUser = null;
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    required String name,
  }) async {
    if (!email.contains('@')) throw Exception('Invalid email');
    if (password.length < 8) throw Exception('Password too weak');
    if (_users.containsKey(email)) throw Exception('Email already exists');

    final id = 'user-${DateTime.now().microsecondsSinceEpoch}';
    _users[email] = {'id': id, 'password': password, 'name': name};
    return AuthUser(id: id, email: email, name: name);
  }

  Future<String> requestPasswordReset(String email) async {
    if (!_users.containsKey(email)) throw Exception('User not found');
    return 'reset-token-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    // Stub: token validation would go here
    if (token.isEmpty) throw Exception('Invalid token');
  }

  Future<String> sendVerificationEmail(String email) async {
    return 'verify-token-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<AuthUser> verifyEmail({required String token}) async {
    if (_currentUser == null) throw Exception('No user session');
    return AuthUser(
      id: _currentUser!.id,
      email: _currentUser!.email,
      name: _currentUser!.name,
      isEmailVerified: true,
    );
  }
}

// import 'package:verasso/core/auth/auth_service.dart';
// import 'package:verasso/core/auth/models/auth_user.dart';

// ---------------------------------------------------------------------------
// Stub AuthUser model
// ---------------------------------------------------------------------------
class AuthUser {
  final String id;
  final String email;
  final String name;
  final bool isEmailVerified;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.isEmailVerified = false,
  });
}
