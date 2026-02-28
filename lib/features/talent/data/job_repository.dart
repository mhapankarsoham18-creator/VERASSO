import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/services/supabase_service.dart';

import '../../../core/mesh/models/mesh_packet.dart';
import '../../../core/services/bluetooth_mesh_service.dart';
import '../../../core/services/network_connectivity_service.dart';
import '../../../core/services/offline_storage_service.dart';
import 'job_model.dart';

/// Provider for the [JobRepository] instance.
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  final network = ref.watch(networkConnectivityServiceProvider);
  final storage = ref.watch(offlineStorageServiceProvider);
  final mesh = ref.watch(bluetoothMeshServiceProvider);
  return JobRepository(SupabaseService.client, network, storage, mesh);
});

/// Repository for managing job requests, applications, and reviews.
class JobRepository {
  final SupabaseClient _client;
  final NetworkConnectivityService _networkService;
  final OfflineStorageService _storageService;
  final BluetoothMeshService _meshService;

  /// Creates a [JobRepository].
  JobRepository(this._client, this._networkService, this._storageService,
      this._meshService);

  /// Submits a job application.
  ///
  /// [jobId] is the ID of the job to apply for.
  /// [userId] is the ID of the applicant.
  /// [message] is the application message.
  Future<void> applyForJob(String jobId, String userId, String message) async {
    final myId = userId;

    final data = {
      'job_id': jobId,
      'talent_id': myId,
      'message': message,
      'status': 'pending',
    };

    if (_meshService.isMeshActive) {
      await _storageService.queueAction('apply_for_job', data);
      await _meshService.broadcastPacket(
          MeshPayloadType.chatMessage, {'action': 'apply_for_job', ...data});
      return;
    }

    if (await _networkService.isConnected) {
      try {
        await _client.from('job_applications').insert(data);
      } catch (e, stack) {
        AppLogger.error('Apply for job error', error: e);
        SentryService.captureException(e, stackTrace: stack);
        throw Exception('Failed to apply for job: $e');
      }
    } else {
      await _storageService.queueAction('apply_for_job', data);
    }
  }

  // --- Payment Processing ---

  /// Completes a job and processes the payment.
  ///
  /// [jobId] is the ID of the job to complete.
  /// [amount] is the payment amount.
  Future<void> completeJobAndProcessPayment(String jobId, double amount) async {
    if (!await _networkService.isConnected) {
      throw Exception("Internet connection required for payments");
    }
    try {
      await updateJobStatus(jobId, 'completed');
    } catch (e, stack) {
      AppLogger.error('Failed to complete job', error: e);
      SentryService.captureException(e, stackTrace: stack);
      throw Exception('Failed to complete job: $e');
    }
  }

  /// Creates a new job request.
  Future<void> createJobRequest(JobRequest request) async {
    if (_meshService.isMeshActive) {
      await _storageService.queueAction('create_job', request.toJson());
      await _meshService.broadcastPacket(MeshPayloadType.feedPost,
          {'action': 'create_job', ...request.toJson()});
      return;
    }

    if (await _networkService.isConnected) {
      try {
        await _client.from('job_requests').insert(request.toJson());
      } catch (e, stack) {
        AppLogger.error('Create job request error', error: e);
        SentryService.captureException(e, stackTrace: stack);
        throw Exception('Failed to create job request: $e');
      }
    } else {
      await _storageService.queueAction('create_job', request.toJson());
    }
  }

  /// Fetches applications for a specific job.
  Future<List<JobApplication>> getApplicationsForJob(String jobId) async {
    final String cacheKey = 'job_applications_$jobId';

    if (await _networkService.isConnected) {
      try {
        final response = await _client
            .from('job_applications')
            .select('*, profiles(full_name, avatar_url)')
            .eq('job_id', jobId);

        await _storageService.cacheData(cacheKey, response);
        return (response as List)
            .map((json) => JobApplication.fromJson(json))
            .toList();
      } catch (e, stack) {
        AppLogger.error("Network error getApplicationsForJob", error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    }

    final cachedData = _storageService.getCachedData(cacheKey);
    if (cachedData != null) {
      return (cachedData as List)
          .map((json) => JobApplication.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Fetches all open job requests with pagination support.
  Future<List<JobRequest>> getJobRequests(
      {int limit = 20, int offset = 0}) async {
    final String cacheKey = 'job_requests_open_${limit}_$offset';

    if (await _networkService.isConnected) {
      try {
        final response = await _client
            .from('job_requests')
            .select('*, profiles(full_name, avatar_url)')
            .eq('status', 'open')
            .order('is_featured', ascending: false)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        await _storageService.cacheData(cacheKey, response);
        return (response as List)
            .map((json) => JobRequest.fromJson(json))
            .toList();
      } catch (e, stack) {
        AppLogger.error("Network error getJobRequests", error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    }

    final cachedData = _storageService.getCachedData(cacheKey);
    if (cachedData != null) {
      return (cachedData as List)
          .map((json) => JobRequest.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Fetches job requests posted by the current user.
  Future<List<JobRequest>> getMyJobRequests(String userId) async {
    final String cacheKey = 'my_jobs_$userId';

    if (await _networkService.isConnected) {
      try {
        final response = await _client
            .from('job_requests')
            .select('*, profiles(full_name, avatar_url)')
            .eq('client_id', userId)
            .order('created_at', ascending: false);

        await _storageService.cacheData(cacheKey, response);
        return (response as List)
            .map((json) => JobRequest.fromJson(json))
            .toList();
      } catch (e, stack) {
        AppLogger.error("Network error getMyJobRequests", error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    }

    final cachedData = _storageService.getCachedData(cacheKey);
    if (cachedData != null) {
      return (cachedData as List)
          .map((json) => JobRequest.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Fetches reviews received by a user.
  Future<List<JobReview>> getReviewsForUser(String userId) async {
    final String cacheKey = 'reviews_$userId';

    if (await _networkService.isConnected) {
      try {
        final response = await _client
            .from('job_reviews')
            .select('*')
            .eq('reviewee_id', userId)
            .order('created_at', ascending: false);

        await _storageService.cacheData(cacheKey, response);
        return (response as List)
            .map((json) => JobReview.fromJson(json))
            .toList();
      } catch (e, stack) {
        AppLogger.error("Network error getReviewsForUser", error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    }

    final cachedData = _storageService.getCachedData(cacheKey);
    if (cachedData != null) {
      return (cachedData as List)
          .map((json) => JobReview.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Fetches job applications sent by the current user.
  Future<List<JobApplication>> getSentApplications(String userId) async {
    final myId = userId;
    final String cacheKey = 'sent_apps_$myId';

    if (await _networkService.isConnected) {
      try {
        final response = await _client
            .from('job_applications')
            .select('*, job_requests(title, budget, currency)')
            .eq('talent_id', myId)
            .order('created_at', ascending: false);

        await _storageService.cacheData(cacheKey, response);
        return (response as List).map((json) {
          return JobApplication.fromJson(json);
        }).toList();
      } catch (e, stack) {
        AppLogger.error("Network error getSentApplications", error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    }

    final cachedData = _storageService.getCachedData(cacheKey);
    if (cachedData != null) {
      return (cachedData as List).map((json) {
        return JobApplication.fromJson(json);
      }).toList();
    }
    return [];
  }

  /// Submits a review for a completed job.
  Future<void> submitReview(JobReview review) async {
    if (await _networkService.isConnected) {
      try {
        await _client.from('job_reviews').insert(review.toJson());
      } catch (e, stack) {
        AppLogger.error('Submit review error', error: e);
        SentryService.captureException(e, stackTrace: stack);
        throw Exception('Failed to submit review: $e');
      }
    }
  }

  /// Updates the status of a job application.
  Future<void> updateApplicationStatus(String appId, String status) async {
    if (await _networkService.isConnected) {
      try {
        await _client
            .from('job_applications')
            .update({'status': status}).eq('id', appId);
      } catch (e, stack) {
        AppLogger.error('Update application status error', error: e);
        SentryService.captureException(e, stackTrace: stack);
        throw Exception('Failed to update application status: $e');
      }
    }
  }

  /// Updates the status of a job request.
  Future<void> updateJobStatus(String jobId, String status) async {
    if (await _networkService.isConnected) {
      try {
        await _client
            .from('job_requests')
            .update({'status': status}).eq('id', jobId);
      } catch (e, stack) {
        AppLogger.error('Update job status error', error: e);
        SentryService.captureException(e, stackTrace: stack);
        throw Exception('Failed to update job status: $e');
      }
    }
  }
}
