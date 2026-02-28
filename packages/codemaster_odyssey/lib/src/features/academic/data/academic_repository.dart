import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/academic_skill_model.dart';

/// Provider for the [AcademicRepository] instance.
final academicRepositoryProvider =
    NotifierProvider<AcademicRepository, List<AcademicSkill>>(
      AcademicRepository.new,
    );

/// Repository responsible for managing academic skill progression.
class AcademicRepository extends Notifier<List<AcademicSkill>> {
  @override
  List<AcademicSkill> build() {
    return [
      const AcademicSkill(
        id: 'chem_1',
        title: 'Stoichiometry Logic',
        subject: 'Chemistry',
        mastery: 0.8,
        relatedBadges: ['Chem Coder'],
      ),
      const AcademicSkill(
        id: 'hist_1',
        title: 'Enigma Cyphers',
        subject: 'History',
        mastery: 0.4,
        relatedBadges: ['History Hacker'],
      ),
      const AcademicSkill(
        id: 'phys_1',
        title: 'Kinematic Algorithms',
        subject: 'Physics',
        mastery: 0.6,
        relatedBadges: ['Physics Pathfinder'],
      ),
    ];
  }

  /// Updates the mastery level of a specific skill by a [delta].
  /// Mastery is clamped between 0.0 and 1.0.
  void updateMastery(String skillId, double delta) {
    state = [
      for (final skill in state)
        if (skill.id == skillId)
          AcademicSkill(
            id: skill.id,
            title: skill.title,
            subject: skill.subject,
            mastery: (skill.mastery + delta).clamp(0.0, 1.0),
            relatedBadges: skill.relatedBadges,
          )
        else
          skill,
    ];
  }
}
