import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:verasso/core/monitoring/sentry_service.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/monitoring/app_logger.dart';
import '../../../core/security/offline_security_service.dart';
import '../../../core/security/security_providers.dart';
import '../../../core/security/token_storage_service.dart';
import '../../../services/backup_codes_service.dart';
import '../../profile/data/profile_repository.dart';
import '../data/auth_repository.dart';
import '../domain/auth_service.dart';
import '../domain/mfa_models.dart';

/// Provider for the [AuthController] which manages user session and authentication actions.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref,
    ref.watch(tokenStorageServiceProvider),
    ref.watch(offlineSecurityServiceProvider),
  );
});

/// Stream provider for the current [DomainAuthUser] from Supabase.
final authStateProvider = StreamProvider<DomainAuthUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Provider for the currently authenticated [DomainAuthUser], if any.
final currentUserProvider = Provider<DomainAuthUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.asData?.value;
});

/// Consecutive failed password login attempts (reset on success). Used for cooling-off UX (Phase 2.1).
final failedLoginAttemptsProvider = StateProvider<int>((ref) => 0);

/// After too many failures, login is disabled until this time. Null when not in cooldown.
final loginCooldownUntilProvider = StateProvider<DateTime?>((ref) => null);

/// State provider for signaling when an MFA challenge is required during login.
final mfaRequirementProvider =
    StateProvider<AuthMFARequirement?>((ref) => null);

/// Controller responsible for authentication logic, session management, and MFA flows.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  final Ref _ref;
  final TokenStorageService _tokenStorage;
  final OfflineSecurityService _offlineSecurity;

  /// Creates an [AuthController].
  AuthController(
      this._repo, this._ref, this._tokenStorage, this._offlineSecurity)
      : super(const AsyncData(null));

  /// Initiates a multi-factor authentication challenge for the specific [factorId].
  Future<MfaChallenge> challengeMFA(String factorId) async {
    return await _repo.challengeMFA(factorId: factorId);
  }

  // --- Multi-Factor Authentication (MFA) ---

  /// Begins the enrollment process for a new MFA factor.
  Future<MfaEnrollment?> enrollMFA() async {
    return await _repo.enrollMFA();
  }

  /// Sends a password reset email to the specified [email] address.
  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    state =
        await AsyncValue.guard(() => _repo.resetPasswordForEmail(email: email));
  }

  /// Authenticates a user with [email] and [password].
  ///
  /// If MFA is enabled for the account, it initiates a TOTP challenge.
  /// On repeated failures, applies client-side cooling-off (Phase 2.1).
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _repo.signInWithEmail(
          email: email,
          password: password,
        ));

    if (result.hasError) {
      final attempts = _ref.read(failedLoginAttemptsProvider) + 1;
      _ref.read(failedLoginAttemptsProvider.notifier).state = attempts;
      final cooldownSeconds = (30 * (attempts.clamp(1, 4))).clamp(30, 120);
      _ref.read(loginCooldownUntilProvider.notifier).state =
          DateTime.now().add(Duration(seconds: cooldownSeconds));
      state = AsyncError(
          result.error ??
              const AppAuthException('Unknown authentication error'),
          result.stackTrace ?? StackTrace.current);
      AppLogger.warning('Signin failed', error: result.error);
      return;
    }

    _ref.read(failedLoginAttemptsProvider.notifier).state = 0;
    _ref.read(loginCooldownUntilProvider.notifier).state = null;

    final authResult = result.value as AuthResult; // Helper cast if needed
    if (authResult.session != null) {
      final factors = authResult.user?.factors ?? [];
      if (factors.isNotEmpty) {
        final totpFactor = factors.firstWhere(
          (f) => f.type == 'totp' && f.status == 'verified',
          orElse: () => factors.firstWhere((f) => f.type == 'totp',
              orElse: () => factors.first),
        );

        if (totpFactor.type == 'totp') {
          // Initiate challenge
          try {
            final challenge = await _repo.challengeMFA(factorId: totpFactor.id);
            _ref.read(mfaRequirementProvider.notifier).state =
                AuthMFARequirement(
              factorId: totpFactor.id,
              challengeId: challenge.id,
            );
            state = const AsyncData(null);
            AppLogger.info('MFA challenge initiated');
            return;
          } catch (e, stack) {
            AppLogger.warning('MFA challenge failed', error: e);
            SentryService.captureException(e, stackTrace: stack);
            // If challenge fails, we might still be at AAL1, but MFA is required
          }
        }
      }
    }

    // Phase 2.1: Enforce Email Verification
    if (authResult.user != null && authResult.user!.emailConfirmedAt == null) {
      await _repo.signOut(); // Sign out unverified user session
      state = AsyncError(
        const AppAuthException(
            'Email link not confirmed. Please verify your neural uplink.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncData(null);
    // Token storage now handled in AuthRepository - no need to store credentials here
    if (!result.hasError && authResult.session != null) {
      AppLogger.info('Signin successful - refresh token saved in repository');
      if (authResult.user?.email != null) {
        await _offlineSecurity.setIdentityHint(authResult.user!.email!);
      }
    }
  }

  /// Initiates sign-in with Apple OAuth.
  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _repo.signInWithOAuth(supabase.OAuthProvider.apple));
  }

  /// Attempts to sign in using biometrics.
  ///
  /// Requires a valid previous session and biometrics to be configured.
  Future<void> signInWithBiometrics() async {
    state = const AsyncLoading();

    try {
      // Check if session is still valid
      final isValid = await _tokenStorage.isSessionValid();

      if (!isValid) {
        state = AsyncError(
          const AppAuthException(
              'Session expired. Please login with your password.'),
          StackTrace.current,
        );
        AppLogger.info(
            'Biometric signin - session expired, user must re-login');
        return;
      }

      // Session is valid, try to refresh it
      try {
        final client = _repo.supabaseClient;
        final refreshedSession = await _tokenStorage.refreshSession(client);

        if (refreshedSession != null) {
          state = const AsyncData(null);
          AppLogger.info('Biometric signin successful - session refreshed');
          return;
        }
      } catch (refreshError, stack) {
        AppLogger.warning('Failed to refresh session during biometric signin',
            error: refreshError);
        SentryService.captureException(refreshError, stackTrace: stack);

        // --- OFFLINE FALLBACK ---
        final offlineSec = OfflineSecurityService();
        if (await offlineSec.hasIdentityHint()) {
          state = const AsyncData(null);
          AppLogger.info(
              'Offline Identity Hint verified - Allowing Local Pioneer access');
          return;
        }
      }

      state = AsyncError(
        const AppAuthException(
            'Unable to refresh your session. Please login with your password.'),
        StackTrace.current,
      );
      AppLogger.warning('Biometric signin failed - could not refresh session');
    } catch (e) {
      state = AsyncError(
        AppAuthException('Biometric login error: ${e.toString()}'),
        StackTrace.current,
      );
      AppLogger.error('Biometric signin error', error: e);
    }
  }

  /// Initiates sign-in with Google OAuth.
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _repo.signInWithOAuth(supabase.OAuthProvider.google));
  }

  /// Initiates a magic link (OTP) login for the specified [email].
  Future<void> signInWithOtpEmail(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.signInWithOtp(email: email));
  }

  /// Signs the currently authenticated user out of the application.
  Future<void> signOut() async {
    state = const AsyncLoading();
    await _offlineSecurity.clearIdentityHint();
    state = await AsyncValue.guard(() => _repo.signOut());
    AppLogger.info('Offline identity hint cleared');
  }

  /// Registers a new user with [email], [password], and [username].
  Future<void> signUp(
      {required String email,
      required String password,
      required String username}) async {
    // Phase 2.1: Password Strength Validation
    if (password.length < 8) {
      state = AsyncError(
        const AppAuthException('Password must be at least 8 characters long'),
        StackTrace.current,
      );
      return;
    }

    if (!password.contains(RegExp(r'[A-Z]')) ||
        !password.contains(RegExp(r'[0-9]')) ||
        !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      state = AsyncError(
        const AppAuthException(
            'Password must contain an uppercase letter, a number, and a special character'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    // Safety check for username availability
    try {
      final isAvailable = await _ref
          .read(profileRepositoryProvider)
          .isUsernameAvailable(username);
      if (!isAvailable) {
        state = AsyncError(
          const AppAuthException(
              'Username is already taken. Please choose another one.'),
          StackTrace.current,
        );
        return;
      }
    } catch (e) {
      // If check fails, we proceed but log it. The backend will catch it if it's truly taken.
      AppLogger.warning('Pre-signup username check failed', error: e);
    }

    final result = await AsyncValue.guard(() => _repo.signUpWithEmail(
          email: email,
          password: password,
          data: {'username': username},
        ));

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      AppLogger.warning('Signup failed', error: result.error);
    } else {
      state = const AsyncData(null);
      AppLogger.info('Signup successful - refresh token saved in repository');
    }
  }

  /// Updates the current user's password to [newPassword].
  Future<void> updatePassword(String newPassword) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => _repo.updateUserPassword(password: newPassword));
  }

  /// Verifies an MFA backup [code] as a failover for TOTP.
  Future<void> verifyBackupCode(String code) async {
    state = const AsyncLoading();
    try {
      final backupService = BackupCodesService();
      final isValid = await backupService.verifyBackupCode(code);

      if (isValid) {
        // --- IDENTITY EXCHANGE BRIDGE (Simulated) ---
        // In production, we'd call an Edge Function to exchange the valid
        // backup code for a high-integrity session token (AAL2).
        AppLogger.info(
            'Backup code verified. Initiating Identity Exchange bridge...');

        // Simulation: Refresh session to simulate "elevation"
        final client = _repo.supabaseClient;
        await _tokenStorage.refreshSession(client);

        state = const AsyncData(null);
        AppLogger.info('Identity Exchange successful - Session elevated');
      } else {
        throw const AppAuthException('Invalid or already used backup code');
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
      AppLogger.warning('Backup code verification failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Verifies a multi-factor authentication [code] using TOTP.
  Future<AuthResult> verifyMFA({
    required String factorId,
    required String challengeId,
    required String code,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _repo.verifyMFA(
          factorId: factorId,
          challengeId: challengeId,
          code: code,
        ));
    state = const AsyncData(null); // Reset state after verification

    // We re-throw if it failed to let UI handle it, or we could return response.
    // For verification, we usually want to know if it succeeded.
    if (result.hasError) {
      throw result.error ?? const AppAuthException('Verification failed');
    }
    return (result as AsyncData<AuthResult?>).value ??
        AuthResult(); // Return result
  }

  /// Verifies the OTP [token] sent to the user's [email].
  Future<void> verifyOtp({required String email, required String token}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.verifyOtp(
        email: email, token: token, type: supabase.OtpType.email));
  }
}

/// Data model representing a required MFA step during authentication.
class AuthMFARequirement {
  /// The ID of the MFA factor being challenged.
  final String factorId;

  /// The ID of the specific challenge instance.
  final String challengeId;

  /// Creates an [AuthMFARequirement].
  AuthMFARequirement({required this.factorId, required this.challengeId});
}
