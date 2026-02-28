/// Represents a record of a celestial observation.
class StargazingLog {
  /// Unique identifier of the log.
  final String id;

  /// The ID of the user who made the observation.
  final String userId;

  /// The name of the celestial object observed (e.g., "Mars", "Andromeda Galaxy").
  final String celestialObject;

  /// The type of equipment used (e.g., "Telescope", "Binoculars", "Naked Eye").
  final String equipmentType;

  /// The name of the location where the observation took place.
  final String? locationName;

  /// A rating of the sky conditions (1 to 5).
  final int skyRating;

  /// Additional notes about the observation.
  final String? notes;

  /// Optional URL to a photo or media captured during the observation.
  final String? mediaUrl;

  /// The date and time when the log was created.
  final DateTime createdAt;

  // Joined profile data
  /// The display name of the creator (optional, populated via joins).
  final String? creatorName;

  /// The avatar URL of the creator (optional, populated via joins).
  final String? creatorAvatar;

  /// Creates a [StargazingLog].
  StargazingLog({
    required this.id,
    required this.userId,
    required this.celestialObject,
    required this.equipmentType,
    this.locationName,
    required this.skyRating,
    this.notes,
    this.mediaUrl,
    required this.createdAt,
    this.creatorName,
    this.creatorAvatar,
  });

  /// Creates a [StargazingLog] from a JSON-compatible map.
  factory StargazingLog.fromJson(Map<String, dynamic> json) {
    return StargazingLog(
      id: json['id'],
      userId: json['user_id'],
      celestialObject: json['celestial_object'],
      equipmentType: json['equipment_type'] ?? 'Naked Eye',
      locationName: json['location_name'],
      skyRating: json['sky_rating'] ?? 3,
      notes: json['notes'],
      mediaUrl: json['media_url'],
      createdAt: DateTime.parse(json['created_at']),
      creatorName:
          json['profiles'] != null ? json['profiles']['full_name'] : null,
      creatorAvatar:
          json['profiles'] != null ? json['profiles']['avatar_url'] : null,
    );
  }

  /// Converts this [StargazingLog] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'celestial_object': celestialObject,
      'equipment_type': equipmentType,
      'location_name': locationName,
      'sky_rating': skyRating,
      'notes': notes,
      'media_url': mediaUrl,
    };
  }
}
