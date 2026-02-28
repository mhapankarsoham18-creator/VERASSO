// Phase 4: Rate Limiting with Shared Counters & Dynamic Feature Flags
// Implements the thundering herd prevention and A/B testing

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Shared Counter Service - Solves thundering herd problem
/// Uses Redis on backend to atomically increment counters
class AdvancedSharedCounterService {
  /// The duration in seconds to cache counter values locally.
  static const int cacheTtlSeconds = 5; // Local cache for 5 seconds
  /// The Supabase client used for database operations.
  final SupabaseClient _supabase;
  final Map<String, int> _localCache = {};

  final Map<String, DateTime> _cacheExpiry = {};

  /// Creates an [AdvancedSharedCounterService] instance.
  AdvancedSharedCounterService(this._supabase);

  /// Atomically decrement counter
  Future<int> atomicDecrement(String counterId, {int amount = 1}) async {
    try {
      final result = await _supabase.rpc('atomic_decrement_counter', params: {
        'counter_id': counterId,
        'decrement_amount': amount,
      });

      final newValue = result as int;
      _invalidateCache(counterId);
      return newValue;
    } catch (e) {
      AppLogger.error('Error decrementing counter', error: e);
      rethrow;
    }
  }

  /// Atomically increment counter (prevents thundering herd)
  Future<int> atomicIncrement(String counterId, {int amount = 1}) async {
    try {
      // Use Redis INCR atomically
      final result = await _supabase.rpc('atomic_increment_counter', params: {
        'counter_id': counterId,
        'increment_amount': amount,
      });

      final newValue = result as int;
      _localCache[counterId] = newValue;
      _cacheExpiry[counterId] = DateTime.now().add(
        Duration(seconds: cacheTtlSeconds),
      );

      return newValue;
    } catch (e) {
      AppLogger.error('Error incrementing counter', error: e);
      rethrow;
    }
  }

  /// Check and increment rate limit atomically
  Future<RateLimitResult> checkAndIncrementRateLimit({
    required String userId,
    required String action,
    required int maxRequests,
    required Duration timeWindow,
  }) async {
    final counterId = _generateRateLimitKey(userId, action, timeWindow);

    try {
      final currentCount = await atomicIncrement(counterId);

      // If first increment in window, set expiry
      if (currentCount == 1) {
        await _setCounterExpiry(counterId, timeWindow);
      }

      final isAllowed = currentCount <= maxRequests;
      final remaining = max(0, maxRequests - currentCount + 1);

      return RateLimitResult(
        isAllowed: isAllowed,
        currentCount: currentCount,
        maxRequests: maxRequests,
        remaining: remaining,
        resetTime: _calculateResetTime(counterId, timeWindow),
      );
    } catch (e) {
      AppLogger.warning('Error checking rate limit', error: e);
      // Fail open (allow) on error
      return RateLimitResult(
        isAllowed: true,
        currentCount: 0,
        maxRequests: maxRequests,
        remaining: maxRequests,
        resetTime: DateTime.now().add(timeWindow),
      );
    }
  }

  /// Get current counter value with local caching
  Future<int> getCounterValue(String counterId) async {
    // Check if cached and not expired
    if (_localCache.containsKey(counterId)) {
      if (_cacheExpiry[counterId]!.isAfter(DateTime.now())) {
        return _localCache[counterId]!;
      }
    }

    try {
      final response = await _supabase
          .from('shared_counters')
          .select('value')
          .eq('id', counterId)
          .single();

      final value = response['value'] as int;
      _localCache[counterId] = value;
      _cacheExpiry[counterId] = DateTime.now().add(
        Duration(seconds: cacheTtlSeconds),
      );

      return value;
    } catch (e) {
      AppLogger.error('Error getting counter value', error: e);
      rethrow;
    }
  }

  /// Initialize a counter atomically
  Future<void> initializeCounter(String counterId,
      {int initialValue = 0}) async {
    try {
      await _supabase.rpc('init_shared_counter_v2', params: {
        'counter_id': counterId,
        'initial_value': initialValue,
      });
      _invalidateCache(counterId);
    } catch (e) {
      AppLogger.error('Error initializing counter', error: e);
      rethrow;
    }
  }

  /// Reset counter
  Future<void> resetCounter(String counterId) async {
    try {
      await _supabase.rpc('reset_shared_counter', params: {
        'counter_id': counterId,
      });
      _invalidateCache(counterId);
    } catch (e) {
      AppLogger.error('Error resetting counter', error: e);
      rethrow;
    }
  }

  /// Calculate reset time for rate limit
  DateTime _calculateResetTime(String counterId, Duration window) {
    // In production, query Redis for actual TTL
    return DateTime.now().add(window);
  }

  String _generateRateLimitKey(
    String userId,
    String action,
    Duration window,
  ) {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(
      minutes: now.minute % window.inMinutes,
      seconds: now.second,
      milliseconds: now.millisecond,
      microseconds: now.microsecond,
    ));
    return 'ratelimit:$userId:$action:${windowStart.millisecondsSinceEpoch}';
  }

  void _invalidateCache(String counterId) {
    _localCache.remove(counterId);
    _cacheExpiry.remove(counterId);
  }

  /// Set expiry on counter using Redis (if window-based)
  Future<void> _setCounterExpiry(String counterId, Duration window) async {
    try {
      await _supabase.rpc('set_counter_expiry', params: {
        'counter_id': counterId,
        'ttl_seconds': window.inSeconds,
      });
    } catch (e) {
      AppLogger.warning('Error setting counter expiry', error: e);
    }
  }
}

/// Represents a complex feature flag with rollout and metadata support.
class FeatureFlag {
  /// The human-readable name of the feature flag.
  final String name;

  /// A description of the feature flag's purpose.
  final String description;

  /// Whether the feature flag is currently enabled globally.
  final bool enabled;

  /// Whether rollout based on percentage is enabled.
  final bool rolloutEnabled;

  /// The percentage of users to whom the feature is rolled out.
  final int rolloutPercentage;

  /// A list of user IDs explicitly allowed to access the feature.
  final List<String> allowedUserIds;

  /// Additional metadata associated with the feature flag.
  final Map<String, dynamic> metadata;

  /// The timestamp when the feature flag was created.
  final DateTime createdAt;

  /// The timestamp when the feature flag was last updated.
  final DateTime updatedAt;

  /// Creates a [FeatureFlag] instance.
  FeatureFlag({
    required this.name,
    required this.description,
    required this.enabled,
    required this.rolloutEnabled,
    required this.rolloutPercentage,
    required this.allowedUserIds,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [FeatureFlag] from a JSON map.
  factory FeatureFlag.fromJson(Map<String, dynamic> json) {
    return FeatureFlag(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      rolloutEnabled: json['rollout_enabled'] as bool? ?? false,
      rolloutPercentage: json['rollout_percentage'] as int? ?? 0,
      allowedUserIds: json['allowed_user_ids'] != null
          ? List<String>.from(jsonDecode(json['allowed_user_ids']) as List)
          : [],
      metadata: json['metadata'] != null
          ? jsonDecode(json['metadata']) as Map<String, dynamic>
          : {},
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Dynamic Feature Flag Service - Control features without app updates
class FeatureFlagService {
  /// The duration in seconds to cache feature flag definitions locally.
  static const int cacheTtlSeconds = 60;

  /// The Supabase client used for database operations.
  final SupabaseClient _supabase;
  final Map<String, FeatureFlag> _flagCache = {};

  final Map<String, DateTime> _flagCacheExpiry = {};

  /// Creates a [FeatureFlagService] instance.
  FeatureFlagService(this._supabase);

  /// Create new feature flag (admin only)
  Future<void> createFeatureFlag({
    required String name,
    required String description,
    required bool enabled,
    bool rolloutEnabled = false,
    int rolloutPercentage = 0,
    List<String> allowedUserIds = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await _supabase.from('feature_flags').insert({
        'name': name,
        'description': description,
        'enabled': enabled,
        'rollout_enabled': rolloutEnabled,
        'rollout_percentage': rolloutPercentage,
        'allowed_user_ids': jsonEncode(allowedUserIds),
        'metadata': jsonEncode(metadata),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      _invalidateFlag(name);
    } catch (e) {
      AppLogger.error('Error creating feature flag', error: e);
      rethrow;
    }
  }

  /// Delete feature flag
  Future<void> deleteFeatureFlag(String name) async {
    try {
      await _supabase.from('feature_flags').delete().eq('name', name);
      _invalidateFlag(name);
    } catch (e) {
      AppLogger.error('Error deleting feature flag', error: e);
      rethrow;
    }
  }

  /// Get all feature flags (public convenience wrapper)
  Future<List<FeatureFlag>> getAllFlags() => _getAllFeatureFlags();

  /// Get all enabled features for user
  Future<List<String>> getEnabledFeatures(String userId) async {
    try {
      final flags = await _getAllFeatureFlags();

      return flags
          .where((flag) => _isUserInAudience(flag, userId) && flag.enabled)
          .map((flag) => flag.name)
          .toList();
    } catch (e) {
      AppLogger.warning('Error getting enabled features', error: e);
      return [];
    }
  }

  /// Get feature flag metadata
  Future<FeatureFlag?> getFeatureMetadata(String featureName) async {
    try {
      if (_flagCache.containsKey(featureName) &&
          _flagCacheExpiry[featureName]!.isAfter(DateTime.now())) {
        return _flagCache[featureName];
      }

      return await _getFeatureFlag(featureName);
    } catch (e) {
      AppLogger.warning('Error getting feature metadata', error: e);
      return null;
    }
  }

  /// Check if feature is enabled for user
  Future<bool> isFeatureEnabled({
    required String featureName,
    required String userId,
  }) async {
    // Try cache first
    if (_flagCache.containsKey(featureName)) {
      if (_flagCacheExpiry[featureName]!.isAfter(DateTime.now())) {
        return _isUserInAudience(
          _flagCache[featureName]!,
          userId,
        );
      }
    }

    try {
      final flag = await _getFeatureFlag(featureName);
      _flagCache[featureName] = flag;
      _flagCacheExpiry[featureName] = DateTime.now().add(
        Duration(seconds: cacheTtlSeconds),
      );

      return _isUserInAudience(flag, userId);
    } catch (e) {
      AppLogger.warning('Error checking feature flag', error: e);
      // Fail closed (disable) for safety
      return false;
    }
  }

  /// Update feature flag state
  Future<void> updateFeatureFlag({
    required String name,
    bool? enabled,
    bool? rolloutEnabled,
    int? rolloutPercentage,
    List<String>? allowedUserIds,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (enabled != null) updates['enabled'] = enabled;
      if (rolloutEnabled != null) updates['rollout_enabled'] = rolloutEnabled;
      if (rolloutPercentage != null) {
        updates['rollout_percentage'] = rolloutPercentage;
      }
      if (allowedUserIds != null) {
        updates['allowed_user_ids'] = jsonEncode(allowedUserIds);
      }

      await _supabase.from('feature_flags').update(updates).eq('name', name);

      _invalidateFlag(name);
    } catch (e) {
      AppLogger.error('Error updating feature flag', error: e);
      rethrow;
    }
  }

  /// Update a feature flag by name (public convenience wrapper)
  Future<void> updateFlag(
    String name, {
    bool? enabled,
    int? rolloutPercentage,
    List<String>? allowedUserIds,
  }) =>
      updateFeatureFlag(
        name: name,
        enabled: enabled,
        rolloutPercentage: rolloutPercentage,
        allowedUserIds: allowedUserIds,
      );

  Future<List<FeatureFlag>> _getAllFeatureFlags() async {
    final response = await _supabase.from('feature_flags').select();

    return (response as List)
        .map((flag) => FeatureFlag.fromJson(flag as Map<String, dynamic>))
        .toList();
  }

  Future<FeatureFlag> _getFeatureFlag(String featureName) async {
    final response = await _supabase
        .from('feature_flags')
        .select()
        .eq('name', featureName)
        .single();

    return FeatureFlag.fromJson(response);
  }

  void _invalidateFlag(String flagName) {
    _flagCache.remove(flagName);
    _flagCacheExpiry.remove(flagName);
  }

  /// Check if user is in audience for flag
  bool _isUserInAudience(FeatureFlag flag, String userId) {
    if (!flag.enabled) return false;

    // Check whitelisted users
    if (flag.allowedUserIds.isNotEmpty &&
        flag.allowedUserIds.contains(userId)) {
      return true;
    }

    // Check rollout percentage
    if (flag.rolloutEnabled) {
      // Use hash of userId for consistent rollout
      final hashValue = userId.hashCode.abs();
      final userPercentile = (hashValue % 100) + 1;
      return userPercentile <= flag.rolloutPercentage;
    }

    return false;
  }
}

/// Data Models

class RateLimitResult {
  /// Whether the request is allowed.
  final bool isAllowed;

  /// The current request count in the window.
  final int currentCount;

  /// The maximum number of requests allowed in the window.
  final int maxRequests;

  /// The number of requests remaining in the window.
  final int remaining;

  /// The time when the rate limit window resets.
  final DateTime resetTime;

  /// Creates a [RateLimitResult] instance.
  RateLimitResult({
    required this.isAllowed,
    required this.currentCount,
    required this.maxRequests,
    required this.remaining,
    required this.resetTime,
  });
}

// SQL Schema for Phase 4

/*
-- Feature Flags table
CREATE TABLE IF NOT EXISTS public.feature_flags (
  id BIGSERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  enabled BOOLEAN DEFAULT FALSE,
  rollout_enabled BOOLEAN DEFAULT FALSE,
  rollout_percentage INTEGER DEFAULT 0,
  allowed_user_ids JSONB DEFAULT '[]',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_feature_flags_name ON public.feature_flags(name);
CREATE INDEX idx_feature_flags_enabled ON public.feature_flags(enabled);

-- Rate limiting counters (Redis-backed in production)
CREATE TABLE IF NOT EXISTS public.rate_limit_counters (
  id TEXT PRIMARY KEY,
  value INTEGER DEFAULT 0,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_rate_limit_expires ON public.rate_limit_counters(expires_at);

-- RLS Policies
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit_counters ENABLE ROW LEVEL SECURITY;

-- Feature flags readable by all authenticated users
CREATE POLICY "Authenticated users can view feature flags"
  ON public.feature_flags FOR SELECT
  TO authenticated
  USING (true);

-- Rate limits are internal only
CREATE POLICY "System can manage rate limits"
  ON public.rate_limit_counters
  USING (true);
*/
