import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import 'learning_models.dart';

/// Provider for the [StudyRepository] instance.
final studyRepositoryProvider = Provider((ref) => StudyRepository());

/// Repository for managing study groups and learning resources.
class StudyRepository {
  final SupabaseClient _client;

  /// Creates a [StudyRepository] instance.
  StudyRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Creates a new study group.
  Future<void> createStudyGroup(StudyGroup group) async {
    await _client.from('study_groups').insert(group.toJson());
  }

  /// Retrieves the IDs of all study groups the current user is a member of.
  Future<List<String>> getMyGroupIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);

    return (response as List)
        .map((json) => json['group_id'] as String)
        .toList();
  }

  // --- Resources ---

  /// Retrieves learning resources, optionally filtered by subject or group.
  Future<List<LearningResource>> getResources(
      {String? subject, String? groupId}) async {
    var query = _client.from('learning_resources').select('*');
    if (subject != null) query = query.eq('subject', subject);
    if (groupId != null) query = query.eq('group_id', groupId);

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => LearningResource.fromJson(json))
        .toList();
  }

  // --- Study Groups ---

  /// Retrieves study groups, optionally filtered by subject.
  Future<List<StudyGroup>> getStudyGroups({String? subject}) async {
    var query = _client.from('study_groups').select('*');
    if (subject != null) {
      query = query.eq('subject', subject);
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => StudyGroup.fromJson(json)).toList();
  }

  /// Joins a specific study group as a member.
  Future<void> joinGroup(String groupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
      'role': 'member',
    });
  }

  /// Uploads a new learning resource.
  Future<void> uploadResource(LearningResource resource) async {
    await _client.from('learning_resources').insert(resource.toJson());
  }
}
