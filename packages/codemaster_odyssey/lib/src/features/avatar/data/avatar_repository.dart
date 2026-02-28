import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../avatar/domain/avatar_model.dart';

/// Provider for the [AvatarRepository] instance.
final avatarRepositoryProvider = Provider((ref) => AvatarRepository());

/// Repository responsible for fetching and managing avatar data.
class AvatarRepository {
  /// Fetches the current user's [Avatar] data.
  Avatar getAvatar() {
    return const Avatar(
      name: 'Code Apprentice',
      level: 2,
      currentXp: 45,
      maxXp: 150,
      skillPoints: 2,
      skills: [
        SkillNode(
          id: 'l1',
          name: 'Basic Logic',
          description: 'Unlock if/else statements.',
          type: SkillType.logic,
          isUnlocked: true,
        ),
        SkillNode(
          id: 's1',
          name: 'Variables',
          description: 'Understand storage containers.',
          type: SkillType.syntax,
          isUnlocked: true,
        ),
        SkillNode(
          id: 'p1',
          name: 'Hello World',
          description: 'Your first program.',
          type: SkillType.projects,
          isUnlocked: true,
        ),
        SkillNode(
          id: 'l2',
          name: 'Loops',
          description: 'Repeat actions efficiently.',
          type: SkillType.logic,
        ),
        SkillNode(
          id: 's2',
          name: 'Functions',
          description: 'Reusable code blocks.',
          type: SkillType.syntax,
        ),
      ],
    );
  }
}
