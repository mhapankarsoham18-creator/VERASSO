import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for exploring gravity and bounce effects with interactive balls.
class GravityLabScreen extends StatefulWidget {
  /// Creates a [GravityLabScreen] instance.
  const GravityLabScreen({super.key});

  @override
  State<GravityLabScreen> createState() => _GravityLabScreenState();
}

/// Represents a physical ball in the gravity simulation.
class _Ball {
  /// The X-coordinate of the ball.
  double x;

  /// The Y-coordinate of the ball.
  double y;

  /// The horizontal velocity.
  double vx = 0;

  /// The vertical velocity.
  double vy = 0;

  /// The visual and physical radius of the ball.
  final double radius;

  /// The color of the ball.
  final Color color;

  /// Creates a [_Ball] instance.
  _Ball({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    this.vx = 0,
    this.vy = 0,
  });
}

/// Custom painter for rendering multiple balls in the [GravityLabScreen].
class _BallsPainter extends CustomPainter {
  /// The list of balls to render.
  final List<_Ball> balls;

  /// Creates a [_BallsPainter] instance.
  _BallsPainter(this.balls);

  @override
  void paint(Canvas canvas, Size size) {
    for (var ball in balls) {
      canvas.drawCircle(
          Offset(ball.x, ball.y), ball.radius, Paint()..color = ball.color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GravityLabScreenState extends State<GravityLabScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_Ball> _balls = [];
  double _gravity = 0.5;
  double _bounceFactor = 0.7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Gravity Lab (Lower School)')),
      body: Stack(
        children: [
          const LiquidBackground(child: SizedBox.expand()),
          GestureDetector(
            onTapDown: (details) =>
                _addBall(details.globalPosition.dx, details.globalPosition.dy),
            child: CustomPaint(
              painter: _BallsPainter(_balls),
              child: Container(),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Controls',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Text('Gravity'),
                      Expanded(
                        child: Slider(
                            value: _gravity,
                            min: 0.0,
                            max: 2.0,
                            onChanged: (v) => setState(() => _gravity = v)),
                      ),
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
                            onChanged: (v) =>
                                setState(() => _bounceFactor = v)),
                      ),
                    ],
                  ),
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
    _addBall(100, 100);
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
        ball.vy += _gravity;
        ball.x += ball.vx;
        ball.y += ball.vy;

        if (ball.y + ball.radius > size.height) {
          ball.y = size.height - ball.radius;
          ball.vy *= -_bounceFactor;
        }
        if (ball.x + ball.radius > size.width || ball.x - ball.radius < 0) {
          ball.vx *= -1;
        }
      }
    });
  }
}
