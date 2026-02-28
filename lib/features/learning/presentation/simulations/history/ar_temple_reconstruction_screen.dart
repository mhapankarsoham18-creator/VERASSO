import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A screen for visualizing and interacting with historical structures using Augmented Reality.
class ARTempleReconstructionScreen extends StatefulWidget {
  /// Creates an [ARTempleReconstructionScreen] instance.
  const ARTempleReconstructionScreen({super.key});

  @override
  State<ARTempleReconstructionScreen> createState() =>
      _ARTempleReconstructionScreenState();
}

class _ARTempleReconstructionScreenState
    extends State<ARTempleReconstructionScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  bool isRuins = false;
  ARNode? currentTempleNode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AR Heritage'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: Stack(
          children: [
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),

            // Interaction Guide
            if (currentTempleNode == null)
              const Center(
                child: GlassContainer(
                  padding: EdgeInsets.all(16),
                  child: Text('Tap on a flat floor to place the Temple',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

            // Controls Overlay
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reconstructed',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Switch(
                          value: isRuins,
                          onChanged: toggleReconstruction,
                          activeThumbColor: Colors.amber,
                        ),
                        const Text('Ruins',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Move your device to explore different angles',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          handleTaps: true,
        );
    this.arObjectManager!.onInitialize();
  }

  Future<void> onPlaneTap(List<ARHitTestResult> hitTestResults) async {
    if (currentTempleNode != null) return; // Only one temple at a time

    final singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);

    final newNode = ARNode(
      type: NodeType.localGLTF2,
      uri: isRuins
          ? "assets/models/temple_ruins.gltf"
          : "assets/models/temple_full.gltf",
      scale: vector.Vector3(0.5, 0.5, 0.5),
      position: vector.Vector3(
        singleHitTestResult.worldTransform.getColumn(3).x,
        singleHitTestResult.worldTransform.getColumn(3).y,
        singleHitTestResult.worldTransform.getColumn(3).z,
      ),
    );

    bool? didAddNode = await arObjectManager!.addNode(newNode);
    if (didAddNode != null && didAddNode) {
      setState(() {
        currentTempleNode = newNode;
      });
    }
  }

  Future<void> toggleReconstruction(bool value) async {
    setState(() => isRuins = value);
    if (currentTempleNode != null) {
      // Remove old node and add new one with different model but same position
      final oldPos = currentTempleNode!.position;
      arObjectManager!.removeNode(currentTempleNode!);

      final newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: isRuins
            ? "assets/models/temple_ruins.gltf"
            : "assets/models/temple_full.gltf",
        scale: vector.Vector3(0.5, 0.5, 0.5),
        position: oldPos,
      );

      await arObjectManager!.addNode(newNode);
      setState(() => currentTempleNode = newNode);
    }
  }
}
