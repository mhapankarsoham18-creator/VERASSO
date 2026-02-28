/// Utility class for calculating relevance scores based on user interests and content tags.
class WeightedTagScorer {
  // Score weights
  /// Multiplier for exact tag matches.
  static const double matchWeight = 5.0;

  /// Multiplier for partial tag matches.
  static const double secondaryMatchWeight = 2.0; // Partial match

  /// Score bonus per unit of popularity (like/view).
  static const double popularityWeight = 0.1; // Per like/view

  /// Calculates a relevance score for an item based on user interests
  static double score({
    required List<String> itemTags,
    required List<String> userInterests,
    int popularityScore = 0,
    DateTime? createdAt,
  }) {
    double score = 0.0;

    // 1. Tag Matching
    for (final tag in itemTags) {
      final normalizedTag = tag.toLowerCase().trim();
      if (userInterests.contains(normalizedTag)) {
        score += matchWeight;
      } else {
        // Check for partial matches (e.g., "flutter" matches "flutter dev")
        bool partial = userInterests.any((interest) =>
            interest.contains(normalizedTag) ||
            normalizedTag.contains(interest));
        if (partial) {
          score += secondaryMatchWeight;
        }
      }
    }

    // 2. Popularity Boost
    score += (popularityScore * popularityWeight);

    // 3. Recency Decay (if date provided)
    if (createdAt != null) {
      final daysOld = DateTime.now().difference(createdAt).inDays;
      // Simple linear decay: lose 0.5 score per day, min 0
      final decay = daysOld * 0.5;
      score = (score - decay).clamp(0.0, double.infinity);
    }

    return score;
  }
}
