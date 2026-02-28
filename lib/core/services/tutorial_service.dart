import 'package:shared_preferences/shared_preferences.dart';

/// Tutorial IDs
/// Unique constants for identifying different application tutorials.
class TutorialIds {
  /// Tutorial for the ROI simulator tool.
  static const String roiSimulator = 'roi_simulator';

  /// Tutorial for the general economics marketplace.
  static const String economicsHub = 'economics_hub';

  /// Tutorial for the interactive accounting dashboard.
  static const String accountingSimulator = 'accounting_simulator';

  /// Tutorial for the business lifecycle workflow.
  static const String businessWorkflow = 'business_workflow';

  /// Tutorial for the investment portfolio tracker.
  static const String portfolioTracker = 'portfolio_tracker';

  /// Tutorial for the central finance management hub.
  static const String financeHub = 'finance_hub';

  /// Tutorial for the stories and dynamic updates feature.
  static const String storiesFeature = 'stories_feature';

  /// Tutorial for the main social learning feed.
  static const String feedFeature = 'feed_feature';
}

/// Service to track and manage tutorial completion state
/// Service to track and manage the completion state of user tutorials.
class TutorialService {
  static const String _prefix = 'tutorial_completed_';

  /// Get list of all completed tutorials
  static Future<List<String>> getCompletedTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    return keys.map((key) => key.replaceFirst(_prefix, '')).toList();
  }

  /// Check if a specific tutorial has been completed
  static Future<bool> isTutorialCompleted(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$tutorialId') ?? false;
  }

  /// Mark a tutorial as completed
  static Future<void> markTutorialCompleted(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$tutorialId', true);
  }

  /// Reset all tutorials (for testing purposes)
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Reset a tutorial (for testing purposes)
  static Future<void> resetTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$tutorialId');
  }
}
