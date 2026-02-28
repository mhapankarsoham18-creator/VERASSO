import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating projectile motion with angle and velocity controls.
class ProjectileLabScreen extends StatefulWidget {
  /// Creates a [ProjectileLabScreen] instance.
  const ProjectileLabScreen({super.key});

  @override
  State<ProjectileLabScreen> createState() => _ProjectileLabScreenState();
}

class _ProjectileLabScreenState extends State<ProjectileLabScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  // Projectile State
  double _x = 50, _y = 0; // Relative to cannon
  double _vx = 0, _vy = 0;
  bool _isFiring = false;
  final List<Offset> _trail = [];

  // Controls
  double _angleDeg = 45;
  double _velocity = 50; // Initial speed
  final double _gravity = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Projectile Motion (Middle School)')),
      body: Stack(
        children: [
          const LiquidBackground(child: SizedBox.expand()),

          // Canvas
          CustomPaint(
            painter: _ProjectilePainter(_x, _y, _trail),
            child: Container(),
          ),

          // Controls
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    const Text('Angle'),
                    Expanded(
                        child: Slider(
                            min: 0,
                            max: 90,
                            value: _angleDeg,
                            onChanged: (v) => setState(() => _angleDeg = v))),
                    Text('${_angleDeg.toInt()}°')
                  ]),
                  Row(children: [
                    const Text('Velocity'),
                    Expanded(
                        child: Slider(
                            min: 10,
                            max: 100,
                            value: _velocity,
                            onChanged: (v) => setState(() => _velocity = v))),
                    Text('${_velocity.toInt()}')
                  ]),
                  ElevatedButton(
                    onPressed: _fire,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('FIRE CANNON'),
                  )
                ],
              ),
            ),
          )
        ],
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

  void _fire() {
    _x = 50;
    _y = MediaQuery.of(context).size.height - 150; // Ground level

    // Convert angle to velocity components
    // Usually 0 deg is right.
    double rad = _angleDeg * pi / 180;
    _vx = _velocity * cos(rad) * 0.3; // Scale down for screen
    _vy = -_velocity * sin(rad) * 0.3; // Up is negative y

    _trail.clear();
    _isFiring = true;
    if (!_ticker.isTicking) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted || !_isFiring) return;
    setState(() {
      _vy += _gravity; // Apply gravity
      _x += _vx;
      _y += _vy;

      _trail.add(Offset(_x, _y));

      // Ground Collision
      final groundY = MediaQuery.of(context).size.height - 150;
      if (_y > groundY) {
        _y = groundY;
        _isFiring = false;
        _ticker.stop();
      }
    });
  }
}

class _ProjectilePainter extends CustomPainter {
  final double x, y;
  final List<Offset> trail;
  _ProjectilePainter(this.x, this.y, this.trail);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Ground
    final groundY = size.height - 150;
    canvas.drawLine(
        Offset(0, groundY),
        Offset(size.width, groundY),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2);

    // Draw Cannon (Simple Arc)
    canvas.drawArc(Rect.fromLTWH(20, groundY - 30, 60, 60), pi, pi / 2, true,
        Paint()..color = Colors.grey);

    // Draw Trail
    if (trail.isNotEmpty) {
      final points = trail.map((e) => e).toList(); // copy
      canvas.drawPoints(
          ui.PointMode.polygon,
          points,
          Paint()
            ..color = Colors.white54
            ..strokeWidth = 1);
    }

    // Draw Ball
    canvas.drawCircle(Offset(x, y), 10, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
