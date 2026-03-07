/// Controls per-region difficulty scaling for enemy counts, HP, and speed.
class DifficultyConfig {
  /// Number of enemies to spawn.
  final int enemyCount;

  /// Health multiplier applied to all enemies in this region.
  final double healthMultiplier;

  /// Speed multiplier applied to all enemies in this region.
  final double speedMultiplier;

  /// Region number (1-25).
  final int region;

  /// Generates a [DifficultyConfig] for the given [region].
  ///
  /// - Enemy count: starts at 4 in R1, increases by 2 per region.
  /// - Health multiplier: 1.0× in R1 → 1.8× in R5.
  /// - Speed multiplier: 1.0× in R1 → 1.4× in R5.
  factory DifficultyConfig.forRegion(int region) {
    final r = region.clamp(1, 25);
    return DifficultyConfig._(
      region: r,
      enemyCount: 4 + (r - 1) * 2,
      healthMultiplier: 1.0 + (r - 1) * 0.2,
      speedMultiplier: 1.0 + (r - 1) * 0.1,
    );
  }

  const DifficultyConfig._({
    required this.region,
    required this.enemyCount,
    required this.healthMultiplier,
    required this.speedMultiplier,
  });
}
