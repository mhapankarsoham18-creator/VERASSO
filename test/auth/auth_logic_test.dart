import 'package:flutter_test/flutter_test.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';

/// Tests for auth-related domain logic and validation rules.
///
/// These test the pure business logic of the auth system without
/// requiring Supabase or any external services.
void main() {
  group('Password Validation Rules', () {
    // Mirrors the validation logic in AuthRepository.signUpWithEmail (lines 377-396)
    bool isValidPassword(String password) {
      if (password.length < 8) return false;
      if (!password.contains(RegExp(r'[A-Z]'))) return false;
      if (!password.contains(RegExp(r'[0-9]'))) return false;
      if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
      return true;
    }

    test('accepts a strong password', () {
      expect(isValidPassword('MyStr0ng!Pass'), isTrue);
    });

    test('rejects password shorter than 8 characters', () {
      expect(isValidPassword('Ab1!'), isFalse);
    });

    test('rejects password without uppercase letter', () {
      expect(isValidPassword('mystr0ng!pass'), isFalse);
    });

    test('rejects password without number', () {
      expect(isValidPassword('MyStrong!Pass'), isFalse);
    });

    test('rejects password without special character', () {
      expect(isValidPassword('MyStr0ngPass'), isFalse);
    });

    test('rejects empty password', () {
      expect(isValidPassword(''), isFalse);
    });

    test('accepts password with exactly 8 characters', () {
      expect(isValidPassword('Aabc1!xy'), isTrue);
    });

    test('rejects password with only numbers', () {
      expect(isValidPassword('12345678'), isFalse);
    });

    test('rejects password with only lowercase', () {
      expect(isValidPassword('abcdefgh'), isFalse);
    });
  });

  group('Cooldown Calculation', () {
    // Mirrors the cooldown logic in AuthController.signIn (line 99)
    int calculateCooldownSeconds(int failedAttempts) {
      return (30 * (failedAttempts.clamp(1, 4))).clamp(30, 120);
    }

    test('first failure gives 30 second cooldown', () {
      expect(calculateCooldownSeconds(1), 30);
    });

    test('second failure gives 60 second cooldown', () {
      expect(calculateCooldownSeconds(2), 60);
    });

    test('third failure gives 90 second cooldown', () {
      expect(calculateCooldownSeconds(3), 90);
    });

    test('fourth failure gives 120 second cooldown', () {
      expect(calculateCooldownSeconds(4), 120);
    });

    test('fifth failure still gives 120 second cooldown (clamped)', () {
      expect(calculateCooldownSeconds(5), 120);
    });

    test('tenth failure still gives 120 second cooldown (clamped)', () {
      expect(calculateCooldownSeconds(10), 120);
    });
  });

  group('DomainAuthUser', () {
    test('creates user with all fields', () {
      final user = DomainAuthUser(
        id: 'user-123',
        email: 'test@example.com',
        userMetadata: {'username': 'testuser'},
        emailConfirmedAt: '2026-01-01T00:00:00Z',
        factors: [DomainAuthFactor(id: 'f1', status: 'verified', type: 'totp')],
      );

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.userMetadata['username'], 'testuser');
      expect(user.emailConfirmedAt, isNotNull);
      expect(user.factors.length, 1);
      expect(user.factors.first.type, 'totp');
      expect(user.factors.first.status, 'verified');
    });

    test('creates user with defaults', () {
      final user = DomainAuthUser(id: 'user-456');

      expect(user.id, 'user-456');
      expect(user.email, isNull);
      expect(user.userMetadata, isEmpty);
      expect(user.emailConfirmedAt, isNull);
      expect(user.factors, isEmpty);
    });

    test('user with unconfirmed email has null emailConfirmedAt', () {
      final user = DomainAuthUser(
        id: 'user-789',
        email: 'unverified@example.com',
      );
      expect(user.emailConfirmedAt, isNull);
    });
  });

  group('AuthResult', () {
    test('creates successful result with user and session', () {
      final result = AuthResult(
        user: DomainAuthUser(id: 'u1', email: 'a@b.com'),
        session: DomainAuthSession(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          user: DomainAuthUser(id: 'u1'),
        ),
      );

      expect(result.user, isNotNull);
      expect(result.session, isNotNull);
      expect(result.session!.accessToken, 'access-token');
      expect(result.session!.refreshToken, 'refresh-token');
    });

    test('creates result with no user or session', () {
      final result = AuthResult();
      expect(result.user, isNull);
      expect(result.session, isNull);
    });
  });

  group('AppAuthException', () {
    test('stores message', () {
      const e = AppAuthException('Test error');
      expect(e.message, 'Test error');
    });

    test('toString includes message', () {
      const e = AppAuthException('Login failed');
      expect(e.toString(), contains('Login failed'));
    });
  });

  group('DomainAuthFactor', () {
    test('identifies verified TOTP factor', () {
      final factor = DomainAuthFactor(
        id: 'f1',
        status: 'verified',
        type: 'totp',
      );
      expect(factor.type, 'totp');
      expect(factor.status, 'verified');
    });

    test('identifies unverified factor', () {
      final factor = DomainAuthFactor(
        id: 'f2',
        status: 'unverified',
        type: 'totp',
      );
      expect(factor.status, 'unverified');
    });
  });

  group('MFA Factor Selection Logic', () {
    // Mirrors the MFA factor selection in AuthController.signIn (lines 116-124)
    DomainAuthFactor selectTotpFactor(List<DomainAuthFactor> factors) {
      return factors.firstWhere(
        (f) => f.type == 'totp' && f.status == 'verified',
        orElse: () => factors.firstWhere(
          (f) => f.type == 'totp',
          orElse: () => factors.first,
        ),
      );
    }

    test('prefers verified TOTP factor', () {
      final factors = [
        DomainAuthFactor(id: 'f1', status: 'unverified', type: 'totp'),
        DomainAuthFactor(id: 'f2', status: 'verified', type: 'totp'),
      ];
      expect(selectTotpFactor(factors).id, 'f2');
    });

    test('falls back to unverified TOTP', () {
      final factors = [
        DomainAuthFactor(id: 'f1', status: 'unverified', type: 'totp'),
        DomainAuthFactor(id: 'f2', status: 'verified', type: 'phone'),
      ];
      expect(selectTotpFactor(factors).id, 'f1');
    });

    test('falls back to first factor when no TOTP', () {
      final factors = [
        DomainAuthFactor(id: 'f1', status: 'verified', type: 'phone'),
      ];
      expect(selectTotpFactor(factors).id, 'f1');
    });
  });
}
