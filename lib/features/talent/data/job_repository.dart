import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/supabase_service.dart';

/// Provider for the [JobRepository] instance.
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(SupabaseService.client);
});

/// Repository for managing job requests and applications.
class JobRepository {
  final SupabaseClient _client;

  /// Creates a [JobRepository] instance.
  JobRepository(this._client);

  /// Creates a new job request in Supabase.
  Future<void> createJob({
    required String creatorId,
    required String title,
    required String description,
    required List<String> tags,
    double? budget,
  }) async {
    try {
      await _client.from('job_requests').insert({
        'creator_id': creatorId,
        'title': title,
        'description': description,
        'tags': tags,
        'budget': budget,
        'status': 'open',
      });
      AppLogger.info('Job created successfully: $title');
    } catch (e) {
      AppLogger.error('Failed to create job', error: e);
      rethrow;
    }
  }

  /// Applies for a specific job.
  Future<void> applyForJob({
    required String jobId,
    required String talentId,
    required String proposal,
  }) async {
    try {
      await _client.from('job_applications').insert({
        'job_id': jobId,
        'talent_id': talentId,
        'proposal': proposal,
        'status': 'applied',
      });
      AppLogger.info('Applied for job $jobId successfully');
    } catch (e) {
      AppLogger.error('Failed to apply for job', error: e);
      rethrow;
    }
  }
}
