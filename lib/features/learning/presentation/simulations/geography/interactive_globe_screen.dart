import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A custom painter for rendering a 3D-like interactive globe with different layers.
class GlobePainter extends CustomPainter {
  /// Rotation around the X-axis.
  final double rotX;

  /// Rotation around the Y-axis.
  final double rotY;

  /// The active data layer to display on the globe (e.g., 'Tectonic', 'Climate').
  final String layer;

  /// Creates a [GlobePainter] instance.
  GlobePainter({required this.rotX, required this.rotY, required this.layer});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw Atmosphere glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.blueAccent.withValues(alpha: 0.2), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.5, glowPaint);

    // Draw Sphere Base
    final spherePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, spherePaint);

    // Draw Grid / Lat-Long lines
    final linePaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Simplified 3D Projection for lines
    for (double lat = -math.pi / 2; lat <= math.pi / 2; lat += math.pi / 10) {
      for (double lng = -math.pi; lng <= math.pi; lng += math.pi / 10) {
        // Apply Rotations
        double x = math.cos(lat) * math.sin(lng);
        double y = math.sin(lat);
        double z = math.cos(lat) * math.cos(lng);

        // Rotation around Y
        double x1 = x * math.cos(rotY) + z * math.sin(rotY);
        double z1 = -x * math.sin(rotY) + z * math.cos(rotY);

        // Rotation around X
        double y2 = y * math.cos(rotX) - z1 * math.sin(rotX);
        double z2 = y * math.sin(rotX) + z1 * math.cos(rotX);

        if (z2 > 0) {
          // On the visible side
          canvas.drawCircle(
            Offset(center.dx + x1 * radius, center.dy + y2 * radius),
            1,
            linePaint..color = _getLayerColor(x1, y2, z2),
          );
        }
      }
    }

    // Shadow for depth
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shadowPaint);

    // Border
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white12
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant GlobePainter oldDelegate) =>
      oldDelegate.rotX != rotX ||
      oldDelegate.rotY != rotY ||
      oldDelegate.layer != layer;

  Color _getLayerColor(double x, double y, double z) {
    if (layer == 'Tectonic') {
      // Procedural tectonic-like lines
      if ((x * 5).floor() % 3 == 0 || (y * 5).floor() % 4 == 0) {
        return Colors.orangeAccent.withValues(alpha: 0.6);
      }
    } else if (layer == 'Climate') {
      // Procedural temperature zones
      double temp = (y.abs() * 100);
      if (temp < 30) return Colors.redAccent.withValues(alpha: 0.4);
      if (temp < 60) return Colors.greenAccent.withValues(alpha: 0.4);
      return Colors.blueAccent.withValues(alpha: 0.4);
    }
    return Colors.white12;
  }
}

/// A screen that displays an interactive 3D globe with draggable rotation and selectable data layers.
class InteractiveGlobeScreen extends StatefulWidget {
  /// Creates an [InteractiveGlobeScreen] instance.
  const InteractiveGlobeScreen({super.key});

  @override
  State<InteractiveGlobeScreen> createState() => _InteractiveGlobeScreenState();
}

class _InteractiveGlobeScreenState extends State<InteractiveGlobeScreen> {
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  String _activeLayer = 'Standard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Interactive Globe'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Stack(
          children: [
            // 3D Globe Viewer
            Center(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _rotationY += details.delta.dx * 0.01;
                    _rotationX -= details.delta.dy * 0.01;
                  });
                },
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: GlobePainter(
                    rotX: _rotationX,
                    rotY: _rotationY,
                    layer: _activeLayer,
                  ),
                ),
              ),
            ),

            // Layer Controls
            Positioned(
              bottom: 40,
              left: 16,
              right: 16,
              child: GlassContainer(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Explore Layers',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _layerButton('Standard', Icons.language),
                        _layerButton('Tectonic', Icons.category),
                        _layerButton('Climate', Icons.thermostat),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Interaction Hint
            const Positioned(
              top: 100,
              right: 16,
              child: GlassContainer(
                padding: EdgeInsets.all(8),
                opacity: 0.1,
                child: Column(
                  children: [
                    Icon(LucideIcons.hand, color: Colors.white54, size: 20),
                    Text('Drag to Rotate',
                        style: TextStyle(fontSize: 10, color: Colors.white38)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _layerButton(String name, IconData icon) {
    final bool isActive = _activeLayer == name;
    return GestureDetector(
      onTap: () => setState(() => _activeLayer = name),
      child: Column(
        children: [
          Icon(icon, color: isActive ? Colors.blueAccent : Colors.white24),
          const SizedBox(height: 4),
          Text(name,
              style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.white : Colors.white24)),
        ],
      ),
    );
  }
}
