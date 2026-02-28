import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:verasso/features/auth/data/auth_repository.dart';
import 'package:verasso/features/auth/domain/auth_service.dart';
import 'package:verasso/features/auth/presentation/auth_screen.dart';
import 'package:verasso/features/home/presentation/home_screen.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/l10n/app_localizations.dart';

import 'auth_flow_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('Auth Flow Integration Tests', () {
    late MockAuthRepository mockAuthRepository;
    late DomainAuthUser testUser;

    setUp(() {
      mockAuthRepository = MockAuthRepository();

      testUser = DomainAuthUser(
        id: 'test-user-id',
        email: 'test@example.com',
      );
    });

    testWidgets('Complete login flow from AuthScreen to generic routing',
        (tester) async {
      when(mockAuthRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      when(mockAuthRepository.signInWithEmail(
              email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async {
        return AuthResult(user: testUser);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            themeControllerProvider.overrideWith(
                (ref) => ThemeController()..togglePowerSaveMode(true)),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en', ''),
            ],
            home: AuthScreen(),
          ),
        ),
      );

      await tester.pump(); // Initial render

      expect(find.byType(AuthScreen), findsOneWidget);
      // Fixed: Match exact localized string "Welcome Back, Pioneer"
      expect(find.text('Welcome Back, Pioneer'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'password123');
      await tester.pump();

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(mockAuthRepository.signInWithEmail(
              email: 'test@example.com', password: 'password123'))
          .called(1);
    });

    testWidgets('App starts at Login when unauthenticated', (tester) async {
      when(mockAuthRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            themeControllerProvider.overrideWith(
                (ref) => ThemeController()..togglePowerSaveMode(true)),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/login',
              routes: [
                GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
                GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
              ],
            ),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
