/// Data model for a celestial object (star, planet, moon, sun).
class CelestialObject {
  final int id;
  final String name;
  final String bayer; // e.g. α Ori
  final String constellation;
  final double ra; // Right Ascension in hours
  final double dec; // Declination in degrees
  final double magnitude; // Apparent magnitude
  final double colorIndex; // B-V color index
  final String type; // star, planet, moon, sun
  final double distanceLy; // Distance in light-years
  final String description;

  // Computed at runtime by SkyEngine
  double altitude = 0; // Degrees above horizon
  double azimuth = 0; // Degrees from north
  double screenX = 0; // Screen pixel position
  double screenY = 0; // Screen pixel position
  bool isVisible = false; // Above horizon?
  bool isDiscovered = false; // Has user tapped it?

  CelestialObject({
    required this.id,
    required this.name,
    this.bayer = '',
    this.constellation = '',
    required this.ra,
    required this.dec,
    required this.magnitude,
    this.colorIndex = 0.0,
    required this.type,
    this.distanceLy = 0,
    this.description = '',
  });

  factory CelestialObject.fromJson(Map<String, dynamic> json) {
    return CelestialObject(
      id: json['id'] as int,
      name: json['name'] as String,
      bayer: json['bayer'] as String? ?? '',
      constellation: json['constellation'] as String? ?? '',
      ra: (json['ra'] as num).toDouble(),
      dec: (json['dec'] as num).toDouble(),
      magnitude: (json['mag'] as num).toDouble(),
      colorIndex: (json['ci'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String,
      distanceLy: (json['dist_ly'] as num?)?.toDouble() ?? 0,
      description: json['desc'] as String? ?? '',
    );
  }

  /// Pixel size based on magnitude (brighter = larger block).
  int get pixelSize {
    if (type == 'sun' || type == 'moon') return 12;
    if (type == 'planet') return 6;
    // Stars: magnitude -1.5 to 3.5 → size 8 to 2
    return (8 - magnitude).clamp(2, 10).round();
  }

  /// Emoji icon for the chat bubble header.
  String get emoji {
    switch (type) {
      case 'sun':
        return '☀️';
      case 'moon':
        return '🌙';
      case 'planet':
        switch (name.toLowerCase()) {
          case 'mercury':
            return '☿️';
          case 'venus':
            return '♀️';
          case 'mars':
            return '♂️';
          case 'jupiter':
            return '♃';
          case 'saturn':
            return '♄';
          case 'uranus':
            return '⛢';
          case 'neptune':
            return '♆';
          default:
            return '🪐';
        }
      default:
        return '⭐';
    }
  }

  /// Short type label for UI.
  String get typeLabel {
    switch (type) {
      case 'sun':
        return 'OUR STAR';
      case 'moon':
        return 'SATELLITE';
      case 'planet':
        return 'PLANET';
      default:
        if (constellation.isNotEmpty) return constellation.toUpperCase();
        return 'STAR';
    }
  }
}
