import 'dart:math';

/// Pure Dart astronomical calculations.
/// No external astronomy library — all math is self-contained.
class SkyMath {
  static const double _deg2rad = pi / 180.0;
  static const double _rad2deg = 180.0 / pi;
  static const double _hours2deg = 15.0; // 1 hour RA = 15 degrees

  /// Convert a UTC DateTime to Julian Date.
  static double julianDate(DateTime utc) {
    int y = utc.year;
    int m = utc.month;
    final double d = utc.day +
        utc.hour / 24.0 +
        utc.minute / 1440.0 +
        utc.second / 86400.0;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }

    final int a = y ~/ 100;
    final int b = 2 - a + (a ~/ 4);

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  /// Greenwich Mean Sidereal Time in degrees from Julian Date.
  static double gmst(double jd) {
    final double t = (jd - 2451545.0) / 36525.0;
    double gmst = 280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        (t * t * t) / 38710000.0;
    return _normalize(gmst, 360.0);
  }

  /// Local Sidereal Time in degrees.
  static double localSiderealTime(double jd, double longitudeDeg) {
    return _normalize(gmst(jd) + longitudeDeg, 360.0);
  }

  /// Convert equatorial (RA hours, Dec degrees) to horizontal (altitude, azimuth)
  /// for a given observer latitude and local sidereal time.
  /// Returns [altitude, azimuth] in degrees.
  static List<double> equatorialToHorizontal(
      double raHours, double decDeg, double latDeg, double lstDeg) {
    final double raDeg = raHours * _hours2deg;
    final double ha = _normalize(lstDeg - raDeg, 360.0) * _deg2rad;
    final double dec = decDeg * _deg2rad;
    final double lat = latDeg * _deg2rad;

    // Altitude
    final double sinAlt =
        sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(ha);
    final double alt = asin(sinAlt.clamp(-1.0, 1.0));

    // Azimuth
    final double cosAz =
        (sin(dec) - sin(alt) * sin(lat)) / (cos(alt) * cos(lat));
    double az = acos(cosAz.clamp(-1.0, 1.0));
    if (sin(ha) > 0) az = 2 * pi - az;

    return [alt * _rad2deg, az * _rad2deg];
  }

  /// Simplified Sun position (ecliptic longitude approach).
  /// Returns [RA hours, Dec degrees].
  static List<double> sunPosition(double jd) {
    final double n = jd - 2451545.0;
    final double l = _normalize(280.460 + 0.9856474 * n, 360.0);
    final double g = _normalize(357.528 + 0.9856003 * n, 360.0) * _deg2rad;
    final double lambda =
        (l + 1.915 * sin(g) + 0.020 * sin(2 * g)) * _deg2rad;

    // Obliquity of ecliptic
    final double epsilon = 23.439 * _deg2rad;

    final double ra =
        atan2(cos(epsilon) * sin(lambda), cos(lambda)) * _rad2deg;
    final double dec = asin(sin(epsilon) * sin(lambda)) * _rad2deg;

    return [_normalize(ra, 360.0) / _hours2deg, dec];
  }

  /// Simplified Moon position.
  /// Returns [RA hours, Dec degrees].
  static List<double> moonPosition(double jd) {
    final double t = (jd - 2451545.0) / 36525.0;

    // Mean elements
    final double l0 = _normalize(218.3165 + 481267.8813 * t, 360.0);
    final double m = _normalize(134.9634 + 477198.8676 * t, 360.0) * _deg2rad;
    final double mSun =
        _normalize(357.5291 + 35999.0503 * t, 360.0) * _deg2rad;
    final double d = _normalize(297.8502 + 445267.1115 * t, 360.0) * _deg2rad;
    final double f = _normalize(93.2720 + 483202.0175 * t, 360.0) * _deg2rad;

    // Longitude correction
    double longitude = l0 +
        6.289 * sin(m) -
        1.274 * sin(2 * d - m) +
        0.658 * sin(2 * d) +
        0.214 * sin(2 * m) -
        0.186 * sin(mSun) -
        0.114 * sin(2 * f);

    // Latitude
    double latitude = 5.128 * sin(f) +
        0.281 * sin(m + f) -
        0.278 * sin(f - m) -
        0.173 * sin(2 * d - f);

    longitude = longitude * _deg2rad;
    latitude = latitude * _deg2rad;

    final double epsilon = 23.439 * _deg2rad;

    final double ra = atan2(
            sin(longitude) * cos(epsilon) - tan(latitude) * sin(epsilon),
            cos(longitude)) *
        _rad2deg;
    final double dec = asin(sin(latitude) * cos(epsilon) +
            cos(latitude) * sin(epsilon) * sin(longitude)) *
        _rad2deg;

    return [_normalize(ra, 360.0) / _hours2deg, dec];
  }

  /// Simplified planetary position using mean orbital elements.
  /// Returns [RA hours, Dec degrees] or null if planet not supported.
  static List<double>? planetPosition(String planet, double jd) {
    final double n = jd - 2451545.0;
    final double t = n / 36525.0;

    // Mean ecliptic longitudes (simplified)
    double? lambda;
    switch (planet.toLowerCase()) {
      case 'mercury':
        lambda = _normalize(252.251 + 149472.675 * t, 360.0);
        break;
      case 'venus':
        lambda = _normalize(181.980 + 58517.816 * t, 360.0);
        break;
      case 'mars':
        lambda = _normalize(355.433 + 19140.299 * t, 360.0);
        break;
      case 'jupiter':
        lambda = _normalize(34.351 + 3034.906 * t, 360.0);
        break;
      case 'saturn':
        lambda = _normalize(50.077 + 1222.114 * t, 360.0);
        break;
      case 'uranus':
        lambda = _normalize(314.055 + 428.947 * t, 360.0);
        break;
      case 'neptune':
        lambda = _normalize(304.349 + 218.486 * t, 360.0);
        break;
      default:
        return null;
    }

    final double lambdaRad = lambda * _deg2rad;
    final double epsilon = 23.439 * _deg2rad;

    // Assume ecliptic latitude ≈ 0 for simplified calculation
    final double ra =
        atan2(cos(epsilon) * sin(lambdaRad), cos(lambdaRad)) * _rad2deg;
    final double dec = asin(sin(epsilon) * sin(lambdaRad)) * _rad2deg;

    return [_normalize(ra, 360.0) / _hours2deg, dec];
  }

  /// Moon phase (0 = new, 0.5 = full, 1 = new again).
  static double moonPhase(double jd) {
    final double t = (jd - 2451545.0) / 29.53059;
    return t - t.floor();
  }

  /// Normalize a value to [0, range).
  static double _normalize(double value, double range) {
    double result = value % range;
    if (result < 0) result += range;
    return result;
  }
}
