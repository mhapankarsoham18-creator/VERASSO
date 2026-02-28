/// Model representing a group found in search results.
class GroupSearchResult {
  /// Unique identifier for the group.
  final String id;

  /// The name of the group.
  final String name;

  /// A brief description of the group.
  final String? description;

  /// URL to the group's avatar image.
  final String? avatarUrl;

  /// The number of members currently in the group.
  final int memberCount;

  /// The type of the result (for unified search).
  final String type = 'group';

  /// The relevance score (for unified search).
  final int relevance;

  /// Creates a [GroupSearchResult].
  GroupSearchResult({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.memberCount = 0,
    this.relevance = 0,
  });

  /// Creates a [GroupSearchResult] from a JSON map.
  factory GroupSearchResult.fromJson(Map<String, dynamic> json) {
    return GroupSearchResult(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Group',
      description: json['description'],
      avatarUrl: json['avatar_url'],
      memberCount: json['member_count'] ?? 0,
      relevance: json['relevance_score'] ?? json['relevance'] ?? 0,
    );
  }
}

/// Model representing a post found in search results.
class PostSearchResult {
  /// Unique identifier for the post.
  final String id;

  /// Unique identifier for the user who created the post.
  final String userId;

  /// The textual content of the post.
  final String content;

  /// The date and time when the post was created.
  final DateTime createdAt;

  /// The full name of the post's author.
  final String? authorName;

  /// URL to the author's avatar image.
  final String? authorAvatar;

  /// The type of the result (for unified search).
  final String type = 'post';

  /// The relevance score (for unified search).
  final int relevance;

  /// Creates a [PostSearchResult].
  PostSearchResult({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.relevance = 0,
  });

  /// Creates a [PostSearchResult] from a JSON map.
  factory PostSearchResult.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return PostSearchResult(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      authorName: profile?['full_name'],
      authorAvatar: profile?['avatar_url'],
      relevance: json['relevance_score'] ?? json['relevance'] ?? 0,
    );
  }
}

/// Container for search results across different categories.
class SearchResults {
  /// List of users matching the search query.
  final List<UserSearchResult> users;

  /// List of posts matching the search query.
  final List<PostSearchResult> posts;

  /// List of groups matching the search query.
  final List<GroupSearchResult> groups;

  /// Creates a [SearchResults] container.
  SearchResults({
    required this.users,
    required this.posts,
    required this.groups,
  });

  /// Whether all result lists are empty.
  bool get isEmpty => users.isEmpty && posts.isEmpty && groups.isEmpty;

  /// Whether there are any results in any category.
  bool get isNotEmpty => !isEmpty;

  /// Returns the total number of results across all categories for test compatibility.
  int get length => totalCount;

  /// The total number of results found.
  int get totalCount => users.length + posts.length + groups.length;

  /// Accesses results by category name or index for test compatibility.
  dynamic operator [](dynamic key) {
    if (key is int) {
      final all = [...users, ...posts, ...groups];
      if (key < 0 || key >= all.length) return null;
      return all[key];
    }
    switch (key.toString()) {
      case 'users':
        return users;
      case 'posts':
        return posts;
      case 'groups':
        return groups;
      default:
        return [];
    }
  }
}

/// Model representing a user found in search results.
class UserSearchResult {
  /// Unique identifier for the user.
  final String id;

  /// The user's full name.
  final String fullName;

  /// URL to the user's avatar image.
  final String? avatarUrl;

  /// The user's brief biography.
  final String? bio;

  /// The type of the result (for unified search).
  final String type = 'user';

  /// The relevance score (for unified search).
  final int relevance;

  /// Creates a [UserSearchResult].
  UserSearchResult({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.relevance = 0,
  });

  /// Creates a [UserSearchResult] from a JSON map.
  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      fullName: json['full_name'] ?? 'Unknown User',
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      relevance: json['relevance_score'] ?? json['relevance'] ?? 0,
    );
  }
}
