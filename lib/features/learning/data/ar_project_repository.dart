import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'ar_project_model.dart';

/// Provider for the [ArProjectRepository].
final arProjectRepositoryProvider = Provider<ArProjectRepository>((ref) {
  return ArProjectRepository(Supabase.instance.client);
});

/// Repository for managing Augmented Reality (AR) projects, including
/// creation, updates, sharing, and storage of AR components.
class ArProjectRepository {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  /// Creates an [ArProjectRepository] instance.
  ArProjectRepository(this._supabase);

  // ========== PROJECTS ==========

  /// Create a new AR project
  Future<ArProject> createProject({
    required String title,
    String description = '',
    List<ArComponent> components = const [],
    List<ComponentConnection> connections = const [],
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final project = ArProject(
        id: _uuid.v4(),
        userId: userId,
        title: title,
        description: description,
        components: components,
        connections: connections,
        createdAt: now,
        updatedAt: now,
      );

      final response = await _supabase
          .from('ar_projects')
          .insert(project.toJson())
          .select()
          .single();

      return ArProject.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  /// Delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      await _supabase.from('ar_projects').delete().eq('id', projectId);
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }

  /// Get a single component from library
  Future<ComponentLibraryItem> getComponentById(String componentId) async {
    try {
      final response = await _supabase
          .from('ar_project_components')
          .select()
          .eq('id', componentId)
          .single();

      return ComponentLibraryItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load component: $e');
    }
  }

  /// Get all available components from the library
  Future<List<ComponentLibraryItem>> getComponentLibrary() async {
    try {
      final response = await _supabase
          .from('ar_project_components')
          .select()
          .eq('is_active', true)
          .order('category');

      return (response as List)
          .map((json) => ComponentLibraryItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load component library: $e');
    }
  }

  /// Get components by category
  Future<List<ComponentLibraryItem>> getComponentsByCategory(
      String category) async {
    try {
      final response = await _supabase
          .from('ar_project_components')
          .select()
          .eq('category', category)
          .eq('is_active', true);

      return (response as List)
          .map((json) => ComponentLibraryItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load components: $e');
    }
  }

  /// Get a single project by ID
  Future<ArProject> getProject(String projectId) async {
    try {
      final response = await _supabase
          .from('ar_projects')
          .select()
          .eq('id', projectId)
          .single();

      return ArProject.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load project: $e');
    }
  }

  /// Get users who have access to a project
  Future<List<Map<String, dynamic>>> getProjectShares(String projectId) async {
    try {
      final response = await _supabase
          .from('ar_project_shares')
          .select('shared_with, can_edit, can_remix, shared_at')
          .eq('project_id', projectId);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to load project shares: $e');
    }
  }

  // ========== COMPONENT LIBRARY ==========

  /// Get public projects
  Future<List<ArProject>> getPublicProjects(
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase.rpc('get_public_ar_projects', params: {
        'limit_param': limit,
        'offset_param': offset,
      });

      // Transform the response to ArProject objects
      return (response as List).map((json) {
        return ArProject.fromJson({
          'id': json['id'],
          'user_id': json['creator_id'],
          'title': json['title'],
          'description': json['description'],
          'thumbnail_url': json['thumbnail_url'],
          'project_data': {},
          'simulation_state': null,
          'is_public': true,
          'shared_with_friends': false,
          'created_at': json['created_at'],
          'updated_at': json['created_at'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to load public projects: $e');
    }
  }

  /// Get projects shared with the current user
  Future<List<SharedArProject>> getSharedProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase.rpc('get_friend_ar_projects', params: {
        'user_id_param': userId,
      });

      return (response as List)
          .map((json) => SharedArProject.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load shared projects: $e');
    }
  }

  /// Get all projects created by the current user
  Future<List<ArProject>> getUserProjects() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('ar_projects')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ArProject.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load projects: $e');
    }
  }

  // ========== SHARING ==========

  /// Make project public
  Future<void> makeProjectPublic(String projectId, bool isPublic) async {
    try {
      await _supabase
          .from('ar_projects')
          .update({'is_public': isPublic}).eq('id', projectId);
    } catch (e) {
      throw Exception('Failed to update project visibility: $e');
    }
  }

  /// Remix (copy) a shared project to own collection
  Future<ArProject> remixProject(String projectId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Load the original project
      final original = await getProject(projectId);

      // Create a new project with copied data
      final now = DateTime.now();
      final remixed = ArProject(
        id: _uuid.v4(),
        userId: userId,
        title: '${original.title} (Remix)',
        description: original.description,
        components: original.components,
        connections: original.connections,
        lastSimulation: original.lastSimulation,
        createdAt: now,
        updatedAt: now,
      );

      final response = await _supabase
          .from('ar_projects')
          .insert(remixed.toJson())
          .select()
          .single();

      return ArProject.fromJson(response);
    } catch (e) {
      throw Exception('Failed to remix project: $e');
    }
  }

  /// Save project with simulation results
  Future<ArProject> saveProjectWithSimulation(
    ArProject project,
    SimulationResult simulation,
  ) async {
    final updated = project.copyWith(lastSimulation: simulation);
    return updateProject(updated);
  }

  /// Share a project with a friend
  Future<void> shareProjectWithFriend(
      String projectId, String friendUserId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('ar_project_shares').insert({
        'id': _uuid.v4(),
        'project_id': projectId,
        'shared_by': userId,
        'shared_with': friendUserId,
        'can_edit': false,
        'can_remix': true,
        'shared_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to share project: $e');
    }
  }

  /// Unshare a project
  Future<void> unshareProject(String projectId, String friendUserId) async {
    try {
      await _supabase
          .from('ar_project_shares')
          .delete()
          .eq('project_id', projectId)
          .eq('shared_with', friendUserId);
    } catch (e) {
      throw Exception('Failed to unshare project: $e');
    }
  }

  /// Update an existing project
  Future<ArProject> updateProject(ArProject project) async {
    try {
      final updatedProject = project.copyWith(updatedAt: DateTime.now());

      final response = await _supabase
          .from('ar_projects')
          .update(updatedProject.toJson())
          .eq('id', project.id)
          .select()
          .single();

      return ArProject.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  /// Upload project thumbnail
  Future<String> uploadThumbnail(String projectId, File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final fileName =
          '$projectId-thumbnail-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'ar_projects/$userId/$fileName';

      await _supabase.storage.from('project-assets').upload(path, imageFile);

      final url = _supabase.storage.from('project-assets').getPublicUrl(path);

      // Update project with thumbnail URL
      await _supabase
          .from('ar_projects')
          .update({'thumbnail_url': url}).eq('id', projectId);

      return url;
    } catch (e) {
      throw Exception('Failed to upload thumbnail: $e');
    }
  }
}
