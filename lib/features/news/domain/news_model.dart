/// Qualification levels for journalists based on their featured article count.
enum JournalistBadge {
  /// No special badge assigned.
  none,

  /// Junior journalist level.
  junior, // 1 featured

  /// Staff journalist level.
  staff, // 5 featured

  /// Senior journalist level.
  senior, // 15 featured

  /// Editor level.
  editor; // 30+ featured

  /// Converts a string value to a [JournalistBadge].
  static JournalistBadge fromString(String? val) {
    if (val == null) return none;
    return JournalistBadge.values.firstWhere(
      (e) => e.name == val.toLowerCase(),
      orElse: () => none,
    );
  }
}

/// Model representing a news article in the system.
class NewsArticle {
  /// Unique identifier for the article.
  final String id;

  /// Unique identifier for the author (user).
  final String authorId;

  /// The headline of the article.
  final String title;

  /// A brief summary of the article content.
  final String? description;

  /// The rich text content of the article in Delta format.
  final Map<String, dynamic> content; // Delta format for rich text

  /// Optional LaTeX content for mathematical formulas.
  final String? latexContent;

  /// The primary topic or subject of the article.
  final String subject;

  /// The intended target audience.
  final String audienceType;

  /// The category or format of the article.
  final String articleType;

  /// Estimated time in minutes required to read the article.
  final int readingTime;

  /// URL to the article's featured image.
  final String? imageUrl;

  /// Whether the article is highlighted on the featured feed.
  final bool isFeatured;

  /// Numerical importance score (1-5).
  final int importance;

  /// Whether the article is publicly visible.
  final bool isPublished;

  /// The total number of upvotes received.
  final int upvotesCount;

  /// The total number of comments posted.
  final int commentsCount;

  /// The date and time when the article was marked as featured.
  final DateTime? featuredAt;

  /// The date and time when the article was created.
  final DateTime createdAt;

  /// The date and time when the article was last updated.
  final DateTime updatedAt;

  // Joined data
  /// The author's full name.
  final String? authorName;

  /// URL to the author's avatar image.
  final String? authorAvatar;

  /// The author's professional level or badge.
  final String? authorBadge;

  /// Creates a [NewsArticle].
  const NewsArticle({
    required this.id,
    required this.authorId,
    required this.title,
    this.description,
    required this.content,
    this.latexContent,
    required this.subject,
    required this.audienceType,
    this.articleType = 'concept_explainer',
    this.readingTime = 5,
    this.imageUrl,
    this.isFeatured = false,
    this.importance = 1,
    this.isPublished = false,
    this.upvotesCount = 0,
    this.commentsCount = 0,
    this.featuredAt,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorAvatar,
    this.authorBadge,
  });

  /// Creates a [NewsArticle] from a JSON map.
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'],
      authorId: json['author_id'],
      title: json['title'] ?? 'No Title',
      description: json['description'],
      content: json['content'] is Map ? json['content'] : {},
      latexContent: json['latex_content'],
      subject: json['subject'] ?? 'General',
      audienceType: json['audience_type'] ?? 'All',
      articleType: json['article_type'] ?? 'concept_explainer',
      readingTime: json['reading_time'] ?? 5,
      imageUrl: json['image_url'],
      isFeatured: json['is_featured'] ?? false,
      importance: json['importance'] ?? 1,
      isPublished: json['is_published'] ?? false,
      upvotesCount: json['upvotes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      featuredAt: json['featured_at'] != null
          ? DateTime.parse(json['featured_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorName: json['profiles']?['full_name'],
      authorAvatar: json['profiles']?['avatar_url'],
      authorBadge: json['profiles']?['journalist_level'],
    );
  }

  /// Creates a copy of [NewsArticle] with updated properties.
  NewsArticle copyWith({
    String? id,
    String? authorId,
    String? title,
    String? description,
    Map<String, dynamic>? content,
    String? latexContent,
    String? subject,
    String? audienceType,
    String? articleType,
    int? readingTime,
    String? imageUrl,
    bool? isFeatured,
    int? importance,
    bool? isPublished,
    int? upvotesCount,
    int? commentsCount,
    DateTime? featuredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? authorAvatar,
    String? authorBadge,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      latexContent: latexContent ?? this.latexContent,
      subject: subject ?? this.subject,
      audienceType: audienceType ?? this.audienceType,
      articleType: articleType ?? this.articleType,
      readingTime: readingTime ?? this.readingTime,
      imageUrl: imageUrl ?? this.imageUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      importance: importance ?? this.importance,
      isPublished: isPublished ?? this.isPublished,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      featuredAt: featuredAt ?? this.featuredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorBadge: authorBadge ?? this.authorBadge,
    );
  }

  /// Converts [NewsArticle] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'title': title,
      'description': description,
      'content': content,
      'latex_content': latexContent,
      'subject': subject,
      'audience_type': audienceType,
      'article_type': articleType,
      'reading_time': readingTime,
      'image_url': imageUrl,
      'is_published': isPublished,
      'is_featured': isFeatured,
      'importance': importance,
      'upvotes_count': upvotesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'featured_at': featuredAt?.toIso8601String(),
      'profiles': {
        'full_name': authorName,
        'avatar_url': authorAvatar,
        'journalist_level': authorBadge,
      },
    };
  }
}
