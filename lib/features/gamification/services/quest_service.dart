import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Provider for the [QuestService].
final questServiceProvider = Provider<QuestService>((ref) {
  return QuestService(Supabase.instance.client);
});

/// Model for a quest.
class Quest {
  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Description.
  final String description;

  /// Type: daily, weekly, seasonal.
  final String questType;

  /// Action type that counts toward this quest.
  final String actionType;

  /// Number of actions needed to complete.
  final int targetCount;

  /// XP reward on completion.
  final int xpReward;

  /// Creates a [Quest].
  const Quest({
    required this.id,
    required this.name,
    required this.description,
    required this.questType,
    required this.actionType,
    required this.targetCount,
    required this.xpReward,
  });

  /// Creates from JSON.
  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
        id: json['id'],
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        questType: json['quest_type'] ?? 'daily',
        actionType: json['action_type'] ?? '',
        targetCount: json['target_count'] ?? 1,
        xpReward: json['xp_reward'] ?? 0,
      );

  /// Icon for quest type.
  String get typeIcon {
    switch (questType) {
      case 'daily':
        return '☀️';
      case 'weekly':
        return '📅';
      case 'seasonal':
        return '🏆';
      default:
        return '⭐';
    }
  }
}

/// Model for user's progress on a quest.
class QuestProgress {
  /// The quest.
  final Quest quest;

  /// Current count of actions done.
  final int currentCount;

  /// Whether the quest is completed.
  final bool isCompleted;

  /// When the quest was completed.
  final DateTime? completedAt;

  /// Creates a [QuestProgress].
  const QuestProgress({
    required this.quest,
    required this.currentCount,
    required this.isCompleted,
    this.completedAt,
  });

  /// Progress fraction (0.0 - 1.0).
  double get progressFraction =>
      (currentCount / quest.targetCount).clamp(0.0, 1.0);

  /// Remaining count.
  int get remaining =>
      (quest.targetCount - currentCount).clamp(0, quest.targetCount);
}

/// Service for fetching and managing quests.
class QuestService {
  final SupabaseClient _supabase;

  /// Creates a [QuestService].
  QuestService(this._supabase);

  /// Gets all active quests with progress.
  Future<List<QuestProgress>> getAllQuests() async {
    final daily = await getDailyQuests();
    final weekly = await getWeeklyQuests();
    return [...daily, ...weekly];
  }

  /// Gets active daily quests with user progress.
  Future<List<QuestProgress>> getDailyQuests() async {
    return _getQuests('daily');
  }

  /// Gets summary stats for the quest dashboard.
  Future<Map<String, int>> getQuestStats() async {
    final all = await getAllQuests();
    final completed = all.where((q) => q.isCompleted).length;
    return {
      'total': all.length,
      'completed': completed,
      'remaining': all.length - completed,
    };
  }

  /// Gets active weekly quests with user progress.
  Future<List<QuestProgress>> getWeeklyQuests() async {
    return _getQuests('weekly');
  }

  Future<List<QuestProgress>> _getQuests(String type) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get active quests of this type
      final quests = await _supabase
          .from('quests')
          .select()
          .eq('quest_type', type)
          .eq('is_active', true);

      final now = DateTime.now();
      final resetAt = type == 'daily'
          ? DateTime(now.year, now.month, now.day).toIso8601String()
          : DateTime(now.year, now.month, now.day - now.weekday + 1)
              .toIso8601String();

      // Get user progress for these quests
      final questIds = (quests as List).map((q) => q['id'] as String).toList();
      if (questIds.isEmpty) return [];

      final progress = await _supabase
          .from('user_quest_progress')
          .select()
          .eq('user_id', userId)
          .inFilter('quest_id', questIds)
          .eq('reset_at', resetAt);

      final progressMap = <String, Map<String, dynamic>>{};
      for (final p in progress as List) {
        progressMap[p['quest_id']] = p;
      }

      return (quests as List).map((q) {
        final quest = Quest.fromJson(q);
        final p = progressMap[quest.id];
        return QuestProgress(
          quest: quest,
          currentCount: p?['current_count'] ?? 0,
          isCompleted: p?['is_completed'] ?? false,
          completedAt: p?['completed_at'] != null
              ? DateTime.parse(p!['completed_at'])
              : null,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch quests', error: e);
      return [];
    }
  }
}
