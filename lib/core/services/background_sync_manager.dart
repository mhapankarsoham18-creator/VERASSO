import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

import 'network_connectivity_service.dart';
import 'sync_strategy_service.dart';

/// Provider for the [BackgroundSyncManager] instance.
final backgroundSyncManagerProvider = Provider<BackgroundSyncManager>((ref) {
  final network = ref.watch(networkConnectivityServiceProvider);
  final sync = ref.watch(syncStrategyServiceProvider);
  return BackgroundSyncManager(network, sync);
});

/// Manager that orchestrates background data synchronization.
///
/// It listens for network restoration or mesh peer availability to
/// trigger the synchronization of pending offline actions.
class BackgroundSyncManager {
  final NetworkConnectivityService _networkService;
  final SyncStrategyService _syncService;

  /// Creates a [BackgroundSyncManager] and initializes network listeners.
  BackgroundSyncManager(this._networkService, this._syncService) {
    _init();
  }

  void _init() {
    _networkService.statusStream.listen((status) async {
      if (status == NetworkStatus.online) {
        AppLogger.info("Network restored. Triggering background sync...");
        await _trySync();
      }
    });

    // Also trigger sync when Mesh Neighbors are found
    // This allows queuing items while totally offline, then walking near a peer and syncing
    _syncService.meshService.connectedDevicesStream.listen((devices) async {
      if (devices.isNotEmpty) {
        AppLogger.info("Mesh peers found. Triggering mesh sync...");
        await _trySync();
      }
    });
  }

  Future<void> _trySync() async {
    try {
      await _syncService.syncPendingActions();
    } catch (e, stack) {
      AppLogger.error("Background sync failed", error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }
}
