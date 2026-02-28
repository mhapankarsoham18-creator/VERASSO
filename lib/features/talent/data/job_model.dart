/// Represents a job application from a talent.
class JobApplication {
  /// The unique identifier for the application.
  final String id;

  /// The ID of the job being applied for.
  final String jobId;

  /// The ID of the talent applying for the job.
  final String talentId;

  /// The application message/cover letter.
  final String? message;

  /// The status of the application (e.g., 'pending', 'accepted', 'rejected').
  final String status;

  /// The date and time when the application was created.
  final DateTime createdAt;

  // Joins
  /// The name of the talent (joined field).
  final String? talentName;

  /// The avatar URL of the talent (joined field).
  final String? talentAvatar;

  /// The title of the job (joined field).
  final String? jobTitle;

  /// Creates a [JobApplication] instance.
  JobApplication({
    required this.id,
    required this.jobId,
    required this.talentId,
    this.message,
    this.status = 'pending',
    required this.createdAt,
    this.talentName,
    this.talentAvatar,
    this.jobTitle,
  });

  /// Creates a [JobApplication] from a JSON map.
  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'],
      jobId: json['job_id'],
      talentId: json['talent_id'],
      message: json['message'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      talentName: json['profiles']?['full_name'],
      talentAvatar: json['profiles']?['avatar_url'],
      jobTitle: json['job_requests']?['title'],
    );
  }

  /// Converts the [JobApplication] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'talent_id': talentId,
      'message': message,
      'status': status,
    };
  }
}

/// Represents a job request posted by a client.
class JobRequest {
  /// The unique identifier for the job request.
  final String id;

  /// The ID of the client who posted the job.
  final String clientId;

  /// The title of the job.
  final String title;

  /// The description of the job.
  final String? description;

  /// The budget for the job.
  final double budget;

  /// The currency of the budget.
  final String currency;

  /// List of required skills for the job.
  final List<String> requiredSkills;

  /// The current status of the job (e.g., 'open', 'closed').
  final String status;

  /// The date and time when the job was created.
  final DateTime createdAt;

  /// Whether the job is featured.
  final bool isFeatured;

  /// The expiry date for the featured status.
  final DateTime? featuredExpiry;

  // Joins
  /// The name of the client (joined field).
  final String? clientName;

  /// The avatar URL of the client (joined field).
  final String? clientAvatar;

  /// Creates a [JobRequest] instance.
  JobRequest({
    required this.id,
    required this.clientId,
    required this.title,
    this.description,
    this.budget = 0.0,
    this.currency = 'USD',
    this.requiredSkills = const [],
    this.status = 'open',
    required this.createdAt,
    this.isFeatured = false,
    this.featuredExpiry,
    this.clientName,
    this.clientAvatar,
  });

  /// Creates a [JobRequest] from a JSON map.
  factory JobRequest.fromJson(Map<String, dynamic> json) {
    return JobRequest(
      id: json['id'],
      clientId: json['client_id'],
      title: json['title'],
      description: json['description'],
      budget: (json['budget'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at']),
      clientName: json['profiles']?['full_name'],
      clientAvatar: json['profiles']?['avatar_url'],
      isFeatured: json['is_featured'] ?? false,
      featuredExpiry: json['featured_expiry'] != null
          ? DateTime.parse(json['featured_expiry'])
          : null,
    );
  }

  /// Converts the [JobRequest] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'title': title,
      'description': description,
      'budget': budget,
      'currency': currency,
      'required_skills': requiredSkills,
      'status': status,
      'is_featured': isFeatured,
      'featured_expiry': featuredExpiry?.toIso8601String(),
    };
  }
}

/// Represents a review for a completed job.
class JobReview {
  /// The unique identifier for the review.
  final String id;

  /// The ID of the job being reviewed.
  final String jobId;

  /// The ID of the user leaving the review.
  final String reviewerId;

  /// The ID of the user receiving the review.
  final String revieweeId;

  /// The rating given (e.g., 1-5).
  final int rating;

  /// The review comment.
  final String? comment;

  /// The date and time when the review was created.
  final DateTime createdAt;

  /// Creates a [JobReview] instance.
  JobReview({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  /// Creates a [JobReview] from a JSON map.
  factory JobReview.fromJson(Map<String, dynamic> json) {
    return JobReview(
      id: json['id'],
      jobId: json['job_id'],
      reviewerId: json['reviewer_id'],
      revieweeId: json['reviewee_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Converts the [JobReview] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'rating': rating,
      'comment': comment,
    };
  }
}
