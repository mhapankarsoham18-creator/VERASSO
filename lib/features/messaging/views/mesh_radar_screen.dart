import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../../core/widgets/verasso_snackbar.dart';
import '../services/mesh_network_service.dart';

class MeshRadarScreen extends StatefulWidget {
  const MeshRadarScreen({super.key});

  @override
  State<MeshRadarScreen> createState() => _MeshRadarScreenState();
}

class _MeshRadarScreenState extends State<MeshRadarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  final MeshNetworkService _mesh = MeshNetworkService();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // Kickoff discovery (advertising is usually already configured, but we re-init here)
    _startMeshOperations();
  }

  Future<void> _startMeshOperations() async {
    final hasPerms = await _mesh.checkPermissions();
    if (!hasPerms) {
      if (mounted) VerassoSnackbar.show(context, message: 'Permissions denied for Mesh networking', isError: true);
      return;
    }
    
    // Use adaptive duty cycle instead of always-on scanning
    _mesh.startPulseScanning();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    // Keep it running in the background for offline messaging, or stop if we want to save battery
    // We'll leave it running per mesh logic.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text(
          'RADAR: ACTIVE PEERS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: context.colors.neutralBg,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NeoPixelBox(
              padding: 12,
              backgroundColor: context.colors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                   Icon(Icons.wifi_tethering, color: context.colors.primary),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       'Broadcasting mesh footprint in local radius (\u224850m). Encrypted Handshake available.',
                       style: TextStyle(
                         fontFamily: 'Courier',
                         fontSize: 12,
                         color: context.colors.textPrimary,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),

          // The Radar Widget
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(color: context.colors.primary.withValues(alpha: 0.5), width: 4),
                      boxShadow: [
                         BoxShadow(
                           color: context.colors.primary.withValues(alpha: 0.2),
                           blurRadius: 20,
                           spreadRadius: 5,
                         ),
                      ],
                    ),
                  ),

                  // Concentric Rings
                  for (var i = 1; i <= 3; i++)
                    Container(
                      width: i * 100.0,
                      height: i * 100.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
                      ),
                    ),

                  // Sweep animation
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * pi,
                        child: Container(
                           width: 300,
                           height: 300,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             gradient: SweepGradient(
                               center: Alignment.center,
                               startAngle: 0.0,
                               endAngle: pi / 2,
                               colors: [
                                 Colors.transparent,
                                 context.colors.primary.withValues(alpha: 0.8),
                                 Colors.transparent,
                               ],
                               stops: const [0.0, 0.9, 1.0],
                             ),
                           ),
                        ),
                      );
                    },
                  ),

                  // Nodes List (Listen to MeshNetworkService via AnimatedBuilder / Provider)
                  ListenableBuilder(
                    listenable: _mesh,
                    builder: (context, _) {
                      final allPeers = _mesh.discoveredPeers.values.toList();
                      if (allPeers.isEmpty) return const SizedBox.shrink();

                      return Stack(
                        children: allPeers.map((peer) {
                          // Simple random position on the radar for demo purposes.
                          // A real implementation might use signal strength to determine distance.
                          final random = Random(peer.endpointId.hashCode);
                          final angle = random.nextDouble() * 2 * pi;
                          final distance = 30 + random.nextDouble() * 100;
                          
                          final dx = cos(angle) * distance;
                          final dy = sin(angle) * distance;

                          final isConnected = _mesh.connectedPeers.containsKey(peer.endpointId);

                          return Transform.translate(
                             offset: Offset(dx, dy),
                             child: GestureDetector(
                               onTap: () {
                                 if (!isConnected) {
                                   VerassoSnackbar.show(context, message: 'Initiating Ad-Hoc handshake with ${peer.peerName}...');
                                   _mesh.requestConnection(peer.endpointId);
                                 } else {
                                   VerassoSnackbar.show(context, message: 'Already connected to ${peer.peerName} via Mesh.');
                                 }
                               },
                               child: Container(
                                 width: 40,
                                 height: 40,
                                 decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isConnected ? Colors.blue.withValues(alpha: 0.4) : context.colors.primary.withValues(alpha: 0.4),
                                    border: Border.all(
                                      color: isConnected ? Colors.blueAccent : context.colors.primary, 
                                      width: 2
                                    )
                                 ),
                                 alignment: Alignment.center,
                                 child: Text(
                                   peer.peerName.substring(0, min(peer.peerName.length, 3)).toUpperCase(),
                                   style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                 ),
                               ),
                             ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          ListenableBuilder(
            listenable: _mesh,
            builder: (context, child) {
               return Container(
                 padding: const EdgeInsets.all(16),
                 child: Text(
                   'STATUS: ${_mesh.state.name.toUpperCase()} | PEERS IN RANGE: ${_mesh.discoveredPeers.length}',
                   style: TextStyle(
                     fontWeight: FontWeight.w900,
                     letterSpacing: 2,
                     color: context.colors.textPrimary,
                     fontSize: 12,
                   ),
                 ),
               );
            }
          ),
        ],
      ),
    );
  }
}
