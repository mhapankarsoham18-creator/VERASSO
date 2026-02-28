import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/services/network_connectivity_service.dart';
import 'package:verasso/core/services/offline_storage_service.dart';
import 'package:verasso/core/services/supabase_service.dart';
import 'package:verasso/core/services/versioned_sync_service.dart';
import 'package:verasso/features/learning/data/doubt_repository.dart';
import 'package:verasso/features/messaging/data/message_repository.dart';
import 'package:verasso/features/notifications/data/notification_service.dart';
import 'package:verasso/features/notifications/models/notification_model.dart';
import 'package:verasso/features/social/data/feed_repository.dart';
import 'package:verasso/features/talent/data/job_model.dart';
import 'package:verasso/features/talent/data/job_repository.dart';

/// Provider for the [SyncBridgeService] instance.
final syncBridgeServiceProvider = Provider((ref) {
  final service = SyncBridgeService(ref);
  // Proactively initialize
  service.initialize();
  return service;
});

/// Service that bridges the Bluetooth Mesh network and the Supabase Cloud.
///
/// It listens for incoming mesh packets and uplinks them to Supabase if the
/// device has internet connectivity. It also triggers synchronization of
/// pending offline actions when the device comes back online.
class SyncBridgeService {
  final Ref _ref;
  StreamSubscription? _meshSubscription;
  StreamSubscription? _networkSubscription;
  NetworkStatus _lastStatus = NetworkStatus.offline;

  /// Creates a [SyncBridgeService] with the provided Riverpod [Ref].
  SyncBridgeService(this._ref);

  /// Cancels all active subscriptions.
  void dispose() {
    _meshSubscription?.cancel();
    _networkSubscription?.cancel();
  }

  /// Initializes the service by subscribing to mesh and network streams.
  void initialize() {
    _meshSubscription = _ref
        .read(bluetoothMeshServiceProvider)
        .meshStream
        .listen(_onMeshPacket);
    _networkSubscription = _ref
        .read(networkConnectivityServiceProvider)
        .statusStream
        .listen(_onNetworkStatusChanged);
    AppLogger.info('SyncBridgeService initialized');
  }

  Future<void> _onMeshPacket(MeshPacket packet) async {
    final isOnline =
        await _ref.read(networkConnectivityServiceProvider).isConnected;
    if (!isOnline) return;

    // Bridge node logic: Forward important data to Supabase
    await _uplinkPacket(packet);
  }

  Future<void> _onNetworkStatusChanged(NetworkStatus status) async {
    if (status == NetworkStatus.online &&
        _lastStatus == NetworkStatus.offline) {
      AppLogger.info('Network came online, starting pending actions sync');
      await _syncPendingActions();
    }
    _lastStatus = status;
  }

  Future<void> _processAction(Map<String, dynamic> action) async {
    final type = action['type'];
    final data = Map<String, dynamic>.from(action['data']);

    switch (type) {
      case 'send_message':
        await _ref.read(messageRepositoryProvider).sendMessage(
              senderId: data['senderId'],
              receiverId: data['receiverId'],
              content: data['content'],
              mediaType: data['mediaType'] ?? 'text',
            );
        break;
      case 'create_post':
        await _ref.read(feedRepositoryProvider).createPost(
              userId: data['userId'],
              content: data['content'],
              tags: List<String>.from(data['tags'] ?? []),
            );
        break;
      case 'ask_doubt':
        await _ref.read(doubtRepositoryProvider).askDoubt(
              userId: data['userId'],
              title: data['title'],
              description: data['description'],
              subject: data['subject'],
            );
        break;
      case 'apply_for_job':
        await _ref.read(jobRepositoryProvider).applyForJob(
              data['job_id'],
              data['talent_id'],
              data['message'],
            );
        break;
      case 'create_job':
        await _ref
            .read(jobRepositoryProvider)
            .createJobRequest(JobRequest.fromJson(data));
        break;
      default:
        AppLogger.warning('Unknown pending action type: $type');
    }
  }

  void _showSyncNotification(String table, String id) {
    AppLogger.info('SyncBridge: Background sync completed for $table:$id');
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId != null) {
      _ref.read(notificationServiceProvider).createNotification(
        targetUserId: userId,
        type: NotificationType.system,
        title: 'Sync Complete',
        body: 'Your $table update has been synchronized successfully.',
        data: {'table': table, 'id': id},
      );
    }
  }

  Future<void> _syncPendingActions() async {
    final storage = _ref.read(offlineStorageServiceProvider);
    final actions = storage.getPendingActionsMap();
    if (actions.isEmpty) return;

    AppLogger.info('Syncing ${actions.length} pending actions');

    for (var entry in actions.entries) {
      final key = entry.key;
      final action = Map<String, dynamic>.from(entry.value);
      final table = action['table'] as String?;
      final id = action['id'] as String?;
      final localVersion = action['version'] as int? ?? 1;

      try {
        if (table != null && id != null) {
          final syncService = _ref.read(versionedSyncServiceProvider);
          final result = await syncService.syncEntity(
            table: table,
            id: id,
            localData: Map<String, dynamic>.from(action['data']),
            localVersion: localVersion,
          );

          if (result.isConflict) {
            AppLogger.warning(
                'SyncBridge: Conflict detected for $table:$id. Resolving via strategy...');
            // In a real app, this would trigger a UI prompt or use a conflict resolution strategy
            // For now, we'll mark it for manual resolution or keep it as pending
            continue;
          }
          _showSyncNotification(table, id);
        } else {
          await _processAction(action);
        }
        await storage.deleteAction(key);
      } catch (e, stack) {
        AppLogger.error('Failed to sync pending action $key', error: e);
        SentryService.captureException(e, stackTrace: stack);
        final retries = (action['retries'] ?? 0) + 1;
        if (retries > 3) {
          AppLogger.warning('Max retries reached for action $key. Discarding.');
          await storage.deleteAction(key);
        } else {
          await storage.updateActionRetry(key, retries);
        }
      }
    }
  }

  Future<void> _uplinkPacket(MeshPacket packet) async {
    try {
      final payload = packet.payload;
      switch (packet.type) {
        case MeshPayloadType.chatMessage:
          if (payload['action'] == 'apply_for_job') {
            await _ref.read(jobRepositoryProvider).applyForJob(
                  payload['job_id'],
                  packet.senderId,
                  payload['message'],
                );
            AppLogger.info('Uplinked mesh job application: ${packet.id}');
          } else {
            await _ref.read(messageRepositoryProvider).sendMessage(
                  senderId: packet.senderId,
                  receiverId: payload['receiverId'],
                  content: payload['content'],
                  mediaType: payload['mediaType'] ?? 'text',
                );
            AppLogger.info('Uplinked mesh chat message: ${packet.id}');
          }
          break;
        case MeshPayloadType.feedPost:
          if (payload['action'] == 'create_job') {
            await _ref
                .read(jobRepositoryProvider)
                .createJobRequest(JobRequest.fromJson(payload));
            AppLogger.info('Uplinked mesh job request: ${packet.id}');
          } else {
            await _ref.read(feedRepositoryProvider).createPost(
                  userId: packet.senderId,
                  content: payload['content'],
                  tags: List<String>.from(payload['tags'] ?? []),
                );
            AppLogger.info('Uplinked mesh feed post: ${packet.id}');
          }
          break;
        case MeshPayloadType.doubtPost:
          await _ref.read(doubtRepositoryProvider).askDoubt(
                userId: packet.senderId,
                title: payload['title'],
                description: payload['description'],
                subject: payload['subject'],
              );
          AppLogger.info('Uplinked mesh doubt post: ${packet.id}');
          break;
        default:
          break;
      }
    } catch (e, stack) {
      AppLogger.error('Failed to uplink mesh packet ${packet.id}', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }
}
