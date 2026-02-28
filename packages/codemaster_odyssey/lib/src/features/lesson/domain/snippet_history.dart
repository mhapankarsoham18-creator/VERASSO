import 'package:flutter/foundation.dart';

/// Represents a history record of a code snippet submitted by a user for a lesson.
/// Maps to the `codedex_history` table in Supabase.
@immutable
class SnippetHistory {
  /// Unique identifier for the history record.
  final String? id;

  /// The ID of the user who submitted the snippet.
  final String userId;

  /// The ID of the lesson associated with the snippet.
  final String lessonId;

  /// The actual code content submitted by the user.
  final String codeSnippet;

  /// Whether the submitted snippet passed the lesson's requirements.
  final bool isPassing;

  /// The timestamp when the record was created.
  final DateTime? createdAt;

  /// Creates a [SnippetHistory] instance.
  const SnippetHistory({
    this.id,
    required this.userId,
    required this.lessonId,
    required this.codeSnippet,
    this.isPassing = false,
    this.createdAt,
  });

  /// Creates a [SnippetHistory] from a JSON map.
  factory SnippetHistory.fromJson(Map<String, dynamic> json) {
    return SnippetHistory(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      lessonId: json['lesson_id'] as String,
      codeSnippet: json['code_snippet'] as String,
      isPassing: json['is_passing'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Creates a copy of this [SnippetHistory] with the given fields replaced.
  SnippetHistory copyWith({
    String? id,
    String? userId,
    String? lessonId,
    String? codeSnippet,
    bool? isPassing,
    DateTime? createdAt,
  }) {
    return SnippetHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      codeSnippet: codeSnippet ?? this.codeSnippet,
      isPassing: isPassing ?? this.isPassing,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this [SnippetHistory] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'lesson_id': lessonId,
      'code_snippet': codeSnippet,
      'is_passing': isPassing,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
