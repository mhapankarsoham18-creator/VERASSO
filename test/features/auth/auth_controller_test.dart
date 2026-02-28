import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/core/security/offline_security_service.dart';
import 'package:verasso/core/security/security_providers.dart';
import 'package:verasso/core/security/token_storage_service.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';
import 'package:verasso/features/auth/domain/mfa_models.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

import '../../mocks.dart' as fakes;
import 'auth_controller_test.mocks.dart' as generated;

@GenerateMocks([AuthRepository, TokenStorageService, OfflineSecurityService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late generated.MockAuthRepository mockAuthRepository;
  late generated.MockTokenStorageService mockTokenStorage;
  late generated.MockOfflineSecurityService mockOfflineSecurity;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthRepository = generated.MockAuthRepository();
    mockTokenStorage = generated.MockTokenStorageService();
    mockOfflineSecurity = generated.MockOfflineSecurityService();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        tokenStorageServiceProvider.overrideWithValue(mockTokenStorage),
        offlineSecurityServiceProvider.overrideWithValue(mockOfflineSecurity),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthController', () {
    group('signIn', () {
      test('should update state to loading then success on valid credentials',
          () async {
        // Arrange
        final mockResult = AuthResult(
          user: DomainAuthUser(
            id: 'test-user-id',
            emailConfirmedAt: DateTime.now().toIso8601String(),
          ),
        );
        when(mockAuthRepository.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockResult);

        // Act
        final controller = container.read(authControllerProvider.notifier);
        await controller.signIn(
            email: 'test@example.com', password: 'password123');

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.hasError, isFalse);
      });

      test('should update state to error on invalid credentials', () async {
        // Arrange
        when(mockAuthRepository.signInWithEmail(
          email: 'test@example.com',
          password: 'wrongpassword',
        )).thenThrow(const AuthException('Invalid login credentials'));

        // Act
        final controller = container.read(authControllerProvider.notifier);
        await controller.signIn(
            email: 'test@example.com', password: 'wrongpassword');

        // Assert
        final state = container.read(authControllerProvider);
        expect(state.hasError, isTrue);
      });
    });

    group('signUp', () {
      test('should call repository signUp with correct parameters', () async {
        // Arrange
        final mockResult = AuthResult(user: DomainAuthUser(id: 'new-user-id'));
        when(mockAuthRepository.signUpWithEmail(
          email: 'new@example.com',
          password: 'securePass123!',
          data: anyNamed('data'),
        )).thenAnswer((_) async => mockResult);

        // Act
        final controller = container.read(authControllerProvider.notifier);
        await controller.signUp(
          email: 'new@example.com',
          password: 'securePass123!',
          username: 'newuser',
        );

        // Assert
        verify(mockAuthRepository.signUpWithEmail(
          email: 'new@example.com',
          password: 'securePass123!',
          data: {'username': 'newuser'},
        )).called(1);
      });
    });

    group('resetPassword', () {
      test('should call repository resetPassword', () async {
        // Arrange
        when(mockAuthRepository.resetPasswordForEmail(
                email: 'test@example.com'))
            .thenAnswer((_) async => {});

        // Act
        final controller = container.read(authControllerProvider.notifier);
        await controller.resetPassword('test@example.com');

        // Assert
        verify(mockAuthRepository.resetPasswordForEmail(
                email: 'test@example.com'))
            .called(1);
      });
    });

    group('signOut', () {
      test('should call dependencies during signOut', () async {
        // Arrange
        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => Future.value());
        when(mockOfflineSecurity.clearIdentityHint())
            .thenAnswer((_) async => Future.value());

        // Act
        final controller = container.read(authControllerProvider.notifier);
        await controller.signOut();

        // Assert
        verify(mockAuthRepository.signOut()).called(1);
        verify(mockOfflineSecurity.clearIdentityHint()).called(1);
      });
    });
  });

  group('MFA', () {
    test('enrollMFA should return enrollment response from domain model',
        () async {
      // Arrange
      final mockMfaResponse = MfaEnrollment(
        id: 'factor-123',
        type: 'totp',
        totpSecret: 'secret-key',
        totpUri: 'otpauth://totp/Verasso:test@example.com?secret=secret-key',
      );
      when(mockAuthRepository.enrollMFA())
          .thenAnswer((_) async => mockMfaResponse);

      // Act
      final controller = container.read(authControllerProvider.notifier);
      final response = await controller.enrollMFA();

      // Assert
      expect(response, isNotNull);
      expect(response!.id, 'factor-123');
      expect(response.totpSecret, 'secret-key');
      verify(mockAuthRepository.enrollMFA()).called(1);
    });

    test('challengeMFA should return challenge response', () async {
      // Arrange
      final mockChallenge = MfaChallenge(id: 'challenge-123');
      when(mockAuthRepository.challengeMFA(factorId: 'factor-123'))
          .thenAnswer((_) async => mockChallenge);

      // Act
      final controller = container.read(authControllerProvider.notifier);
      final response = await controller.challengeMFA('factor-123');

      // Assert
      expect(response.id, 'challenge-123');
      verify(mockAuthRepository.challengeMFA(factorId: 'factor-123')).called(1);
    });
  });

  group('AuthController - Phase 2.1 Expanded', () {
    test('signIn should apply cooling-off on failure', () async {
      // Arrange
      when(mockAuthRepository.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(const AppAuthException('Auth failed'));

      // Act
      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn(
          email: 'test@example.com', password: 'password123');

      // Assert
      expect(container.read(failedLoginAttemptsProvider), 1);
      expect(container.read(loginCooldownUntilProvider), isNotNull);
      final state = container.read(authControllerProvider);
      expect(state.hasError, isTrue);
    });

    test('signIn should enforce email verification', () async {
      // Arrange
      final mockResult = AuthResult(
        user: DomainAuthUser(
          id: 'test-user-id',
          emailConfirmedAt: null, // Unverified
        ),
        session: DomainAuthSession(accessToken: 'fake-access-token'),
      );
      when(mockAuthRepository.signInWithEmail(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockResult);
      when(mockAuthRepository.signOut()).thenAnswer((_) async => {});

      // Act
      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn(
          email: 'test@example.com', password: 'password123');

      // Assert
      verify(mockAuthRepository.signOut()).called(1);
      final state = container.read(authControllerProvider);
      expect(state.error.toString(), contains('Email link not confirmed'));
    });

    test('signInWithBiometrics should succeed if session is valid', () async {
      // Arrange
      when(mockTokenStorage.isSessionValid()).thenAnswer((_) async => true);
      when(mockAuthRepository.supabaseClient)
          .thenReturn(fakes.MockSupabaseClient());
      when(mockTokenStorage.refreshSession(any))
          .thenAnswer((_) async => AuthResponse(session: fakes.FakeSession()));

      // Act
      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithBiometrics();

      // Assert
      final state = container.read(authControllerProvider);
      expect(state.hasError, isFalse);
    });
  });
}
