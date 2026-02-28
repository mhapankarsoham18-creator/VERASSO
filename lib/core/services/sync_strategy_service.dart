import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/services/network_connectivity_service.dart';
import 'package:verasso/core/services/offline_storage_service.dart';

import '../mesh/models/mesh_packet.dart';

/// Provider for the [SyncStrategyService] instance.
final syncStrategyServiceProvider = Provider<SyncStrategyService>((ref) {
  final network = ref.watch(networkConnectivityServiceProvider);
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  final storage = ref.watch(offlineStorageServiceProvider);
  return SyncStrategyService(network, mesh, storage, Supabase.instance.client);
});

/// Defines the available data synchronization strategies.
enum SyncMode {
  /// Optimal connection (WiFi), supports high-bandwidth realtime sync.
  realtime,

  /// Limited connection, supports compressed delta updates.
  compressed,

  /// Local proximity connection via Bluetooth mesh.
  mesh,

  /// No connection, data is queued locally.
  offline,
}

/// Service that orchestrates data synchronization across different network conditions.
///
/// It determines the best [SyncMode] and manages the resolution of pending offline actions.
class SyncStrategyService {
  final NetworkConnectivityService _networkService;
  final BluetoothMeshService _meshService;
  final OfflineStorageService _storageService;
  final SupabaseClient _supabaseClient;

  /// Creates a [SyncStrategyService] with required dependencies.
  SyncStrategyService(this._networkService, this._meshService,
      this._storageService, this._supabaseClient);

  /// Access to the underlying [BluetoothMeshService].
  BluetoothMeshService get meshService => _meshService;

  // Called by UI/Repos to send data to Mesh directly (if applicable)
  // This bypasses the "Queue" if we want realtime mesh, or we can queue for mesh too.
  // For "Every feature works on mesh", we want immediate broadcast.
  /// Directly broadcasts a [payload] of a specific [type] to the mesh network.
  Future<void> broadcastToMesh(
      MeshPayloadType type, Map<String, dynamic> payload) async {
    await _meshService.broadcastPacket(type, payload);
  }

  /// Evaluates current network conditions to determine the optimal [SyncMode].
  Future<SyncMode> determineSyncMode() async {
    // Priority 1: Mesh (User Request: "Mesh Primary if active")
    // If mesh is active, we consider it "Mesh Mode", though we might still background sync to cloud.
    if (_meshService.isMeshActive) {
      return SyncMode.mesh;
    }

    // Priority 2: WiFi/Mobile
    final isConnected = await _networkService.isConnected;
    if (isConnected) {
      return SyncMode.realtime;
    }

    // Priority 3: Offline
    return SyncMode.offline;
  }

  /// Attempts to synchronize all locally queued pending actions based on current [SyncMode].
  Future<void> syncPendingActions() async {
    final mode = await determineSyncMode();
    if (mode == SyncMode.offline) return;

    final pendingMap = _storageService.getPendingActionsMap();
    if (pendingMap.isEmpty) return;

    // Process queue
    for (final key in pendingMap.keys) {
      final action = pendingMap[key];
      try {
        final processedType = await _processAction(action, mode);

        // If we synced to Cloud (Realtime), we remove it.
        // If we only broadcasted to Mesh, we KEEP it in queue for later Cloud sync.
        if (processedType == SyncMode.realtime) {
          await _storageService.deleteAction(key);
        } else if (processedType == SyncMode.mesh) {
          // Sent to Mesh successfully. Keep in queue for Cloud.
          // Optimization: Could flag it as "Mesh Sent" to avoid re-broadcasting.
          // For now, simple keeping.
        }
      } catch (e, stack) {
        AppLogger.error('Sync failed for action $key', error: e);
        SentryService.captureException(e, stackTrace: stack);
        break;
      }
    }
  }

  // Returns the mode used to process (Mesh or Realtime)
  Future<SyncMode> _processAction(
      Map<dynamic, dynamic> action, SyncMode currentMode) async {
    final type = action['type'];
    final data = action['data'] as Map<dynamic, dynamic>;
    final supabase = _supabaseClient;

    if (currentMode == SyncMode.mesh) {
      // Broadcast pending item to Mesh
      MeshPayloadType meshType = MeshPayloadType.scienceData; // Default
      if (type == 'create_project' || type == 'create_job') {
        meshType = MeshPayloadType.feedPost;
      }
      if (type == 'apply_for_job') meshType = MeshPayloadType.chatMessage;
      if (type == 'toggle_mentor_status') {
        meshType = MeshPayloadType.profileSync;
      }

      await _meshService.broadcastPacket(meshType, {'action': type, ...data});
      return SyncMode.mesh;
    }

    // Otherwise, Realtime Sync to Cloud
    if (type == 'create_project') {
      final cleanData = Map<String, dynamic>.from(data)..remove('temp_id');
      try {
        final response =
            await supabase.from('projects').insert(cleanData).select().single();
        final realId = response['id'];
        if (cleanData.containsKey('leader_id')) {
          await supabase.from('project_members').insert({
            'project_id': realId,
            'user_id': cleanData['leader_id'],
            'role': 'Leader',
          });
        }
      } catch (e, stack) {
        AppLogger.error("Conflict/Error creating project", error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    } else if (type == 'create_task') {
      await supabase
          .from('project_tasks')
          .insert(Map<String, dynamic>.from(data));
    } else if (type == 'update_task_status') {
      final taskId = data['task_id'];
      final status = data['status'];
      final currentTask = await supabase
          .from('project_tasks')
          .select('updated_at, status')
          .eq('id', taskId)
          .maybeSingle();
      if (currentTask != null && currentTask['status'] == status) {
        return SyncMode.realtime;
      }

      await supabase.from('project_tasks').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
    } else if (type == 'toggle_mentor_status') {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase
            .from('profiles')
            .update({'is_alumni_mentor': data['is_open']}).eq('id', userId);
      }
    } else if (type == 'create_job') {
      await supabase
          .from('job_requests')
          .insert(Map<String, dynamic>.from(data));
    } else if (type == 'apply_for_job') {
      final myId = supabase.auth.currentUser?.id;
      if (myId != null) {
        final jobData = Map<String, dynamic>.from(data);
        jobData['talent_id'] = myId;
        await supabase.from('job_applications').insert(jobData);
      }
    }
    // Classroom Actions
    else if (type == 'start_session') {
      final sessionData = Map<String, dynamic>.from(data);
      sessionData['host_id'] =
          supabase.auth.currentUser?.id; // Ensure auth host
      await supabase.from('classroom_sessions').insert({
        'id': sessionData['id'],
        'host_id': sessionData['host_id'],
        'subject': sessionData['subject'],
        'topic': sessionData['topic'],
        'created_at': sessionData['createdAt']
      });
    } else if (type == 'publish_poll') {
      final pollData = Map<String, dynamic>.from(data);
      await supabase.from('session_polls').insert({
        'id': pollData['id'],
        'session_id': pollData['sessionId'],
        'question': pollData['question'],
        'options': pollData['options'],
      });
    } else if (type == 'raise_doubt') {
      final doubtData = Map<String, dynamic>.from(data);
      await supabase.from('session_doubts').insert({
        'session_id': doubtData['sessionId'],
        'user_id': supabase.auth.currentUser?.id,
        'question': doubtData['question']
      });
    }

    return SyncMode.realtime;
  }
}
