import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';

/// A simulation for exploring projectile motion with adjustable launch angle and initial velocity.
class ProjectileMotionSimulation extends StatefulWidget {
  /// Creates a [ProjectileMotionSimulation] instance.
  const ProjectileMotionSimulation({super.key});

  @override
  State<ProjectileMotionSimulation> createState() =>
      _ProjectileMotionSimulationState();
}

class _ProjectileMotionSimulationState extends State<ProjectileMotionSimulation>
    with SingleTickerProviderStateMixin {
  double _angle = 45.0; // Degrees
  double _velocity = 50.0; // m/s
  bool _isAnimating = false;

  // Animation state
  late AnimationController _controller;
  double _time = 0;
  List<Offset> _trajectoryPoints = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Projectile Motion'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: LiquidBackground(
        child: Column(
          children: [
            // Simulation Canvas
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRect(
                  child: CustomPaint(
                    painter: _ProjectilePainter(_trajectoryPoints),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),

            // Controls
            Expanded(
              flex: 1,
              child: GlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSlider('Launch Angle', _angle, 0, 90,
                        (v) => setState(() => _angle = v), '°'),
                    _buildSlider('Initial Velocity', _velocity, 10, 100,
                        (v) => setState(() => _velocity = v), ' m/s'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isAnimating ? null : _fire,
                      icon: const Icon(LucideIcons.rocket),
                      label: const Text('LAUNCH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
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
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _controller.addListener(_updatePhysics);
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${value.toStringAsFixed(1)}$unit',
                style: const TextStyle(color: Colors.cyanAccent)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Colors.cyanAccent,
          onChanged: _isAnimating ? null : onChanged,
        ),
      ],
    );
  }

  void _fire() async {
    setState(() {
      _isAnimating = true;
      _time = 0;
      _trajectoryPoints = [];
    });
    _controller.repeat(
        period: const Duration(milliseconds: 16)); // ~60 FPS loop

    // Hook: Log Activity
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await ProgressTrackingService().logActivity(
          userId: userId,
          activityType: 'simulation_run',
          metadata: {
            'simulation': 'projectile_motion',
            'category': 'learning',
          },
        );
      }
    } catch (e) {
      AppLogger.info('Error logging simulation: $e');
    }
  }

  void _stopSimulation() {
    _controller.stop();
    setState(() => _isAnimating = false);
  }

  void _updatePhysics() {
    if (!_isAnimating) return;

    // Physics Constants
    const g = 9.81;
    final rad = _angle * pi / 180;
    final v0x = _velocity * cos(rad);
    final v0y = _velocity * sin(rad);

    // Time step (simulated)
    _time += 0.05;

    // Calculate position
    final x = v0x * _time;
    final y = (v0y * _time) - (0.5 * g * _time * _time);

    if (y < 0) {
      _stopSimulation();
    } else {
      setState(() {
        // Scale for screen fitting (simple scaling)
        _trajectoryPoints.add(Offset(x * 2, 300 - (y * 2)));
      });
    }
  }
}

/// Custom painter for rendering the projectile trajectory and current position.
class _ProjectilePainter extends CustomPainter {
  /// The list of points representing the trajectory.
  final List<Offset> points;

  /// Creates a [_ProjectilePainter] instance.
  _ProjectilePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // Cannon Base
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(0, size.height - 20), 10, paint);

    // Ground
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height),
        paint..color = Colors.white54);

    // Trajectory
    if (points.isNotEmpty) {
      final path = Path();
      // Adjust points to canvas coordinates (Origin at bottom-left)
      final adjustedPoints = points
          .map((p) => Offset(p.dx + 20, size.height - 20 - (300 - p.dy)))
          .toList();

      path.moveTo(20, size.height - 20);
      for (var p in adjustedPoints) {
        path.lineTo(p.dx, p.dy);
      }

      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.amber
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);

      // Projectile
      final lastPoint = adjustedPoints.last;
      canvas.drawCircle(lastPoint, 6, Paint()..color = Colors.redAccent);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
