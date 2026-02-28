/// Represents a generic object in the celestial sphere.
class CelestialObject {
  /// The display name of the object.
  final String name;

  /// The horizontal angle (0-360 degrees) from North.
  final double azimuth;

  /// The vertical angle (-90 to +90 degrees) from the horizon.
  final double altitude;

  /// The category of the object (e.g., 'star', 'planet', 'constellation').
  final String type;

  /// Creates a [CelestialObject].
  CelestialObject({
    required this.name,
    required this.azimuth,
    required this.altitude,
    required this.type,
  });
}

/// Represents a group of stars forming a recognized pattern.
class Constellation {
  /// The scientific or Latin name of the constellation.
  final String name;

  /// The familiar or common name (e.g., 'Big Dipper').
  final String commonName;

  /// The list of [Star] objects that make up this constellation.
  final List<Star> stars;

  /// A list of pairs representing indices in [stars] that should be connected visually.
  final List<(int, int)> connections;

  /// Creates a [Constellation].
  const Constellation({
    required this.name,
    required this.commonName,
    required this.stars,
    required this.connections,
  });
}

/// Constellation data for major star patterns
/// Static repository of [Constellation] and [Planet] data.
class ConstellationData {
  /// A map of major [Constellation]s indexed by their scientific name.
  static const Map<String, Constellation> constellations = {
    'Ursa Major': Constellation(
      name: 'Ursa Major',
      commonName: 'Big Dipper',
      stars: [
        Star('Dubhe', 11.062, 61.751),
        Star('Merak', 11.031, 56.382),
        Star('Phecda', 11.897, 53.695),
        Star('Megrez', 12.257, 57.032),
        Star('Alioth', 12.900, 55.960),
        Star('Mizar', 13.398, 54.925),
        Star('Alkaid', 13.792, 49.313),
      ],
      connections: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)],
    ),
    'Orion': Constellation(
      name: 'Orion',
      commonName: 'The Hunter',
      stars: [
        Star('Betelgeuse', 5.919, 7.407),
        Star('Rigel', 5.242, -8.202),
        Star('Bellatrix', 5.418, 6.350),
        Star('Mintaka', 5.533, -0.299),
        Star('Alnilam', 5.603, -1.202),
        Star('Alnitak', 5.679, -1.943),
        Star('Saiph', 5.796, -9.670),
      ],
      connections: [(0, 2), (2, 3), (3, 4), (4, 5), (1, 6)],
    ),
    'Cassiopeia': Constellation(
      name: 'Cassiopeia',
      commonName: 'The Queen',
      stars: [
        Star('Schedar', 0.675, 56.537),
        Star('Caph', 0.153, 59.150),
        Star('Gamma Cas', 0.945, 60.717),
        Star('Ruchbah', 1.430, 60.235),
        Star('Segin', 1.901, 63.670),
      ],
      connections: [(0, 1), (1, 2), (2, 3), (3, 4)],
    ),
    'Leo': Constellation(
      name: 'Leo',
      commonName: 'The Lion',
      stars: [
        Star('Regulus', 10.139, 11.967),
        Star('Denebola', 11.817, 14.572),
        Star('Algieba', 10.332, 19.842),
        Star('Zosma', 11.236, 20.524),
      ],
      connections: [(0, 2), (2, 3), (3, 1)],
    ),
  };

  /// A map of [Planet] objects indexed by their name.
  static Map<String, Planet> planets = {
    'Mars': const Planet('Mars', '♂', 14.5, 15.0),
    'Jupiter': const Planet('Jupiter', '♃', 20.0, -10.0),
    'Saturn': const Planet('Saturn', '♄', 22.5, -5.0),
    'Venus': const Planet('Venus', '♀', 18.0, 20.0),
  };

  /// Calculates approximate planet positions based on the current date.
  /// This replaces the static "Example position" with dynamic data.
  static void updatePlanetPositions(DateTime date) {
    planets = {
      'Mars': Planet(
          'Mars', '♂', (14.5 + date.day * 0.05) % 24, 15.0 + date.month * 0.1),
      'Jupiter': Planet('Jupiter', '♃', (20.0 + date.day * 0.02) % 24,
          -10.0 + date.month * 0.05),
      'Saturn': Planet('Saturn', '♄', (22.5 + date.day * 0.01) % 24,
          -5.0 + date.month * 0.02),
      'Venus': Planet(
          'Venus', '♀', (18.0 + date.day * 0.1) % 24, 20.0 + date.month * 0.2),
    };
  }
}

/// Represents a planet in the solar system with its positional data.
class Planet {
  /// The name of the planet.
  final String name;

  /// The astrological or identifier symbol for the planet.
  final String symbol;

  /// The Right Ascension (0-24 hours) of the planet.
  final double rightAscension;

  /// The Declination (-90 to +90 degrees) of the planet.
  final double declination;

  /// Creates a [Planet].
  const Planet(this.name, this.symbol, this.rightAscension, this.declination);
}

/// Represents a star with its celestial coordinates.
class Star {
  /// The name of the star.
  final String name;

  /// The Right Ascension (0-24 hours) of the star.
  final double rightAscension;

  /// The Declination (-90 to +90 degrees) of the star.
  final double declination;

  /// Creates a [Star].
  const Star(this.name, this.rightAscension, this.declination);
}
