import 'package:flutter_test/flutter_test.dart';
// Service tests for core services
import 'package:verasso/core/services/validation_service.dart';

void main() {
  group('ValidationService', () {
    group('Email Validation', () {
      test('valid email returns null', () {
        expect(ValidationService.validateEmail('test@example.com'), isNull);
        expect(ValidationService.validateEmail('user.name@domain.org'), isNull);
        expect(ValidationService.validateEmail('user+tag@gmail.com'), isNull);
      });

      test('invalid email returns error message', () {
        expect(ValidationService.validateEmail(''), isNotNull);
        expect(ValidationService.validateEmail('notanemail'), isNotNull);
        expect(ValidationService.validateEmail('missing@'), isNotNull);
      });

      test('empty email returns required error', () {
        final result = ValidationService.validateEmail(null);
        expect(result, isNotNull);
        expect(result, contains('required'));
      });
    });

    group('Password Validation', () {
      test('strong password returns null', () {
        expect(ValidationService.validatePassword('SecurePass123!'), isNull);
        expect(ValidationService.validatePassword('MyP@ssw0rd'), isNull);
      });

      test('weak password returns error message', () {
        expect(ValidationService.validatePassword(''), isNotNull);
        expect(ValidationService.validatePassword('short'), isNotNull);
        expect(
            ValidationService.validatePassword('nouppercase123!'), isNotNull);
        expect(
            ValidationService.validatePassword('NOLOWERCASE123!'), isNotNull);
      });

      test('password without special char returns error', () {
        final result = ValidationService.validatePassword('SecurePass123');
        expect(result, isNotNull);
        expect(result, contains('special character'));
      });
    });

    group('Username Validation', () {
      test('valid username returns null', () {
        expect(ValidationService.validateUsername('validuser'), isNull);
        expect(ValidationService.validateUsername('user_123'), isNull);
        expect(ValidationService.validateUsername('User123'), isNull);
      });

      test('invalid username returns error message', () {
        expect(ValidationService.validateUsername(''), isNotNull);
        expect(
            ValidationService.validateUsername('ab'), isNotNull); // Too short
        expect(ValidationService.validateUsername('user@name'),
            isNotNull); // Invalid chars
      });

      test('username starting with number returns error', () {
        final result = ValidationService.validateUsername('123user');
        expect(result, isNotNull);
        expect(result, contains('start with a letter'));
      });
    });

    group('Post Content Validation', () {
      test('valid post returns null', () {
        expect(ValidationService.validatePostContent('Hello world!'), isNull);
      });

      test('empty post returns error', () {
        expect(ValidationService.validatePostContent(''), isNotNull);
      });

      test('whitespace only post returns error', () {
        expect(ValidationService.validatePostContent('   '), isNotNull);
      });
    });

    group('Registration Validation', () {
      test('valid registration returns null', () {
        final result = ValidationService.validateRegistration(
          email: 'test@example.com',
          password: 'SecurePass123!',
          username: 'testuser',
          fullName: 'Test User',
        );
        expect(result, isNull);
      });

      test('invalid email in registration returns error', () {
        final result = ValidationService.validateRegistration(
          email: 'invalid',
          password: 'SecurePass123!',
          username: 'testuser',
          fullName: 'Test User',
        );
        expect(result, isNotNull);
      });
    });
  });
}
