import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/supabase_service.dart';

/// Provider for the [DataDeletionService].
final dataDeletionServiceProvider = Provider<DataDeletionService>((ref) {
  return DataDeletionService();
});

/// Service responsible for managing user data deletion and account closure.
/// Required for GDPR compliance and App Store guidelines.
class DataDeletionService {
  final SupabaseClient _client;

  /// Creates a [DataDeletionService].
  DataDeletionService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Permanently deletes the current user's account and all associated data.
  ///
  /// This invokes the `delete_user_account` RPC on Supabase and then signs the user out.
  /// Throws an exception if the process fails.
  Future<void> deleteAccount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated');
    }

    try {
      AppLogger.info('Initiating account deletion for user: $userId');

      // 1. Call the database purge RPC
      await _client.rpc('delete_user_account');

      // 2. Sign out the user immediately
      await _client.auth.signOut();

      AppLogger.info('Account and data purged successfully for user: $userId');
    } catch (e) {
      AppLogger.error('Failed to delete account', error: e);
      rethrow;
    }
  }
}
