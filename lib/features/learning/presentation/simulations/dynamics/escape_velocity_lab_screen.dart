import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for calculating the escape velocity of various planets.
class EscapeVelocityLabScreen extends StatefulWidget {
  /// Creates an [EscapeVelocityLabScreen] instance.
  const EscapeVelocityLabScreen({super.key});

  @override
  State<EscapeVelocityLabScreen> createState() =>
      _EscapeVelocityLabScreenState();
}

class _EscapeVelocityLabScreenState extends State<EscapeVelocityLabScreen> {
  double _planetMass = 5.97; // x 10^24 kg (Earth)
  double _planetRadius = 6.37; // x 10^6 m (Earth)

  // Constants

  @override
  Widget build(BuildContext context) {
    // Calculate Escape Velocity
    // v = sqrt(2GM/R)
    // result in km/s
    double v = 11.186 * _sqrt((_planetMass / 5.97) / (_planetRadius / 6.37));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Escape Velocity')),
      body: LiquidBackground(
        child: Padding(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          child: Column(
            children: [
              GlassContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Escape Velocity Calculator',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'This simulation calculates the velocity needed to escape a planet\'s gravitational pull.',
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildControl('Planet Mass (x 10²⁴ kg)', _planetMass, 0.1,
                          500.0, (val) => setState(() => _planetMass = val)),
                      _buildControl(
                          'Planet Radius (x 10⁶ m)',
                          _planetRadius,
                          0.1,
                          100.0,
                          (val) => setState(() => _planetRadius = val)),
                      const SizedBox(height: 20),
                      Text(
                        'Escape Velocity: ${v.toStringAsFixed(2)} km/s',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GlassContainer(
                  child: Center(
                    child: CustomPaint(
                      size: const Size(300, 300),
                      painter: _PlanetPainter(_planetRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControl(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  double _sqrt(double x) {
    if (x < 0) return 0;
    if (x == 0) return 0;
    double r = x;
    for (int i = 0; i < 10; i++) {
      r = 0.5 * (r + x / r);
    }
    return r;
  }
}

class _PlanetPainter extends CustomPainter {
  final double radius;
  _PlanetPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = Colors.blueAccent;

    // Scale radius for visual representation (clamped)
    double visualRadius = (radius * 10).clamp(20.0, 140.0);

    canvas.drawCircle(center, visualRadius, paint);

    // Draw "rocket" path
    final pathPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: visualRadius + 20),
        -1.57, // start top
        3.14, // half circle
        false,
        pathPaint);
  }

  @override
  bool shouldRepaint(covariant _PlanetPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
