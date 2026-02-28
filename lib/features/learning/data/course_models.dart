/// Represents a single chapter or lesson within a course.
class Chapter {
  /// Unique identifier of the chapter.
  final String id;

  /// The ID of the course this chapter belongs to.
  final String courseId;

  /// The title of the chapter.
  final String title;

  /// Detailed content of the chapter in Markdown format.
  final String? contentMarkdown;

  /// URL to a video lesson for this chapter.
  final String? videoUrl;

  /// URL to external resources or reading material.
  final String? externalResourceUrl;

  /// The sequential order of this chapter within the course.
  final int orderIndex;

  /// The date and time when the chapter was created.
  final DateTime createdAt;

  /// Creates a [Chapter] instance.
  Chapter({
    required this.id,
    required this.courseId,
    required this.title,
    this.contentMarkdown,
    this.videoUrl,
    this.externalResourceUrl,
    required this.orderIndex,
    required this.createdAt,
  });

  /// Creates a [Chapter] from a JSON-compatible map.
  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      contentMarkdown: json['content_markdown'],
      videoUrl: json['video_url'],
      externalResourceUrl: json['external_resource_url'],
      orderIndex: json['order_index'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [Chapter] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'title': title,
      'content_markdown': contentMarkdown,
      'video_url': videoUrl,
      'external_resource_url': externalResourceUrl,
      'order_index': orderIndex,
    };
  }
}

/// Represents a course created by a mentor or instructor.
class Course {
  /// Unique identifier of the course.
  final String id;

  /// The ID of the user who created the course.
  final String creatorId;

  /// The title of the course.
  final String title;

  /// Optional detailed description of the course content.
  final String? description;

  /// The price of the course (defaults to 0.0 for free courses).
  final double price;

  /// The currency code for the price (e.g., 'USD').
  final String currency;

  /// URL to the cover image of the course.
  final String? coverUrl;

  /// Subject category of the course (e.g., 'Physics', 'Finance').
  final String? category;

  /// Whether the course is currently published and visible to students.
  final bool isPublished;

  /// Whether this course is a practical lab session.
  final bool isLab;

  /// The date and time when the course was created.
  final DateTime createdAt;

  // Joins
  /// The display name of the creator (optional, populated via joins).
  final String? creatorName;

  /// Creates a [Course] instance.
  Course({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    this.price = 0.0,
    this.currency = 'USD',
    this.coverUrl,
    this.category,
    this.isPublished = false,
    this.isLab = false,
    required this.createdAt,
    this.creatorName,
  });

  /// Creates a [Course] from a JSON-compatible map.
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      creatorId: json['creator_id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      coverUrl: json['cover_url'],
      category: json['category'],
      isPublished: json['is_published'] ?? false,
      isLab: json['is_lab'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      creatorName: json['profiles']?['full_name'],
    );
  }

  /// Converts the [Course] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'cover_url': coverUrl,
      'category': category,
      'is_published': isPublished,
      'is_lab': isLab,
    };
  }
}

/// Represents a student's enrollment in a course and their progress.
class Enrollment {
  /// Unique identifier of the enrollment record.
  final String id;

  /// The ID of the student who is enrolled.
  final String studentId;

  /// The ID of the course the student is enrolled in.
  final String courseId;

  /// The student's progress in the course as a percentage (0-100).
  final int progressPercent;

  /// List of IDs of chapters completed by the student.
  final List<String> completedChapters;

  /// The date and time when the student enrolled.
  final DateTime enrolledAt;

  /// The date and time when the student completed the course, if applicable.
  final DateTime? completedAt;

  // Joins
  /// The title of the course (optional, populated via joins).
  final String? courseTitle;

  /// The cover URL of the course (optional, populated via joins).
  final String? courseCoverUrl;

  /// Creates an [Enrollment] instance.
  Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    this.progressPercent = 0,
    this.completedChapters = const [],
    required this.enrolledAt,
    this.completedAt,
    this.courseTitle,
    this.courseCoverUrl,
  });

  /// Creates an [Enrollment] from a JSON-compatible map.
  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'],
      studentId: json['student_id'],
      courseId: json['course_id'],
      progressPercent: json['progress_percent'] ?? 0,
      completedChapters: List<String>.from(json['completed_chapters'] ?? []),
      enrolledAt: DateTime.parse(json['enrolled_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      courseTitle: json['courses']?['title'],
      courseCoverUrl: json['courses']?['cover_url'],
    );
  }

  /// Converts the [Enrollment] instance to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'course_id': courseId,
      'progress_percent': progressPercent,
      'completed_chapters': completedChapters,
    };
  }
}
