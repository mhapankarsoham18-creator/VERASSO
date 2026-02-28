/// Represents a themed learning realm within the Odyssey map.
class Realm {
  /// Unique identifier for the realm.
  final String id;

  /// Human-readable name of the realm.
  final String name;

  /// A brief description of the realm's subject or theme.
  final String description;

  /// Whether the realm is currently locked for the user.
  final bool isLocked;

  /// The user's completion progress in this realm (0.0 to 1.0).
  final double progress;

  /// Creates a [Realm] instance.
  const Realm({
    required this.id,
    required this.name,
    required this.description,
    this.isLocked = true,
    this.progress = 0.0,
  });
}
