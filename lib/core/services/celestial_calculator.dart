import 'dart:math';

import '../data/constellation_data.dart';

/// Calculate celestial positions based on location, time, and device orientation
/// Utility for calculating celestial positions based on location, time, and device orientation.
class CelestialCalculator {
  /// Convert celestial coordinates (RA/Dec) to horizontal coordinates (Alt/Az)
  /// based on observer's location and time.
  static Map<String, double> equatorialToHorizontal({
    required double rightAscension, // hours (0-24)
    required double declination, // degrees
    required double latitude, // observer's latitude (degrees)
    required double longitude, // observer's longitude (degrees)
    required DateTime time,
  }) {
    // Convert RA to degrees
    final raDegrees = rightAscension * 15.0; // 15 degrees per hour

    // Calculate Local Sidereal Time (LST)
    final lst = _calculateLST(time, longitude);

    // Calculate Hour Angle
    final hourAngle = lst - raDegrees;

    // Convert to radians
    final ha = _degreesToRadians(hourAngle);
    final dec = _degreesToRadians(declination);
    final lat = _degreesToRadians(latitude);

    // Calculate altitude
    final sinAlt = sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(ha);
    final altitude = _radiansToDegrees(asin(sinAlt));

    // Calculate azimuth
    final cosAz =
        (sin(dec) - sin(lat) * sinAlt) / (cos(lat) * cos(asin(sinAlt)));
    var azimuth = _radiansToDegrees(acos(cosAz.clamp(-1.0, 1.0)));

    // Adjust azimuth based on hour angle
    if (sin(ha) > 0) {
      azimuth = 360 - azimuth;
    }

    return {'azimuth': azimuth, 'altitude': altitude};
  }

  /// Get visible celestial objects for current location and time.
  static List<CelestialObject> getVisibleObjects({
    required double latitude,
    required double longitude,
    required DateTime time,
  }) {
    final objects = <CelestialObject>[];

    // Add stars from constellations
    for (final constellation in ConstellationData.constellations.values) {
      for (final star in constellation.stars) {
        final coords = equatorialToHorizontal(
          rightAscension: star.rightAscension,
          declination: star.declination,
          latitude: latitude,
          longitude: longitude,
          time: time,
        );

        // Only include objects above horizon
        if (coords['altitude']! > 0) {
          objects.add(CelestialObject(
            name: '${constellation.name} - ${star.name}',
            azimuth: coords['azimuth']!,
            altitude: coords['altitude']!,
            type: 'star',
          ));
        }
      }
    }

    // Add planets
    for (final planet in ConstellationData.planets.values) {
      final coords = equatorialToHorizontal(
        rightAscension: planet.rightAscension,
        declination: planet.declination,
        latitude: latitude,
        longitude: longitude,
        time: time,
      );

      if (coords['altitude']! > 0) {
        objects.add(CelestialObject(
          name: planet.name,
          azimuth: coords['azimuth']!,
          altitude: coords['altitude']!,
          type: 'planet',
        ));
      }
    }

    return objects;
  }

  /// Convert screen position to azimuth/altitude based on device orientation.
  static Map<String, double> screenToSky({
    required double screenX,
    required double screenY,
    required double screenWidth,
    required double screenHeight,
    required double deviceAzimuth, // From compass
    required double devicePitch, // From accelerometer
    required double fieldOfView, // Camera FOV in degrees
  }) {
    // Normalize screen coordinates to -1 to 1
    final normalizedX = (screenX - screenWidth / 2) / (screenWidth / 2);
    final normalizedY = (screenY - screenHeight / 2) / (screenHeight / 2);

    // Calculate angular offsets
    final azimuthOffset = normalizedX * (fieldOfView / 2);
    final altitudeOffset = -normalizedY * (fieldOfView / 2);

    // Calculate absolute sky coordinates
    final azimuth = (deviceAzimuth + azimuthOffset) % 360;
    final altitude = devicePitch + altitudeOffset;

    return {'azimuth': azimuth, 'altitude': altitude};
  }

  /// Calculates the Local Sidereal Time (LST) for a given [time] and [longitude].
  static double _calculateLST(DateTime time, double longitude) {
    // Simplified LST calculation
    final hourOfDay = time.hour + time.minute / 60.0 + time.second / 3600.0;
    final dayOfYear = time.difference(DateTime(time.year, 1, 1)).inDays;

    // Approximate formula
    final gst = (hourOfDay + dayOfYear * 0.065710) % 24.0;
    final lst = (gst * 15.0 + longitude) % 360.0;

    return lst;
  }

  // Helper methods
  static double _degreesToRadians(double degrees) => degrees * pi / 180.0;
  static double _radiansToDegrees(double radians) => radians * 180.0 / pi;
}
