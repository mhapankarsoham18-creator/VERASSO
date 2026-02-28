import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [NetworkConnectivityService] instance.
final networkConnectivityServiceProvider =
    Provider<NetworkConnectivityService>((ref) {
  return NetworkConnectivityService();
});

/// Provider for the current [NetworkStatus] stream.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(networkConnectivityServiceProvider);
  return service.statusStream;
});

/// Service that monitors the device's internet connectivity status.
class NetworkConnectivityService {
  final Connectivity _connectivity;
  // Note: StreamController is not closed because this service lives
  // for the entire app lifecycle as a Riverpod Provider singleton.
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  /// Creates a [NetworkConnectivityService] and starts monitoring.
  NetworkConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    // Only init if we are not injecting for a pure unit test without mocking streams properly?
    // Actually, we should allow init, but we need to mock the stream in the test.
    _init();
  }

  /// Checks if the device is currently connected to a valid network.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }

  /// Stream of current [NetworkStatus] updates.
  Stream<NetworkStatus> get statusStream => _controller.stream;

  Future<void> _checkStatus(List<ConnectivityResult> results) async {
    bool isConnected = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    if (isConnected) {
      _controller.add(NetworkStatus.online);
    } else {
      _controller.add(NetworkStatus.offline);
    }
  }

  void _init() {
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _checkStatus(results);
    });
  }
}

/// Represents the current network status of the device.
enum NetworkStatus {
  /// The device is connected to a network.
  online,

  /// The device is offline.
  offline,
}
