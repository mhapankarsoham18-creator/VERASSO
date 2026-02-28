/// Represents an educational lesson within a realm.
class Lesson {
  /// Unique identifier for the lesson.
  final String id;

  /// Title of the lesson.
  final String title;

  /// A brief description of the lesson's goal.
  final String description;

  /// Optional URL to a video tutorial for the lesson.
  final String videoUrl;

  /// Markdown-formatted content for the lesson instructions.
  final String markdownContent;

  /// Initial code snippet provided to the user.
  final String starterCode;

  /// The expected code solution to pass the lesson.
  final String solutionCode;

  /// Creates a [Lesson] instance.
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    this.videoUrl = '',
    required this.markdownContent,
    required this.starterCode,
    required this.solutionCode,
  });
}
