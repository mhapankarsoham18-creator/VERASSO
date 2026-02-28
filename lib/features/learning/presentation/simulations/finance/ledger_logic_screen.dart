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
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// An AR-based accounting simulation for visualizing assets and liabilities.
class LedgerLogicScreen extends StatefulWidget {
  /// Creates a [LedgerLogicScreen] instance.
  const LedgerLogicScreen({super.key});

  @override
  State<LedgerLogicScreen> createState() => _LedgerLogicScreenState();
}

class _LedgerLogicScreenState extends State<LedgerLogicScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  final List<ARNode> nodes = [];
  double totalAssets = 0;
  double totalLiabilities = 0;
  bool isAssetMode = true;

  @override
  Widget build(BuildContext context) {
    final isBalanced = totalAssets == totalLiabilities;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('LedgerLogic AR'),
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

            // Stats Overlay
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                        label: 'Assets',
                        value: '\$${totalAssets.toInt()}',
                        color: Colors.greenAccent),
                    _StatItem(
                        label: 'Liabilities',
                        value: '\$${totalLiabilities.toInt()}',
                        color: Colors.redAccent),
                    Icon(
                      isBalanced ? LucideIcons.checkCircle : LucideIcons.scale,
                      color: isBalanced ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ),
            ),

            // Controls
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => isAssetMode = true),
                          icon: const Icon(LucideIcons.plus),
                          label: const Text('Asset'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAssetMode
                                ? Colors.greenAccent
                                : Colors.white10,
                            foregroundColor:
                                isAssetMode ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => isAssetMode = false),
                          icon: const Icon(LucideIcons.minus),
                          label: const Text('Liability'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isAssetMode
                                ? Colors.redAccent
                                : Colors.white10,
                            foregroundColor:
                                !isAssetMode ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap on the floor to place a block',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
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
          showWorldOrigin: true,
          handleTaps: true,
        );
    this.arObjectManager!.onInitialize();
  }

  Future<void> onPlaneTap(List<ARHitTestResult> hitTestResults) async {
    final singleHitTestResult = hitTestResults.firstWhere(
        (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);

    final newNode = ARNode(
      type: NodeType.localGLTF2,
      uri: isAssetMode
          ? "assets/models/bank_vault.gltf"
          : "assets/models/bill_stack.gltf",
      scale: vector.Vector3(0.2, 0.2, 0.2),
      position: vector.Vector3(
        singleHitTestResult.worldTransform.getColumn(3).x,
        singleHitTestResult.worldTransform.getColumn(3).y,
        singleHitTestResult.worldTransform.getColumn(3).z,
      ),
      rotation: vector.Vector4(1, 0, 0, 0),
    );

    bool? didAddNode = await arObjectManager!.addNode(newNode);
    if (didAddNode != null && didAddNode) {
      setState(() {
        nodes.add(newNode);
        if (isAssetMode) {
          totalAssets += 1000;
        } else {
          totalLiabilities += 1000;
        }
      });
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white60)),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
