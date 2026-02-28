import 'package:flutter/material.dart';

/// Represents an achievement or reward earned by the user.
class Badge {
  /// Unique identifier for the badge.
  final String id;

  /// Human-readable name of the badge.
  final String name;

  /// Detailed description of how the badge was earned.
  final String description;

  /// Icon data used to represent the badge visually.
  final IconData iconData;

  /// Whether the user has unlocked this badge.
  final bool isUnlocked;

  /// The date and time when the badge was unlocked, if applicable.
  final DateTime? unlockedAt;

  /// Creates a [Badge] instance.
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconData,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  /// Creates a copy of this [Badge] with the given fields replaced.
  Badge copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return Badge(
      id: id,
      name: name,
      description: description,
      iconData: iconData,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
