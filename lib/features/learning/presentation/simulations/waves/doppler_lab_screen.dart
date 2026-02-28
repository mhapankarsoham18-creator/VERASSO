import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating the Doppler Effect using moving sound sources.
class DopplerLabScreen extends StatefulWidget {
  /// Creates a [DopplerLabScreen] instance.
  const DopplerLabScreen({super.key});

  @override
  State<DopplerLabScreen> createState() => _DopplerLabScreenState();
}

class _DopplerLabScreenState extends State<DopplerLabScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_WaveFront> _waves = [];

  // Simulation Params
  double _sourceX = 100.0;
  final double _sourceY = 200.0;
  double _sourceVelocity = 50.0; // Px/sec
  double _waveSpeed = 100.0; // Px/sec
  double _frequency = 2.0; // Emission rate (Hz)

  double _timeSinceLastEmission = 0.0;
  final bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Sound: The Doppler Effect'),
          backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: Column(
          children: [
            Expanded(
              child: ClipRect(
                child: CustomPaint(
                  painter: _DopplerPainter(
                      waves: _waves, sourceX: _sourceX, sourceY: _sourceY),
                  child: Container(),
                ),
              ),
            ),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildControlSlider('Source Speed (vs)', _sourceVelocity, 0,
                      150, (v) => _sourceVelocity = v),
                  _buildControlSlider('Wave Speed (v)', _waveSpeed, 50, 200,
                      (v) => _waveSpeed = v),
                  _buildControlSlider('Frequency (f)', _frequency, 0.5, 5,
                      (v) => _frequency = v),
                  const SizedBox(height: 10),
                  Text(
                    'Mach: ${(_sourceVelocity / _waveSpeed).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: (_sourceVelocity > _waveSpeed)
                            ? Colors.redAccent
                            : Colors.white70,
                        fontWeight: FontWeight.bold),
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
            width: 100,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.white70))),
        Expanded(
          child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (v) => setState(() => onChanged(v))),
        ),
      ],
    );
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying) return;
    setState(() {
      double dt = 0.016; // Approx 60fps

      // Move Source
      _sourceX += _sourceVelocity * dt;
      if (_sourceX > 400) {
        _sourceX = 0; // Wrap around
      }

      // Expand Waves
      for (var wave in _waves) {
        wave.radius += _waveSpeed * dt;
        wave.opacity -= 0.5 * dt; // Fade out
      }
      _waves.removeWhere((w) => w.opacity <= 0);

      // Emit new wave
      _timeSinceLastEmission += dt;
      if (_timeSinceLastEmission >= (1 / _frequency)) {
        _waves.add(_WaveFront(x: _sourceX, y: _sourceY));
        _timeSinceLastEmission = 0;
      }
    });
  }
}

class _DopplerPainter extends CustomPainter {
  final List<_WaveFront> waves;
  final double sourceX;
  final double sourceY;

  _DopplerPainter(
      {required this.waves, required this.sourceX, required this.sourceY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var wave in waves) {
      paint.color =
          Colors.cyanAccent.withValues(alpha: wave.opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(wave.x, wave.y), wave.radius, paint);
    }

    // Draw Source
    paint.style = PaintingStyle.fill;
    paint.color = Colors.redAccent;
    canvas.drawCircle(Offset(sourceX, sourceY), 8, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Represents a single wave front emitted by a moving source.
class _WaveFront {
  /// The X-coordinate of the wave front's origin.
  final double x;

  /// The Y-coordinate of the wave front's origin.
  final double y;

  /// The current radius of the wave front.
  double radius = 0;

  /// The visual opacity of the wave front.
  double opacity = 1.0;

  /// Creates a [_WaveFront] instance.
  _WaveFront({required this.x, required this.y});
}
