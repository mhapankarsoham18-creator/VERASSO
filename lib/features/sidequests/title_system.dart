class TitleTier {
  final String title;
  final int xpThreshold;
  final String emoji;

  TitleTier(this.title, this.xpThreshold, this.emoji);
}

class TitleSystem {
  static List<TitleTier> tiers = [
    TitleTier('Wanderer', 0, '🚶‍♂️'),
    TitleTier('Explorer', 500, '🗺️'),
    TitleTier('Adventurer', 1500, '⚔️'),
    TitleTier('Trailblazer', 3000, '🔥'),
    TitleTier('Drifter', 5000, '🌪️'),
    TitleTier('Nomad', 8000, '🐪'),
    TitleTier('Sage', 12000, '🔮'),
    TitleTier('Legend', 20000, '👑'),
  ];

  /// Returns the current title tier based on XP
  static TitleTier getCurrentTier(int xp) {
    for (int i = tiers.length - 1; i >= 0; i--) {
      if (xp >= tiers[i].xpThreshold) return tiers[i];
    }
    return tiers.first;
  }

  /// Returns the next possible title tier, or null if at max
  static TitleTier? getNextTier(int xp) {
    for (int i = 0; i < tiers.length; i++) {
      if (tiers[i].xpThreshold > xp) return tiers[i];
    }
    return null; // Already max level
  }

  /// Calculates the progress percentage (0.0 to 1.0) towards the next tier.
  static double getProgressToNextTier(int xp) {
    final currentTier = getCurrentTier(xp);
    final nextTier = getNextTier(xp);

    if (nextTier == null) return 1.0; // Max tier reached

    final xpIntoCurrentTier = xp - currentTier.xpThreshold;
    final xpNeededForNextTier = nextTier.xpThreshold - currentTier.xpThreshold;

    return (xpIntoCurrentTier / xpNeededForNextTier).clamp(0.0, 1.0);
  }

  /// Returns whether this exact XP amount means the user JUST leveled up.
  /// (Useful for triggering the level up ceremony animation)
  static bool didJustLevelUp(int oldXp, int newXp) {
    final oldTier = getCurrentTier(oldXp);
    final newTier = getCurrentTier(newXp);
    return newTier.xpThreshold > oldTier.xpThreshold;
  }
}
