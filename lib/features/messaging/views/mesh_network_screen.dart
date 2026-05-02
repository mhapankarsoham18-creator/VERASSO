import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../services/mesh_network_service.dart';

class MeshNetworkScreen extends StatefulWidget {
  const MeshNetworkScreen({super.key});

  @override
  State<MeshNetworkScreen> createState() => _MeshNetworkScreenState();
}

class _MeshNetworkScreenState extends State<MeshNetworkScreen> {
  bool _isRelayActive = false;
  // ignore: prefer_final_fields
  int _packetsRelayed = 0;

  @override
  void initState() {
    super.initState();
    MeshNetworkService().addListener(_updateState);
    _isRelayActive = MeshNetworkService().state != MeshNodeState.disconnected;
  }

  @override
  void dispose() {
    MeshNetworkService().removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final meshService = MeshNetworkService();
    final connectedNodes = meshService.connectedPeers.length;
    final isPowerSaver = meshService.powerMode == MeshPowerMode.background;

    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('MESH RADAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.colors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Radar Status Box
            NeoPixelBox(
              padding: 24,
              child: Column(
                children: [
                  Icon(
                    connectedNodes > 0 ? Icons.radar : Icons.radar_outlined,
                    size: 64,
                    color: _isRelayActive ? context.colors.primary : context.colors.shadowDark,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _isRelayActive 
                      ? (isPowerSaver ? '🔋 POWER SAVER' : '⚡ FULL POWER') 
                      : 'RADAR OFFLINE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _isRelayActive ? context.colors.primary : context.colors.textSecondary,
                      letterSpacing: 2,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$connectedNodes LOCAL NODES IN RANGE',
                    style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textPrimary, fontSize: 12),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Statistics Box
            Row(
              children: [
                Expanded(
                  child: NeoPixelBox(
                    padding: 16,
                    child: Column(
                      children: [
                        Text('$_packetsRelayed', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: context.colors.textPrimary)),
                        Text('PACKETS RELAYED', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: context.colors.shadowDark)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: NeoPixelBox(
                    padding: 16,
                    child: Column(
                      children: [
                        Text('10 / 50', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: context.colors.textPrimary)),
                        Text('MB DEVICE CACHE', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: context.colors.shadowDark)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 48),

            // Toggle Box
            NeoPixelBox(
              padding: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BACKGROUND RELAY', style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.textPrimary, fontSize: 14)),
                        Text('Energy Cost: ~1% per day', style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.shadowDark, fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isRelayActive,
                    onChanged: (val) {
                      setState(() {
                         _isRelayActive = val;
                         if (val) {
                            meshService.startPulseScanning();
                         } else {
                            meshService.stopAll();
                         }
                      });
                    },
                    activeThumbColor: context.colors.primary,
                    activeTrackColor: context.colors.primary.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
