import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// Represents a neurotransmitter molecule in the synapse simulation.
class Neurotransmitter {
  /// The starting position of the molecule.
  final Offset startPos;

  /// The angle at which the molecule is released.
  final double angle;

  /// The age/progress of the molecule in its journey across the synapse.
  double age = 0.0;

  /// Whether the molecule has successfully bound to a receptor.
  bool isBound = false;

  /// Creates a [Neurotransmitter] instance.
  Neurotransmitter({required this.startPos, required this.angle}) {
    isBound = math.Random().nextDouble() > 0.4;
  }
}

/// A custom painter for rendering the synaptic cleft, neurotransmitters, and receptors.
class SynapsePainter extends CustomPainter {
  /// The current value of the pulse animation.
  final double pulseValue;

  /// The list of active neurotransmitters.
  final List<Neurotransmitter> transmitters;

  /// Whether an action potential is currently pulsing.
  final bool isPulsing;

  /// Creates a [SynapsePainter] instance.
  SynapsePainter({
    required this.pulseValue,
    required this.transmitters,
    required this.isPulsing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final topY = size.height * 0.2;
    final bottomY = size.height * 0.8;

    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 1. Pre-synaptic Terminal (Top)
    final topPath = Path();
    topPath.moveTo(centerX - 100, 0);
    topPath.quadraticBezierTo(centerX - 100, topY, centerX - 40, topY);
    topPath.lineTo(centerX + 40, topY);
    topPath.quadraticBezierTo(centerX + 100, topY, centerX + 100, 0);
    canvas.drawPath(topPath, paint);

    if (isPulsing) {
      final pulsePaint = Paint()
        ..color = Colors.amber.withValues(alpha: 1.0 - pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawPath(topPath, pulsePaint);
    }

    // 2. Post-synaptic Membrane (Bottom)
    final bottomPath = Path();
    bottomPath.moveTo(centerX - 120, size.height);
    bottomPath.lineTo(centerX - 120, bottomY);
    bottomPath.lineTo(centerX + 120, bottomY);
    bottomPath.lineTo(centerX + 120, size.height);
    canvas.drawPath(bottomPath, paint);

    // 3. Receptors
    final receptorPaint = Paint()
      ..color = Colors.purpleAccent.withValues(alpha: 0.5);
    for (int i = 0; i < 5; i++) {
      final rx = centerX - 80 + i * 40;
      canvas.drawRect(
          Rect.fromCenter(center: Offset(rx, bottomY), width: 20, height: 10),
          receptorPaint);
    }

    // 4. Transmitters
    final tPaint = Paint()..color = Colors.greenAccent;
    for (var t in transmitters) {
      final double dist = t.age * (bottomY - topY);
      final double x = centerX - 40 + (t.angle * 20);
      final double y = topY + dist;
      canvas.drawCircle(Offset(x, y), 3, tPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SynapsePainter oldDelegate) => true;
}

/// A screen for simulating synaptic transmission between two neurons.
class SynapseSimScreen extends StatefulWidget {
  /// Creates a [SynapseSimScreen] instance.
  const SynapseSimScreen({super.key});

  @override
  State<SynapseSimScreen> createState() => _SynapseSimScreenState();
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white54)),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Colors.amber, label: 'Axon'),
        SizedBox(width: 16),
        _LegendItem(color: Colors.greenAccent, label: 'Dopamine'),
        SizedBox(width: 16),
        _LegendItem(color: Colors.purpleAccent, label: 'Receptors'),
      ],
    );
  }
}

class _SynapseSimScreenState extends State<SynapseSimScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final List<Neurotransmitter> _transmitters = [];
  int _receptorsBound = 0;
  bool _isActionPotentialRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Synaptic Transmission'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: SynapsePainter(
                          pulseValue: _pulseController.value,
                          transmitters: _transmitters,
                          isPulsing: _isActionPotentialRunning,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: GlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Post-Synaptic Response',
                                style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold)),
                            Text('Receptor binding events',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.white38)),
                          ],
                        ),
                        Text('$_receptorsBound pts',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _triggerActionPotential,
                      icon: const Icon(LucideIcons.zap),
                      label: const Text('Trigger Action Potential'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _LegendRow(),
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  void _releaseTransmitters() {
    setState(() {
      final random = math.Random();
      for (int i = 0; i < 20; i++) {
        _transmitters.add(Neurotransmitter(
          startPos: const Offset(150, 150),
          angle: (math.pi / 4) + (random.nextDouble() * math.pi / 2),
        ));
      }
    });

    // Animate transmitters
    Timer.periodic(const Duration(milliseconds: 32), (timer) {
      if (_transmitters.isEmpty) {
        timer.cancel();
        return;
      }

      setState(() {
        for (var t in _transmitters.toList()) {
          t.age += 0.05;
          if (t.age > 1.0) {
            if (t.isBound) _receptorsBound++;
            _transmitters.remove(t);
          }
        }
      });
    });
  }

  void _triggerActionPotential() {
    if (_isActionPotentialRunning) return;

    setState(() {
      _isActionPotentialRunning = true;
      _receptorsBound = 0;
    });

    _pulseController.forward(from: 0.0).then((_) {
      _releaseTransmitters();
      setState(() => _isActionPotentialRunning = false);
    });
  }
}
