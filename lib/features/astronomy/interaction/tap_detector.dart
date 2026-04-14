import 'dart:math';
import 'package:flutter/material.dart';
import '../models/celestial_object.dart';

/// Finds the nearest celestial object to a screen tap position.
class TapDetector {
  /// Find the nearest visible object to the tap position.
  /// Returns null if no object is within threshold distance.
  static CelestialObject? findNearestObject(
    Offset tapPosition,
    List<CelestialObject> visibleObjects,
  ) {
    CelestialObject? nearest;
    double minDist = double.infinity;

    for (final obj in visibleObjects) {
      if (!obj.isVisible) continue;

      final dx = tapPosition.dx - obj.screenX;
      final dy = tapPosition.dy - obj.screenY;
      final dist = sqrt(dx * dx + dy * dy);

      // Threshold varies by object type (larger targets for planets/moon)
      final threshold = _hitThreshold(obj);

      if (dist < threshold && dist < minDist) {
        minDist = dist;
        nearest = obj;
      }
    }

    return nearest;
  }

  /// Hit detection radius varies by object type.
  static double _hitThreshold(CelestialObject obj) {
    switch (obj.type) {
      case 'sun':
      case 'moon':
        return 50;
      case 'planet':
        return 40;
      default:
        // Bright stars are easier to tap
        if (obj.magnitude < 1.0) return 35;
        if (obj.magnitude < 2.0) return 25;
        return 20;
    }
  }
}
