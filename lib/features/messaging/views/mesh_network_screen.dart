import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';


class MeshNetworkScreen extends StatefulWidget {
  const MeshNetworkScreen({super.key});

  @override
  State<MeshNetworkScreen> createState() => _MeshNetworkScreenState();
}

class _MeshNetworkScreenState extends State<MeshNetworkScreen> {
  bool _isRelayActive = false;
  int _connectedNodes = 0;
  // ignore: prefer_final_fields
  int _packetsRelayed = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: const Text('MESH RADAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Radar Status Box
            NeoPixelBox(
              padding: 24,
              child: Column(
                children: [
                  Icon(
                    _connectedNodes > 0 ? Icons.radar : Icons.radar_outlined,
                    size: 64,
                    color: _isRelayActive ? AppColors.primary : AppColors.shadowDark,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRelayActive ? 'RADAR ACTIVE' : 'RADAR OFFLINE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _isRelayActive ? AppColors.primary : AppColors.textSecondary,
                      letterSpacing: 2,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_connectedNodes LOCAL NODES IN RANGE',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Statistics Box
            Row(
              children: [
                Expanded(
                  child: NeoPixelBox(
                    padding: 16,
                    child: Column(
                      children: [
                        Text('$_packetsRelayed', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: AppColors.textPrimary)),
                        const Text('PACKETS RELAYED', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: AppColors.shadowDark)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NeoPixelBox(
                    padding: 16,
                    child: Column(
                      children: [
                        const Text('10 / 50', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, color: AppColors.textPrimary)),
                        const Text('MB DEVICE CACHE', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: AppColors.shadowDark)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Toggle Box
            NeoPixelBox(
              padding: 16,
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BACKGROUND RELAY', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 14)),
                        Text('Energy Cost: ~1% per day', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.shadowDark, fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isRelayActive,
                    onChanged: (val) {
                      setState(() {
                         _isRelayActive = val;
                         if (val) {
                            // BleSignalingService().startScanning(...) 
                         } else {
                            _connectedNodes = 0;
                         }
                      });
                    },
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
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
