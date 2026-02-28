/// Represents a user's customizable character and their progression.
class Avatar {
  /// Name of the avatar.
  final String name;

  /// Current character level.
  final int level;

  /// Current experience points.
  final int currentXp;

  /// Experience points required to reach the next level.
  final int maxXp;

  /// Unspent skill points for the skill tree.
  final int skillPoints;

  /// List of skill nodes available to the avatar.
  final List<SkillNode> skills;

  /// Hex string for hair color.
  final String hairColor;

  /// Hex string for skin tone.
  final String skinTone;

  /// Creates an [Avatar] instance.
  const Avatar({
    required this.name,
    this.level = 1,
    this.currentXp = 0,
    this.maxXp = 100,
    this.skillPoints = 0,
    required this.skills,
    this.hairColor = '0xFF000000',
    this.skinTone = '0xFFFFCC80',
  });

  /// Calculates the level for a specific [SkillType] based on unlocked nodes.
  int getStatLevel(SkillType type) {
    return skills.where((s) => s.type == type && s.isUnlocked).length + 1;
  }
}

/// A node in the avatar's skill tree.
class SkillNode {
  /// Unique identifier for the skill node.
  final String id;

  /// Name of the skill.
  final String name;

  /// Detailed description of what the skill unlocks or improves.
  final String description;

  /// Category of the skill (logic, syntax, or projects).
  final SkillType type;

  /// Cost in skill points to unlock.
  final int cost;

  /// Whether the skill has been unlocked by the user.
  final bool isUnlocked;

  /// Creates a [SkillNode] instance.
  const SkillNode({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.cost = 1,
    this.isUnlocked = false,
  });

  /// Creates a copy of this [SkillNode] with the given fields replaced.
  SkillNode copyWith({bool? isUnlocked}) {
    return SkillNode(
      id: id,
      name: name,
      description: description,
      type: type,
      cost: cost,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

/// Categories for skills in the skill tree.
enum SkillType {
  /// Coding logic and control flow.
  logic,

  /// Language syntax and structures.
  syntax,

  /// Real-world project application.
  projects,
}
