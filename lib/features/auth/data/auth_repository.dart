import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    as supabase; // Alias for internal use
import 'package:supabase_flutter/supabase_flutter.dart'
    hide User, Session; // Hide conflicting types
import 'package:verasso/core/auth/secure_auth_service.dart';
import 'package:verasso/core/exceptions/app_exceptions.dart';
import 'package:verasso/core/exceptions/error_handler_mixin.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/security/audit_log_service.dart';
import 'package:verasso/core/security/security_initializer.dart';
import 'package:verasso/core/security/token_storage_service.dart';
import 'package:verasso/core/services/rate_limit_service.dart';
import 'package:verasso/core/services/supabase_service.dart';
import 'package:verasso/core/utils/network_util.dart';

import '../domain/auth_service.dart';
import '../domain/mfa_models.dart';

/// Provider for the [AuthRepository] instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Use explicit dependencies to avoid singleton issues in tests
  return AuthRepository(
    client: SupabaseService.client,
  );
});

/// Repository that coordinates user authentication and session management.
class AuthRepository with ErrorHandlerMixin implements AuthService {
  final supabase.SupabaseClient _client;
  final SecureAuthService _secureAuth;
  final AuditLogService _auditLog;
  final TokenStorageService _tokenStorage;
  final RateLimitService _rateLimitService;

  /// Creates an [AuthRepository] with necessary services.
  AuthRepository({
    supabase.SupabaseClient? client,
    SecureAuthService? secureAuth,
    AuditLogService? auditLog,
    RateLimitService? rateLimitService,
    TokenStorageService? tokenStorage,
  })  : _client = client ?? Supabase.instance.client,
        _secureAuth = secureAuth ?? SecurityInitializer.authService,
        _auditLog = auditLog ?? AuditLogService(client: client),
        _rateLimitService =
            rateLimitService ?? RateLimitService(client: client),
        _tokenStorage = tokenStorage ?? TokenStorageService();

  /// Stream of authentication state changes.
  @override
  Stream<DomainAuthUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      return user != null ? _mapToDomainAuthUser(user) : null;
    });
  }

  /// The currently authenticated user, if any.
  @override
  DomainAuthUser? get currentUser {
    final user = _client.auth.currentUser;
    return user != null ? _mapToDomainAuthUser(user) : null;
  }

  /// Access to the underlying [supabase.SupabaseClient].
  supabase.SupabaseClient get supabaseClient => _client;

  /// Challenges the user with MFA and verifies the provided code.
  @override
  Future<void> challengeAndVerify(
      {required String factorId, required String code}) async {
    await handleError(
      context: 'AuthRepository.challengeAndVerify',
      operation: () async {
        final challenge = await _client.auth.mfa.challenge(factorId: factorId);
        await _client.auth.mfa
            .verify(factorId: factorId, challengeId: challenge.id, code: code);
      },
      reportToSentry: true,
    );
  }

  /// Creates an MFA challenge for the specified factor.
  @override
  Future<MfaChallenge> challengeMFA({required String factorId}) async {
    final response = await _client.auth.mfa.challenge(factorId: factorId);
    return MfaChallenge(id: response.id);
  }

  /// Deletes the current user's account and personal data via a secure RPC.
  @override
  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AppAuthException('No authenticated user found for deletion');
    }

    SentryService.addBreadcrumb(
      message: 'Account deletion requested for: ${user.id}',
      category: 'auth',
    );

    await handleError(
      context: 'AuthRepository.deleteAccount',
      operation: () async {
        // We use a backend RPC to ensure all user records (posts, profiles, wallets)
        // are deleted or anonymized securely before the auth record is removed.
        await _client.rpc('delete_user_account_v1');

        // Sign out locally and clear storage
        await signOut();
      },
      reportToSentry: true,
    );

    // Audit Log (Before deletion complete if possible, or via backend trigger)
    AppLogger.info('Account deletion initiated for ${user.id}');
  }

  /// Enrolls the current user in MFA using TOTP.
  @override
  Future<MfaEnrollment?> enrollMFA() async {
    await _checkRateLimit('enroll_mfa', limit: 5, window: 3600);
    return await handleError(
      context: 'AuthRepository.enrollMFA',
      operation: () async {
        final response =
            await _client.auth.mfa.enroll(factorType: supabase.FactorType.totp);
        return MfaEnrollment(
          id: response.id,
          type: response.type.name,
          totpSecret: response.totp?.secret,
          totpUri: response.totp?.uri,
        );
      },
      reportToSentry: true,
    );
  }

  // --- MFA / 2FA Methods ---

  /// Lists all MFA factors enrolled for the current user.
  @override
  Future<List<dynamic>> listFactors() async {
    final response = await _client.auth.mfa.listFactors();
    return response.all; // Returns List<Factor> (Supabase type)
    // In strict DDD, we should map this to List<DomainAuthFactor>,
    // but AuthService defines it as List<dynamic> for now.
  }

  /// Triggers a password reset flow for the given email address.
  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    SentryService.addBreadcrumb(
      message: 'Password reset requested for: $email',
      category: 'auth',
    );
    await _secureAuth.resetPasswordForEmail(email);
  }

  /// Authenticates a user using their email and password.
  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    SentryService.addBreadcrumb(
      message: 'User signing in with email: $email',
      category: 'auth',
    );

    try {
      // 1. --- SERVER-SIDE BRUTE FORCE PROTECTION ---
      // This calls a SECURITY DEFINER function to track attempts even before Supabase Auth sees them.
      final allowed = await _client.rpc('track_failed_login', params: {
        'p_email': email,
        'p_ip_address': await NetworkUtil.getIpAddress(),
      });

      if (allowed == false) {
        throw const AppAuthException(
          'Too many failed attempts. Account locked for 15 minutes.',
        );
      }

      // 2. --- CLIENT-SIDE RATE LIMIT CHECK (UI/UX) ---
      final isLimited = await _rateLimitService.isLimited(
        email,
        RateLimitType.login,
      );

      if (isLimited) {
        throw const AppAuthException(
          'Too many login attempts. Please try again in 30 minutes.',
        );
      }

      final response = await _secureAuth.signInWithPassword(
        email: email,
        password: password,
      );

      // On Success: Clear failed attempts on server
      await _client.rpc('clear_failed_login_attempts', params: {
        'p_email': email,
        'p_ip_address': await NetworkUtil.getIpAddress(),
      });

      // Save refresh token for session management
      if (response.session?.accessToken != null) {
        try {
          if (response.session?.refreshToken != null) {
            await _tokenStorage
                .saveRefreshToken(response.session!.refreshToken!);
          }
          await _tokenStorage.saveSessionExpiry(
            DateTime.now().add(const Duration(hours: 1)),
          );
        } catch (tokenError) {
          AppLogger.warning('Failed to save tokens after signin',
              error: tokenError);
        }
      }

      await _auditLog.logEvent(
        type: 'auth',
        action: 'signin_success',
        severity: 'low',
        metadata: {'email': email},
      );

      return AuthResult(
        user:
            response.user != null ? _mapToDomainAuthUser(response.user!) : null,
        session: response.session != null
            ? _mapToDomainAuthSession(response.session!)
            : null,
      );
    } catch (e) {
      // Log failed attempt for rate limiting
      await _rateLimitService.logAttempt(
        email: email,
        action: 'login',
        success: false,
      );

      SentryService.captureException(e, hint: 'Base Sign In failed');
      if (e is supabase.AuthException) {
        throw AppAuthException(e.message);
      }
      rethrow;
    }
  }

  /// Initiates an OAuth sign-in flow (e.g., Google, Apple).
  Future<void> signInWithOAuth(supabase.OAuthProvider provider) async {
    SentryService.addBreadcrumb(
      message: 'User signing in with OAuth: ${provider.name}',
      category: 'auth',
    );

    await handleError(
      context: 'AuthRepository.signInWithOAuth',
      operation: () async {
        await _client.auth.signInWithOAuth(
          provider,
          authScreenLaunchMode: supabase.LaunchMode.externalApplication,
          redirectTo: 'io.supabase.verasso://login-callback',
        );
      },
      reportToSentry: true,
    );

    // Audit Log
    await _auditLog.logEvent(
      type: 'auth',
      action: 'oauth_signin_initiated',
      severity: 'low',
      metadata: {'provider': provider.name},
    );
  }

  /// Requests a one-time password (OTP) for the given email address.
  @override
  Future<void> signInWithOtp({
    required String email,
    bool isWeb = false,
  }) async {
    SentryService.addBreadcrumb(
      message: 'OTP login requested for: $email',
      category: 'auth',
    );
    await handleError(
      context: 'AuthRepository.signInWithOtp',
      operation: () => _secureAuth.signInWithOtp(email),
      reportToSentry: true,
    );
  }

  // --- OTP Methods ---

  /// Requests an OTP for the given phone number.
  Future<void> signInWithPhone({
    required String phone,
  }) async {
    await handleError(
      context: 'AuthRepository.signInWithPhone',
      operation: () => _client.auth.signInWithOtp(phone: phone),
      reportToSentry: true,
    );
  }

  /// Signs out the current user and clears stored session tokens.
  @override
  Future<void> signOut() async {
    SentryService.addBreadcrumb(
      message: 'User signing out',
      category: 'auth',
    );

    try {
      // Clear stored tokens before signing out
      await _tokenStorage.clearTokens();
      AppLogger.info('Tokens cleared on signout');
    } catch (tokenError) {
      AppLogger.warning('Failed to clear tokens on signout', error: tokenError);
      // Continue with signout even if token clearing fails
    }

    await _secureAuth.signOut();
  }

  /// Creates a new user account using email and password.
  @override
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    Map<String, dynamic>? data,
  }) async {
    SentryService.addBreadcrumb(
      message: 'User signing up with email: $email',
      category: 'auth',
    );

    try {
      // Check rate limit BEFORE signup attempt
      final isLimited = await _rateLimitService.isLimited(
        email,
        RateLimitType.signup,
      );

      if (isLimited) {
        AppLogger.warning('Signup rate limited for: $email');
        await _auditLog.logEvent(
          type: 'auth',
          action: 'signup_rate_limited',
          severity: 'low',
          metadata: {'email': email},
        );
        throw const AppAuthException(
          'Too many signup attempts. Please try again in a few hours.',
        );
      }

      // 2.1 — Add password strength validation on signup
      if (password.length < 8) {
        throw const AppAuthException(
            'Password must be at least 8 characters long');
      }
      if (!password.contains(RegExp(r'[A-Z]'))) {
        throw const AppAuthException(
            'Password must contain at least one uppercase letter');
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        throw const AppAuthException(
            'Password must contain at least one number');
      }
      if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        throw const AppAuthException(
            'Password must contain at least one special character');
      }

      final response = await _secureAuth.signUpWithPassword(
        email: email,
        password: password,
        username: username ?? data?['username'] ?? email.split('@')[0],
        metadata: data,
      );

      // Save refresh token (not password) for session management
      if (response.session?.accessToken != null) {
        try {
          // Extract refresh token from response
          if (response.session?.refreshToken != null) {
            await _tokenStorage
                .saveRefreshToken(response.session!.refreshToken!);
            AppLogger.info('Refresh token saved for signup user');
          }

          // Save session expiry information
          await _tokenStorage.saveSessionExpiry(
            DateTime.now().add(const Duration(hours: 1)),
          );
        } catch (tokenError) {
          AppLogger.warning('Failed to save tokens after signup',
              error: tokenError);
          // Don't throw - signup succeeded, token storage is optional fallback
        }
      }

      // Log successful signup
      await _auditLog.logEvent(
        type: 'auth',
        action: 'signup_success',
        severity: 'low',
        metadata: {'email': email, 'username': username},
      );

      return AuthResult(
        user:
            response.user != null ? _mapToDomainAuthUser(response.user!) : null,
        session: response.session != null
            ? _mapToDomainAuthSession(response.session!)
            : null,
      );
    } catch (e) {
      // Log failed signup
      await _auditLog.logEvent(
        type: 'auth',
        action: 'signup_failed',
        severity: 'medium',
        metadata: {'email': email, 'error': e.toString()},
      );

      // Log failed attempt for rate limiting
      await _rateLimitService.logAttempt(
        email: email,
        action: 'signup',
        success: false,
      );

      SentryService.captureException(e, hint: 'Base Sign Up failed');
      if (e is supabase.AuthException) {
        throw AppAuthException(e.message);
      }
      throw AppAuthException('Sign up failed: ${e.toString()}');
    }
  }

  /// Removes an MFA factor for the current user.
  @override
  Future<void> unenrollMFA({required String factorId}) async {
    await _client.auth.mfa.unenroll(factorId);
  }

  /// Updates the current user's password.
  @override
  Future<void> updateUserPassword({required String password}) async {
    await _secureAuth.setNewPassword(password);
  }

  /// Verifies an MFA challenge code.
  @override
  Future<AuthResult?> verifyMFA(
      {required String factorId,
      required String challengeId,
      required String code}) async {
    return await handleError(
      context: 'AuthRepository.verifyMFA',
      operation: () async {
        await _client.auth.mfa
            .verify(factorId: factorId, challengeId: challengeId, code: code);
        // Supabase verify returns AuthMFAVerifyResponse which usually contains user/session
        // But the SDK type might be different. Let's assume it has typical response structure.
        // If SDK returns AuthMFAVerifyResponse and it has access_token, we can map it.
        // Actually, let's check if we can get the session from the client after verify.
        return AuthResult(
            user: currentUser, // user should be updated in client
            session:
                null // we might not get session directly from this specific call return in all SDK versions, but client state updates
            );
        // Refinement: If verify returns a response with session, map it.
        // For now, return checks current state.
      },
      reportToSentry: true,
    );
  }

  /// Verifies an OTP code for sign-in or other flows.
  @override
  Future<AuthResult?> verifyOtp({
    required String token,
    required dynamic type, // Use dynamic to map
    String? email,
    String? phone,
  }) async {
    SentryService.addBreadcrumb(
      message: 'Verifying OTP for $email',
      category: 'auth',
    );

    final mappedType = type is supabase.OtpType
        ? type
        : supabase.OtpType.values.firstWhere(
            (e) => e.toString() == type.toString(),
            orElse: () => supabase.OtpType.email, // Default or Error
          );

    return await handleError(
      context: 'AuthRepository.verifyOtp',
      operation: () async {
        try {
          supabase.AuthResponse response;
          if (email != null) {
            response = await _secureAuth.verifyOTP(
              email: email,
              token: token,
              type: mappedType,
            );
          } else {
            response = await _client.auth.verifyOTP(
              token: token,
              type: mappedType,
              email: email,
              phone: phone,
            );
          }
          return AuthResult(
            user: response.user != null
                ? _mapToDomainAuthUser(response.user!)
                : null,
            session: response.session != null
                ? _mapToDomainAuthSession(response.session!)
                : null,
          );
        } catch (e) {
          if (e is supabase.AuthException) {
            throw AppAuthException(e.message);
          }
          rethrow;
        }
      },
      reportToSentry: true,
    );
  }

  Future<void> _checkRateLimit(String action,
      {int limit = 100, int window = 60}) async {
    final user = _client.auth.currentUser;
    if (user == null) return; // Can't limit anonymous here via RPC easily

    try {
      final allowed = await _client.rpc('check_rate_limit', params: {
        'p_user_id': user.id,
        'p_action': action,
        'p_limit': limit,
        'p_window_seconds': window,
      });

      if (allowed == false) {
        throw const AppAuthException(
            'Rate limit exceeded. Please try again later.');
      }
    } catch (e, stack) {
      // If function doesn't exist or fails, we log but maybe don't block unless strict
      if (e.toString().contains('Rate limit exceeded')) rethrow;
      AppLogger.warning('Rate limit check failed', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }

  DomainAuthSession _mapToDomainAuthSession(supabase.Session session) {
    return DomainAuthSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      user: _mapToDomainAuthUser(session.user),
    );
  }

  DomainAuthUser _mapToDomainAuthUser(supabase.User user) {
    return DomainAuthUser(
      id: user.id,
      email: user.email,
      userMetadata: user.userMetadata ?? {},
      emailConfirmedAt: user.emailConfirmedAt,
      factors: user.factors
              ?.map((f) => DomainAuthFactor(
                    id: f.id,
                    status: f.status.name,
                    type: f.factorType.name,
                  ))
              .toList() ??
          [],
    );
  }
}
