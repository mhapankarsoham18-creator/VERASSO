import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

class ConnectivityNotifier extends Notifier<NetworkStatus> {
  @override
  NetworkStatus build() {
    // Start listening on boot
    Future.microtask(_init);
    return NetworkStatus.online;
  }

  void _init() async {
    final initial = await Connectivity().checkConnectivity();
    _updateState(initial);
    Connectivity().onConnectivityChanged.listen(_updateState);
  }

  void _updateState(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      state = NetworkStatus.offline;
    } else {
      state = NetworkStatus.online;
    }
  }
}

final connectivityProvider = NotifierProvider<ConnectivityNotifier, NetworkStatus>(() {
  return ConnectivityNotifier();
});
