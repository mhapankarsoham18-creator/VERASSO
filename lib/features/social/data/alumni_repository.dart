import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../../../core/mesh/models/mesh_packet.dart';
import '../../../core/services/bluetooth_mesh_service.dart';
import '../../../core/services/network_connectivity_service.dart';
import '../../../core/services/offline_storage_service.dart';
import '../../auth/data/user_profile_model.dart';

/// Provider for the [AlumniRepository].
final alumniRepositoryProvider = Provider<AlumniRepository>((ref) {
  final network = ref.watch(networkConnectivityServiceProvider);
  final storage = ref.watch(offlineStorageServiceProvider);
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return AlumniRepository(Supabase.instance.client, network, storage, mesh);
});

/// Repository for managing alumni-user interactions, mentoring, and course-based lists.
class AlumniRepository {
  final SupabaseClient _client;
  final NetworkConnectivityService _networkService;
  final OfflineStorageService _storageService;
  final BluetoothMeshService _meshService;

  /// Creates an [AlumniRepository] instance.
  AlumniRepository(this._client, this._networkService, this._storageService,
      this._meshService);

  // 1. Get Alumni for a specific Course
  /// Retrieves a list of alumni who completed a specific course, with offline caching support.
  Future<List<Map<String, dynamic>>> getAlumniForCourse(String courseId) async {
    final String cacheKey = 'alumni_course_$courseId';

    if (await _networkService.isConnected) {
      try {
        final response = await _client
            .from('view_course_alumni')
            .select()
            .eq('course_id', courseId)
            .order('completion_date', ascending: false);

        await _storageService.cacheData(cacheKey, response);
        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        AppLogger.info("Network error getAlumniForCourse: $e");
      }
    }

    final cachedData = _storageService.getCachedData(cacheKey);
    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(cachedData);
    }
    return [];
  }

  // 2. Get Global Alumni Mentors (Directory)
  /// Retrieves user profiles for alumni who have opted in as mentors.
  Future<List<UserProfile>> getAlumniMentors() async {
    const String cacheKey = 'alumni_mentors';

    if (await _networkService.isConnected) {
      try {
        final response = await _client
            .from('profiles')
            .select()
            .eq('is_alumni_mentor', true)
            .limit(50); // Pagination in real app

        await _storageService.cacheData(cacheKey, response);
        return (response as List)
            .map((json) => UserProfile.fromJson(json))
            .toList();
      } catch (e) {
        AppLogger.info("Network error getAlumniMentors: $e");
      }
    }

    final cachedData = _storageService.getCachedData(cacheKey);
    if (cachedData != null) {
      return (cachedData as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    }
    return [];
  }

  // 3. Toggle Mentor Status
  /// Toggles whether the current user is active as an alumni mentor, supporting both cloud and mesh syncing.
  Future<void> toggleAlumniMentorStatus(bool isOpen) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    if (_meshService.isMeshActive) {
      await _storageService.queueAction('toggle_mentor_status', {
        'is_open': isOpen,
      });
      await _meshService.broadcastPacket(MeshPayloadType.profileSync,
          {'userId': userId, 'is_alumni_mentor': isOpen});
      return;
    }

    if (await _networkService.isConnected) {
      await _client
          .from('profiles')
          .update({'is_alumni_mentor': isOpen}).eq('id', userId);
    } else {
      await _storageService.queueAction('toggle_mentor_status', {
        'is_open': isOpen,
      });
    }
  }
}
