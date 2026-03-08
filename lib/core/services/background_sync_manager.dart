import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

import 'network_connectivity_service.dart';
import 'offline_storage_service.dart';
import 'supabase_service.dart';

/// Provider for the [BackgroundSyncManager] instance.
final backgroundSyncManagerProvider = Provider<BackgroundSyncManager>((ref) {
  final network = ref.watch(networkConnectivityServiceProvider);
  final storage = ref.watch(offlineStorageServiceProvider);
  return BackgroundSyncManager(network, storage);
});

/// Manager that orchestrates background data synchronization.
///
/// Listens for network restoration to trigger the synchronization
/// of pending offline actions queued in [OfflineStorageService].
class BackgroundSyncManager {
  final NetworkConnectivityService _networkService;
  final OfflineStorageService _storageService;

  /// Creates a [BackgroundSyncManager] and initializes network listeners.
  BackgroundSyncManager(this._networkService, this._storageService) {
    _init();
  }

  void _init() {
    _networkService.statusStream.listen((status) async {
      if (status == NetworkStatus.online) {
        AppLogger.info("Network restored. Triggering background sync...");
        await _trySync();
      }
    });
  }

  Future<void> _trySync() async {
    try {
      final pending = _storageService.getPendingActionsMap();
      if (pending.isEmpty) {
        AppLogger.debug("No pending actions to sync.");
        return;
      }

      AppLogger.info("Syncing ${pending.length} pending actions...");
      final client = SupabaseService.client;

      for (final entry in pending.entries) {
        final action = Map<String, dynamic>.from(entry.value);
        final type = action['type'] as String;
        final data = Map<String, dynamic>.from(action['data']);
        final retries = (action['retries'] as int?) ?? 0;

        try {
          switch (type) {
            case 'create_project':
              data.remove('temp_id');
              await client.from('projects').insert(data).select().single();
              break;
            case 'create_task':
              await client.from('project_tasks').insert(data);
              break;
            case 'join_project':
              await client
                  .from('project_members')
                  .upsert(data, onConflict: 'project_id,user_id');
              break;
            case 'update_task_status':
              final taskId = data['task_id'];
              final status = data['status'];
              await client
                  .from('project_tasks')
                  .update({'status': status})
                  .eq('id', taskId);
              break;
            default:
              AppLogger.warning("Unknown sync action type: $type");
              continue;
          }
          // Success — remove from queue
          await _storageService.deleteAction(entry.key);
          AppLogger.info("Synced action: $type");
        } catch (e) {
          if (retries >= 3) {
            AppLogger.error("Action $type failed 3 times, discarding.",
                error: e);
            await _storageService.deleteAction(entry.key);
          } else {
            await _storageService.updateActionRetry(entry.key, retries + 1);
            AppLogger.warning("Action $type failed (retry ${retries + 1}/3)",
                error: e);
          }
        }
      }
    } catch (e, stack) {
      AppLogger.error("Background sync failed", error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }
}
