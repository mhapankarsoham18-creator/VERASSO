/// Represents an achievement that can be tracked and unlocked.
class Achievement {
  /// Unique identifier of the achievement.
  final String id;

  /// Title of the achievement.
  final String title;

  /// Description of what is required to unlock the achievement.
  final String description;

  /// Number of experience points rewarded upon unlocking.
  final int xpReward;

  /// Optional badge rewarded upon unlocking.
  final Badge? badge;

  /// Whether the achievement has been unlocked.
  final bool isUnlocked;

  /// The timestamp when the achievement was unlocked, if applicable.
  final DateTime? unlockedAt;

  /// The current completion progress (0.0 to 1.0).
  final double progress;

  /// Creates an [Achievement].
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    this.badge,
    required this.isUnlocked,
    this.unlockedAt,
    required this.progress,
  });
}

/// Represents a badge that can be earned by a user.
class Badge {
  /// Unique identifier of the badge.
  final String id;

  /// Display name of the badge.
  final String name;

  /// Description of the badge's requirements or significance.
  final String description;

  /// Icon or emoji representing the badge.
  final String icon;

  /// Category the badge belongs to.
  final BadgeCategory category;

  /// Number of points required to earn this badge.
  final int requiredPoints;

  /// Rarity level of the badge.
  final BadgeRarity rarity;

  /// Creates a [Badge].
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.requiredPoints,
    required this.rarity,
  });
}

/// Categories used to group badges based on the type of achievement.
enum BadgeCategory {
  /// Badges earned by completing all simulations in a specific subject.
  subject,

  /// Badges earned by exploring a wide variety of simulations.
  explorer,

  /// Badges earned through social interactions and community involvement.
  social,

  /// Badges earned by contributing content to the platform.
  contributor,

  /// Unique badges awarded for specific, non-category milestones.
  special,
}

/// Predefined badges
/// Contains static definitions for all available badges in the application.
class BadgeDefinitions {
  /// A map of all available badges, keyed by their ID.
  static const Map<String, Badge> availableBadges = {
    'physics_master': Badge(
      id: 'physics_master',
      name: 'Physics Master',
      description: 'Complete all 12 Physics simulations',
      icon: '⚛️',
      category: BadgeCategory.subject,
      requiredPoints: 1200,
      rarity: BadgeRarity.epic,
    ),

    'chemistry_expert': Badge(
      id: 'chemistry_expert',
      name: 'Chemistry Expert',
      description: 'Complete all 6 Chemistry simulations',
      icon: '🧪',
      category: BadgeCategory.subject,
      requiredPoints: 600,
      rarity: BadgeRarity.rare,
    ),

    'biology_genius': Badge(
      id: 'biology_genius',
      name: 'Biology Genius',
      description: 'Complete all 11 Biology simulations',
      icon: '🧬',
      category: BadgeCategory.subject,
      requiredPoints: 1100,
      rarity: BadgeRarity.epic,
    ),

    'stargazer': Badge(
      id: 'stargazer',
      name: 'Stargazer',
      description: 'Use AR Stargazing feature',
      icon: '⭐',
      category: BadgeCategory.special,
      requiredPoints: 50,
      rarity: BadgeRarity.rare,
    ),

    'explorer': Badge(
      id: 'explorer',
      name: 'Explorer',
      description: 'Try all 29 simulations',
      icon: '🗺️',
      category: BadgeCategory.explorer,
      requiredPoints: 2900,
      rarity: BadgeRarity.legendary,
    ),

    'social_butterfly': Badge(
      id: 'social_butterfly',
      name: 'Social Butterfly',
      description: 'Have 10+ friends',
      icon: '🦋',
      category: BadgeCategory.social,
      requiredPoints: 100,
      rarity: BadgeRarity.common,
    ),

    'contributor': Badge(
      id: 'contributor',
      name: 'Contributor',
      description: 'Create 50+ posts',
      icon: '📝',
      category: BadgeCategory.contributor,
      requiredPoints: 500,
      rarity: BadgeRarity.rare,
    ),

    'streak_master': Badge(
      id: 'streak_master',
      name: 'Streak Master',
      description: 'Maintain a 30-day learning streak',
      icon: '🔥',
      category: BadgeCategory.special,
      requiredPoints: 300,
      rarity: BadgeRarity.epic,
    ),

    'first_steps': Badge(
      id: 'first_steps',
      name: 'First Steps',
      description: 'Complete your first simulation',
      icon: '👶',
      category: BadgeCategory.explorer,
      requiredPoints: 10,
      rarity: BadgeRarity.common,
    ),

    'molecule_builder': Badge(
      id: 'molecule_builder',
      name: 'Molecule Builder',
      description: 'Create 10+ molecules in Molecular Builder',
      icon: '🔬',
      category: BadgeCategory.subject,
      requiredPoints: 100,
      rarity: BadgeRarity.common,
    ),

    // Finance & Business Badges
    'entrepreneur': Badge(
      id: 'entrepreneur',
      name: 'Entrepreneur',
      description: 'Complete all Business Workflow stages',
      icon: '🚀',
      category: BadgeCategory.subject,
      requiredPoints: 500,
      rarity: BadgeRarity.rare,
    ),

    'economist': Badge(
      id: 'economist',
      name: 'Economist',
      description: 'Master Economics Hub scenarios',
      icon: '📊',
      category: BadgeCategory.subject,
      requiredPoints: 300,
      rarity: BadgeRarity.rare,
    ),

    'master_accountant': Badge(
      id: 'master_accountant',
      name: 'Master Accountant',
      description: 'Create 20+ balanced journal entries',
      icon: '💰',
      category: BadgeCategory.subject,
      requiredPoints: 400,
      rarity: BadgeRarity.epic,
    ),

    'investment_guru': Badge(
      id: 'investment_guru',
      name: 'Investment Guru',
      description: 'Achieve 50%+ portfolio returns',
      icon: '💎',
      category: BadgeCategory.subject,
      requiredPoints: 600,
      rarity: BadgeRarity.epic,
    ),

    'finance_scholar': Badge(
      id: 'finance_scholar',
      name: 'Finance Scholar',
      description: 'Complete all finance modules',
      icon: '🎓',
      category: BadgeCategory.subject,
      requiredPoints: 1000,
      rarity: BadgeRarity.legendary,
    ),
  };
}

/// Defines the rarity levels for badges, affecting their visual presentation.
enum BadgeRarity {
  /// Easy to earn, awarded for initial milestones.
  common,

  /// Requires moderate effort or multiple completions.
  rare,

  /// Difficult to earn, awarded for significant mastery.
  epic,

  /// Extremely challenging, awarded for complete subject mastery or rare accomplishments.
  legendary,
}

/// Represents high-level gamification statistics for a user.
class UserStats {
  /// Unique identifier of the user.
  final String userId;

  /// User's unique handle.
  final String? username;

  /// User's display name.
  final String? fullName;

  /// URL to the user's profile picture.
  final String? avatarUrl;

  /// Total experience points accumulated by the user.
  final int totalXP;

  /// Current level of the user.
  final int level;

  /// List of badge IDs unlocked by the user.
  final List<String> unlockedBadges;

  /// Current consecutive days the user has been active.
  final int currentStreak;

  /// The longest consecutive active streak achieved by the user.
  final int longestStreak;

  /// Progress made in different subjects (subject name to count of completed simulations).
  final Map<String, int> subjectProgress;

  /// The timestamp of the user's last activity.
  final DateTime lastActive;

  /// Creates a [UserStats] instance.
  UserStats({
    required this.userId,
    this.username,
    this.fullName,
    this.avatarUrl,
    required this.totalXP,
    required this.level,
    required this.unlockedBadges,
    required this.currentStreak,
    required this.longestStreak,
    required this.subjectProgress,
    required this.lastActive,
  });

  /// The best available display name for the user.
  String get displayName =>
      fullName ?? username ?? 'User ${userId.substring(0, 6)}';

  /// The percentage progress toward the next level (0.0 to 1.0).
  double get levelProgress => xpProgress / xpForNextLevel;

  /// The total XP required to reach the next level from the start of the current level.
  int get xpForNextLevel => level * 100;

  /// The amount of XP earned within the current level.
  int get xpProgress => totalXP % xpForNextLevel;
}
