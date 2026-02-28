import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating a mass-spring-damper system.
class SpringLabScreen extends StatefulWidget {
  /// Creates a [SpringLabScreen] instance.
  const SpringLabScreen({super.key});

  @override
  State<SpringLabScreen> createState() => _SpringLabScreenState();
}

class _SpringLabScreenState extends State<SpringLabScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  // Physics Parameters
  double _mass = 5.0; // kg
  double _k = 50.0; // Spring constant (N/m)
  double _damping = 0.5; // Damping coefficient

  // State Variables
  double _position = 100.0; // Displacement from equilibrium (pixels)
  double _velocity = 0.0;
  final double _timeStep = 0.016; // approx 60fps

  bool _isPlaying = false;
  final double _equilibriumY = 300.0; // Screen Y coordinate for equilibrium

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Spring & Damping'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Equilibrium Line
                  Positioned(
                    top: _equilibriumY,
                    left: 50,
                    right: 50,
                    child: Container(height: 2, color: Colors.white24),
                  ),

                  // Spring
                  Positioned(
                    top: 100, // Anchor point
                    child: CustomPaint(
                      painter: _SpringPainter(
                          endY: (_equilibriumY + _position) - 100, width: 40),
                      size: Size(40, (_equilibriumY + _position) - 100),
                    ),
                  ),

                  // Mass Block
                  Positioned(
                    top: _equilibriumY + _position,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _isPlaying = false;
                          _ticker.stop();
                          _position += details.delta.dy;
                          _velocity = 0;
                        });
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(blurRadius: 10, color: Colors.black26)
                            ]),
                        child: Center(
                          child: Text(
                            '${_mass.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Controls
            GlassContainer(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSlider(
                      'Spring Constant (k)', _k, 10, 200, (val) => _k = val),
                  _buildSlider('Mass (m)', _mass, 1, 20, (val) => _mass = val),
                  _buildSlider(
                      'Damping (c)', _damping, 0, 5, (val) => _damping = val),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: 'play',
                        onPressed: _togglePlay,
                        child:
                            Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      const SizedBox(width: 20),
                      FloatingActionButton(
                        heroTag: 'reset',
                        onPressed: _reset,
                        backgroundColor: Colors.redAccent,
                        child: const Icon(LucideIcons.refreshCw),
                      ),
                    ],
                  )
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
    _ticker.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  Widget _buildSlider(String label, double value, double min, double max,
      Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(value.toStringAsFixed(1),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Theme.of(context).colorScheme.secondary,
          onChanged: (val) {
            setState(() {
              onChanged(val);
            });
          },
        ),
      ],
    );
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying) return;

    setState(() {
      // F = -kx - cv
      // a = F/m
      double forceSpring = -_k * (_position);
      double forceDamping = -_damping * _velocity;
      double acceleration = (forceSpring + forceDamping) / _mass;

      _velocity += acceleration * _timeStep * 10; // Scale up for visual speed
      _position += _velocity * _timeStep * 10;
    });
  }

  void _reset() {
    setState(() {
      _isPlaying = false;
      _ticker.stop();
      _position = 100.0;
      _velocity = 0.0;
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _ticker.start();
      } else {
        _ticker.stop();
      }
    });
  }
}

class _SpringPainter extends CustomPainter {
  final double endY;
  final double width;

  _SpringPainter({required this.endY, required this.width});

  @override
  void paint(Canvas canvas, Size size) {
    if (endY <= 0) return;

    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(width / 2, 0);

    // Draw zig-zag spring
    int coils = 12;
    double step = endY / coils;

    for (int i = 0; i < coils; i++) {
      double x = (i % 2 == 0) ? 0 : width;
      double y = (i * step) + (step / 2);
      path.lineTo(x, y);
    }

    path.lineTo(width / 2, endY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpringPainter oldDelegate) => oldDelegate.endY != endY;
}
