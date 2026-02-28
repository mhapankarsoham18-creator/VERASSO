import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/supabase_service.dart';

/// Provider for the [SharedCounterService].
final sharedCounterServiceProvider = Provider((ref) {
  return SharedCounterService(ref.watch(supabaseServiceProvider));
});

/// Service for managing distributed atomic counters with thundering herd prevention.
class SharedCounterService {
  final Map<String, Completer<int>> _pendingRequests = {};

  /// Creates a [SharedCounterService] instance.
  SharedCounterService(SupabaseService _);

  /// Gets the current value of a shared counter.
  Future<int> getValue(String counterName) async {
    try {
      final response = await SupabaseService.client
          .from('shared_counters')
          .select('current_value')
          .eq('name', counterName)
          .single();

      return response['current_value'] as int;
    } catch (e) {
      AppLogger.warning(
          'SharedCounter: Could not fetch value for $counterName, defaulting to 0');
      return 0;
    }
  }

  /// Increments a shared counter identified by [counterName].
  ///
  /// Uses a coordinated wait (Completer) to prevent multiple simultaneous
  /// requests for the same counter from hitting the backend (Thundering Herd).
  Future<int> increment(String counterName) async {
    // Check if there is already a pending request for this counter
    if (_pendingRequests.containsKey(counterName)) {
      AppLogger.info('SharedCounter: Coordinated wait for $counterName');
      return _pendingRequests[counterName]!.future;
    }

    final completer = Completer<int>();
    _pendingRequests[counterName] = completer;

    try {
      // Execute the RPC for atomic increment
      // Assuming a Supabase function 'increment_counter' exists
      final response = await SupabaseService.client.rpc(
        'increment_shared_counter',
        params: {'counter_name': counterName},
      );

      final newValue = response as int;
      completer.complete(newValue);
      return newValue;
    } catch (e) {
      AppLogger.error('SharedCounter: Failed to increment $counterName',
          error: e);
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(counterName);
    }
  }
}
