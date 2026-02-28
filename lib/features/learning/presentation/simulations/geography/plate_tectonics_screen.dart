import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// Types of tectonic plate boundaries.
enum BoundaryType {
  /// Plates moving toward each other.
  convergent,

  /// Plates moving away from each other.
  divergent,

  /// Plates sliding past each other.
  transform
}

/// A screen for simulating tectonic plate boundaries and their associated geological features.
class PlateTectonicsScreen extends StatefulWidget {
  /// Creates a [PlateTectonicsScreen] instance.
  const PlateTectonicsScreen({super.key});

  @override
  State<PlateTectonicsScreen> createState() => _PlateTectonicsScreenState();
}

/// Represents a tectonic boundary on the map with its associated type and description.
class TectonicBoundary {
  /// The name of the boundary (e.g., 'Himalayas').
  final String name;

  /// The type of boundary (convergent, divergent, transform).
  final BoundaryType type;

  /// A description of the boundary and its geological effects.
  final String description;

  /// The normalized (0-1) position of the boundary on the map.
  final Offset position;

  /// Creates a [TectonicBoundary] instance.
  TectonicBoundary({
    required this.name,
    required this.type,
    required this.description,
    required this.position,
  });
}

/// A custom painter for rendering a tectonic plate map and boundary animations.
class TectonicMapPainter extends CustomPainter {
  /// The animation value for boundary movement.
  final Animation<double> animationValue;

  /// The currently active boundary being simulated.
  final TectonicBoundary? activeBoundary;

  /// Creates a [TectonicMapPainter] instance.
  TectonicMapPainter({required this.animationValue, this.activeBoundary})
      : super(repaint: animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white24;

    // Draw simplified plate outlines (Static)
    final path = Path();
    // NA Plate
    path.moveTo(size.width * 0.1, size.height * 0.1);
    path.lineTo(size.width * 0.45, size.height * 0.15); // Mid-ocean ridge line
    path.lineTo(size.width * 0.45, size.height * 0.4);
    path.lineTo(size.width * 0.1, size.height * 0.3);
    path.close();

    // Eurasia
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.lineTo(size.width * 0.9, size.height * 0.1);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.35); // Himalayas
    path.close();

    // South America
    path.moveTo(size.width * 0.3, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.8);
    path.lineTo(size.width * 0.28, size.height * 0.6); // Andes
    path.close();

    canvas.drawPath(path, paint);

    // Dynamic Animation based on boundary type
    if (activeBoundary != null) {
      final center = Offset(
          activeBoundary!.position.dx * size.width,
          activeBoundary!.position.dy *
              size.height *
              0.8 // Adjust for map aspect ratio
          );

      final animPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.orangeAccent;

      final arrowDist = 20.0 * sin(animationValue.value * pi); // Oscillate

      if (activeBoundary!.type == BoundaryType.divergent) {
        // Arrows pointing away
        _drawArrow(canvas, center.translate(-10, 0), pi, arrowDist, animPaint);
        _drawArrow(canvas, center.translate(10, 0), 0, arrowDist, animPaint);
      } else if (activeBoundary!.type == BoundaryType.convergent) {
        // Arrows pointing together
        _drawArrow(canvas, center.translate(-15 - arrowDist, 0), 0, 10,
            animPaint); // Converging
        _drawArrow(
            canvas, center.translate(15 + arrowDist, 0), pi, 10, animPaint);

        // Mountain rise effect
        canvas.drawCircle(
            center,
            5 + (animationValue.value * 10),
            Paint()
              ..color = Colors.brown.withValues(alpha: 0.5)
              ..style = PaintingStyle.fill);
      } else if (activeBoundary!.type == BoundaryType.transform) {
        // Arrows sliding active
        _drawArrow(canvas, center.translate(-5, -10 + arrowDist), pi / 2, 10,
            animPaint); // Down
        _drawArrow(canvas, center.translate(5, 10 - arrowDist), -pi / 2, 10,
            animPaint); // Up
      }
    }
  }

  @override
  bool shouldRepaint(covariant TectonicMapPainter oldDelegate) => true;

  void _drawArrow(
      Canvas canvas, Offset pos, double angle, double length, Paint paint) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    canvas.drawLine(Offset.zero, Offset(length, 0), paint);
    canvas.drawLine(Offset(length, 0), Offset(length - 5, -5), paint);
    canvas.drawLine(Offset(length, 0), Offset(length - 5, 5), paint);
    canvas.restore();
  }
}

class _PlateTectonicsScreenState extends State<PlateTectonicsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  TectonicBoundary? _selectedBoundary;

  final List<TectonicBoundary> _boundaries = [
    TectonicBoundary(
      name: 'Mid-Atlantic Ridge',
      type: BoundaryType.divergent,
      description: 'Plates move apart, creating new seafloor (magma rises).',
      position: const Offset(0.48, 0.4),
    ),
    TectonicBoundary(
      name: 'Himalayas',
      type: BoundaryType.convergent,
      description: 'Indian and Eurasian plates collide, forming mountains.',
      position: const Offset(0.65, 0.35),
    ),
    TectonicBoundary(
      name: 'San Andreas Fault',
      type: BoundaryType.transform,
      description: 'Pacific and North American plates slide past each other.',
      position: const Offset(0.15, 0.32),
    ),
    TectonicBoundary(
      name: 'Andes Mountains',
      type: BoundaryType.convergent,
      description: 'Nazca plate subducts under South American plate.',
      position: const Offset(0.28, 0.6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Plate Tectonics', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            // Visualization
            Expanded(
              flex: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 80),
                child: GlassContainer(
                  child: Stack(
                    children: [
                      // Base Map (Simplified Tectonic Map)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: TectonicMapPainter(
                            animationValue: _animationController,
                            activeBoundary: _selectedBoundary,
                          ),
                        ),
                      ),

                      // Interactive Hotspots
                      ..._boundaries.map((boundary) {
                        return Positioned(
                          left: boundary.position.dx *
                              (MediaQuery.of(context).size.width - 64),
                          top: boundary.position.dy * 300, // Approximate height
                          child: GestureDetector(
                            onTap: () => _triggerSimulation(boundary),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedBoundary == boundary
                                    ? Colors.redAccent
                                    : Colors.amber.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      spreadRadius: 1)
                                ],
                              ),
                              child: Icon(LucideIcons.activity,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // Controls & Info
            Expanded(
              flex: 2,
              child: GlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedBoundary?.name ?? 'Select a Boundary',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedBoundary?.description ??
                          'Tap a hotspot on the map to simulate tectonic movement.',
                      style:
                          const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedBoundary != null)
                      Row(
                        children: [
                          Icon(LucideIcons.move, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Type: ${_selectedBoundary!.type.name.toUpperCase()}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    if (_selectedBoundary != null)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _triggerSimulation(_selectedBoundary!),
                          icon: const Icon(LucideIcons.play),
                          label: const Text('Replay Simulation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  void _triggerSimulation(TectonicBoundary boundary) {
    setState(() {
      _selectedBoundary = boundary;
    });
    _animationController.forward(from: 0.0);
  }
}
