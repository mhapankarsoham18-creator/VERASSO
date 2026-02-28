import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';

/// A dashboard widget that visualizes the user's cognitive progress and knowledge graph.
class CognitiveDashboard extends ConsumerStatefulWidget {
  /// Creates a [CognitiveDashboard] instance.
  const CognitiveDashboard({super.key});

  @override
  ConsumerState<CognitiveDashboard> createState() => _CognitiveDashboardState();
}

/// Custom painter used to render a 3D-like knowledge graph on a 2D canvas.
class KnowledgeGraphPainter extends CustomPainter {
  /// The list of nodes to be rendered in the graph.
  final List<KnowledgeNode> nodes;

  /// The current rotation around the X-axis.
  final double rotationX;

  /// The current rotation around the Y-axis.
  final double rotationY;

  /// Creates a [KnowledgeGraphPainter] instance.
  KnowledgeGraphPainter({
    required this.nodes,
    required this.rotationX,
    required this.rotationY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final List<Offset> projectedPoints = [];

    // 1. Project points to 2D
    for (var node in nodes) {
      // Rotation matrices
      double x = node.x;
      double y = node.y;
      double z = node.z;

      // Rotate Y
      double x1 = x * cos(rotationY) + z * sin(rotationY);
      double z1 = -x * sin(rotationY) + z * cos(rotationY);

      // Rotate X
      double y2 = y * cos(rotationX) - z1 * sin(rotationX);
      double z2 = y * sin(rotationX) + z1 * cos(rotationX);

      // Perspective projection
      double factor = 600 / (600 + z2);
      projectedPoints
          .add(Offset(center.dx + x1 * factor, center.dy + y2 * factor));

      // Draw Node
      paint.color = node.color.withValues(alpha: (factor * 0.8).clamp(0, 1));
      canvas.drawCircle(projectedPoints.last, 4 * factor, paint);
    }

    // 2. Draw connections (Spider-web style)
    final linePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (int i = 0; i < projectedPoints.length; i++) {
      for (int j = i + 1; j < projectedPoints.length; j++) {
        double dist = (nodes[i].x - nodes[j].x).abs() +
            (nodes[i].y - nodes[j].y).abs() +
            (nodes[i].z - nodes[j].z).abs();
        if (dist < 300) {
          canvas.drawLine(projectedPoints[i], projectedPoints[j], linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Represents a node within the cognitive knowledge graph.
class KnowledgeNode {
  /// Unique identifier for the node.
  final String id;

  /// Display label for the node.
  final String label;

  /// 3D coordinates of the node.
  final double x, y, z;

  /// Color used for rendering the node.
  final Color color;

  /// Creates a [KnowledgeNode] instance.
  KnowledgeNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.z,
    required this.color,
  });
}

class _CognitiveDashboardState extends ConsumerState<CognitiveDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<KnowledgeNode> _nodes = [];
  double _rotationX = 0.0;
  double _rotationY = 0.0;

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(userProgressSummaryProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: LiquidBackground(
        child: Stack(
          children: [
            // 3D Visualizer
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _rotationY += details.delta.dx * 0.01;
                  _rotationX -= details.delta.dy * 0.01;
                });
              },
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: KnowledgeGraphPainter(
                      nodes: _nodes,
                      rotationX: _rotationX,
                      rotationY: _rotationY + (_controller.value * 2 * pi),
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),

            // UI Overlays
            Positioned(
              top: 40,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COGNITIVE STATUS',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(letterSpacing: 4, color: Colors.cyanAccent),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user != null
                        ? 'Level ${progressAsync.value?.level ?? 1} Architect'
                        : 'Guest Access',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: GlassContainer(
                meshStress: 0.1, // Slight visual reaction to mesh backgrounding
                child: progressAsync.when(
                  data: (progress) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(context, LucideIcons.brain,
                          '${(progress.levelProgress * 100).toInt()}%', 'Sync'),
                      _buildStat(
                          context, LucideIcons.shieldCheck, 'ZK', 'Identity'),
                      _buildStat(context, LucideIcons.zap,
                          '${progress.circuitsSimulated}', 'Engines'),
                    ],
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                      child: Text('Data Unavailable',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 10))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();

    _generateNodes();
  }

  Widget _buildStat(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }

  void _generateNodes() {
    // Generate Knowledge Graph based on real-ish distribution
    final random = Random();
    _nodes.clear();
    for (int i = 0; i < 20; i++) {
      _nodes.add(KnowledgeNode(
        id: 'node_$i',
        label: i == 0 ? 'Core Self' : 'Skill $i',
        x: (random.nextDouble() - 0.5) * 450,
        y: (random.nextDouble() - 0.5) * 450,
        z: (random.nextDouble() - 0.5) * 450,
        color: i == 0 ? Colors.cyanAccent : Colors.white70,
      ));
    }
  }
}
