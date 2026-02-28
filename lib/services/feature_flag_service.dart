// Dynamic Feature Flag System
// Supports gradual rollout, A/B testing, and real-time flag updates

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/monitoring/sentry_service.dart';

/// Provider for getting all enabled features for the current user.
final allFeaturesProvider = FutureProvider<Map<String, bool>>((ref) async {
  final service = ref.watch(featureFlagServiceProvider);
  await service.initialize();

  final userId = Supabase.instance.client.auth.currentUser?.id;
  return service.getAllEnabledFeatures(userContext: {
    'userId': userId,
  });
});

// ============================================================================
// RIVERPOD PROVIDER
// ============================================================================

/// Provider for checking if a specific feature is enabled.
final featureEnabledProvider =
    FutureProvider.family<bool, String>((ref, key) async {
  final service = ref.watch(featureFlagServiceProvider);
  await service.initialize();

  final userId = Supabase.instance.client.auth.currentUser?.id;
  return service.isFeatureEnabled(key, userContext: {
    'userId': userId,
  });
});

/// Provider for the [FeatureFlagService] instance.
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  final supabase = Supabase.instance.client;
  return FeatureFlagService(supabase);
});

/// Represents a dynamic feature flag.
class FeatureFlag {
  /// The unique key for the feature flag.
  final String key;

  /// The human-readable name of the feature.
  final String name;

  /// A description of what the feature does.
  final String description;

  /// Whether the feature is currently enabled.
  final bool enabled;

  /// The percentage of users who should see this feature (0-100).
  final int rolloutPercentage; // 0-100

  /// A list of rules for specific user targeting.
  final List<TargetingRule> targetingRules;

  /// Creates a [FeatureFlag] instance.
  FeatureFlag({
    required this.key,
    required this.name,
    required this.description,
    required this.enabled,
    required this.rolloutPercentage,
    required this.targetingRules,
  });

  /// Creates a [FeatureFlag] from a JSON map.
  factory FeatureFlag.fromJson(Map<String, dynamic> json) => FeatureFlag(
        key: json['key'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
        rolloutPercentage: json['rollout_percentage'] as int? ?? 0,
        targetingRules: (json['targeting_rules'] as List?)
                ?.map((r) => TargetingRule.fromJson(r))
                .toList() ??
            [],
      );

  /// Converts the [FeatureFlag] instance to a JSON map.
  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'description': description,
        'enabled': enabled,
        'rollout_percentage': rolloutPercentage,
        'targeting_rules': targetingRules.map((r) => r.toJson()).toList(),
      };
}

// ============================================================================
// DATA MODELS
// ============================================================================

/// Input data for creating or updating a feature flag.
class FeatureFlagInput {
  /// The unique key for the flag.
  final String key;

  /// The name of the flag.
  final String name;

  /// The description for the flag.
  final String description;

  /// Whether the flag should be enabled by default.
  final bool enabled;

  /// The initial rollout percentage.
  final int rolloutPercentage;

  /// The initial set of targeting rules.
  final List<TargetingRule> targetingRules;

  /// Creates a [FeatureFlagInput] instance.
  FeatureFlagInput({
    required this.key,
    required this.name,
    this.description = '',
    this.enabled = true,
    this.rolloutPercentage = 100,
    this.targetingRules = const [],
  });
}

/// Service for managing dynamic feature flags.
class FeatureFlagService {
  /// The Supabase client instance.
  final SupabaseClient _supabase;
  final Map<String, FeatureFlag> _flagCache = {};
  late RealtimeChannel _realtimeChannel;
  bool _initialized = false;

  /// Creates a [FeatureFlagService] instance.
  FeatureFlagService(this._supabase);

  /// Delete feature flag
  Future<void> deleteFlag(String key) async {
    try {
      await _supabase.from('feature_flags').delete().eq('key', key);
      _flagCache.remove(key);
    } catch (e, stack) {
      AppLogger.error('Error deleting feature flag', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Cleanup
  void dispose() {
    if (_initialized) {
      _realtimeChannel.unsubscribe();
    }
  }

  /// Get all enabled features
  Map<String, bool> getAllEnabledFeatures({
    Map<String, dynamic>? userContext,
  }) {
    return Map.fromEntries(
      _flagCache.entries.map((entry) => MapEntry(
            entry.key,
            isFeatureEnabled(entry.key, userContext: userContext),
          )),
    );
  }

  /// Get feature flag details
  FeatureFlag? getFlag(String key) => _flagCache[key];

  /// Initialize feature flag service with real-time updates
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load all flags into cache
      final flags = await _supabase.from('feature_flags').select();

      for (final flagJson in flags) {
        final flag = FeatureFlag.fromJson(flagJson);
        _flagCache[flag.key] = flag;
      }

      // Listen to real-time updates
      _realtimeChannel = _supabase.realtime.channel('feature_flags');
      _realtimeChannel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'feature_flags',
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty) {
                final flag = FeatureFlag.fromJson(
                  Map<String, dynamic>.from(newRecord),
                );
                _flagCache[flag.key] = flag;
              }
            },
          )
          .subscribe();

      _initialized = true;
    } catch (e, stack) {
      AppLogger.error('Error initializing feature flags', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Check if feature is enabled for current user
  /// Evaluates target criteria (percentage, user segment, etc.)
  bool isFeatureEnabled(
    String featureFlagKey, {
    Map<String, dynamic>? userContext,
  }) {
    final flag = _flagCache[featureFlagKey];
    if (flag == null) return false;

    if (!flag.enabled) return false;

    // Check if feature is globally enabled
    if (flag.rolloutPercentage == 100) return true;

    // Check user-specific targeting
    if (userContext != null) {
      return _evaluateTargeting(flag, userContext);
    }

    // Fallback: use random percentage
    return _checkRolloutPercentage(flag.key, flag.rolloutPercentage);
  }

  /// Create or update feature flag (admin only)
  Future<void> updateFlag(FeatureFlagInput input) async {
    try {
      await _supabase.from('feature_flags').upsert({
        'key': input.key,
        'name': input.name,
        'description': input.description,
        'enabled': input.enabled,
        'rollout_percentage': input.rolloutPercentage,
        'targeting_rules': input.targetingRules,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update local cache
      _flagCache[input.key] = FeatureFlag(
        key: input.key,
        name: input.name,
        description: input.description,
        enabled: input.enabled,
        rolloutPercentage: input.rolloutPercentage,
        targetingRules: input.targetingRules,
      );
    } catch (e, stack) {
      AppLogger.error('Error updating feature flag', error: e);
      SentryService.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Check rollout percentage using user ID as seed
  bool _checkRolloutPercentage(String featureKey, int percentage) {
    final userId = _supabase.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return percentage == 100;

    // Consistent hash across app instance
    final hash = _hashString('$featureKey:$userId');
    return (hash % 100) < percentage;
  }

  /// Evaluate single targeting rule
  bool _evaluateRule(TargetingRule rule, Map<String, dynamic> userContext) {
    final userValue = userContext[rule.attribute];
    if (userValue == null) return false;

    switch (rule.operator) {
      case 'equals':
        return userValue == rule.value;
      case 'contains':
        return userValue.toString().contains(rule.value);
      case 'in':
        return (rule.value as List).contains(userValue);
      case 'greater_than':
        return (userValue as num) > (rule.value as num);
      case 'less_than':
        return (userValue as num) < (rule.value as num);
      case 'starts_with':
        return userValue.toString().startsWith(rule.value);
      case 'regex':
        return RegExp(rule.value).hasMatch(userValue.toString());
      default:
        return false;
    }
  }

  /// Evaluate targeting rules for user
  bool _evaluateTargeting(
    FeatureFlag flag,
    Map<String, dynamic> userContext,
  ) {
    if (flag.targetingRules.isEmpty) {
      return _checkRolloutPercentage(flag.key, flag.rolloutPercentage);
    }

    // Evaluate each rule with AND logic
    for (final rule in flag.targetingRules) {
      if (!_evaluateRule(rule, userContext)) {
        return false;
      }
    }

    return true;
  }

  /// Simple hash function for consistent percentage assignment
  int _hashString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      final char = input.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return hash.abs();
  }
}

/// Represents a single targeting rule for a feature flag.
class TargetingRule {
  /// The user attribute to evaluate (e.g., 'userId', 'region').
  final String attribute;

  /// The operator to use for evaluation (e.g., 'equals', 'contains').
  final String
      operator; // 'equals', 'contains', 'in', 'greater_than', 'less_than', 'starts_with', 'regex'

  /// The value to compare against.
  final dynamic value;

  /// Creates a [TargetingRule] instance.
  TargetingRule({
    required this.attribute,
    required this.operator,
    required this.value,
  });

  /// Creates a [TargetingRule] from a JSON map.
  factory TargetingRule.fromJson(Map<String, dynamic> json) => TargetingRule(
        attribute: json['attribute'] as String,
        operator: json['operator'] as String,
        value: json['value'],
      );

  /// Converts the [TargetingRule] instance to a JSON map.
  Map<String, dynamic> toJson() => {
        'attribute': attribute,
        'operator': operator,
        'value': value,
      };
}
