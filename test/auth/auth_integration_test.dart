import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    AppLogger.suppressLogs = true;
  });
  late MockAuthRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthController Integration', () {
    test('initial state is AsyncData(null)', () {
      final state = container.read(authControllerProvider);
      expect(state, const AsyncData<void>(null));
    });

    test('signIn success updates state correctly', () async {
      when(
        mockRepository.signInWithEmail(
          email: 'test@example.com',
          password: 'Password123!',
        ),
      ).thenAnswer(
        (_) async => AuthResult(
          user: DomainAuthUser(
            id: '123',
            emailConfirmedAt: DateTime.now()
                .toIso8601String(), // Email verified
          ),
          session: DomainAuthSession(accessToken: 'token'),
        ),
      );

      final controller = container.read(authControllerProvider.notifier);

      final future = controller.signIn(
        email: 'test@example.com',
        password: 'Password123!',
      );

      // Should show loading
      expect(container.read(authControllerProvider), isA<AsyncLoading>());

      await future;

      // Should be back to data (null) on success, as session is handled by client internally
      expect(
        container.read(authControllerProvider),
        const AsyncData<void>(null),
      );
      verify(
        mockRepository.signInWithEmail(
          email: 'test@example.com',
          password: 'Password123!',
        ),
      ).called(1);
    });

    test('signIn failure sets error state', () async {
      when(
        mockRepository.signInWithEmail(
          email: 'fail@example.com',
          password: 'Password123!',
        ),
      ).thenThrow(const AppAuthException('Invalid credentials'));

      final controller = container.read(authControllerProvider.notifier);

      await controller.signIn(
        email: 'fail@example.com',
        password: 'Password123!',
      );

      final state = container.read(authControllerProvider);
      expect(state, isA<AsyncError>());
      expect(state.error, isA<AppAuthException>());
    });

    test('signOut successful clears state', () async {
      final controller = container.read(authControllerProvider.notifier);

      await controller.signOut();

      expect(
        container.read(authControllerProvider),
        const AsyncData<void>(null),
      );
      verify(mockRepository.signOut()).called(1);
    });
  });
}

// Manual mock for AuthService/AuthRepository
class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) =>
      super.noSuchMethod(
            Invocation.method(#signInWithEmail, [], {
              #email: email,
              #password: password,
            }),
            returnValue: Future.value(AuthResult()),
            returnValueForMissingStub: Future.value(AuthResult()),
          )
          as Future<AuthResult>;

  @override
  Future<void> signOut() =>
      super.noSuchMethod(
            Invocation.method(#signOut, []),
            returnValue: Future<void>.value(),
            returnValueForMissingStub: Future<void>.value(),
          )
          as Future<void>;
}
