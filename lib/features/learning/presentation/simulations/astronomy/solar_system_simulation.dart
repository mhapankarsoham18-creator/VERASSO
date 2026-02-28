import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/features/learning/presentation/classroom/ai_assistant/ai_assistant_screen.dart';

/// Represents the physical and visual data for a planet in the solar system simulation.
class PlanetData {
  /// The name of the planet.
  final String name;

  /// The color used to represent the planet.
  final Color color;

  /// The radius of the planet's orbit around the sun.
  final double orbitRadius;

  /// The orbital speed of the planet.
  final double speed;

  /// The visual size of the planet.
  final double size;

  /// The relative mass of the planet.
  final double mass;

  /// Physics State: The current position of the planet.
  Offset position = Offset.zero;

  /// Physics State: The current velocity of the planet.
  Offset velocity = Offset.zero;

  /// Physics State: A trail of previous positions for rendering.
  List<Offset> history = [];

  /// Creates a [PlanetData] instance.
  PlanetData({
    required this.name,
    required this.color,
    required this.orbitRadius,
    required this.speed,
    required this.size,
    required this.mass,
  });
}

/// A custom painter for rendering the solar system, including the sun, orbits, and planets.
class SolarSystemPainter extends CustomPainter {
  /// The list of planets to render.
  final List<PlanetData> planets;

  /// The current simulation time.
  final double time;

  /// Whether to display engineering-specific vectors (velocity, gravity).
  final bool engineeringMode;

  /// Creates a [SolarSystemPainter] instance.
  SolarSystemPainter({
    required this.planets,
    required this.time,
    required this.engineeringMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Sun
    final sunPaint = Paint()
      ..color = Colors.yellow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, 30, sunPaint);
    canvas.drawCircle(center, 25, Paint()..color = Colors.yellowAccent);

    // Orbits & Planets
    for (var planet in planets) {
      if (!engineeringMode) {
        // Orbit Path (Only in Orrery mode)
        canvas.drawCircle(
            center,
            planet.orbitRadius,
            Paint()
              ..color = Colors.white10
              ..style = PaintingStyle.stroke);
      }

      // Planet Position
      Offset planetPos;
      if (engineeringMode) {
        planetPos = planet.position;

        // Draw Trails
        if (planet.history.length > 1) {
          final trailPaint = Paint()
            ..color = planet.color.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          final path = Path()
            ..moveTo(planet.history.first.dx, planet.history.first.dy);
          for (var p in planet.history.skip(1)) {
            path.lineTo(p.dx, p.dy);
          }
          canvas.drawPath(path, trailPaint);
        }
      } else {
        final angle = time * planet.speed * 0.1;
        final x = center.dx + math.cos(angle) * planet.orbitRadius;
        final y = center.dy + math.sin(angle) * planet.orbitRadius;
        planetPos = Offset(x, y);
      }

      // Planet Body
      canvas.drawCircle(planetPos, planet.size, Paint()..color = planet.color);

      // Engineering Vectors
      if (engineeringMode) {
        // Velocity Vector
        canvas.drawLine(
            planetPos,
            planetPos + (planet.velocity * 5),
            Paint()
              ..color = Colors.cyanAccent
              ..strokeWidth = 2);

        // Force Vector (Gravity)
        final diff = center - planetPos;
        final forceDir = diff / diff.distance;
        canvas.drawLine(
            planetPos,
            planetPos + (forceDir * 20),
            Paint()
              ..color = Colors.redAccent
              ..strokeWidth = 2);
      }

      // Label
      final textSpan = TextSpan(
          text: planet.name,
          style: const TextStyle(color: Colors.white70, fontSize: 10));
      final textPainter =
          TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(planetPos.dx - textPainter.width / 2,
              planetPos.dy + planet.size + 4));
    }
  }

  @override
  bool shouldRepaint(covariant SolarSystemPainter oldDelegate) => true;
}

/// A simulation screen that displays an interactive solar system with orrery and engineering modes.
class SolarSystemSimulation extends StatefulWidget {
  /// Creates a [SolarSystemSimulation] instance.
  const SolarSystemSimulation({super.key});

  @override
  State<SolarSystemSimulation> createState() => _SolarSystemSimulationState();
}

/// A custom painter for rendering a background star field.
class StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42);
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < 200; i++) {
      paint.color =
          Colors.white.withValues(alpha: rand.nextDouble() * 0.8 + 0.2);
      canvas.drawCircle(
          Offset(
              rand.nextDouble() * size.width, rand.nextDouble() * size.height),
          rand.nextDouble() * 1.5,
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SolarSystemSimulationState extends State<SolarSystemSimulation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Game State
  bool _gameActive = false;
  int _score = 0;
  String? _targetPlanetName;
  String _message = "Explore the Solar System";
  Color _messageColor = Colors.white;
  bool _engineeringMode = false;
  final double _timeScale = 1.0;
  final double _gConstant = 100.0; // Scaled for simulation visual

  final double _canvasSize = 800.0;

  final List<PlanetData> _planets = [
    PlanetData(
        name: 'Mercury',
        color: Colors.grey,
        orbitRadius: 60,
        speed: 4.7,
        size: 8,
        mass: 0.05),
    PlanetData(
        name: 'Venus',
        color: Colors.orangeAccent,
        orbitRadius: 90,
        speed: 3.5,
        size: 12,
        mass: 0.81),
    PlanetData(
        name: 'Earth',
        color: Colors.blue,
        orbitRadius: 130,
        speed: 2.9,
        size: 14,
        mass: 1.0),
    PlanetData(
        name: 'Mars',
        color: Colors.redAccent,
        orbitRadius: 170,
        speed: 2.4,
        size: 10,
        mass: 0.1),
    PlanetData(
        name: 'Jupiter',
        color: Colors.brown,
        orbitRadius: 240,
        speed: 1.3,
        size: 28,
        mass: 317.0),
    PlanetData(
        name: 'Saturn',
        color: Colors.amber,
        orbitRadius: 320,
        speed: 0.9,
        size: 24,
        mass: 95.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Stars
          Positioned.fill(
            child: CustomPaint(painter: StarFieldPainter()),
          ),

          // Solar System
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(400),
              child: Center(
                child: GestureDetector(
                  onTapUp: _handleTap,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(_canvasSize, _canvasSize),
                        painter: SolarSystemPainter(
                            planets: _planets,
                            time: _controller.value * 2 * math.pi * 10,
                            engineeringMode: _engineeringMode),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Top Controls
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(backgroundColor: Colors.white10),
                ),
                GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    _message,
                    style: TextStyle(
                        color: _messageColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                if (_gameActive)
                  GlassContainer(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('Score: $_score',
                        style: const TextStyle(
                            color: Colors.amber, fontWeight: FontWeight.bold)),
                  )
                else
                  IconButton(
                    icon: Icon(
                        _engineeringMode
                            ? LucideIcons.gauge
                            : LucideIcons.circleDot,
                        color: _engineeringMode
                            ? Colors.orangeAccent
                            : Colors.white),
                    onPressed: () {
                      setState(() {
                        _engineeringMode = !_engineeringMode;
                        if (_engineeringMode) _initializePhysics();
                      });
                    },
                    style:
                        IconButton.styleFrom(backgroundColor: Colors.white10),
                    tooltip: 'Toggle Engineering Mode',
                  ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_gameActive) ...[
                  FloatingActionButton.small(
                    heroTag: 'cosmos_solar',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AIAssistantScreen())),
                    backgroundColor: Colors.cyanAccent.withValues(alpha: 0.8),
                    child: const Icon(LucideIcons.bot, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _startGame,
                    icon: const Icon(LucideIcons.gamepad2),
                    label: const Text('Start "Find the Planet"'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.white),
                  )
                ] else
                  ElevatedButton.icon(
                    onPressed: _stopGame,
                    icon: const Icon(LucideIcons.x),
                    label: const Text('Quit Game'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white),
                  ),
              ],
            ),
          ),

          if (!_gameActive)
            Positioned(
              bottom: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Solar System Orrery',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Pinch to zoom • Drag to move',
                        style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializePhysics();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..addListener(_onTick)
          ..repeat();
  }

  void _handleTap(TapUpDetails details) {
    if (!_gameActive) return;

    final center = Offset(_canvasSize / 2, _canvasSize / 2);
    final tapPos = details.localPosition;
    final time = _controller.value * 2 * math.pi * 10;

    for (var planet in _planets) {
      Offset planetPos;
      if (_engineeringMode) {
        planetPos = planet.position;
      } else {
        final angle = time * planet.speed * 0.1;
        final x = center.dx + math.cos(angle) * planet.orbitRadius;
        final y = center.dy + math.sin(angle) * planet.orbitRadius;
        planetPos = Offset(x, y);
      }

      // Hitbox: Planet size + 20px padding for easier tapping
      if ((tapPos - planetPos).distance <= planet.size + 20) {
        if (planet.name == _targetPlanetName) {
          _triggerSuccess();
          break;
        } else {
          _triggerFailure("That's ${planet.name}!");
          return; // Wrong planet, stop checking
        }
      }
    }
  }

  void _initializePhysics() {
    final center = Offset(_canvasSize / 2, _canvasSize / 2);
    for (var planet in _planets) {
      // Set initial position based on orbitRadius
      final angle = math.Random().nextDouble() * 2 * math.pi;
      planet.position = Offset(
        center.dx + math.cos(angle) * planet.orbitRadius,
        center.dy + math.sin(angle) * planet.orbitRadius,
      );

      // Set initial velocity for circular motion: v = sqrt(G*M/r)
      // Here we approximate based on the existing speed for simplicity in transition
      final orbitalSpeed = planet.speed * 1.5;
      planet.velocity = Offset(
        -math.sin(angle) * orbitalSpeed,
        math.cos(angle) * orbitalSpeed,
      );
    }
  }

  void _onTick() {
    if (_engineeringMode) {
      _runPhysicsTick();
    }
  }

  void _pickNewTarget() {
    final rand = math.Random();
    _targetPlanetName = _planets[rand.nextInt(_planets.length)].name;
    _message = "Find $_targetPlanetName!";
    _messageColor = Colors.white;
  }

  void _runPhysicsTick() {
    const dt = 0.016; // Approx 60fps
    final center = Offset(_canvasSize / 2, _canvasSize / 2);
    const sunMass = 10000.0;

    setState(() {
      for (var planet in _planets) {
        // 1. Calculate Force (Gravity from Sun)
        final diff = center - planet.position;
        final r = diff.distance.clamp(30.0, 1000.0);
        final forceMag = (_gConstant * sunMass * planet.mass) / (r * r);
        final force = (diff / r) * forceMag;

        // 2. Update Velocity (v = v + a*dt) where a = F/m
        final acceleration = force / planet.mass;
        planet.velocity += acceleration * dt * _timeScale;

        // 3. Update Position (p = p + v*dt)
        planet.position += planet.velocity * dt * _timeScale;

        // 4. Update History (Trails)
        planet.history.add(planet.position);
        if (planet.history.length > 50) planet.history.removeAt(0);
      }
    });
  }

  void _startGame() {
    setState(() {
      _gameActive = true;
      _score = 0;
      _pickNewTarget();
    });
  }

  void _stopGame() {
    setState(() {
      _gameActive = false;
      _targetPlanetName = null;
      _message = "Explore the Solar System";
      _messageColor = Colors.white;
    });
  }

  void _triggerFailure(String msg) {
    setState(() {
      _message = "Wrong! $msg";
      _messageColor = Colors.redAccent;
    });
  }

  void _triggerSuccess() {
    setState(() {
      _message = "Correct! +10 Points";
      _messageColor = Colors.greenAccent;
    });

    // Phase 2: Persist Simulation Result
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        Supabase.instance.client.from('user_simulation_results').insert({
          'user_id': userId,
          'sim_id': 'solar_system_game',
          'parameters': {'target': _targetPlanetName},
          'results': {'score': _score, 'status': 'success'},
        }).then((_) => debugPrint('Solar system game result saved'));
      }
    } catch (e) {
      debugPrint('Error persisting solar system result: $e');
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _gameActive) {
        setState(() => _pickNewTarget());
      }
    });
  }
}
