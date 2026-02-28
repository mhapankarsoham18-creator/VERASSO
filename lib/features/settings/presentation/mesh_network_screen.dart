import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/mesh/models/mesh_packet.dart';
import 'package:verasso/core/services/bluetooth_mesh_service.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

/// Screen for managing and monitoring the Bluetooth mesh network.
class MeshNetworkScreen extends ConsumerStatefulWidget {
  /// Creates a [MeshNetworkScreen].
  const MeshNetworkScreen({super.key});

  @override
  ConsumerState<MeshNetworkScreen> createState() => _MeshNetworkScreenState();
}

class _MeshNetworkScreenState extends ConsumerState<MeshNetworkScreen> {
  bool _isAdvertising = false;
  bool _isDiscovering = false;
  final TextEditingController _msgController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final connectedPeers = ref.watch(connectedMeshDevicesProvider);
    final meshService = ref.read(bluetoothMeshServiceProvider);
    final meshStream = ref.watch(meshMessagesProvider); // Keep stream active

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Bluetooth Mesh Network"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Status Card
                GlassContainer(
                  child: Column(
                    children: [
                      _buildStatusRow("Advertising", _isAdvertising,
                          (val) async {
                        if (val) {
                          final user = ref.read(currentUserProvider);
                          await meshService.initialize(
                              user?.email?.split('@').first ?? "User",
                              user?.id ?? "anonymous");
                          final res = await meshService.startAdvertising();
                          setState(() => _isAdvertising = res);
                        } else {
                          meshService.stopAdvertising();
                          setState(() => _isAdvertising = false);
                        }
                      }),
                      const SizedBox(height: 10),
                      _buildStatusRow("Discovery", _isDiscovering, (val) async {
                        if (val) {
                          final user = ref.read(currentUserProvider);
                          await meshService.initialize(
                              user?.email?.split('@').first ?? "User",
                              user?.id ?? "anonymous");
                          final res = await meshService.startDiscovery();
                          setState(() => _isDiscovering = res);
                        } else {
                          meshService.stopDiscovery();
                          setState(() => _isDiscovering = false);
                        }
                      }),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Min Trust Score",
                              style: TextStyle(color: Colors.white)),
                          Text("${meshService.trustThreshold}",
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: meshService.trustThreshold.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 10,
                        onChanged: (val) {
                          setState(() {
                            meshService.setTrustThreshold(val.toInt());
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Active Peers List
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Nearby Peers",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(height: 10),

                Expanded(
                  flex: 1,
                  child: connectedPeers.when(
                    data: (peers) {
                      if (peers.isEmpty) {
                        return const Center(
                            child: Text("No peers connected",
                                style: TextStyle(color: Colors.white70)));
                      }
                      return ListView.builder(
                        itemCount: peers.length,
                        itemBuilder: (context, index) {
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(LucideIcons.smartphone,
                                  color: Colors.greenAccent),
                              title: Text(peers[index],
                                  style: const TextStyle(color: Colors.white)),
                              trailing: const Icon(LucideIcons.signal,
                                  color: Colors.white54),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => AppErrorView(
                      message: e.toString(),
                      onRetry: () =>
                          ref.invalidate(connectedMeshDevicesProvider),
                    ),
                  ),
                ),

                const Divider(color: Colors.white24),

                // Test Broadcast
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Broadcast Test",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white),
                      icon: const Icon(LucideIcons.send),
                      onPressed: () {
                        if (_msgController.text.isNotEmpty) {
                          meshService
                              .broadcastPacket(MeshPayloadType.chatMessage, {
                            'content': _msgController.text,
                          });
                          _msgController.clear();
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Log / Stream View (Simple Debugger)
                Expanded(
                  flex: 1,
                  child: GlassContainer(
                    child: meshStream.when(
                      data: (packet) {
                        return ListView(
                          reverse:
                              true, // Auto scroll to bottom essentially by reversing
                          children: [
                            // Note: StreamProvider only gives latest value usually unless we accumulate.
                            // For a real chat/log, we need a StateProvider that appends packets.
                            // But for this debug view, we just show "Last Packet".
                            ListTile(
                              title: Text(
                                  "${packet.senderName}: ${packet.payload}",
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                  "Type: ${packet.type} | TTL: ${packet.ttl}",
                                  style:
                                      const TextStyle(color: Colors.white54)),
                            )
                          ],
                        );
                      },
                      loading: () => const Center(
                          child: Text("Waiting for packets...",
                              style: TextStyle(color: Colors.white54))),
                      error: (e, _) => AppErrorView(
                        message: e.toString(),
                        onRetry: () => ref.invalidate(meshMessagesProvider),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(
      String label, bool isActive, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Switch(
          value: isActive,
          onChanged: onChanged,
          activeThumbColor: Colors.greenAccent,
        ),
      ],
    );
  }
}
