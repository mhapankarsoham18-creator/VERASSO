import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A custom painter for rendering the interference pattern from a double-slit experiment.
class InterferencePainter extends CustomPainter {
  /// The wavelength of the light source in nanometers.
  final double wavelength;

  /// The distance between the two slits in nanometers.
  final double slitDistance;

  /// The distance from the slit to the screen in centimeters.
  final double distanceToScreen;

  /// Creates an [InterferencePainter] instance.
  InterferencePainter({
    required this.wavelength,
    required this.slitDistance,
    required this.distanceToScreen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;

    final paint = Paint()..strokeWidth = 2.0;

    // Draw interference pattern base
    for (double x = 0; x < width; x += 2) {
      final double normalizedX = (x - centerX) / (width / 2); // -1 to 1

      // I = I0 * cos^2( (π * d * sin(θ)) / λ )
      // sin(θ) ≈ tan(θ) = y/L
      // Phase difference φ = (2π/λ) * d * (y/L)

      final double theta =
          math.atan(normalizedX * 0.1); // Small angle approximation
      final double phase =
          (math.pi * slitDistance * math.sin(theta)) / wavelength;
      final double intensity = math.pow(math.cos(phase), 2).toDouble();

      paint.color = _getColorForWavelength(wavelength)
          .withValues(alpha: intensity.clamp(0.0, 1.0));
      canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
    }

    // Draw scale
    paint.color = Colors.white30;
    canvas.drawLine(Offset(0, height - 20), Offset(width, height - 20), paint);

    for (int i = -2; i <= 2; i++) {
      final x = centerX + i * (width / 4);
      canvas.drawLine(Offset(x, height - 25), Offset(x, height - 15), paint);
    }
  }

  @override
  bool shouldRepaint(covariant InterferencePainter oldDelegate) =>
      oldDelegate.wavelength != wavelength ||
      oldDelegate.slitDistance != slitDistance ||
      oldDelegate.distanceToScreen != distanceToScreen;

  Color _getColorForWavelength(double wavelength) {
    if (wavelength < 440) return Colors.deepPurple;
    if (wavelength < 485) return Colors.blue;
    if (wavelength < 500) return Colors.cyan;
    if (wavelength < 565) return Colors.green;
    if (wavelength < 590) return Colors.yellow;
    if (wavelength < 625) return Colors.orange;
    return Colors.red;
  }
}

/// A screen for simulating light wave interference through a double-slit experiment.
class InterferenceSimScreen extends StatefulWidget {
  /// Creates an [InterferenceSimScreen] instance.
  const InterferenceSimScreen({super.key});

  @override
  State<InterferenceSimScreen> createState() => _InterferenceSimScreenState();
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white38)),
            Text(value,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _InterferenceSimScreenState extends State<InterferenceSimScreen> {
  double _wavelength = 500.0; // nm
  double _slitDistance = 2000.0; // nm
  double _distanceToScreen = 100.0; // cm

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Wave Interference Lab'),
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
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: InterferencePainter(
                      wavelength: _wavelength,
                      slitDistance: _slitDistance,
                      distanceToScreen: _distanceToScreen,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: GlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Double Slit Parameters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _ParameterSlider(
                      label: 'Wavelength (λ)',
                      value: _wavelength,
                      min: 380,
                      max: 750,
                      unit: 'nm',
                      color: _getColorForWavelength(_wavelength),
                      onChanged: (val) => setState(() => _wavelength = val),
                    ),
                    _ParameterSlider(
                      label: 'Slit Distance (d)',
                      value: _slitDistance,
                      min: 1000,
                      max: 5000,
                      unit: 'nm',
                      onChanged: (val) => setState(() => _slitDistance = val),
                    ),
                    _ParameterSlider(
                      label: 'Distance to Screen (L)',
                      value: _distanceToScreen,
                      min: 50,
                      max: 500,
                      unit: 'cm',
                      onChanged: (val) =>
                          setState(() => _distanceToScreen = val),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const _InfoItem(
                          icon: LucideIcons.info,
                          label: 'Central Max',
                          value: 'Brightest',
                        ),
                        _InfoItem(
                          icon: LucideIcons.maximize,
                          label: 'Fringe Width',
                          value:
                              '${_calculateFringeWidth().toStringAsFixed(2)} mm',
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

  double _calculateFringeWidth() {
    // Δy = λL / d
    return (_wavelength * 1e-9 * _distanceToScreen * 1e-2) /
        (_slitDistance * 1e-9) *
        1000;
  }

  Color _getColorForWavelength(double wavelength) {
    if (wavelength < 440) return Colors.deepPurple;
    if (wavelength < 485) return Colors.blue;
    if (wavelength < 500) return Colors.cyan;
    if (wavelength < 565) return Colors.green;
    if (wavelength < 590) return Colors.yellow;
    if (wavelength < 625) return Colors.orange;
    return Colors.red;
  }
}

class _ParameterSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Color? color;
  final ValueChanged<double> onChanged;

  const _ParameterSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.white60)),
            Text('${value.toStringAsFixed(0)} $unit',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.white)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: color ?? Colors.amber,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
