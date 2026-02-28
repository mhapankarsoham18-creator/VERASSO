import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../monitoring/app_logger.dart';

/// Service for managing secure storage of authentication tokens and session data.
///
/// It strictly adheres to the principle of never storing plaintext passwords.
/// Instead, it uses refresh tokens and session identifiers to maintain
/// persistent authentication, ideally protected by biometric re-verification.
class TokenStorageService {
  static const _refreshTokenKey = 'verasso_refresh_token';
  static const _sessionExpiryKey = 'verasso_session_expiry';

  static const _userIdKey = 'verasso_user_id';

  static const _emailKey = 'verasso_user_email';
  final FlutterSecureStorage _storage;

  /// Creates a [TokenStorageService]. If [storage] is null, uses a default [FlutterSecureStorage].
  TokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Clear all stored tokens and session data
  /// Call this when user logs out or session expires
  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _sessionExpiryKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _emailKey);
      AppLogger.info('All tokens cleared');
    } catch (e) {
      AppLogger.error('Failed to clear tokens', error: e);
    }
  }

  /// Get all stored data (for debugging only - NOT for production)
  @Deprecated('Only use for debugging. Do not expose in production.')
  Future<Map<String, String?>> getAllStoredData() async {
    try {
      return {
        'hasRefreshToken':
            (await _storage.read(key: _refreshTokenKey)) != null ? 'YES' : 'NO',
        'sessionExpiry': await _storage.read(key: _sessionExpiryKey),
        'userId': await _storage.read(key: _userIdKey),
        'email': await _storage.read(key: _emailKey),
      };
    } catch (e) {
      AppLogger.error('Failed to get stored data', error: e);
      return {};
    }
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      AppLogger.error('Failed to read refresh token', error: e);
      return null;
    }
  }

  /// Get saved user email
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _emailKey);
    } catch (e) {
      AppLogger.error('Failed to read email', error: e);
      return null;
    }
  }

  /// Get saved user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      AppLogger.error('Failed to read user ID', error: e);
      return null;
    }
  }

  /// Check if any credentials are stored
  Future<bool> hasStoredCredentials() async {
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      return token != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if session is still valid
  /// Returns true if refresh token exists and hasn't expired
  Future<bool> isSessionValid() async {
    try {
      final expiryString = await _storage.read(key: _sessionExpiryKey);
      if (expiryString == null) {
        return false;
      }

      final expiry = DateTime.parse(expiryString);
      final isValid = DateTime.now().isBefore(expiry);

      if (!isValid) {
        AppLogger.debug('Session has expired');
        await clearTokens();
      }

      return isValid;
    } catch (e) {
      AppLogger.error('Failed to check session validity', error: e);
      return false;
    }
  }

  /// Refresh the session using stored refresh token
  /// This is used to get a new access token without asking for password
  Future<AuthResponse?> refreshSession(SupabaseClient client) async {
    try {
      final token = await getRefreshToken();
      if (token == null) {
        AppLogger.debug('No refresh token available for session refresh');
        return null;
      }

      // Attempt to refresh the session
      final response = await client.auth.refreshSession();

      if (response.session != null) {
        // Update stored refresh token if it changed
        final newRefreshToken = response.session?.refreshToken;
        if (newRefreshToken != null) {
          await saveRefreshToken(newRefreshToken);
        }

        AppLogger.info('Session refreshed successfully');
        return response;
      }
    } catch (e) {
      // Token invalid or expired - clear it
      AppLogger.warning('Session refresh failed', error: e);
      await clearTokens();
    }

    return null;
  }

  /// Save refresh token after successful authentication
  /// This is called after login/signup to store the session token
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      AppLogger.debug('Refresh token saved securely');
    } catch (e) {
      AppLogger.error('Failed to save refresh token', error: e);
      rethrow;
    }
  }

  /// Save session expiry time (usually 1 hour from now)
  Future<void> saveSessionExpiry(DateTime expiry) async {
    try {
      await _storage.write(
        key: _sessionExpiryKey,
        value: expiry.toIso8601String(),
      );
      AppLogger.debug('Session expiry time saved');
    } catch (e) {
      AppLogger.error('Failed to save session expiry', error: e);
      rethrow;
    }
  }

  /// Save user email for reference
  Future<void> saveUserEmail(String email) async {
    try {
      await _storage.write(key: _emailKey, value: email);
    } catch (e) {
      AppLogger.error('Failed to save email', error: e);
    }
  }

  /// Save user ID for reference
  Future<void> saveUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      AppLogger.error('Failed to save user ID', error: e);
    }
  }
}
