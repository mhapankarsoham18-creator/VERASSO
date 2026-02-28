import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating and visualizing transverse waves.
class WaveLabScreen extends StatefulWidget {
  /// Creates a [WaveLabScreen] instance.
  const WaveLabScreen({super.key});

  @override
  State<WaveLabScreen> createState() => _WaveLabScreenState();
}

class _WaveLabScreenState extends State<WaveLabScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  // Wave Parameters
  double _amplitude = 50.0;
  double _wavelength = 200.0;
  double _speed = 100.0; // pixels per second
  double _phase = 0.0;

  bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Wave Machine'),
          backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: _WavePainter(
                    amplitude: _amplitude,
                    wavelength: _wavelength,
                    phase: _phase,
                    color: Theme.of(context).colorScheme.primary),
                child: Container(),
              ),
            ),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildControlSlider(
                      'Amplitude', _amplitude, 10, 150, (v) => _amplitude = v),
                  _buildControlSlider('Frequency / Wavelength', _wavelength, 50,
                      400, (v) => _wavelength = v),
                  _buildControlSlider(
                      'Speed', _speed, 0, 300, (v) => _speed = v),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        heroTag: 'play_wave',
                        onPressed: _togglePlay,
                        child:
                            Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      const SizedBox(width: 20),
                      FloatingActionButton(
                        heroTag: 'reset_wave',
                        onPressed: _reset,
                        backgroundColor: Colors.redAccent,
                        child: const Icon(LucideIcons.refreshCw),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
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

  Widget _buildControlSlider(String label, double value, double min, double max,
      Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.white70))),
        Expanded(
          child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (v) => setState(() => onChanged(v))),
        ),
        Text(value.toStringAsFixed(0),
            style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying) return;
    setState(() {
      _phase += (_speed * 0.016 / _wavelength) * 2 * math.pi;
    });
  }

  void _reset() {
    setState(() {
      _phase = 0.0;
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _ticker.start();
      } else {
        _ticker.stop();
      }
    });
  }
}

class _WavePainter extends CustomPainter {
  final double amplitude;
  final double wavelength;
  final double phase;
  final Color color;

  /// Creates a [_WavePainter] instance.
  _WavePainter(
      {required this.amplitude,
      required this.wavelength,
      required this.phase,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    final centerY = size.height / 2;

    // y = A * sin(kx - wt + phi)
    // k = 2pi / wavelength
    final k = 2 * math.pi / wavelength;

    for (double x = 0; x <= size.width; x += 2) {
      double y = centerY + amplitude * math.sin(k * x - phase);
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw equilibrium
    paint.color = Colors.white24;
    paint.strokeWidth = 1;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}
