// Geospatial Indexing for Nearby User Discovery
// Uses PostGIS for efficient spatial queries

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Represents a specific location with a concentration of user activity.
class ActivityHotspot {
  /// The latitude of the hotspot center.
  final double latitude;

  /// The longitude of the hotspot center.
  final double longitude;

  /// The total number of recorded activities in this area.
  final int activityCount;

  /// The most common interests among users in this area.
  final List<String> topInterests;

  /// The density of activity (0.0-1.0).
  final double density; // 0.0-1.0

  /// Creates an [ActivityHotspot] instance.
  ActivityHotspot({
    required this.latitude,
    required this.longitude,
    required this.activityCount,
    required this.topInterests,
    required this.density,
  });

  /// Creates an [ActivityHotspot] from a JSON map.
  factory ActivityHotspot.fromJson(Map<String, dynamic> json) =>
      ActivityHotspot(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lon'] as num).toDouble(),
        activityCount: json['activity_count'] as int,
        topInterests: List<String>.from(json['top_interests'] as List? ?? []),
        density: (json['density'] as num).toDouble(),
      );
}

/// Service for handling geospatial indexing and nearby user discovery.
class GeospatialService {
  /// The Supabase client used for operations.
  final SupabaseClient _supabase;

  /// Creates a [GeospatialService] instance.
  GeospatialService(this._supabase);

  /// Find users interested in same topics within radius
  Future<List<NearbyUser>> findCollaborators({
    required double latitude,
    required double longitude,
    required List<String> interests,
    required double radiusKm,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.rpc(
        'find_collaborators_nearby',
        params: {
          'user_lat': latitude,
          'user_lon': longitude,
          'interests': interests,
          'radius_km': radiusKm,
          'limit': limit,
        },
      );

      return (response as List)
          .map((user) => NearbyUser.fromJson(user))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Error finding collaborators', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get heatmap of user activity in region
  /// For visualizing community hotspots
  Future<List<ActivityHotspot>> getActivityHeatmap({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    required int cellSize, // meters
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_activity_heatmap',
        params: {
          'min_lat': minLat,
          'max_lat': maxLat,
          'min_lon': minLon,
          'max_lon': maxLon,
          'cell_size': cellSize,
        },
      );

      return (response as List)
          .map((hotspot) => ActivityHotspot.fromJson(hotspot))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Error getting activity heatmap', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get user's current position
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied';
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Stream of user location updates
  Stream<Position> getLocationUpdates({
    int distanceFilter = 100, // meters
    int intervalMillis = 5000,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        timeLimit: Duration(milliseconds: intervalMillis),
      ),
    );
  }

  /// Get nearby users within radius (km)
  /// Uses PostGIS GiST index for O(log n) lookup
  Future<List<NearbyUser>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase.rpc(
        'find_nearby_users',
        params: {
          'user_lat': latitude,
          'user_lon': longitude,
          'radius_km': radiusKm,
          'limit': limit,
        },
      );

      return (response as List)
          .map((user) => NearbyUser.fromJson(user))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Error fetching nearby users', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Update user location in database
  /// Called periodically or on significant location change
  Future<void> updateUserLocation(
    String userId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _supabase.from('user_locations').upsert({
        'user_id': userId,
        'coordinates': 'POINT($longitude $latitude)',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e, stack) {
      AppLogger.error('Error updating user location', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }
}

/// Represents a user found in a nearby geospatial search.
class NearbyUser {
  /// The unique identifier for the user.
  final String id;

  /// The display name of the user.
  final String name;

  /// The URL to the user's avatar image.
  final String avatar;

  /// The distance from the search origin in kilometers.
  final double distance; // in km

  /// A list of interests associated with the user.
  final List<String> interests;

  /// A strength rating for the connection (0-100).
  final int connectionStrength; // 0-100

  /// Whether the user is currently online.
  final bool isOnline;

  /// Creates a [NearbyUser] instance.
  NearbyUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.distance,
    required this.interests,
    required this.connectionStrength,
    required this.isOnline,
  });

  /// Creates a [NearbyUser] from a JSON map.
  factory NearbyUser.fromJson(Map<String, dynamic> json) => NearbyUser(
        id: json['user_id'] as String,
        name: json['display_name'] as String,
        avatar: json['avatar_url'] as String? ?? '',
        distance: (json['distance_km'] as num).toDouble(),
        interests: List<String>.from(json['interests'] as List? ?? []),
        connectionStrength: json['connection_strength'] as int? ?? 0,
        isOnline: json['is_online'] as bool? ?? false,
      );
}
