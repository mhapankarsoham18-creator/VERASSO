import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/simulation_result.dart';

/// Repository for managing simulation results in Supabase.
class SimulationRepository {
  final SupabaseClient _client;

  /// Creates a [SimulationRepository] instance with the provided [SupabaseClient].
  SimulationRepository(this._client);

  /// Fetches simulation results for a specific user and simulation.
  Future<List<SimulationResult>> getResults(String userId, String simId) async {
    final response = await _client
        .from('user_simulation_results')
        .select()
        .eq('user_id', userId)
        .eq('sim_id', simId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SimulationResult.fromJson(json))
        .toList();
  }

  /// Saves a simulation result to the user_simulation_results table.
  Future<void> saveResult(SimulationResult result) async {
    await _client.from('user_simulation_results').insert(result.toJson());
  }
}
