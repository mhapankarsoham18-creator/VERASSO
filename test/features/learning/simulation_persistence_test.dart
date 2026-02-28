import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/features/learning/domain/simulation_result.dart';

void main() {
  group('Simulation Persistence Verification', () {
    test('Verify SimulationResult model mapping', () {
      final result = SimulationResult(
        id: 'test-id',
        userId: 'user-id',
        simId: 'sim-id',
        category: 'Physics',
        parameters: {'gravity': 9.8},
        results: {'final_velocity': 19.6},
        createdAt: DateTime.now(),
      );

      expect(result.simId, 'sim-id');
      expect(result.parameters['gravity'], 9.8);
      expect(result.results['final_velocity'], 19.6);
      expect(result.category, 'Physics');

      // Verify JSON serialization
      final json = result.toJson();
      expect(json['id'], 'test-id');
      expect(json['simId'], 'sim-id');

      final fromJson = SimulationResult.fromJson(json);
      expect(fromJson.id, result.id);
      expect(fromJson.parameters['gravity'], 9.8);
    });

    // Integration test with real Supabase would go here
  });
}

class MockSupabaseClient extends Mock implements SupabaseClient {}
