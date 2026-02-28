/// Represents a curated collection of posts.
class Collection {
  /// Unique identifier of the collection.
  final String id;

  /// ID of the user who owns the collection.
  final String ownerId;

  /// Name of the collection.
  final String name;

  /// Brief description of the collection's theme.
  final String? description;

  /// Whether the collection is visible only to the owner and collaborators.
  final bool isPrivate;

  /// List of IDs of posts included in this collection.
  final List<String> postIds;

  /// List of user IDs who have permission to edit this collection.
  final List<String> collaboratorIds;

  /// When the collection was first created.
  final DateTime createdAt;

  /// Tracking ID for synchronization/versioning.
  final int revisionId;

  /// Creates a [Collection] instance.
  Collection({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.isPrivate = true,
    this.postIds = const [],
    this.collaboratorIds = const [],
    required this.createdAt,
    this.revisionId = 1,
  });

  /// Creates a [Collection] from a JSON map.
  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      description: json['description'],
      isPrivate: json['is_private'] ?? true,
      postIds: List<String>.from(json['post_ids'] ?? []),
      collaboratorIds: List<String>.from(json['collaborator_ids'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      revisionId: json['revision_id'] ?? 1,
    );
  }

  /// Whether multiple users can contribute to this collection.
  bool get isCollaboration => collaboratorIds.isNotEmpty;

  /// Creates a copy of this collection with updated fields.
  Collection copyWith({
    String? name,
    String? description,
    bool? isPrivate,
    List<String>? postIds,
    List<String>? collaboratorIds,
    int? revisionId,
  }) {
    return Collection(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      isPrivate: isPrivate ?? this.isPrivate,
      postIds: postIds ?? this.postIds,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      createdAt: createdAt,
      revisionId: revisionId ?? this.revisionId,
    );
  }

  /// Converts the collection to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'is_private': isPrivate,
      'post_ids': postIds,
      'collaborator_ids': collaboratorIds,
      'revision_id': revisionId,
    };
  }
}
