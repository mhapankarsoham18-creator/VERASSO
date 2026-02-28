import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../core/mesh/models/mesh_packet.dart';
import '../../../core/services/bluetooth_mesh_service.dart';
import '../../../core/services/network_connectivity_service.dart';
import '../../../core/services/offline_storage_service.dart';
import 'project_model.dart';

/// Provider for the [ProjectRepository] instance.
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final network = ref.watch(networkConnectivityServiceProvider);
  final storage = ref.watch(offlineStorageServiceProvider);
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return ProjectRepository(Supabase.instance.client, network, storage, mesh);
});

/// Repository for managing collaborative projects, tasks, and memberships.
/// Supports offline synchronization and mesh network communication.
class ProjectRepository {
  final SupabaseClient _client;
  final NetworkConnectivityService _networkService;
  final OfflineStorageService _storageService;
  final BluetoothMeshService _meshService;

  /// Creates a [ProjectRepository] instance.
  ProjectRepository(this._client, this._networkService, this._storageService,
      this._meshService);

  // 1. Create Project
  /// Creates a new collaborative project.
  Future<void> createProject({
    required String leaderId,
    required String title,
    required String description,
  }) async {
    final Map<String, dynamic> projectData = {
      'leader_id': leaderId,
      'title': title,
      'description': description,
    };

    // PRIMARY: Mesh Network
    if (_meshService.isMeshActive) {
      await _storageService.queueAction('create_project', {
        ...projectData,
        'temp_id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      await _meshService.broadcastPacket(MeshPayloadType.feedPost,
          {'action': 'create_project', ...projectData});
      return;
    }

    if (await _networkService.isConnected) {
      // Fallback: Direct Cloud
      final response =
          await _client.from('projects').insert(projectData).select().single();
      final projectId = response['id'];

      await _client.from('project_members').insert({
        'project_id': projectId,
        'user_id': leaderId,
        'role': 'Leader',
      });
    } else {
      // Offline
      await _storageService.queueAction('create_project', {
        ...projectData,
        'temp_id': DateTime.now().millisecondsSinceEpoch.toString(),
      });
    }
  }

  /// Creates a new task within a project.
  Future<void> createTask(String projectId, String title) async {
    final data = {
      'project_id': projectId,
      'title': title,
      'status': 'Todo',
    };

    if (_meshService.isMeshActive) {
      await _storageService.queueAction('create_task', data);
      await _meshService.broadcastPacket(
          MeshPayloadType.scienceData, {'action': 'create_task', ...data});
      return;
    }

    if (await _networkService.isConnected) {
      await _client.from('project_tasks').insert(data);
    } else {
      await _storageService.queueAction('create_task', data);
    }
  }

  // 2. Fetch My Projects
  /// Retrieves projects associated with a specific user.
  Future<List<Project>> getMyProjects(String userId) async {
    const String cacheKey = 'my_projects';

    if (await _networkService.isConnected) {
      try {
        final memberships = await _client
            .from('project_members')
            .select('project_id')
            .eq('user_id', userId);
        final projectIds =
            (memberships as List).map((e) => e['project_id']).toList();

        if (projectIds.isEmpty) {
          await _storageService.cacheData(cacheKey, []);
          return [];
        }

        final response = await _client
            .from('projects')
            .select('*, profiles:leader_id(full_name, avatar_url)')
            .inFilter('id', projectIds)
            .neq('status', 'Shipped')
            .order('created_at', ascending: false);

        final projects =
            (response as List).map((json) => Project.fromJson(json)).toList();
        await _storageService.cacheData(cacheKey, response);
        return projects;
      } catch (e) {
        AppLogger.info("Network fetch failed: $e, falling back to cache");
      }
    }

    final cachedData = _storageService.getCachedData(cacheKey);
    if (cachedData != null) {
      return (cachedData as List)
          .map((json) => Project.fromJson(json))
          .toList();
    }
    return [];
  }

  // 3. Fetch Shipped Projects
  /// Retrieves all open projects that are looking for team members.
  /// Returns projects with status 'In Progress' or 'Planning', excluding
  /// projects the user is already a member of.
  Future<List<Project>> getOpenProjects(String userId) async {
    try {
      // Get IDs of projects user already belongs to
      final memberships = await _client
          .from('project_members')
          .select('project_id')
          .eq('user_id', userId);
      final myProjectIds =
          (memberships as List).map((e) => e['project_id'] as String).toList();

      var query = _client
          .from('projects')
          .select('*, profiles:leader_id(full_name, avatar_url)')
          .neq('status', 'Shipped')
          .order('created_at', ascending: false)
          .limit(20);

      final response = await query;
      final allProjects =
          (response as List).map((json) => Project.fromJson(json)).toList();

      // Filter out projects user is already in
      return allProjects.where((p) => !myProjectIds.contains(p.id)).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch open projects', error: e);
      return [];
    }
  }

  /// Retrieves all projects that have been marked as 'Shipped'.
  Future<List<Project>> getShippedProjects() async {
    final response = await _client
        .from('projects')
        .select('*, profiles:leader_id(full_name, avatar_url)')
        .eq('status', 'Shipped')
        .order('updated_at', ascending: false);

    return (response as List).map((json) => Project.fromJson(json)).toList();
  }

  /// Retrieves all tasks for a specific project.
  Future<List<ProjectTask>> getTasks(String projectId) async {
    final String cacheKey = 'tasks_$projectId';

    if (await _networkService.isConnected) {
      try {
        final response = await _client
            .from('project_tasks')
            .select('*, profiles:assigned_to(full_name, avatar_url)')
            .eq('project_id', projectId);

        await _storageService.cacheData(cacheKey, response);
        return (response as List)
            .map((json) => ProjectTask.fromJson(json))
            .toList();
      } catch (e) {
        AppLogger.info("Network error getTasks: $e");
      }
    }

    final cachedData = _storageService.getCachedData(cacheKey);
    if (cachedData != null) {
      return (cachedData as List)
          .map((json) => ProjectTask.fromJson(json))
          .toList();
    }
    return [];
  }

  // 4. Tasks
  /// Request to join a project team with a specific role.
  Future<void> joinProject(String projectId, String userId, String role) async {
    final data = {
      'project_id': projectId,
      'user_id': userId,
      'role': role,
    };

    if (_meshService.isMeshActive) {
      await _storageService.queueAction('join_project', data);
      await _meshService.broadcastPacket(
          MeshPayloadType.feedPost, {'action': 'join_project', ...data});
      return;
    }

    if (await _networkService.isConnected) {
      await _client.from('project_members').upsert(
            data,
            onConflict: 'project_id,user_id',
          );
    } else {
      await _storageService.queueAction('join_project', data);
    }
  }

  /// Updates the status of a specific task.
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    final data = {'task_id': taskId, 'status': newStatus};

    if (_meshService.isMeshActive) {
      await _storageService.queueAction('update_task_status', data);
      await _meshService.broadcastPacket(MeshPayloadType.scienceData,
          {'action': 'update_task_status', ...data});
      return;
    }

    if (await _networkService.isConnected) {
      await _client
          .from('project_tasks')
          .update({'status': newStatus}).eq('id', taskId);
    } else {
      await _storageService.queueAction('update_task_status', data);
    }
  }
}
