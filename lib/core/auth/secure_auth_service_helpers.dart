part of 'secure_auth_service.dart';

/// Helper extension for [SecureAuthService] to provide additional security status checks.
extension SecureAuthServiceHelpers on SecureAuthService {
  /// Get password security service
  UserPasswordSecurityService get passwordSecurity => _passwordSecurity;

  /// Get user security status
  Future<Map<String, dynamic>> getUserSecurityStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    return await _passwordSecurity.getSecurityStatus(userId);
  }

  /// Check if password is expired
  Future<bool> isPasswordExpired() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    return await _passwordSecurity.isPasswordExpired(userId);
  }
}
