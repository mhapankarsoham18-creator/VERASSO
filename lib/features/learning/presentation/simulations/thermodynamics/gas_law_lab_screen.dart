import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating the ideal gas law (PV = nRT).
class GasLawLabScreen extends StatefulWidget {
  /// Creates a [GasLawLabScreen] instance.
  const GasLawLabScreen({super.key});

  @override
  State<GasLawLabScreen> createState() => _GasLawLabScreenState();
}

class _GasLawLabScreenState extends State<GasLawLabScreen> {
  // Ideal Gas Law: PV = nRT
  // We'll simulate P = nRT / V

  double _volume = 50.0; // Liters (arbitrary scale 10-100)
  double _temperature = 300.0; // Kelvin (100-1000)
  double _moles = 1.0; // Moles (0.1 - 5.0)

  final double _idealGasConstant = 8.314; // J/(mol·K)

  double get _pressure {
    // P = (n * R * T) / V
    // Result in kPa (if V is Liters? approximate units for simulation)
    // P (kPa) * V (L) = n * R * T ...
    // Let's just use proportional values for visualization
    return (_moles * _idealGasConstant * _temperature) / _volume;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Thermodynamics: Gas Law')),
      body: LiquidBackground(
        child: Padding(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          child: Column(
            children: [
              // Visualization
              Expanded(
                flex: 4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Container (Cylinder)
                    Container(
                      width: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 4),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Piston
                          Container(
                            height: 20,
                            color: Colors.grey,
                            margin: EdgeInsets.only(
                                bottom: (_volume * 3).clamp(
                                    0, 300)), // Move piston based on Volume
                          ),
                          // Particles
                          SizedBox(
                            height: (_volume * 3).clamp(0, 300),
                            width: double.infinity,
                            child: ClipRect(
                              child: CustomPaint(
                                painter: _ParticlePainter(
                                    _moles, _temperature, _volume),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),

                    // Readout
                    Positioned(
                      top: 20,
                      right: 20,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Pressure: ${_pressure.toStringAsFixed(1)} kPa',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 5),
                            const Text('PV = nRT'),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),

              // Controls
              Expanded(
                flex: 3,
                child: GlassContainer(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSlider('Volume (V)', _volume, 10, 100,
                          (v) => setState(() => _volume = v), 'L'),
                      _buildSlider('Temperature (T)', _temperature, 100, 1000,
                          (v) => setState(() => _temperature = v), 'K'),
                      _buildSlider('Moles (n)', _moles, 0.5, 5.0,
                          (v) => setState(() => _moles = v), 'mol'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      ValueChanged<double> onChanged, String unit) {
    return Row(
      children: [
        SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: _colorForTemp(label),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
            width: 60,
            child: Text('${value.toStringAsFixed(1)} $unit',
                style: const TextStyle(color: Colors.white, fontSize: 12))),
      ],
    );
  }

  Color _colorForTemp(String label) {
    if (label.contains('Temp')) {
      // Gradient from blue to red based on temp?
      return Color.lerp(Colors.blue, Colors.red, (_temperature - 100) / 900) ??
          Colors.amber;
    }
    return Colors.cyanAccent;
  }
}

/// Custom painter for rendering gas particles in the [GasLawLabScreen].
class _ParticlePainter extends CustomPainter {
  /// The number of moles (determines particle count).
  final double moles;

  /// The temperature of the gas (determines speed).
  final double temp;

  /// The volume of the container.
  final double volume;

  /// Creates a [_ParticlePainter] instance.
  _ParticlePainter(this.moles, this.temp, this.volume);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = DateTime.now()
        .millisecondsSinceEpoch; // Use a fixed seed in real sim or ticker
    // We just draw random dots for now to simulate particles

    int count = (moles * 20).toInt();
    // Speed visual
    // paint.color = Color.lerp(Colors.blue, Colors.red, (temp - 100) / 900)!.withValues(alpha: 0.6);

    // Animate? For now static random distribution redraws
    // Ideally use Ticker to animate positions.
    for (int i = 0; i < count; i++) {
      double x = (i * 1324.23 + random) % size.width;
      double y = (i * 4532.12 + random) % size.height;
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      true; // Redraw for "jitter" effect if we used ticker, but here just on state change.
}
