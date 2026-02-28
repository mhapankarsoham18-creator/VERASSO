/// Choice option within a [PostPoll].
class PollOption {
  /// Unique identifier for the option.
  final String id;

  /// Text label for the option.
  final String text;

  /// Number of votes received for this specific option.
  final int votes;

  /// Creates a [PollOption] instance.
  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
  });

  /// Creates a [PollOption] instance from a JSON map.
  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'],
      text: json['text'],
      votes: json['votes'] ?? 0,
    );
  }

  /// Calculates the percentage of total votes for this option.
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return (votes / totalVotes) * 100;
  }

  /// Converts the [PollOption] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'votes': votes,
    };
  }
}

/// Represents a community or personal post in the social feed.
class Post {
  /// Unique identifier of the post.
  final String id;

  /// ID of the user who created the post.
  final String userId;

  /// Text content of the post.
  final String? content;

  /// List of URLs for media attachments (images/videos).
  final List<String> mediaUrls;

  /// Subject area related to the post (Chemistry, Biology, etc).
  final String? subject;

  /// Catchy labels for categorization.
  final List<String> tags;

  /// Number of likes received.
  final int likesCount;

  /// Number of top-level comments.
  final int commentsCount;

  /// When the post was published.
  final DateTime createdAt;

  /// Whether this is a personal thought/log rather than a community query.
  final bool isPersonal;

  /// Whether the current user has liked this post.
  final bool isLiked;

  /// Author's display name (populated via join).
  final String? authorName;

  /// Author's profile image URL (populated via join).
  final String? authorAvatar;

  /// Optional poll attached to the post.
  final PostPoll? poll;

  /// URL for an audio snippet/podcast.
  final String? audioUrl;

  /// Duration of the audio in seconds.
  final int? audioDuration;

  /// List of mentioned user IDs or handles.
  final List<String> mentions;

  /// Primary type of content in the post.
  final PostType type;

  /// Raw JSON data for the simulation (if type is simulation).
  final Map<String, dynamic>? simulationData;

  /// Creates a [Post] instance.
  Post({
    required this.id,
    required this.userId,
    this.content,
    this.mediaUrls = const [],
    this.subject,
    this.tags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.poll,
    this.audioUrl,
    this.audioDuration,
    this.mentions = const [],
    this.type = PostType.text,
    this.isPersonal = false,
    this.isLiked = false,
    this.simulationData,
  });

  /// Creates a [Post] instance from a JSON map.
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      subject: json['subject'],
      tags: List<String>.from(json['tags'] ?? []),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      // Handling joined profile data if available
      authorName:
          json['profiles'] != null ? json['profiles']['full_name'] : null,
      authorAvatar:
          json['profiles'] != null ? json['profiles']['avatar_url'] : null,
      poll: json['poll'] != null ? PostPoll.fromJson(json['poll']) : null,
      audioUrl: json['audio_url'],
      audioDuration: json['audio_duration'],
      mentions: List<String>.from(json['mentions'] ?? []),
      type: PostType.values.firstWhere(
          (e) => e.name == (json['type'] ?? 'text'),
          orElse: () => PostType.text),
      isPersonal: json['is_personal'] ?? false,
      isLiked: json['is_liked'] ?? false,
      simulationData: json['simulation_data'],
    );
  }

  /// Compatibility getter for comment count.
  int get commentCount => commentsCount;

  /// Compatibility getters for tests
  /// Compatibility getter for like count.
  int get likeCount => likesCount;

  /// Creates a copy of this [Post] with the given fields replaced.
  Post copyWith({
    String? id,
    String? userId,
    String? content,
    List<String>? mediaUrls,
    String? subject,
    List<String>? tags,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    String? authorName,
    String? authorAvatar,
    PostPoll? poll,
    String? audioUrl,
    int? audioDuration,
    List<String>? mentions,
    PostType? type,
    bool? isPersonal,
    bool? isLiked,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      subject: subject ?? this.subject,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      poll: poll ?? this.poll,
      audioUrl: audioUrl ?? this.audioUrl,
      audioDuration: audioDuration ?? this.audioDuration,
      mentions: mentions ?? this.mentions,
      type: type ?? this.type,
      isPersonal: isPersonal ?? this.isPersonal,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  /// Converts the [Post] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'content': content,
      'media_urls': mediaUrls,
      'subject': subject,
      'tags': tags,
      'poll': poll?.toJson(),
      'audio_url': audioUrl,
      'audio_duration': audioDuration,
      'mentions': mentions,
      'type': type.name,
      'is_personal': isPersonal,
      'is_liked': isLiked,
      'simulation_data': simulationData,
    };
  }
}

/// Represents an interactive poll attached to a [Post].
class PostPoll {
  /// The question being asked.
  final String question;

  /// Available choices for the poll.
  final List<PollOption> options;

  /// When the poll stops accepting votes.
  final DateTime? expiresAt;

  /// Total number of votes cast across all options.
  final int totalVotes;

  /// Creates a [PostPoll] instance.
  PostPoll({
    required this.question,
    required this.options,
    this.expiresAt,
    this.totalVotes = 0,
  });

  /// Creates a [PostPoll] instance from a JSON map.
  factory PostPoll.fromJson(Map<String, dynamic> json) {
    return PostPoll(
      question: json['question'],
      options:
          (json['options'] as List).map((o) => PollOption.fromJson(o)).toList(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      totalVotes: json['total_votes'] ?? 0,
    );
  }

  /// Converts the [PostPoll] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options.map((o) => o.toJson()).toList(),
      'expires_at': expiresAt?.toIso8601String(),
      'total_votes': totalVotes,
    };
  }
}

/// Categorization of post content structure.
enum PostType {
  /// Simple text message.
  text,

  /// Image or video content.
  media,

  /// Interactive question with options.
  poll,

  /// Audio snippet or podcast entry.
  audio,

  /// Interactive educational simulation.
  simulation,
}
