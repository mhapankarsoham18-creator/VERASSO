import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/bluetooth_mesh_service.dart';
import '../services/network_connectivity_service.dart';

/// A floating indicator that displays the current network and Bluetooth mesh status.
///
/// Shows offline warnings if the primary connection is lost and tracks the
/// number of active devices in the mesh network.
class NetworkStatusIndicator extends ConsumerWidget {
  /// Creates a [NetworkStatusIndicator].
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);
    final connectedMeshDevices = ref.watch(connectedMeshDevicesProvider);

    return networkStatus.when(
      data: (status) {
        final isOffline = status == NetworkStatus.offline;
        final meshCount = connectedMeshDevices.value?.length ?? 0;

        if (!isOffline && meshCount == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOffline
                ? Colors.red.withValues(alpha: 0.9)
                : Colors.blue.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline ? LucideIcons.wifiOff : LucideIcons.bluetooth,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                isOffline
                    ? (meshCount > 0
                        ? 'Offline (Mesh Active: $meshCount)'
                        : 'Offline')
                    : 'Mesh: $meshCount Devices',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
