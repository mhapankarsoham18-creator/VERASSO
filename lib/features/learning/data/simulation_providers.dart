import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'simulation_repository.dart';

/// Provider for the [SimulationRepository] instance.
final simulationRepositoryProvider = Provider<SimulationRepository>((ref) {
  final client = ref.watch(simulationSupabaseClientProvider);
  return SimulationRepository(client);
});

/// Provider for the [SupabaseClient] used by simulation services.
final simulationSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
