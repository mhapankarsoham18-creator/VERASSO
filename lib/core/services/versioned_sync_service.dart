import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/services/offline_storage_service.dart';
import 'package:verasso/core/services/supabase_service.dart';

/// Provider for the [VersionedSyncService].
final versionedSyncServiceProvider = Provider((ref) {
  return VersionedSyncService(
    ref.watch(supabaseServiceProvider),
    ref.watch(offlineStorageServiceProvider),
  );
});

/// Represents the outcome of a synchronization attempt.
class SyncResult {
  /// Whether the synchronization was successful.
  final bool isSuccess;

  /// Whether a conflict was detected during synchronization.
  final bool isConflict;

  /// The error message if the synchronization failed.
  final String? error;

  /// The data returned from the synchronization attempt.
  final dynamic data;

  /// Creates a [SyncResult] instance.
  SyncResult({
    required this.isSuccess,
    this.isConflict = false,
    this.error,
    this.data,
  });

  /// Creates a [SyncResult] indicating a conflict.
  factory SyncResult.conflict(dynamic remoteData) =>
      SyncResult(isSuccess: false, isConflict: true, data: remoteData);

  /// Creates a [SyncResult] indicating an error.
  factory SyncResult.error(String message) =>
      SyncResult(isSuccess: false, error: message);

  /// Creates a [SyncResult] indicating a successful sync.
  factory SyncResult.success(int newVersion) =>
      SyncResult(isSuccess: true, data: newVersion);
}

/// Service for managing optimistic concurrency Control (OCC) and sync versioning.
class VersionedSyncService {
  final OfflineStorageService _offlineStorage;

  /// Creates a [VersionedSyncService] instance.
  VersionedSyncService(SupabaseService _, this._offlineStorage);

  /// Synchronizes an entity while checking for version conflicts.
  ///
  /// If the remote version is higher than the local version, it triggers
  /// a conflict resolution state instead of overwriting.
  Future<SyncResult> syncEntity({
    required String table,
    required String id,
    required Map<String, dynamic> localData,
    required int localVersion,
  }) async {
    try {
      // 1. Fetch remote version
      final remoteData = await SupabaseService.client
          .from(table)
          .select('version, last_modified')
          .eq('id', id)
          .single();

      final remoteVersion = remoteData['version'] as int;

      // 2. Conflict Detection
      if (remoteVersion > localVersion) {
        AppLogger.warning(
            'SyncConflict: Version mismatch for $table:$id. Local:$localVersion, Remote:$remoteVersion');
        return SyncResult.conflict(remoteData);
      }

      // 3. Optimistic Update
      final nextVersion = localVersion + 1;
      final updateData = Map<String, dynamic>.from(localData)
        ..['version'] = nextVersion
        ..['last_modified'] = DateTime.now().toIso8601String();

      await SupabaseService.client
          .from(table)
          .update(updateData)
          .eq('id', id)
          .eq('version', localVersion); // Strict OCC

      // 4. Update local storage
      await _offlineStorage.cacheData('sync_$table', updateData);

      return SyncResult.success(nextVersion);
    } catch (e, stack) {
      AppLogger.error('SyncError: Failed to sync $table:$id', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return SyncResult.error(e.toString());
    }
  }
}
