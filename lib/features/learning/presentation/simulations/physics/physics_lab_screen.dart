import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for exploring gravity and collision physics through an interactive canvas.
class PhysicsLabScreen extends StatefulWidget {
  /// Creates a [PhysicsLabScreen] instance.
  const PhysicsLabScreen({super.key});

  @override
  State<PhysicsLabScreen> createState() => _PhysicsLabScreenState();
}

class _Ball {
  double x, y;
  double vx = 0, vy = 0;
  final double radius;
  final Color color;

  _Ball(
      {required this.x,
      required this.y,
      required this.radius,
      required this.color,
      this.vx = 0,
      this.vy = 0});
}

class _BallsPainter extends CustomPainter {
  final List<_Ball> balls;

  /// Creates a [_BallsPainter] instance.
  _BallsPainter(this.balls);

  @override
  void paint(Canvas canvas, Size size) {
    for (var ball in balls) {
      final paint = Paint()..color = ball.color;
      canvas.drawCircle(Offset(ball.x, ball.y), ball.radius, paint);
      // Shine
      final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
      canvas.drawCircle(
          Offset(ball.x - ball.radius * 0.3, ball.y - ball.radius * 0.3),
          ball.radius * 0.3,
          shinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PhysicsLabScreenState extends State<PhysicsLabScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  // Physics State
  final List<_Ball> _balls = [];
  double _gravity = 0.5;
  double _bounceFactor = 0.7; // Energy loss

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Gravity Lab')),
      body: Stack(
        children: [
          // 1. Background
          const LiquidBackground(child: SizedBox.expand()),

          // 2. Interactive Canvas
          GestureDetector(
            onTapDown: (details) =>
                _addBall(details.globalPosition.dx, details.globalPosition.dy),
            child: CustomPaint(
              painter: _BallsPainter(_balls),
              child: Container(),
            ),
          ),

          // 3. Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Simulation Controls',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Text('Gravity'),
                      Expanded(
                        child: Slider(
                          value: _gravity,
                          min: 0.0,
                          max: 2.0,
                          onChanged: (v) => setState(() => _gravity = v),
                        ),
                      ),
                      Text(_gravity.toStringAsFixed(1)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Bounce'),
                      Expanded(
                        child: Slider(
                          value: _bounceFactor,
                          min: 0.1,
                          max: 1.5,
                          onChanged: (v) => setState(() => _bounceFactor = v),
                        ),
                      ),
                      Text(_bounceFactor.toStringAsFixed(1)),
                    ],
                  ),
                  const Text('Tap anywhere to spawn objects',
                      style: TextStyle(fontSize: 12, color: Colors.white70))
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
    _ticker = createTicker(_onTick)..start();
    _addBall(100, 100); // Initial ball
  }

  void _addBall(double x, double y) {
    _balls.add(_Ball(
        x: x,
        y: y,
        radius: Random().nextDouble() * 20 + 10,
        color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
        vx: (Random().nextDouble() - 0.5) * 10,
        vy: (Random().nextDouble() - 0.5) * 10));
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    setState(() {
      final size = MediaQuery.of(context).size;
      for (var ball in _balls) {
        // Apply Gravity
        ball.vy += _gravity;

        // Update Position
        ball.x += ball.vx;
        ball.y += ball.vy;

        // Floor Collision
        if (ball.y + ball.radius > size.height) {
          ball.y = size.height - ball.radius;
          ball.vy *= -_bounceFactor;
        }

        // Wall Collision
        if (ball.x + ball.radius > size.width || ball.x - ball.radius < 0) {
          ball.vx *= -1;
        }
      }
    });
  }
}
