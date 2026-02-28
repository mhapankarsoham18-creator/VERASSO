import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';

/// Provider for the [ForecastingAiService].
final forecastingAiServiceProvider = Provider((ref) {
  return ForecastingAiService(ref.watch(progressTrackingServiceProvider));
});

/// AI-driven insights for student learning.
///
/// Analyzes progress to predict knowledge gaps and optimize study patterns.
class ForecastingAiService {
  final ProgressTrackingService _progressService;

  /// Creates a [ForecastingAiService].
  ForecastingAiService(this._progressService);

  /// Analyzes progress to identify subjects needing attention.
  Map<String, double> identifyKnowledgeGaps(UserProgressModel progress) {
    // Logic: Identify categories with lower relative scores or progress
    final gaps = <String, double>{};

    final stats = {
      'Physics': progress.circuitsSimulated,
      'AR Projects': progress.arProjectsCompleted,
      'General Theory': progress.lessonsCompleted,
    };

    final total = stats.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return {'Getting Started': 1.0};

    stats.forEach((subject, count) {
      final percentageOfTotal = count / total;
      if (percentageOfTotal < 0.2) {
        // Less than 20% of effort in this area
        gaps[subject] = 1.0 - (percentageOfTotal * 5); // Normalized priority
      }
    });

    return gaps;
  }

  /// Predicts future performance based on current trends.
  Future<double> predictExamReadiness() async {
    final progress = await _progressService.getUserProgressSummary();

    // Weighted factors for readiness
    final factor1 = progress.quizAverageScore * 0.5; // Accuracy matters most
    final factor2 =
        (progress.streakDays / 7).clamp(0.0, 1.0) * 0.2; // Consistency
    final factor3 =
        (progress.lessonsCompleted / 20).clamp(0.0, 1.0) * 0.3; // Depth

    return factor1 + factor2 + factor3;
  }

  /// Recommends optimal study times based on user historical activity.
  Future<List<StudyScheduleItem>> suggestStudySchedule() async {
    try {
      final activities = await _progressService.getRecentActivities(limit: 50);

      if (activities.isEmpty) {
        return [
          StudyScheduleItem(
            time: '09:00 AM',
            reason: 'Fresh start for a new learner!',
            subject: 'Orientation',
          ),
          StudyScheduleItem(
            time: '02:00 PM',
            reason: 'Good time for a quick review.',
            subject: 'Fundamentals',
          ),
        ];
      }

      // Analyze peak activity hours
      final hourlyActivity = <int, int>{};
      for (final activity in activities) {
        final hour = activity.createdAt.hour;
        hourlyActivity[hour] = (hourlyActivity[hour] ?? 0) + 1;
      }

      final peakHour = hourlyActivity.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final formattedPeak = _formatHour(peakHour);
      final secondPeak = _formatHour((peakHour + 4) % 24);

      return [
        StudyScheduleItem(
          time: formattedPeak,
          reason: 'Your peak productivity interval based on past activity.',
          subject: 'Core Focus',
        ),
        StudyScheduleItem(
          time: secondPeak,
          reason: 'Ideal secondary slot to maintain consistency.',
          subject: 'Review Session',
        ),
      ];
    } catch (e, stack) {
      AppLogger.error('Error suggesting study schedule', error: e);
      SentryService.captureException(e, stackTrace: stack);
      return [
        StudyScheduleItem(
          time: '10:00 AM',
          reason: 'General peak productivity window.',
          subject: 'Priority Learning',
        ),
      ];
    }
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }
}

/// Represents a recommended study session.
class StudyScheduleItem {
  /// The time of the session (e.g., '02:00 PM').
  final String time;

  /// The reason why this time was suggested.
  final String reason;

  /// The suggested subject for study.
  final String subject;

  /// Creates a [StudyScheduleItem].
  StudyScheduleItem({
    required this.time,
    required this.reason,
    required this.subject,
  });
}
