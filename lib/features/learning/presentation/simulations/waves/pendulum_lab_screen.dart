import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating a simple pendulum and exploring its harmonic motion.
class PendulumLabScreen extends StatefulWidget {
  /// Creates a [PendulumLabScreen] instance.
  const PendulumLabScreen({super.key});

  @override
  State<PendulumLabScreen> createState() => _PendulumLabScreenState();
}

class _PendulumLabScreenState extends State<PendulumLabScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  // Pendulum State
  double _angle = pi / 4; // Initial 45 degrees
  double _angularVelocity = 0;
  double _angularAcceleration = 0;

  // Constants
  double _length = 200; // pixels
  double _gravity = 0.5;
  final double _damping = 0.995; // Resistance

  // Origin point (Pivot)
  Offset _origin = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _origin = Offset(size.width / 2, 100);

    // Calculate bob position
    final bobX = _origin.dx + _length * sin(_angle);
    final bobY = _origin.dy + _length * cos(_angle);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Pendulum (High School)')),
      body: Stack(
        children: [
          const LiquidBackground(child: SizedBox.expand()),
          CustomPaint(
            painter: _PendulumPainter(_origin, Offset(bobX, bobY)),
            child: Container(),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    const Text('Length'),
                    Expanded(
                        child: Slider(
                            min: 50,
                            max: 400,
                            value: _length,
                            onChanged: (v) => setState(() => _length = v))),
                  ]),
                  Row(children: [
                    const Text('Gravity'),
                    Expanded(
                        child: Slider(
                            min: 0.1,
                            max: 2,
                            value: _gravity,
                            onChanged: (v) => setState(() => _gravity = v))),
                  ]),
                  ElevatedButton(
                    onPressed: () {
                      // Reset
                      setState(() {
                        _angle = pi / 4;
                        _angularVelocity = 0;
                      });
                    },
                    child: const Text('Reset'),
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
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    setState(() {
      _angularAcceleration = (-1 * _gravity / _length) * sin(_angle);
      _angularVelocity += _angularAcceleration;
      _angularVelocity *= _damping;
      _angle += _angularVelocity;
    });
  }
}

class _PendulumPainter extends CustomPainter {
  final Offset origin;
  final Offset bob;

  /// Creates a [_PendulumPainter] instance.
  _PendulumPainter(this.origin, this.bob);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Pivot
    canvas.drawCircle(origin, 5, Paint()..color = Colors.white);

    // Draw String
    canvas.drawLine(
        origin,
        bob,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2);

    // Draw Bob
    canvas.drawCircle(bob, 20, Paint()..color = Colors.purple);
    canvas.drawCircle(
        bob,
        20,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
