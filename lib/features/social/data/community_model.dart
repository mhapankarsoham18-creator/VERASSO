import 'package:json_annotation/json_annotation.dart';

part 'community_model.g.dart';

/// Represents a large group formed around a specific educational subject.
@JsonSerializable()
class Community {
  /// Unique identifier of the community.
  final String id;

  /// Name of the community (e.g. "Biology Scholars").
  final String name;

  /// Description of the community's focus.
  final String description;

  /// URL of the community's avatar image.
  final String? avatarUrl;

  /// The subject area this community belongs to.
  final String subject;

  /// Current number of members in the community.
  final int memberCount;

  /// Whether the community is private or public.
  final bool isPrivate;

  /// When the community was established.
  final DateTime createdAt;

  /// ID of the user who founded the community.
  final String? creatorId;

  /// Creates a [Community] instance.
  Community({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.subject,
    this.memberCount = 0,
    this.isPrivate = false,
    required this.createdAt,
    this.creatorId,
  });

  /// Creates a [Community] from a JSON map using generated code.
  factory Community.fromJson(Map<String, dynamic> json) =>
      _$CommunityFromJson(json);

  /// Converts the community to a JSON map using generated code.
  Map<String, dynamic> toJson() => _$CommunityToJson(this);
}
