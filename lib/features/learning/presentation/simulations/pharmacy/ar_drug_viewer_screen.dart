import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A screen for visualizing drug molecular structures in 3D using AR.
class ARDrugViewerScreen extends StatefulWidget {
  /// The name of the drug.
  final String drugName;

  /// The file path or URL to the 3D model (GLB/GLTF).
  final String modelPath;

  /// A brief description of the drug.
  final String description;

  /// Creates an [ARDrugViewerScreen] instance.
  const ARDrugViewerScreen({
    super.key,
    required this.drugName,
    required this.modelPath,
    required this.description,
  });

  @override
  State<ARDrugViewerScreen> createState() => _ARDrugViewerScreenState();
}

class _ARDrugViewerScreenState extends State<ARDrugViewerScreen> {
  final Flutter3DController _controller = Flutter3DController();
  final bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('${widget.drugName} Molecule'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: Stack(
          children: [
            // 3D Model Viewer
            Positioned.fill(
              child: Flutter3DViewer(
                controller: _controller,
                src: widget.modelPath,
                // Removed onProgress since it's not supported in this version
                // onProgress: (double? progress) {
                //   if (progress == 1.0) setState(() => _isLoading = false);
                // },
              ),
            ),

            if (_isLoading) const Center(child: CircularProgressIndicator()),

            // Overlay Details
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.drugName,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const Icon(LucideIcons.radio, color: Colors.blueAccent),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.description,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoAction(LucideIcons.info, 'Mechanism'),
                        _infoAction(LucideIcons.alertTriangle, 'Interactions'),
                        _infoAction(
                            LucideIcons.thermometer, 'Bio-availability'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Interaction Hints
            const Positioned(
              top: 120,
              right: 16,
              child: Column(
                children: [
                  _HintIcon(icon: LucideIcons.rotateCcw, label: 'Rotate'),
                  SizedBox(height: 12),
                  _HintIcon(icon: LucideIcons.zoomIn, label: 'Zoom'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white38)),
      ],
    );
  }
}

class _HintIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HintIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white54, size: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 8, color: Colors.white38)),
      ],
    );
  }
}
