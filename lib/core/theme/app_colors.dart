import 'package:flutter/material.dart';

/// A centralized repository of color constants used throughout the Verasso application.
///
/// Includes brand colors, HSL-derived premium tones, background variations,
/// and specialized gradients for the "Liquid Glass" UI system.
class AppColors {
  // Brand Colors - Cyberpunk / Neon
  /// The primary brand color (Neon Cyan).
  static const Color primary = Color(0xFF00F2FF);

  /// The secondary brand color (Pure White).
  static const Color secondary = Color(0xFFFFFFFF);

  /// The accent brand color (Magenta/Pink).
  static const Color accent = Color(0xFFFF00FF);

  /// A warm amber/orange color for 2049/2099 aesthetic accents.
  static const Color amber = Color(0xFFFFB800);

  // Premium HSL-Derived Tones
  /// A deep, obsidian-like indigo for dark mode surfaces.
  static const Color spaceIndigo = Color(0xFF0B0D17);

  /// A deep cosmic navy blue.
  static const Color cosmicBlue = Color(0xFF141E30);

  /// A bright, ethereal cyan glow.
  static const Color etherealCyan = Color(0xFF00F2FF);

  /// A bright starlight gold for achievements and rewards.
  static const Color starlightGold = Color(0xFFFFD700);

  // Backgrounds
  /// The near-black background color for the main application scaffold.
  static const Color darkBackground = Color(0xFF06070B);

  /// A deep space black for larger surface areas.
  static const Color deepSpace = Color(0xFF0B0D17);

  // Glass Gradients (Light)
  /// A light glass gradient used for semi-transparent surfaces in light mode.
  static const List<Color> glassLight = [
    Color(0x80FFFFFF), // 50% White
    Color(0x33FFFFFF), // 20% White
  ];

  // Glass Gradients (Dark)
  /// A dark glass gradient with a cyan glow for dark mode surfaces.
  static const List<Color> glassDark = [
    Color(0x4D00F2FF), // 30% Cyan Glow
    Color(0x1A0B0D17), // 10% Obsidian
  ];

  // Borders
  /// The standard border color for glass components in light mode.
  static const Color glassBorderLight = Color(0x66FFFFFF);

  /// The standard border color for glass components in dark mode.
  static const Color glassBorderDark = Color(0x4D00F2FF);

  // Text
  /// Primary text color for dark backgrounds.
  static const Color textLight = Color(0xFFFFFFFF);

  /// Primary text color for light backgrounds.
  static const Color textDark = Color(0xFF0B0D17);

  /// A very subtle cyan with 5% opacity for surface layering.
  static Color get cyan05 => const Color(0xFF00F2FF).withValues(alpha: 0.05);

  /// A very subtle magenta with 5% opacity for surface layering.
  static Color get magenta05 => const Color(0xFFFF00FF).withValues(alpha: 0.05);

  /// Complete transparency.
  static Color get transparent => Colors.transparent;

  // Utility Opacity Colors
  /// Pure white with 5% opacity.
  static Color get white05 => Colors.white.withValues(alpha: 0.05);

  /// Pure white with 34% opacity.
  static Color get white34 => Colors.white.withValues(alpha: 0.34);
}
