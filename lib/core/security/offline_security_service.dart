import 'package:shared_preferences/shared_preferences.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Service responsible for handling offline-first identity persistence.
///
/// It manages non-sensitive hints about the user's identity (like email)
/// to improve the offline experience and allow for smoother transitions
/// when the user returns to an online state.
class OfflineSecurityService {
  static const String _kIdentityHintKey = 'offline_identity_hint';
  static const String _kLastUserEmailKey = 'last_known_user_email';

  /// Remove the hint (on logout)
  Future<void> clearIdentityHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIdentityHintKey);
    await prefs.remove(_kLastUserEmailKey);
    AppLogger.info('Offline identity hint cleared');
  }

  /// Get the last known user email
  Future<String?> getLastKnownEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastUserEmailKey);
  }

  /// Check if a hint exists
  Future<bool> hasIdentityHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIdentityHintKey) ?? false;
  }

  /// Store a hint that the user has a valid authenticated session
  /// This doesn't store the session but allows local access to cached content
  Future<void> setIdentityHint(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIdentityHintKey, true);
    await prefs.setString(_kLastUserEmailKey, email);
    AppLogger.info('Offline identity hint established for $email');
  }
}
