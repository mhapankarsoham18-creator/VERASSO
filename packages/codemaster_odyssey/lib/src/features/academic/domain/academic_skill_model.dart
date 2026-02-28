/// Represents an academic skill or concept linked to a coding realm.
class AcademicSkill {
  /// Unique identifier for the skill.
  final String id;

  /// Human-readable title of the skill.
  final String title;

  /// Subject area (e.g., 'Chemistry', 'History').
  final String subject;

  /// Mastery level from 0.0 to 1.0.
  final double mastery;

  /// List of related badge IDs that can be earned through this skill.
  final List<String> relatedBadges;

  /// Creates an [AcademicSkill] instance.
  const AcademicSkill({
    required this.id,
    required this.title,
    required this.subject,
    this.mastery = 0.0,
    required this.relatedBadges,
  });
}
