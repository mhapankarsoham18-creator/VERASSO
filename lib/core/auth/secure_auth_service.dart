import 'package:supabase/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/auth/user_password_security_service.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/security/audit_log_service.dart';
import 'package:verasso/core/security/password_hashing_service.dart';
import 'package:verasso/core/services/ip_service.dart';

part 'secure_auth_service_helpers.dart';

/// Enhanced authentication service with bcrypt and security features
class SecureAuthService {
  final SupabaseClient _supabase;
  final UserPasswordSecurityService _passwordSecurity;
  final IpService _ipService;
  final AuditLogService _auditLog;

  /// Creates a [SecureAuthService] with the required [SupabaseClient].
  SecureAuthService(this._supabase)
      : _passwordSecurity = UserPasswordSecurityService(_supabase),
        _ipService = IpService(),
        _auditLog = AuditLogService(client: _supabase);

  // ============================================================
  // SIGNUP WITH BCRYPT
  // ============================================================

  /// Get user's active sessions
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('auth_sessions')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('last_activity', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================
  // LOGIN WITH SECURITY
  // ============================================================

  /// Get failed login attempts
  Future<Map<String, dynamic>> getFailedAttempts() async {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('auth_failed_attempts')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (response == null) {
      return {
        'attempt_count': 0,
        'locked': false,
      };
    }

    final lockedUntil = response['locked_until'] != null
        ? DateTime.parse(response['locked_until'] as String)
        : null;

    return {
      'attempt_count': response['attempt_count'],
      'locked': lockedUntil != null && lockedUntil.isAfter(DateTime.now()),
      'locked_until': lockedUntil,
      'last_attempt': DateTime.parse(response['last_attempt'] as String),
    };
  }

  // ============================================================
  // PASSWORD RESET WITH SECURITY
  // ============================================================

  /// Get password strength history
  Future<List<Map<String, dynamic>>> getPasswordStrengthHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('password_strength_log')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Invalidate specific session
  Future<void> invalidateSession(String sessionId) async {
    await _supabase
        .from('auth_sessions')
        .update({'is_active': false}).eq('id', sessionId);
  }

  /// Request password reset with rate limiting
  Future<void> resetPasswordForEmail(String email) async {
    await _checkRateLimit('/auth/password-reset');

    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e, stackTrace) {
      await SentryService.captureException(e,
          stackTrace: stackTrace,
          hint: 'Password reset request failed for $email');
      rethrow;
    }
  }

  /// Update password without old password (for reset flow)
  Future<void> setNewPassword(String newPassword) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Not authenticated');

    // Set password in our table
    await _passwordSecurity.setPassword(
      userId: userId,
      password: newPassword,
    );

    // Update Supabase auth
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ============================================================
  // OTP VERIFICATION WITH RATE LIMITING
  // ============================================================

  /// Request OTP for email login with rate limiting
  Future<void> signInWithOtp(String email) async {
    await _checkRateLimit('/auth/otp-request');

    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.verasso://login-callback',
      );
    } catch (e, stackTrace) {
      await SentryService.captureException(e,
          stackTrace: stackTrace, hint: 'OTP request failed for $email');
      rethrow;
    }
  }

  // ============================================================
  // SESSION MANAGEMENT
  // ============================================================

  /// Sign in with email and password (with rate limiting and attempt tracking)
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    // Check rate limit
    await _checkRateLimit('/auth/login');

    // Check if account is locked due to failed attempts
    final canAttempt = await _trackFailedAttempt(email, isSuccessful: false);
    if (!canAttempt) {
      throw const AuthException(
          'Account temporarily locked due to multiple failed attempts');
    }

    try {
      // Attempt login with Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Additional verification with our password table
      if (response.user != null) {
        final isValid = await _passwordSecurity.verifyPassword(
          userId: response.user?.id ?? '',
          password: password,
        );

        if (!isValid) {
          // Password doesn't match our records - possible security issue
          await _supabase.auth.signOut();
          throw const AuthException('Authentication failed');
        }
      }

      // Clear failed attempts on success
      await _clearFailedAttempts(email);

      // Log success to audit trail
      await _auditLog.logEvent(
        type: 'authentication',
        action: 'login_success',
        severity: 'low',
        metadata: {'email': email},
      );

      // Create session record
      if (response.session != null && response.user != null) {
        await _createSession(
          userId: response.user?.id ?? '',
          sessionToken: response.session?.accessToken ?? '',
        );

        // Sync user to Sentry
        await SentryService.syncUserFromSupabase();
      }

      return response;
    } on AuthException catch (e) {
      // Track failed attempt
      await _trackFailedAttempt(email, isSuccessful: false);

      // Log failure to audit trail
      await _auditLog.logEvent(
        type: 'authentication',
        action: 'login_failure',
        severity: 'medium',
        metadata: {'email': email, 'error': e.message},
      );
      rethrow;
    } catch (e, stackTrace) {
      await _trackFailedAttempt(email, isSuccessful: false);

      // Log critical failure to audit trail
      await _auditLog.logEvent(
        type: 'authentication',
        action: 'login_error',
        severity: 'high',
        metadata: {'email': email, 'error': e.toString()},
      );

      await SentryService.captureException(e,
          stackTrace: stackTrace, hint: 'Login failed for $email');
      rethrow;
    }
  }

  /// Sign out and invalidate session
  Future<void> signOut() async {
    final session = _supabase.auth.currentSession;

    if (session != null) {
      // Invalidate session in database
      await _supabase.rpc('invalidate_session', params: {
        'p_session_token': session.accessToken,
      });
    }

    await _supabase.auth.signOut();
  }

  /// Sign up with email and bcrypt-hashed password
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    required String username,
    String? fullName,
    Map<String, dynamic>? metadata,
  }) async {
    // Check rate limit
    await _checkRateLimit('/auth/signup');

    // Validate password strength
    final (isValid, errorMessage) =
        PasswordHashingService.validatePasswordStrength(password);

    if (!isValid) {
      throw AuthException(errorMessage!);
    }

    // Hash password with bcrypt
    final passwordHash = await PasswordHashingService.hashPassword(password);

    try {
      // Sign up with Supabase (still uses their auth, but we hash additionally)
      final response = await _supabase.auth.signUp(
        email: email,
        password: password, // Supabase handles their own hashing
        data: {
          'username': username,
          'full_name': fullName,
          'password_hash_bcrypt': passwordHash, // Store our bcrypt hash
          ...?metadata,
        },
      );

      if (response.user != null) {
        // Store password in our secure table with bcrypt
        await _passwordSecurity.setPassword(
          userId: response.user?.id ?? '',
          password: password,
        );

        // Log password strength
        await _supabase.rpc('log_password_strength', params: {
          'p_user_id': response.user?.id ?? '',
          'p_password': password,
        });

        // Clear any failed attempts
        await _clearFailedAttempts(email);

        // Sync user to Sentry
        await SentryService.setUser(
          userId: response.user?.id ?? '',
          email: email,
          username: username,
        );
      }

      return response;
    } catch (e, stackTrace) {
      await SentryService.captureException(e,
          stackTrace: stackTrace, hint: 'Signup failed for $email');
      throw AuthException('Signup failed: $e');
    }
  }

  // ============================================================
  // SECURITY ANALYTICS
  // ============================================================

  /// Update password with bcrypt (with old password verification)
  Future<UserResponse> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Not authenticated');

    // Use password security service (includes history check)
    await _passwordSecurity.updatePassword(
      userId: userId,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    // Update Supabase auth password
    final response = await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    return response;
  }

  /// Verify OTP with rate limiting
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    await _checkRateLimit('/auth/verify-otp');

    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  /// Check rate limit for endpoint
  Future<void> _checkRateLimit(String endpoint) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final ipAddress = await _ipService.getClientIpAddress();

      final response = await _supabase.rpc('check_rate_limit', params: {
        'p_user_id': userId,
        'p_ip_address': ipAddress,
        'p_endpoint': endpoint,
      });

      final result = response as Map<String, dynamic>;

      if (result['allowed'] == false) {
        final retryAfter = result['retry_after'] as int?;
        throw AuthException(
          'Rate limit exceeded. Try again in ${retryAfter ?? 60} seconds.',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      // If rate limit check fails, allow request (fail open)
    }
  }

  /// Clear failed login attempts
  Future<void> _clearFailedAttempts(String email) async {
    try {
      final ipAddress = await _ipService.getClientIpAddress();

      await _supabase.rpc('clear_failed_login_attempts', params: {
        'p_email': email,
        'p_ip_address': ipAddress,
      });
    } catch (e) {
      // Ignore errors in clearing attempts
    }
  }

  /// Create session record
  Future<void> _createSession({
    required String userId,
    required String sessionToken,
  }) async {
    try {
      final ipAddress = await _ipService.getClientIpAddress();
      final ipInfo = await _ipService.getIpInfo();

      await _supabase.rpc('create_auth_session', params: {
        'p_user_id': userId,
        'p_session_token': sessionToken,
        'p_ip_address': ipAddress,
        'p_user_agent':
            null, // In a real app, use a package like device_info_plus
        'p_device_info': ipInfo ?? {},
        'p_is_new_ip': ipInfo != null, // Simplified logic for demo
      });

      // If IP info indicates a new country/city, trigger alert
      if (ipInfo != null && ipInfo['country_name'] != null) {
        await _supabase.from('security_alerts').insert({
          'user_id': userId,
          'type': 'new_login_location',
          'severity': 'medium',
          'metadata': {
            'ip': ipAddress,
            'location': '${ipInfo['city']}, ${ipInfo['country_name']}',
          }
        });
      }
    } catch (e) {
      // Ignore errors in session creation
    }
  }

  /// Track failed login attempt
  Future<bool> _trackFailedAttempt(String email,
      {required bool isSuccessful}) async {
    if (isSuccessful) return true;

    try {
      final ipAddress = await _ipService.getClientIpAddress();

      final canAttempt = await _supabase.rpc('track_failed_login', params: {
        'p_email': email,
        'p_ip_address': ipAddress,
        'p_user_agent': null,
      }) as bool;

      return canAttempt;
    } catch (e) {
      // If tracking fails, allow attempt (fail open)
      return true;
    }
  }
}
