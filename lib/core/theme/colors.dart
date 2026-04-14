import 'package:flutter/material.dart';

/// Uniquely styled palette adhering strictly to constraints:
/// No purple/indigo. Earthy, solid, calm 3-color palette.
class AppColors {
  // Main colors
  static const Color neutralBg = Color(0xFFEAF0EA); // Pale greenish white
  static const Color primary = Color(0xFF4A5D23);   // Olive Green
  static const Color accent = Color(0xFFE27D60);    // Terracotta

  // Text/Content colors
  static const Color textPrimary = Color(0xFF2C2F33);
  static const Color textSecondary = Color(0xFF6B6E70);

  // Neumorphic / Pixel 3D Shadow colors
  static const Color shadowDark = Color(0xFFCFCAC1);
  static const Color shadowLight = Color(0xFFFFFFFF);
  
  // Specific pixel 3D borders
  static const Color blockEdge = Color(0xFF1E2124);
  
  static const Color error = Color(0xFFD32F2F);
}
