import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider for the [SessionTimeoutService], used to manage user inactivity.
final sessionTimeoutProvider =
    ChangeNotifierProvider((ref) => SessionTimeoutService());

/// Service that monitors user inactivity and triggers a session lock.
///
/// It listens to app lifecycle changes and provides callbacks for warnings
/// and actual timeouts, ensuring sensitive information is protected when
/// the device is left unattended.
class SessionTimeoutService extends ChangeNotifier with WidgetsBindingObserver {
  /// Default duration of inactivity before the session is locked.
  static const Duration sessionTimeout = Duration(minutes: 60); // 1 hour

  /// Duration before [sessionTimeout] to trigger a warning notification.
  static const Duration warningShowTime =
      Duration(minutes: 5); // Show warning 5 min before

  Timer? _inactivityTimer;
  Timer? _warningTimer;

  Duration _timeoutDuration = sessionTimeout;
  bool _isLocked = false;
  bool _isActive = false;
  DateTime? _lastActivityTime;
  VoidCallback? _onWarningNeeded;
  VoidCallback? _onTimeout;

  /// Creates a [SessionTimeoutService] and registers it as an observer.
  SessionTimeoutService() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Whether the session is currently locked.
  bool get isLocked => _isLocked;

  /// The current duration after which the session will time out.
  Duration get timeoutDuration => _timeoutDuration;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isActive && !_isLocked) {
      if (_lastActivityTime != null) {
        final elapsed = DateTime.now().difference(_lastActivityTime!);
        if (elapsed >= _timeoutDuration) {
          _lockSession();
        } else {
          resetTimer();
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _warningTimer?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  /// Manually locks the session.
  void lock() => _lockSession();

  /// Resets the inactivity timer. Call this on any user interaction.
  void resetTimer() {
    if (_isLocked || !_isActive) return;
    _lastActivityTime = DateTime.now();
    _inactivityTimer?.cancel();
    _warningTimer?.cancel();

    // Set warning timer (shows warning before timeout)
    _warningTimer = Timer(
      _timeoutDuration - warningShowTime,
      _showWarning,
    );

    // Set actual timeout timer
    _inactivityTimer = Timer(_timeoutDuration, _lockSession);
  }

  /// Register callback for when session actually times out
  void setOnTimeoutCallback(VoidCallback callback) {
    _onTimeout = callback;
  }

  /// Register callback for when warning dialog should be shown
  void setOnWarningCallback(VoidCallback callback) {
    _onWarningNeeded = callback;
  }

  /// Sets a new timeout duration for the session.
  /// If the service is active, the timer will be reset with the new duration.
  void setTimeoutDuration(Duration duration) {
    _timeoutDuration = duration;
    if (_isActive) resetTimer();
    notifyListeners();
  }

  /// Starts the session timeout monitoring.
  /// Resets the timer and sets the service to active.
  void start() {
    if (_isActive) return;
    _isActive = true;
    _isLocked = false;
    resetTimer();
  }

  /// Stops the session timeout monitoring.
  /// Cancels any active timers.
  void stop() {
    _isActive = false;
    _inactivityTimer?.cancel();
  }

  /// Unlocks the session and restarts the inactivity timer.
  void unlock() {
    _isLocked = false;
    resetTimer();
    notifyListeners();
  }

  void _lockSession() {
    if (_isLocked) return;
    _isLocked = true;
    _warningTimer?.cancel();
    _inactivityTimer?.cancel();
    _onTimeout?.call();
    notifyListeners();
  }

  void _showWarning() {
    if (!_isLocked && _isActive) {
      _onWarningNeeded?.call();
    }
  }
}
