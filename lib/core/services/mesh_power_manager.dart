import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

import 'bluetooth_mesh_service.dart';

/// Provider for the [MeshPowerManager] instance.
final meshPowerManagerProvider = Provider<MeshPowerManager>((ref) {
  final meshService = ref.watch(bluetoothMeshServiceProvider);
  return MeshPowerManager(meshService);
});

/// Manages the power-saving duty cycles of the Bluetooth mesh network.
///
/// It adjusts scanning and advertising intervals based on the application's
/// lifecycle state (foreground vs background) to preserve battery.
class MeshPowerManager with WidgetsBindingObserver {
  final BluetoothMeshService _meshService;
  Timer? _dutyCycleTimer;
  MeshPowerMode _currentMode = MeshPowerMode.normal;
  bool _isDisposed = false;

  /// Creates a [MeshPowerManager] and starts the duty cycle loop.
  MeshPowerManager(this._meshService) {
    WidgetsBinding.instance.addObserver(this);
    _startDutyCycle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        setMode(MeshPowerMode.normal);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        setMode(MeshPowerMode.deepSleep);
        break;
    }
  }

  /// Disposes of the manager and stops the duty cycle timer.
  void dispose() {
    _isDisposed = true;
    _dutyCycleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Updates the active [MeshPowerMode], adjusting duty cycles accordingly.
  void setMode(MeshPowerMode mode) {
    if (_currentMode == mode) return;
    AppLogger.info('MeshPowerManager: Switching to mode $mode');
    _currentMode = mode;
    _restartDutyCycle();
  }

  _DutyCycleConfig _getDutyCycleConfig() {
    switch (_currentMode) {
      case MeshPowerMode.highActive:
        return _DutyCycleConfig(
          scanDuration: const Duration(minutes: 5), // Effectively constant
          sleepDuration: Duration.zero,
        );
      case MeshPowerMode.normal:
        return _DutyCycleConfig(
          scanDuration: const Duration(seconds: 10),
          sleepDuration: const Duration(seconds: 20),
        );
      case MeshPowerMode.deepSleep:
        return _DutyCycleConfig(
          scanDuration: const Duration(seconds: 5),
          sleepDuration: const Duration(minutes: 2),
        );
    }
  }

  void _restartDutyCycle() {
    _dutyCycleTimer?.cancel();
    _startDutyCycle();
  }

  Future<void> _startDutyCycle() async {
    while (!_isDisposed) {
      final config = _getDutyCycleConfig();

      // 1. Discovery Phase
      AppLogger.info(
          'MeshPowerManager: Starting Discovery (${config.scanDuration.inSeconds}s)');
      await _meshService.startDiscovery();
      await _meshService.startAdvertising();
      await Future.delayed(config.scanDuration);

      // 2. Sleep Phase
      if (config.sleepDuration > Duration.zero) {
        AppLogger.info(
            'MeshPowerManager: Pausing Discovery (${config.sleepDuration.inSeconds}s)');
        await _meshService.stopDiscovery();
        await _meshService.stopAdvertising();
        await Future.delayed(config.sleepDuration);
      }
    }
  }
}

/// Defines the power consumption strategy for the mesh network.
enum MeshPowerMode {
  /// Constant scanning and advertising for high-throughput interactions.
  highActive,

  /// Balanced duty cycle for typical foreground usage.
  normal,

  /// Minimal duty cycle for background power preservation.
  deepSleep
}

/// Tracks performance statistics for a specific mesh node.
class NodeStats {
  /// Total number of successful packet deliveries via this node.
  int successCount = 0;

  /// Total number of delivery failures via this node.
  int failureCount = 0;

  /// Moving average of latency in milliseconds.
  double averageLatencyMs = 0.0;

  /// The last time this node was seen or interacted with.
  DateTime lastSeen = DateTime.now();
}

class _DutyCycleConfig {
  final Duration scanDuration;
  final Duration sleepDuration;

  _DutyCycleConfig({required this.scanDuration, required this.sleepDuration});
}
