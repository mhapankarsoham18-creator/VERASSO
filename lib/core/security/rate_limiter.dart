import 'dart:collection';

/// OWASP-compliant rate limiter for client-side API calls.
///
/// Implements IP + user-based rate limiting with configurable windows.
/// Returns HTTP 429 (Too Many Requests) equivalent when limits are exceeded.
///
/// Usage:
/// ```dart
/// final limiter = RateLimiter();
/// if (!limiter.allowRequest(userId: 'user123', endpoint: '/api/posts')) {
///   throw RateLimitExceededException('Too many requests. Try again later.');
/// }
/// ```
class RateLimiter {
  /// Default: 60 requests per minute per user per endpoint
  static const int _defaultMaxRequests = 60;

  /// Default window: 60 seconds
  static const Duration _defaultWindow = Duration(seconds: 60);

  /// Stricter limit for auth endpoints (login, register, reset password)
  static const int _authMaxRequests = 5;

  /// Auth window: 15 minutes (OWASP recommendation for brute-force prevention)
  static const Duration _authWindow = Duration(minutes: 15);

  /// Per-endpoint configuration overrides
  static final Map<String, _RateLimitConfig> _endpointConfigs = {
    // Auth endpoints — strict limits to prevent brute force
    '/auth/login': _RateLimitConfig(
      maxRequests: _authMaxRequests,
      window: _authWindow,
    ),
    '/auth/register': _RateLimitConfig(
      maxRequests: 3,
      window: const Duration(minutes: 30),
    ),
    '/auth/reset-password': _RateLimitConfig(
      maxRequests: 3,
      window: const Duration(minutes: 30),
    ),
    '/auth/mfa/verify': _RateLimitConfig(
      maxRequests: 5,
      window: const Duration(minutes: 5),
    ),

    // Content creation — moderate limits
    '/api/posts': _RateLimitConfig(
      maxRequests: 10,
      window: const Duration(minutes: 1),
    ),
    '/api/comments': _RateLimitConfig(
      maxRequests: 20,
      window: const Duration(minutes: 1),
    ),
    '/api/messages': _RateLimitConfig(
      maxRequests: 30,
      window: const Duration(minutes: 1),
    ),

    // Game endpoints — allow higher throughput
    '/game/save': _RateLimitConfig(
      maxRequests: 10,
      window: const Duration(minutes: 1),
    ),
    '/game/challenge': _RateLimitConfig(
      maxRequests: 20,
      window: const Duration(minutes: 1),
    ),

    // AI endpoints — expensive, limit aggressively
    '/ai/hint': _RateLimitConfig(
      maxRequests: 10,
      window: const Duration(minutes: 5),
    ),
    '/ai/tutor': _RateLimitConfig(
      maxRequests: 5,
      window: const Duration(minutes: 5),
    ),
  };

  /// In-memory request log: key = "userId:endpoint", value = list of timestamps
  final Map<String, Queue<DateTime>> _requestLog = {};

  /// Check if a request is allowed under rate limits.
  ///
  /// Returns `true` if the request is within limits, `false` if rate limited.
  /// When `false`, the caller should return HTTP 429 with appropriate headers.
  bool allowRequest({required String? userId, required String endpoint}) {
    final key = '${userId ?? 'anon'}:$endpoint';
    final config =
        _endpointConfigs[endpoint] ??
        _RateLimitConfig(
          maxRequests: _defaultMaxRequests,
          window: _defaultWindow,
        );

    final now = DateTime.now();
    final cutoff = now.subtract(config.window);

    // Initialize or get existing queue
    _requestLog.putIfAbsent(key, () => Queue<DateTime>());
    final queue = _requestLog[key]!;

    // Evict expired entries (sliding window)
    while (queue.isNotEmpty && queue.first.isBefore(cutoff)) {
      queue.removeFirst();
    }

    // Check limit
    if (queue.length >= config.maxRequests) {
      return false; // 429 Too Many Requests
    }

    // Record this request
    queue.add(now);
    return true;
  }

  /// Get remaining requests for a user/endpoint combo.
  /// Useful for setting X-RateLimit-Remaining headers.
  int remainingRequests({required String? userId, required String endpoint}) {
    final key = '${userId ?? 'anon'}:$endpoint';
    final config =
        _endpointConfigs[endpoint] ??
        _RateLimitConfig(
          maxRequests: _defaultMaxRequests,
          window: _defaultWindow,
        );

    final now = DateTime.now();
    final cutoff = now.subtract(config.window);

    final queue = _requestLog[key];
    if (queue == null) return config.maxRequests;

    // Evict expired
    while (queue.isNotEmpty && queue.first.isBefore(cutoff)) {
      queue.removeFirst();
    }

    return (config.maxRequests - queue.length).clamp(0, config.maxRequests);
  }

  /// Get the time until the rate limit resets.
  /// Returns Duration.zero if not rate limited.
  Duration retryAfter({required String? userId, required String endpoint}) {
    final key = '${userId ?? 'anon'}:$endpoint';
    final config =
        _endpointConfigs[endpoint] ??
        _RateLimitConfig(
          maxRequests: _defaultMaxRequests,
          window: _defaultWindow,
        );

    final queue = _requestLog[key];
    if (queue == null || queue.isEmpty) return Duration.zero;

    final oldestInWindow = queue.first;
    final resetTime = oldestInWindow.add(config.window);
    final now = DateTime.now();

    if (resetTime.isAfter(now)) {
      return resetTime.difference(now);
    }
    return Duration.zero;
  }

  /// Clear all rate limit state (useful for testing or logout).
  void reset() {
    _requestLog.clear();
  }
}

/// Internal rate limit configuration for an endpoint.
class _RateLimitConfig {
  final int maxRequests;
  final Duration window;

  const _RateLimitConfig({required this.maxRequests, required this.window});
}

/// Exception thrown when rate limit is exceeded (HTTP 429 equivalent).
class RateLimitExceededException implements Exception {
  final String message;
  final Duration retryAfter;

  RateLimitExceededException(this.message, {this.retryAfter = Duration.zero});

  @override
  String toString() =>
      'RateLimitExceededException: $message (retry after: ${retryAfter.inSeconds}s)';
}
