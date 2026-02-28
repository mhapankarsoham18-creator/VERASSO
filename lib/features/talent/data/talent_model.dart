/// Represents a talent post offering a service.
class TalentPost {
  /// The unique identifier for the post.
  final String id;

  /// The ID of the user who created the post.
  final String userId;

  /// The title of the post.
  final String title;

  /// The description of the service.
  final String? description;

  /// The price of the service.
  final double price;

  /// The currency of the price.
  final String currency;

  /// List of media URLs associated with the post.
  final List<String> mediaUrls;

  /// Details about how to inquire for the service.
  final String? enquiryDetails;

  /// The category of the service.
  final String? category;

  /// The date and time when the post was created.
  final DateTime createdAt;

  /// Whether the post is featured.
  final bool isFeatured;

  /// The expiry date for the featured status.
  final DateTime? featuredExpiry;

  /// The billing period (e.g., 'hourly', 'fixed').
  final String
      billingPeriod; // 'hourly', 'monthly', 'quarterly', 'yearly', 'free', 'one-off'

  /// Whether this post is a mentorship package.
  final bool isMentorPackage;

  // Joins
  /// The name of the author (joined field).
  final String? authorName;

  /// The avatar URL of the author (joined field).
  final String? authorAvatar;

  /// Whether the author is a mentor (joined field).
  final bool authorIsMentor;

  /// Creates a [TalentPost] instance.
  TalentPost({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.price = 0.0,
    this.currency = 'USD',
    this.mediaUrls = const [],
    this.enquiryDetails,
    this.category,
    required this.createdAt,
    this.isFeatured = false,
    this.featuredExpiry,
    this.billingPeriod = 'one-off',
    this.isMentorPackage = false,
    this.authorName,
    this.authorAvatar,
    this.authorIsMentor = false,
  });

  /// Creates a [TalentPost] from a JSON map.
  factory TalentPost.fromJson(Map<String, dynamic> json) {
    return TalentPost(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      enquiryDetails: json['enquiry_details'],
      category: json['category'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isFeatured: json['is_featured'] ?? false,
      featuredExpiry: json['featured_expiry'] != null
          ? DateTime.parse(json['featured_expiry'])
          : null,
      billingPeriod: json['billing_period'] ?? 'one-off',
      isMentorPackage: json['is_mentor_package'] ?? false,
      authorName: json['profiles']?['full_name'],
      authorAvatar: json['profiles']?['avatar_url'],
      authorIsMentor: json['profiles']?['is_mentor'] ?? false,
    );
  }

  /// Converts the [TalentPost] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'media_urls': mediaUrls,
      'enquiry_details': enquiryDetails,
      'category': category,
      'is_featured': isFeatured,
      'featured_expiry': featuredExpiry?.toIso8601String(),
      'billing_period': billingPeriod,
      'is_mentor_package': isMentorPackage,
    };
  }
}
