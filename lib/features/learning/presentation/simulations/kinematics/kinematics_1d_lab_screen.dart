import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A laboratory screen for simulating one-dimensional motion with constant acceleration.
class Kinematics1DLabScreen extends StatefulWidget {
  /// Creates a [Kinematics1DLabScreen] instance.
  const Kinematics1DLabScreen({super.key});

  @override
  State<Kinematics1DLabScreen> createState() => _Kinematics1DLabScreenState();
}

class _Kinematics1DLabScreenState extends State<Kinematics1DLabScreen>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  // State
  double _position = 0.0; // meters (0 to 100)
  double _velocity = 0.0; // m/s
  double _acceleration = 0.0; // m/s^2
  double _time = 0.0; // seconds

  bool _isPlaying = false;

  // Config
  final double _pixelsPerMeter = 5.0; // Scale

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Kinematics: 1D Motion'),
          backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: Column(
          children: [
            // Visualization Area
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Track
                  Positioned(
                    left: 20,
                    right: 20,
                    top: MediaQuery.of(context).size.height * 0.2,
                    child: Container(height: 4, color: Colors.white24),
                  ),

                  // Car/Object
                  Positioned(
                    left: 20 + (_position * _pixelsPerMeter), // Offset start
                    top: MediaQuery.of(context).size.height * 0.2 - 20,
                    child: Column(
                      children: [
                        const Icon(LucideIcons.car,
                            color: Colors.cyanAccent, size: 40),
                        Text('${_position.toStringAsFixed(1)}m',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10))
                      ],
                    ),
                  ),

                  // Data Overlay
                  Positioned(
                    top: 100,
                    right: 20,
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time: ${_time.toStringAsFixed(2)}s'),
                          Text('Pos (x): ${_position.toStringAsFixed(2)}m'),
                          Text('Vel (v): ${_velocity.toStringAsFixed(2)}m/s'),
                          Text(
                              'Acc (a): ${_acceleration.toStringAsFixed(2)}m/s²'),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Controls
            Expanded(
              flex: 2,
              child: GlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Controls',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildControlSlider('Initial Velocity', _velocity, -20, 50,
                        (v) => _velocity = v,
                        enabled: !_isPlaying),
                    _buildControlSlider('Acceleration', _acceleration, -10, 10,
                        (v) => _acceleration = v,
                        enabled: true), // Can change acceleration while running

                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          heroTag: 'play_k1d',
                          onPressed: _togglePlay,
                          child:
                              Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        ),
                        const SizedBox(width: 20),
                        FloatingActionButton(
                          heroTag: 'reset_k1d',
                          onPressed: _reset,
                          backgroundColor: Colors.redAccent,
                          child: const Icon(LucideIcons.refreshCw),
                        ),
                      ],
                    )
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
    _ticker.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  Widget _buildControlSlider(String label, double value, double min, double max,
      Function(double) onChanged,
      {bool enabled = true}) {
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
              onChanged: enabled ? (v) => setState(() => onChanged(v)) : null),
        ),
        SizedBox(
            width: 40,
            child: Text(value.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 12))),
      ],
    );
  }

  void _onTick(Duration elapsed) {
    if (!_isPlaying) return;

    // Euler integration
    // v = v0 + at
    // x = x0 + vt
    double dt = 0.016; // Fixed step for simplicity

    setState(() {
      _time += dt;
      _velocity += _acceleration * dt;
      _position += _velocity * dt;

      // Wall collision (simple stop)
      if (_position < 0) {
        _position = 0;
        _velocity = 0;
        _isPlaying = false;
        _ticker.stop();
      } else if (_position > 1000) {
        // arbitrary far limit
        // keep going
      }
    });
  }

  void _reset() {
    setState(() {
      _isPlaying = false;
      _ticker.stop();
      _position = 0.0;
      _velocity = 0.0;
      _acceleration = 0.0;
      _time = 0.0;
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
