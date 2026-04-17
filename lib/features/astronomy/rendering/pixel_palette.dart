import 'package:flutter/material.dart';

/// Strict limited color palette for the retro pixel sky.
class PixelPalette {
  // Sky background
  static Color skyBlack = Color(0xFF0A0A12);
  static Color skyDeepBlue = Color(0xFF0D1117);

  // Star colors mapped from B-V color index
  static Color starBlueWhite = Color(0xFFAAC8FF); // B-V < -0.1
  static Color starWhite = Color(0xFFE8E8FF);     // B-V 0.0 - 0.3
  static Color starYellow = Color(0xFFFFE87A);    // B-V 0.3 - 0.8
  static Color starOrange = Color(0xFFFFB347);    // B-V 0.8 - 1.4
  static Color starRed = Color(0xFFFF6B6B);       // B-V > 1.4

  // Planet colors
  static Color mercury = Color(0xFFB0B0B0);
  static Color venus = Color(0xFFFFE4B5);
  static Color mars = Color(0xFFFF4500);
  static Color jupiter = Color(0xFFD4A574);
  static Color saturn = Color(0xFFDAA520);
  static Color uranus = Color(0xFF7EC8E3);
  static Color neptune = Color(0xFF4169E1);

  // Moon
  static Color moonBright = Color(0xFFF5F5DC);
  static Color moonDark = Color(0xFF3A3A3A);

  // Sun (rendered only near horizon)
  static Color sunGlow = Color(0xFFFFD700);

  // UI elements
  static Color constellationLine = Color(0x33FFFFFF);
  static Color gridColor = Color(0x11FFFFFF);
  static Color labelColor = Color(0xAA88FF88); // Green terminal text
  static Color scanLineOverlay = Color(0x08000000);
  static Color hudText = Color(0xFF88FF88);
  static Color hudDim = Color(0xFF336633);
  static Color bubbleBg = Color(0xE60A0A12);
  static Color bubbleBorder = Color(0xFF88FF88);

  /// Get star color from B-V color index.
  static Color starColorFromCI(double ci) {
    if (ci < -0.1) return starBlueWhite;
    if (ci < 0.3) return starWhite;
    if (ci < 0.8) return starYellow;
    if (ci < 1.4) return starOrange;
    return starRed;
  }

  /// Get planet color by name.
  static Color planetColor(String name) {
    switch (name.toLowerCase()) {
      case 'mercury': return mercury;
      case 'venus': return venus;
      case 'mars': return mars;
      case 'jupiter': return jupiter;
      case 'saturn': return saturn;
      case 'uranus': return uranus;
      case 'neptune': return neptune;
      default: return starWhite;
    }
  }
}
