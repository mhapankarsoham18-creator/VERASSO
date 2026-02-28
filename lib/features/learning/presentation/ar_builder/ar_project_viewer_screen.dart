import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../data/ar_project_model.dart';
import '../../data/ar_project_repository.dart';
import 'ar_simulation_view.dart';

/// 3D viewer for AR projects without camera/AR mode
class ArProjectViewerScreen extends ConsumerStatefulWidget {
  /// The AR project to be viewed in 3D/Blueprint mode.
  final ArProject project;

  /// Creates an [ArProjectViewerScreen] instance.
  const ArProjectViewerScreen({super.key, required this.project});

  @override
  ConsumerState<ArProjectViewerScreen> createState() =>
      _ArProjectViewerScreenState();
}

/// Painter for rendering a 2D "blueprint" style schematic of the circuit.
class BlueprintPainter extends CustomPainter {
  /// List of components to render on the blueprint.
  final List<ArComponent> components;

  /// List of connections between components.
  final List<ComponentConnection> connections;

  /// Creates a [BlueprintPainter] instance.
  BlueprintPainter({required this.components, required this.connections});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    // Draw Grid
    const gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final connectionPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var conn in connections) {
      final startComp = components.firstWhere(
          (c) => c.id == conn.fromComponentId,
          orElse: () => components.first);
      final endComp = components.firstWhere((c) => c.id == conn.toComponentId,
          orElse: () => components.first);

      final startPos = Offset(
        center.dx + startComp.transform.x * 150,
        center.dy + startComp.transform.y * 150,
      );
      final endPos = Offset(
        center.dx + endComp.transform.x * 150,
        center.dy + endComp.transform.y * 150,
      );

      final path = Path();
      path.moveTo(startPos.dx, startPos.dy);
      path.cubicTo(
        startPos.dx,
        (startPos.dy + endPos.dy) / 2,
        endPos.dx,
        (startPos.dy + endPos.dy) / 2,
        endPos.dx,
        endPos.dy,
      );
      canvas.drawPath(path, connectionPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArProjectViewerScreenState extends ConsumerState<ArProjectViewerScreen> {
  // 2D Pan/Zoom state
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;
  bool _showSimulation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.project.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.play),
            onPressed: () => setState(() => _showSimulation = true),
            tooltip: 'Simulate',
          ),
          IconButton(
            icon: const Icon(LucideIcons.copy),
            onPressed: _remixProject,
            tooltip: 'Remix to My Projects',
          ),
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: _shareProject,
            tooltip: 'Share Project',
          ),
          if (widget.project.userId ==
              Supabase.instance.client.auth.currentUser?.id)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
              onPressed: _deleteProject,
              tooltip: 'Delete Project',
            ),
        ],
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 3D View (simplified - would use actual 3D rendering in production)
              _build3DView(),

              // Simulation overlay
              if (_showSimulation)
                Positioned.fill(
                  child: ArSimulationView(
                    components: widget.project.components,
                    connections: widget.project.connections,
                    onClose: () => setState(() => _showSimulation = false),
                  ),
                ),

              // Info panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildInfoPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build3DView() {
    return _buildBlueprintView();
  }

  Widget _buildBlueprintView() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _panOffset += details.delta;
        });
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = details.scale.clamp(0.5, 3.0);
        });
      },
      child: Container(
        color: const Color(0xFF0A192F), // Deep Blueprint Blue
        child: Stack(
          children: [
            // Grid and Connections
            Transform.translate(
              offset: _panOffset,
              child: Transform.scale(
                scale: _scale,
                alignment: Alignment.center,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: BlueprintPainter(
                    components: widget.project.components,
                    connections: widget.project.connections,
                  ),
                ),
              ),
            ),
            // Component Widgets
            ...widget.project.components.map((component) {
              return LayoutBuilder(builder: (context, constraints) {
                final center =
                    Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
                final pos = Offset(
                  center.dx +
                      _panOffset.dx +
                      (component.transform.x * 150 * _scale),
                  center.dy +
                      _panOffset.dy +
                      (component.transform.y * 150 * _scale),
                );
                return Positioned(
                  left: pos.dx - 25,
                  top: pos.dy - 25,
                  child: _buildComponentIcon(component),
                );
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentIcon(ArComponent component) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF0A192F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blueAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Icon(
            _getComponentIcon(component.category),
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          component.category.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Project title
          Text(
            widget.project.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (widget.project.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.project.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _buildStatChip(
                LucideIcons.box,
                '${widget.project.components.length} Components',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                LucideIcons.link,
                '${widget.project.connections.length} Connections',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Controls hint
          const Text(
            '👆 Drag to rotate • Pinch to zoom',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, end: 0.0);
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  void _deleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Project?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Are you sure you want to delete this project? This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(arProjectRepositoryProvider);
        await repo.deleteProject(widget.project.id);
        if (mounted) {
          Navigator.pop(context); // Close viewer
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  IconData _getComponentIcon(String category) {
    switch (category) {
      case 'power':
        return LucideIcons.battery;
      case 'resistor':
        return LucideIcons.wind;
      case 'led':
        return LucideIcons.lightbulb;
      case 'capacitor':
        return LucideIcons.database;
      case 'switch':
        return LucideIcons.toggleRight;
      default:
        return LucideIcons.box;
    }
  }

  void _remixProject() async {
    try {
      final repo = ref.read(arProjectRepositoryProvider);
      await repo.remixProject(widget.project.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project remixed to your collection!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remix: $e')),
        );
      }
    }
  }

  void _shareProject() async {
    // Show friend picker or link generator
    // For now, just show a placeholder or call repository if we had a target friend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing functionality opening...')),
    );
  }
}
