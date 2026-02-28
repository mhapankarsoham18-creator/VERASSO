import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/services/supabase_service.dart';

/// Provider for the [GeospatialDiscoveryService].
final geospatialDiscoveryServiceProvider = Provider((ref) {
  return GeospatialDiscoveryService(ref.watch(supabaseServiceProvider));
});

/// Service for proximity-based user and content discovery using PostGIS.
class GeospatialDiscoveryService {
  /// Creates a [GeospatialDiscoveryService] instance.
  GeospatialDiscoveryService(SupabaseService _);

  /// Finds users within a certain [radiusKm] of [lat], [lng].
  Future<List<Map<String, dynamic>>> findNearbyUsers({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  }) async {
    try {
      // Uses the PostGIS radial search function
      final response = await SupabaseService.client.rpc(
        'find_nearby_users',
        params: {
          'user_lat': lat,
          'user_lng': lng,
          'radius_km': radiusKm,
        },
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('Geospatial: Proximity search failed', error: e);
      return [];
    }
  }

  /// Updates the current user's location in a privacy-safe manner.
  ///
  /// In a production environment, this should add slight jitter to coordinates
  /// to protect exact home/work locations.
  Future<void> updateMyLocation(double lat, double lng) async {
    try {
      // Send location to Supabase - the backend column is a 'geography(POINT, 4326)'
      await SupabaseService.client.from('profiles').update({
        'last_location': 'POINT($lng $lat)',
        'location_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', SupabaseService.client.auth.currentUser?.id ?? '');

      AppLogger.info('Geospatial: Location updated successfully');
    } catch (e) {
      AppLogger.error('Geospatial: Location update failed', error: e);
    }
  }
}
