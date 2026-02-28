import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating light refraction using Snell's Law.
class RefractionLabScreen extends StatefulWidget {
  /// Creates a [RefractionLabScreen] instance.
  const RefractionLabScreen({super.key});

  @override
  State<RefractionLabScreen> createState() => _RefractionLabScreenState();
}

/// A custom painter for visualizing light rays crossing a boundary between two media.
class RefractionPainter extends CustomPainter {
  /// The refractive index of the first medium.
  final double n1;

  /// The refractive index of the second medium.
  final double n2;

  /// The angle of incidence in degrees.
  final double angleIncidence;

  /// Creates a [RefractionPainter] instance.
  RefractionPainter({
    required this.n1,
    required this.n2,
    required this.angleIncidence,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw Surface
    paint.color = Colors.white54;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);

    // Draw Normal
    paint.color = Colors.white24;
    Util.drawDashedLine(
        canvas, Offset(center.dx, 0), Offset(center.dx, size.height), paint);

    // Calculate Angles (in radians)
    final theta1 = angleIncidence * math.pi / 180;

    // Snell's Law: n1 * sin(theta1) = n2 * sin(theta2)
    // theta2 = asin( (n1/n2) * sin(theta1) )
    double? theta2;
    bool totalInternalReflection = false;

    double sinTheta2 = (n1 / n2) * math.sin(theta1);

    if (sinTheta2.abs() > 1.0) {
      totalInternalReflection = true;
      theta2 = theta1; // Reflection angle equals incidence
    } else {
      theta2 = math.asin(sinTheta2);
    }

    // Draw Incident Ray
    paint.color = Colors.yellowAccent;
    paint.strokeWidth = 4;
    final incidentLen = math.min(size.width, size.height) * 0.4;
    final incidentStart = Offset(center.dx - incidentLen * math.sin(theta1),
        center.dy - incidentLen * math.cos(theta1));
    canvas.drawLine(incidentStart, center, paint);

    // Draw Refracted/Reflected Ray
    paint.color = totalInternalReflection
        ? Colors.yellowAccent.withValues(alpha: 0.5)
        : Colors.cyanAccent;
    final refractedLen = incidentLen;
    // If n1 > n2 and TIR, it reflects back up (-y), else it goes down (+y)
    double dy = totalInternalReflection ? -math.cos(theta2) : math.cos(theta2);
    double dx = math.sin(theta2);

    final refractedEnd =
        Offset(center.dx + refractedLen * dx, center.dy + refractedLen * dy);
    canvas.drawLine(center, refractedEnd, paint);
  }

  @override
  bool shouldRepaint(RefractionPainter old) => true;
}

/// Utility class for drawing helper functions in the optics simulation.
class Util {
  /// Draws a vertical dashed line on the [canvas].
  static void drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint,
      {double dashWidth = 5, double dashSpace = 5}) {
    // Distance used implicitly in calculation
    double startY = p1.dy;
    double currentY = startY;
    while (currentY < p2.dy) {
      canvas.drawLine(
          Offset(p1.dx, currentY), Offset(p1.dx, currentY + dashWidth), paint);
      currentY += dashWidth + dashSpace;
    }
  }
}

class _RefractionLabScreenState extends State<RefractionLabScreen> {
  // Parameters
  double _n1 = 1.0; // Air
  double _n2 = 1.5; // Glass
  double _angleIncidence = 45.0; // Degrees

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Light: Refraction (Snell\'s Law)'),
          backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: RefractionPainter(
                    n1: _n1, n2: _n2, angleIncidence: _angleIncidence),
                child: Container(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildControlSlider(
                        'Medium 1 Index (n1)', _n1, 1.0, 2.5, (v) => _n1 = v),
                    _buildControlSlider(
                        'Medium 2 Index (n2)', _n2, 1.0, 2.5, (v) => _n2 = v),
                    _buildControlSlider('Incidence Angle', _angleIncidence, 0,
                        89, (v) => _angleIncidence = v),
                    const SizedBox(height: 10),
                    Text(
                      'Critical Angle: ${(_n2 < _n1) ? '${(math.asin(_n2 / _n1) * 180 / math.pi).toStringAsFixed(1)}°' : 'None'}',
                      style: const TextStyle(
                          color: Colors.white70, fontStyle: FontStyle.italic),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildControlSlider(String label, double value, double min, double max,
      Function(double) onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(value.toStringAsFixed(2),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) => setState(() => onChanged(v))),
      ],
    );
  }
}
