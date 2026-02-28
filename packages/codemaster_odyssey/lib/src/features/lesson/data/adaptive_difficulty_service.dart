import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [AdaptiveDifficultyService], which scales challenge difficulty.
final adaptiveDifficultyProvider =
    NotifierProvider<AdaptiveDifficultyService, double>(
      AdaptiveDifficultyService.new,
    );

/// Service that adjusts the difficulty multiplier based on user performance.
class AdaptiveDifficultyService extends Notifier<double> {
  @override
  double build() {
    return 1.0; // Default difficulty multiplier
  }

  /// Decreases difficulty when the user encounters repeated failures.
  void recordFailure() {
    // If user fails too much, reduce difficulty or offer tips
    if (state > 0.5) {
      state -= 0.1;
    }
  }

  /// Increases difficulty when the user succeeds rapidly.
  void recordSuccess() {
    if (state < 2.0) {
      state += 0.05;
    }
  }

  /// Returns true if the system should offer additional help to the user.
  bool shouldUnlockHelp() {
    return state < 0.7;
  }
}
