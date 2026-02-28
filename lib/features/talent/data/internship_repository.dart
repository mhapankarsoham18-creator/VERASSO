import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import '../data/job_model.dart'; // To fetch Job Requests
import 'internship_model.dart';

/// Provider for the [InternshipRepository] instance.
final internshipRepositoryProvider = Provider<InternshipRepository>((ref) {
  return InternshipRepository(Supabase.instance.client);
});

/// Repository for managing internships and contracts.
class InternshipRepository {
  final SupabaseClient _client;

  /// Creates an [InternshipRepository].
  InternshipRepository(this._client);

  // 1. Fetch Internship Opportunities
  /// Creates a new internship contract.
  Future<void> createContract(InternshipContract contract) async {
    try {
      await _client.from('internship_contracts').insert(contract.toJson());
    } catch (e) {
      AppLogger.error('Failed to create internship contract', error: e);
      rethrow;
    }
  }

  // 2. Hire a Project Team (Create Contract)
  /// Fetches contracts associated with a specific project.
  Future<List<InternshipContract>> getContractsForProject(
      String projectId) async {
    try {
      final response = await _client
          .from('internship_contracts')
          .select('*')
          .eq('project_id', projectId);

      return (response as List)
          .map((json) => InternshipContract.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get contracts for project', error: e);
      return [];
    }
  }

  // 3. Get Contracts for a Project
  /// Fetches open internship listings.
  Future<List<JobRequest>> getInternshipListings() async {
    try {
      final response = await _client
          .from('job_requests')
          .select('*, profiles(full_name, avatar_url)')
          .eq('job_type', 'Internship')
          .eq('status', 'open')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => JobRequest.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get internship listings', error: e);
      return [];
    }
  }
}
