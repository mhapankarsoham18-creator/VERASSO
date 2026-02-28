import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating enzyme-substrate kinetics and inhibition.
class EnzymeKineticsScreen extends StatefulWidget {
  /// Creates an [EnzymeKineticsScreen] instance.
  const EnzymeKineticsScreen({super.key});

  @override
  State<EnzymeKineticsScreen> createState() => _EnzymeKineticsScreenState();
}

/// A custom painter for visualizing enzyme-substrate interactions.
class EnzymePainter extends CustomPainter {
  /// The current animation progress.
  final double progress;

  /// The concentration of the substrate.
  final double substrateConc;

  /// Whether an inhibitor is present.
  final bool hasInhibitor;

  /// Creates an [EnzymePainter] instance.
  EnzymePainter({
    required this.progress,
    required this.substrateConc,
    required this.hasInhibitor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final enzymePaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Draw Enzyme
    canvas.drawCircle(center, 60, enzymePaint);
    final activeSitePaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromCenter(center: center, width: 30, height: 30),
        activeSitePaint);

    // Draw Substrates
    final substratePaint = Paint()..color = Colors.blueAccent;
    final int count = (substrateConc / 10).round() + 5;

    final random = math.Random(42);
    for (int i = 0; i < count; i++) {
      final double radius = 80 + random.nextDouble() * 100;
      final double angle =
          random.nextDouble() * 2 * math.pi + (progress * 2 * math.pi);
      final pos =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawCircle(pos, 5, substratePaint);
    }

    // Draw Inhibitors
    if (hasInhibitor) {
      final inhibitorPaint = Paint()..color = Colors.redAccent;
      for (int i = 0; i < 5; i++) {
        final double radius = 70 + random.nextDouble() * 80;
        final double angle =
            -random.nextDouble() * 2 * math.pi - (progress * 3 * math.pi);
        final pos =
            center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        canvas.drawRect(
            Rect.fromCenter(center: pos, width: 8, height: 8), inhibitorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(EnzymePainter oldDelegate) => true;
}

/// Painter for rendering the Michaelis-Menten enzyme kinetics graph.
class GraphPainter extends CustomPainter {
  /// Current substrate concentration.
  final double substrate;

  /// Maximum reaction velocity.
  final double vMax;

  /// Michaelis constant (substrate concentration at half Vmax).
  final double km;

  /// Whether a competitive inhibitor is present in the simulation.
  final bool hasInhibitor;

  /// Concentration of the inhibitor.
  final double inhibitorConc;

  /// Creates a [GraphPainter] instance.
  GraphPainter({
    required this.substrate,
    required this.vMax,
    required this.km,
    required this.hasInhibitor,
    required this.inhibitorConc,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    // Axes
    canvas.drawLine(Offset(10, size.height - 10),
        Offset(size.width - 10, size.height - 10), paint);
    canvas.drawLine(const Offset(10, 10), Offset(10, size.height - 10), paint);

    // Curve
    final curvePaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(10, size.height - 10);

    for (double x = 0; x < size.width - 20; x++) {
      double s = (x / (size.width - 20)) * 200; // mapped to [0, 200]
      double effectiveKm = km;
      if (hasInhibitor) {
        effectiveKm = km * (1 + inhibitorConc / 20.0);
      }
      double v = (vMax * s) / (effectiveKm + s);
      double y = size.height - 10 - (v / vMax) * (size.height - 20);
      path.lineTo(x + 10, y);
    }
    canvas.drawPath(path, curvePaint);

    // Current point
    final double currentX = 10 + (substrate / 200) * (size.width - 20);
    double effectiveKm = km;
    if (hasInhibitor) {
      effectiveKm = km * (1 + inhibitorConc / 20.0);
    }
    final double currentV = (vMax * substrate) / (effectiveKm + substrate);
    final double currentY =
        size.height - 10 - (currentV / vMax) * (size.height - 20);

    canvas.drawCircle(
        Offset(currentX, currentY), 4, Paint()..color = Colors.amber);
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) => true;
}

class _EnzymeKineticsScreenState extends State<EnzymeKineticsScreen>
    with SingleTickerProviderStateMixin {
  double _substrateConc = 50.0; // [S]
  final double _vMax = 100.0;
  final double _km = 25.0;
  bool _hasInhibitor = false;
  double _inhibitorConc = 0.0;

  late AnimationController _animationController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Enzyme Kinetics Lab'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            const SizedBox(height: 100),
            // Top Section: Molecular Visualization (Animated)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassContainer(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: EnzymePainter(
                          progress: _animationController.value,
                          substrateConc: _substrateConc,
                          hasInhibitor: _hasInhibitor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Bottom Section: Control & Graph
            Expanded(
              flex: 4,
              child: GlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kinetic Parameters',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(color: Colors.amber)),
                              const SizedBox(height: 16),
                              _ParamSlider(
                                label: 'Substrate [S]',
                                value: _substrateConc,
                                unit: 'mM',
                                max: 200,
                                color: Colors.blueAccent,
                                onChanged: (v) =>
                                    setState(() => _substrateConc = v),
                              ),
                              _ParamSlider(
                                label: 'Inhibitor [I]',
                                value: _inhibitorConc,
                                unit: 'mM',
                                max: 100,
                                color: Colors.redAccent,
                                onChanged: (v) => setState(() {
                                  _inhibitorConc = v;
                                  _hasInhibitor = v > 0;
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Mini Graph
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: CustomPaint(
                            painter: GraphPainter(
                              substrate: _substrateConc,
                              vMax: _vMax,
                              km: _km,
                              hasInhibitor: _hasInhibitor,
                              inhibitorConc: _inhibitorConc,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                            label: 'Vmax',
                            value: '${_vMax.toStringAsFixed(0)} units/s'),
                        _StatItem(
                            label: 'Km', value: '${_km.toStringAsFixed(0)} mM'),
                        _StatItem(
                          label: 'Velocity (v)',
                          value:
                              '${_calculateVelocity(_substrateConc).toStringAsFixed(1)} units/s',
                          color: Colors.greenAccent,
                        ),
                      ],
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
    )..repeat();
  }

  double _calculateVelocity(double s) {
    // Michaelis-Menten equation: v = (Vmax * [S]) / (Km + [S])
    // With Competitive Inhibitor: Km_app = Km * (1 + [I]/Ki)
    double effectiveKm = _km;
    if (_hasInhibitor) {
      effectiveKm = _km * (1 + _inhibitorConc / 20.0);
    }
    return (_vMax * s) / (effectiveKm + s);
  }
}

class _ParamSlider extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _ParamSlider({
    required this.label,
    required this.value,
    required this.unit,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white54)),
            Text('${value.toStringAsFixed(0)} $unit',
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: max,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.white)),
      ],
    );
  }
}
