import 'package:flutter/material.dart';

/// Represents a cultural or thematic realm within the Odyssey.
class CulturalTheme {
  /// Unique identifier for the cultural theme.
  final String id;

  /// Human-readable name of the theme (e.g., 'Mayan Math').
  final String name;

  /// A brief description of what the theme entails.
  final String description;

  /// The primary color used for branding and UI elements of this theme.
  final Color primaryColor;

  /// Icon representing the cultural theme.
  final IconData icon;

  /// Creates a [CulturalTheme] instance.
  const CulturalTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.icon,
  });
}
