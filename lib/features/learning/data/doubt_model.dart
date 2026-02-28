/// Represents a doubt or question raised by a student.
class Doubt {
  /// Unique identifier of the doubt.
  final String id;

  /// The ID of the student who raised the doubt.
  final String userId;

  /// The summary or title of the question.
  final String questionTitle;

  /// Optional detailed description of the doubt.
  final String? questionDescription;

  /// The subject area (e.g., 'Physics', 'Biology').
  final String subject;

  /// Optional specific topic within the subject.
  final String? topic;

  /// Whether the doubt has been resolved.
  final bool isSolved;

  /// List of URLs to images attached to the doubt.
  final List<String> imageUrls;

  /// The date and time when the doubt was raised.
  final DateTime createdAt;

  // Author details
  /// The display name of the author (optional, populated via joins).
  final String? authorName;

  /// The avatar URL of the author (optional, populated via joins).
  final String? authorAvatar;

  /// Number of answers/replies to this doubt.
  final int answerCount;

  /// Creates a [Doubt] instance.
  Doubt({
    required this.id,
    required this.userId,
    required this.questionTitle,
    this.questionDescription,
    required this.subject,
    this.topic,
    this.isSolved = false,
    this.imageUrls = const [],
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
    this.answerCount = 0,
  });

  /// Creates a [Doubt] from a JSON-compatible map.
  factory Doubt.fromJson(Map<String, dynamic> json) {
    return Doubt(
      id: json['id'],
      userId: json['user_id'],
      questionTitle: json['question_title'],
      questionDescription: json['question_description'],
      subject: json['subject'],
      topic: json['topic'],
      isSolved: json['is_solved'] ?? false,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      authorName:
          json['profiles'] != null ? json['profiles']['full_name'] : null,
      authorAvatar:
          json['profiles'] != null ? json['profiles']['avatar_url'] : null,
      answerCount: json['answer_count'] ?? 0,
    );
  }

  /// Converts the [Doubt] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'question_title': questionTitle,
      'question_description': questionDescription,
      'subject': subject,
      'topic': topic,
      'is_solved': isSolved,
      'image_urls': imageUrls,
    };
  }
}
