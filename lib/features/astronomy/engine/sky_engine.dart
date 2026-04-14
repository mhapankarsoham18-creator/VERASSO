import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/celestial_object.dart';
import 'sky_math.dart';

/// Core orchestrator: loads star catalog, computes positions,
/// projects to screen coordinates.
class SkyEngine {
  List<CelestialObject> _catalog = [];
  List<List<int>> _constellationLines = [];
  bool _isLoaded = false;

  // Observer state
  double latitude = 0;
  double longitude = 0;
  double compassHeading = 0; // degrees from north
  double devicePitch = 45; // degrees above horizon the phone is pointing

  // Screen dimensions
  double screenWidth = 0;
  double screenHeight = 0;

  // Field of view in degrees
  double fovHorizontal = 90;
  double fovVertical = 120;

  bool get isLoaded => _isLoaded;
  List<CelestialObject> get catalog => _catalog;

  /// Load star catalog and constellation lines from bundled JSON assets.
  Future<void> loadCatalog() async {
    if (_isLoaded) return;

    try {
      // Load stars
      final starJson =
          await rootBundle.loadString('assets/astro/star_catalog.json');
      final List<dynamic> starList = json.decode(starJson);
      _catalog = starList
          .map((e) => CelestialObject.fromJson(e as Map<String, dynamic>))
          .toList();

      // Load constellation lines
      final constJson =
          await rootBundle.loadString('assets/astro/constellation_lines.json');
      final Map<String, dynamic> constData = json.decode(constJson);
      final List<dynamic> constellations = constData['constellations'];
      _constellationLines = [];
      for (final c in constellations) {
        final lines = c['lines'] as List<dynamic>;
        for (final line in lines) {
          final pair = (line as List<dynamic>).map((e) => e as int).toList();
          if (pair.length == 2 && pair[0] != pair[1]) {
            _constellationLines.add(pair);
          }
        }
      }

      _isLoaded = true;
    } catch (e) {
      // Fail silently — catalog will be empty
      _isLoaded = true;
    }
  }

  /// Get constellation line pairs as star ID pairs.
  List<List<int>> get constellationLines => _constellationLines;

  /// Update all object positions based on current observer state.
  /// Call this every frame (or at ~30fps).
  void updatePositions() {
    final now = DateTime.now().toUtc();
    final jd = SkyMath.julianDate(now);
    final lst = SkyMath.localSiderealTime(jd, longitude);

    for (final obj in _catalog) {
      double ra = obj.ra;
      double dec = obj.dec;

      // For solar system objects, compute real-time positions
      if (obj.type == 'sun') {
        final pos = SkyMath.sunPosition(jd);
        ra = pos[0];
        dec = pos[1];
      } else if (obj.type == 'moon') {
        final pos = SkyMath.moonPosition(jd);
        ra = pos[0];
        dec = pos[1];
      } else if (obj.type == 'planet') {
        final pos = SkyMath.planetPosition(obj.name, jd);
        if (pos != null) {
          ra = pos[0];
          dec = pos[1];
        }
      }

      // Convert to horizontal coordinates
      final altAz = SkyMath.equatorialToHorizontal(ra, dec, latitude, lst);
      obj.altitude = altAz[0];
      obj.azimuth = altAz[1];
      obj.isVisible = obj.altitude > -5; // Show slightly below horizon

      // Project to screen coordinates
      if (obj.isVisible) {
        _projectToScreen(obj);
      }
    }
  }

  /// Project a celestial object's alt/az to screen X/Y.
  void _projectToScreen(CelestialObject obj) {
    // Delta azimuth from where the phone is pointing
    double deltaAz = obj.azimuth - compassHeading;
    // Normalize to [-180, 180]
    if (deltaAz > 180) deltaAz -= 360;
    if (deltaAz < -180) deltaAz += 360;

    // Delta altitude from where the phone is pointing
    double deltaAlt = obj.altitude - devicePitch;

    // Convert angular offset to screen position
    // Center of screen = where the phone is pointing
    final double pixelsPerDegH = screenWidth / fovHorizontal;
    final double pixelsPerDegV = screenHeight / fovVertical;

    obj.screenX = screenWidth / 2 + deltaAz * pixelsPerDegH;
    obj.screenY = screenHeight / 2 - deltaAlt * pixelsPerDegV;

    // Snap to 2px grid for pixel aesthetic
    obj.screenX = (obj.screenX / 2).round() * 2.0;
    obj.screenY = (obj.screenY / 2).round() * 2.0;
  }

  /// Get all visible objects (on screen).
  List<CelestialObject> get visibleObjects {
    return _catalog.where((obj) {
      if (!obj.isVisible) return false;
      return obj.screenX > -50 &&
          obj.screenX < screenWidth + 50 &&
          obj.screenY > -50 &&
          obj.screenY < screenHeight + 50;
    }).toList();
  }

  /// Find the star object by ID (for constellation line drawing).
  CelestialObject? findById(int id) {
    try {
      return _catalog.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Moon phase for rendering (0=new, 0.5=full).
  double get currentMoonPhase {
    final jd = SkyMath.julianDate(DateTime.now().toUtc());
    return SkyMath.moonPhase(jd);
  }
}
