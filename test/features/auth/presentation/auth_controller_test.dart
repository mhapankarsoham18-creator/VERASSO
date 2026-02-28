import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:verasso/core/security/offline_security_service.dart';
import 'package:verasso/core/security/security_providers.dart';
import 'package:verasso/core/security/token_storage_service.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

// Generate mock repository
@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<TokenStorageService>(),
  MockSpec<OfflineSecurityService>()
])
import 'auth_controller_test.mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    final mockTokenStorage = MockTokenStorageService();
    final mockOfflineSecurity = MockOfflineSecurityService();

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

  group('AuthController Tests', () {
    test('initial state is AsyncData(null)', () {
      container.read(authControllerProvider.notifier);
      expect(
          container.read(authControllerProvider), const AsyncData<void>(null));
    });

    test('signIn success updates state to AsyncData', () async {
      when(mockAuthRepository.signInWithEmail(
              email: 'test@example.com', password: 'password'))
          .thenAnswer((_) async => AuthResult(
                user: DomainAuthUser(
                  id: 'user_id',
                  email: 'test@example.com',
                  emailConfirmedAt: DateTime.now().toIso8601String(),
                ),
              ));

      final authController = container.read(authControllerProvider.notifier);
      await authController.signIn(
          email: 'test@example.com', password: 'password');

      expect(
          container.read(authControllerProvider), const AsyncData<void>(null));
      verify(mockAuthRepository.signInWithEmail(
              email: 'test@example.com', password: 'password'))
          .called(1);
    });

    test('signIn failure updates state to AsyncError', () async {
      when(mockAuthRepository.signInWithEmail(
              email: 'test@example.com', password: 'wrong'))
          .thenThrow(Exception('Login failed'));

      final authController = container.read(authControllerProvider.notifier);
      await authController.signIn(email: 'test@example.com', password: 'wrong');

      expect(container.read(authControllerProvider).hasError, true);
    });
  });
}
