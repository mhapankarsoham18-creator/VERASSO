// Shared Counter System for Thundering Herd Problem
// Backend: Supabase RLS + PostgreSQL Transactions

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Service for handling shared counters and thundering herd prevention.
class SharedCounterService {
  /// The Supabase client instance.
  final SupabaseClient _supabase;

  /// Creates a [SharedCounterService] instance.
  SharedCounterService(this._supabase);

  /// Check if rate limit exceeded using counter
  /// Returns true if within limit, false if exceeded
  Future<bool> checkRateLimit(
    String userId,
    String action,
    int maxRequests,
    Duration window,
  ) async {
    final counterId = '${userId}_${action}_${_getWindowKey(window)}';
    final currentCount = await getCounterValue(counterId);
    return currentCount < maxRequests;
  }

  /// Decrement counter atomically
  Future<int> decrementCounter(String counterId, {int amount = 1}) async {
    try {
      final result = await _supabase.rpc(
        'decrement_shared_counter',
        params: {
          'counter_id': counterId,
          'decrement_amount': amount,
        },
      );
      return result as int;
    } catch (e, stack) {
      AppLogger.error('Error decrementing shared counter', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get current counter value with optimistic read
  Future<int> getCounterValue(String counterId) async {
    try {
      final response = await _supabase
          .from('shared_counters')
          .select('value')
          .eq('id', counterId)
          .single();
      return response['value'] as int;
    } catch (e, stack) {
      AppLogger.error('Error getting shared counter value', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Atomically increment counter with advisory lock
  /// Returns the new value
  Future<int> incrementCounter(String counterId, {int amount = 1}) async {
    try {
      final result = await _supabase.rpc(
        'increment_shared_counter',
        params: {
          'counter_id': counterId,
          'increment_amount': amount,
        },
      );
      return result as int;
    } catch (e, stack) {
      AppLogger.error('Error incrementing shared counter', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Initialize counter with atomic increment
  /// Prevents thundering herd by using advisory locks
  Future<void> initCounter(String counterId, {int initialValue = 0}) async {
    try {
      await _supabase.rpc('init_shared_counter', params: {
        'counter_id': counterId,
        'initial_value': initialValue,
      });
    } catch (e, stack) {
      AppLogger.error('Error initializing shared counter', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Increment rate limit counter
  Future<void> recordAction(
    String userId,
    String action,
    Duration window,
  ) async {
    final counterId = '${userId}_${action}_${_getWindowKey(window)}';
    await incrementCounter(counterId);
  }

  /// Gets a unique key for the given time window.
  String _getWindowKey(Duration window) {
    final now = DateTime.now();
    final windowSeconds = window.inSeconds;
    final windowStart = now.subtract(window);
    return '${windowStart.millisecondsSinceEpoch ~/ windowSeconds}';
  }
}
