import 'package:ar_flutter_plugin_plus/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// An AR-based simulation for practicing boardroom meetings and corporate governance.
class ARBoardroomScreen extends StatefulWidget {
  /// Creates an [ARBoardroomScreen] instance.
  const ARBoardroomScreen({super.key});

  @override
  State<ARBoardroomScreen> createState() => _ARBoardroomScreenState();
}

class _ARBoardroomScreenState extends State<ARBoardroomScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  ARNode? boardroomTableNode;
  bool isMeetingActive = false;
  String currentAgenda = "Select an Agenda Item";
  int votesFor = 0;
  int votesAgainst = 0;

  final List<String> agendaItems = [
    "Appointment of Auditor",
    "Declaration of Dividend",
    "Approval of Annual Accounts",
    "Election of Directors",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AR Boardroom'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Stack(
          children: [
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontal,
            ),

            if (boardroomTableNode == null)
              const Center(
                child: GlassContainer(
                  padding: EdgeInsets.all(16),
                  child: Text('Tap floor to set up Boardroom Table',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

            // Agenda & Voting Overlay
            if (boardroomTableNode != null)
              Positioned(
                bottom: 40,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    if (!isMeetingActive)
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Select Resolution to Propose',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...agendaItems.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigoAccent,
                                      minimumSize:
                                          const Size(double.infinity, 40),
                                    ),
                                    onPressed: () => _startResolution(item),
                                    child: Text(item),
                                  ),
                                )),
                          ],
                        ),
                      )
                    else
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text('Resolution: $currentAgenda',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _VoteCounter(
                                    label: 'For',
                                    count: votesFor,
                                    color: Colors.greenAccent),
                                _VoteCounter(
                                    label: 'Against',
                                    count: votesAgainst,
                                    color: Colors.redAccent),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _castVote(true),
                                    icon: const Icon(LucideIcons.check),
                                    label: const Text('Vote For'),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.greenAccent),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _castVote(false),
                                    icon: const Icon(LucideIcons.x),
                                    label: const Text('Vote Against'),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  setState(() => isMeetingActive = false),
                              child: const Text('End Resolution',
                                  style: TextStyle(color: Colors.white54)),
                            ),
                          ],
                        ),
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
          handleTaps: true,
        );
    this.arObjectManager!.onInitialize();
    this.arSessionManager!.onPlaneOrPointTap = onPlaneTap;
  }

  Future<void> onPlaneTap(List<ARHitTestResult> hitTestResults) async {
    if (boardroomTableNode != null) return;

    try {
      final singleHitTestResult = hitTestResults.firstWhere(
          (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);

      final newNode = ARNode(
        type: NodeType.localGLTF2,
        uri:
            "assets/models/boardroom_table.gltf", // Requires premium AR asset pack
        scale: vector.Vector3(0.8, 0.8, 0.8),
        position: vector.Vector3(
          singleHitTestResult.worldTransform.getColumn(3).x,
          singleHitTestResult.worldTransform.getColumn(3).y,
          singleHitTestResult.worldTransform.getColumn(3).z,
        ),
      );

      bool? didAddNode = await arObjectManager!.addNode(newNode);
      if (didAddNode != null && didAddNode) {
        setState(() {
          boardroomTableNode = newNode;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '3D model could not be loaded. AR asset pack may be missing.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'AR Error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _castVote(bool inFavor) {
    setState(() {
      if (inFavor) {
        votesFor++;
      } else {
        votesAgainst++;
      }
    });
  }

  void _startResolution(String agenda) {
    setState(() {
      currentAgenda = agenda;
      isMeetingActive = true;
      votesFor = 0;
      votesAgainst = 0;
    });
  }
}

class _VoteCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _VoteCounter(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text('$count',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
