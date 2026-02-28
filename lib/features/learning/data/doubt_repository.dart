import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/core/services/supabase_service.dart';
import 'package:verasso/features/learning/data/doubt_model.dart';

/// Provider for the [DoubtRepository].
final doubtRepositoryProvider = Provider<DoubtRepository>((ref) {
  return DoubtRepository();
});

/// Repository for managing student doubts, including asking and solving them.
class DoubtRepository {
  final SupabaseClient _client;

  /// Creates a [DoubtRepository] instance.
  DoubtRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Submits a new doubt, optionally with an attached image.
  Future<void> askDoubt({
    required String userId,
    required String title,
    String? description,
    required String subject,
    File? image,
  }) async {
    List<String> imageUrls = [];
    if (image != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_doubt.jpg';
      try {
        await _client.storage
            .from('posts')
            .upload(fileName, image); // Reuse posts bucket or create 'doubts'
        final url = _client.storage.from('posts').getPublicUrl(fileName);
        imageUrls.add(url);
      } catch (e, stack) {
        AppLogger.error('Doubt image upload error', error: e);
        SentryService.captureException(e, stackTrace: stack);
      }
    }

    final doubt = Doubt(
      id: '',
      userId: userId,
      questionTitle: title,
      questionDescription: description,
      subject: subject,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    try {
      await _client.from('doubts').insert(doubt.toJson());
    } catch (e, stack) {
      AppLogger.error('Ask doubt error', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Retrieves doubts, optionally filtered by subject.
  Future<List<Doubt>> getDoubts({String? subject}) async {
    try {
      var query = _client
          .from('doubts')
          .select('*, profiles:user_id(full_name, avatar_url)');

      if (subject != null && subject != 'All') {
        query = query.eq('subject', subject);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((e) => Doubt.fromJson(e)).toList();
    } catch (e, stack) {
      AppLogger.error('Error fetching doubts', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [];
    }
  }

  /// Marks a specific doubt as solved.
  Future<void> markSolved(String doubtId) async {
    try {
      await _client
          .from('doubts')
          .update({'is_solved': true}).eq('id', doubtId);
    } catch (e, stack) {
      AppLogger.error('Mark doubt solved error', error: e);
      SentryService.captureException(e, stackTrace: stack);
    }
  }
}
