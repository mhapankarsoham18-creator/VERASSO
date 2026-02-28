import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating simple DC circuits and Ohm's Law.
class CircuitLabScreen extends StatefulWidget {
  /// Creates a [CircuitLabScreen] instance.
  const CircuitLabScreen({super.key});

  @override
  State<CircuitLabScreen> createState() => _CircuitLabScreenState();
}

class _CircuitLabScreenState extends State<CircuitLabScreen> {
  double _voltage = 9.0;
  double _resistance = 100.0;
  bool _switchClosed = false;

  double get _current => _switchClosed ? _voltage / _resistance : 0.0;
  double get _power =>
      _switchClosed ? (_voltage * _voltage) / _resistance : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Circuit Lab')),
      body: LiquidBackground(
        child: Padding(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Ohm\'s Law: V = I * R',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildReadout(
                            'Voltage', '${_voltage.toStringAsFixed(1)} V'),
                        _buildReadout('Current',
                            '${(_current * 1000).toStringAsFixed(1)} mA'),
                        _buildReadout(
                            'Power', '${_power.toStringAsFixed(2)} W'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildControl('Voltage Source', _voltage, 1.0, 24.0,
                        (v) => setState(() => _voltage = v)),
                    _buildControl('Resistor (Ohms)', _resistance, 10.0, 1000.0,
                        (v) => setState(() => _resistance = v)),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('Switch',
                          style: TextStyle(color: Colors.white)),
                      value: _switchClosed,
                      activeThumbColor: Colors.amber,
                      onChanged: (v) => setState(() => _switchClosed = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GlassContainer(
                  child: Center(
                    child: CustomPaint(
                      size: const Size(300, 200),
                      painter:
                          _CircuitPainter(_switchClosed, _voltage, _resistance),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControl(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 100,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildReadout(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

/// Custom painter for rendering simple DC circuits with a battery, resistor, and wires.
class _CircuitPainter extends CustomPainter {
  /// Whether the circuit switch is closed (allowing current to flow).
  final bool isClosed;

  /// The voltage supplied by the battery.
  final double voltage;

  /// The resistance of the circuit component.
  final double resistance;

  /// Creates a [_CircuitPainter] instance.
  _CircuitPainter(this.isClosed, this.voltage, this.resistance);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

    // Wire Loop
    final path = Path();
    path.moveTo(width * 0.1, height * 0.2);
    path.lineTo(width * 0.9, height * 0.2); // Top wire
    path.lineTo(width * 0.9, height * 0.8); // Right wire
    path.lineTo(width * 0.1, height * 0.8); // Bottom wire
    path.close();

    canvas.drawPath(path, paint);

    // Battery (Left side)
    final batteryPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(width * 0.1, height * 0.5), width: 20, height: 40),
        batteryPaint);

    // Resistor (Top center)
    final resistorPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(width * 0.5, height * 0.2), width: 60, height: 20),
        resistorPaint);

    // Light bulb / Load visual (changes intensity with power)
    if (isClosed) {
      final intensity = (voltage / 24.0).clamp(0.2, 1.0);
      final glowPaint = Paint()
        ..color = Colors.amber.withValues(alpha: intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawCircle(
          Offset(size.width * 0.5, size.height * 0.2), 30, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter oldDelegate) =>
      oldDelegate.isClosed != isClosed || oldDelegate.voltage != voltage;
}
