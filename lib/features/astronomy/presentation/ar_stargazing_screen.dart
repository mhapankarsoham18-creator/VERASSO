import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../../core/data/constellation_data.dart';
import '../../../core/services/celestial_calculator.dart';

/// A screen that provides an Augmented Reality (AR) stargazing experience.
class ArStargazingScreen extends StatefulWidget {
  /// Creates an [ArStargazingScreen].
  const ArStargazingScreen({super.key});

  @override
  State<ArStargazingScreen> createState() => _ArStargazingScreenState();
}

class _ArStargazingScreenState extends State<ArStargazingScreen> {
  CameraController? _cameraController;
  Position? _currentPosition;
  double _deviceAzimuth = 0.0;
  double _devicePitch = 0.0;
  List<CelestialObject> _visibleObjects = [];
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription? _magnetometerSubscription;
  StreamSubscription? _accelerometerSubscription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AR Stargazing'),
        backgroundColor: Colors.black54,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : Stack(
                  children: [
                    // Camera view
                    if (_cameraController != null &&
                        _cameraController!.value.isInitialized)
                      SizedBox.expand(
                        child: CameraPreview(_cameraController!),
                      ),

                    // AR Overlay
                    CustomPaint(
                      size: Size.infinite,
                      painter: _CelestialOverlayPainter(
                        visibleObjects: _visibleObjects,
                        deviceAzimuth: _deviceAzimuth,
                        devicePitch: _devicePitch,
                        constellations: ConstellationData.constellations,
                        planets: ConstellationData.planets,
                        currentPosition: _currentPosition,
                      ),
                    ),

                    // Info overlay
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: GlassContainer(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                'Azimuth: ${_deviceAzimuth.toStringAsFixed(1)}°',
                                style: const TextStyle(fontSize: 12)),
                            Text('Pitch: ${_devicePitch.toStringAsFixed(1)}°',
                                style: const TextStyle(fontSize: 12)),
                            Text('Visible Objects: ${_visibleObjects.length}',
                                style: const TextStyle(fontSize: 12)),
                            if (_currentPosition != null)
                              Text(
                                  'Location: ${_currentPosition!.latitude.toStringAsFixed(2)}, ${_currentPosition!.longitude.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white70)),
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
    _cameraController?.dispose();
    _magnetometerSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Request permissions
      final cameraStatus = await Permission.camera.request();
      final locationStatus = await Permission.location.request();

      if (!cameraStatus.isGranted || !locationStatus.isGranted) {
        setState(() {
          _errorMessage = 'Camera and Location permissions required';
          _isLoading = false;
        });
        return;
      }

      // Initialize camera
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera available';
          _isLoading = false;
        });
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Get location
      _currentPosition = await Geolocator.getCurrentPosition();

      // Setup sensors
      _setupSensors();

      // Calculate visible objects
      _updateVisibleObjects();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization error: $e';
        _isLoading = false;
      });
    }
  }

  void _setupSensors() {
    // Magnetometer for compass (azimuth)
    _magnetometerSubscription = magnetometerEventStream().listen((event) {
      final azimuth = atan2(event.y, event.x) * 180 / pi;
      setState(() => _deviceAzimuth = (azimuth + 360) % 360);
    });

    // Accelerometer for tilt (pitch)
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      final pitch =
          atan2(-event.y, sqrt(event.x * event.x + event.z * event.z)) *
              180 /
              pi;
      setState(() => _devicePitch = pitch);
    });

    // Update visible objects every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (_) => _updateVisibleObjects());
  }

  void _updateVisibleObjects() {
    if (_currentPosition == null) return;

    // Sync planet positions for the current date
    ConstellationData.updatePlanetPositions(DateTime.now());

    final objects = CelestialCalculator.getVisibleObjects(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      time: DateTime.now(),
    );

    setState(() => _visibleObjects = objects);
  }
}

class _CelestialOverlayPainter extends CustomPainter {
  final List<CelestialObject> visibleObjects;
  final double deviceAzimuth;
  final double devicePitch;
  final Map<String, Constellation> constellations;
  final Map<String, Planet> planets;
  final Position? currentPosition;

  _CelestialOverlayPainter({
    required this.visibleObjects,
    required this.deviceAzimuth,
    required this.devicePitch,
    required this.constellations,
    required this.planets,
    required this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const fieldOfView = 60.0; // degrees

    // Draw constellations
    for (final constellation in constellations.values) {
      _drawConstellation(canvas, size, constellation, fieldOfView);
    }

    // Draw planets
    for (final planet in planets.values) {
      _drawPlanet(canvas, size, planet, fieldOfView);
    }

    // Draw individual stars
    for (final obj in visibleObjects) {
      if (obj.type == 'star') {
        final screenPos =
            _skyToScreen(obj.azimuth, obj.altitude, size, fieldOfView);
        if (screenPos != null) {
          _drawStar(canvas, screenPos);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void _drawConstellation(
      Canvas canvas, Size size, Constellation constellation, double fov) {
    if (currentPosition == null) return;

    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Convert star positions and draw connections
    final starPositions = <Offset?>[];
    for (final star in constellation.stars) {
      final coords = CelestialCalculator.equatorialToHorizontal(
        rightAscension: star.rightAscension,
        declination: star.declination,
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
        time: DateTime.now(),
      );

      starPositions.add(
          _skyToScreen(coords['azimuth']!, coords['altitude']!, size, fov));
    }

    // Draw lines between connected stars
    for (final (start, end) in constellation.connections) {
      final pos1 = starPositions[start];
      final pos2 = starPositions[end];
      if (pos1 != null && pos2 != null) {
        canvas.drawLine(pos1, pos2, paint);
      }
    }
  }

  void _drawPlanet(Canvas canvas, Size size, Planet planet, double fov) {
    if (currentPosition == null) return;

    final coords = CelestialCalculator.equatorialToHorizontal(
      rightAscension: planet.rightAscension,
      declination: planet.declination,
      latitude: currentPosition!.latitude,
      longitude: currentPosition!.longitude,
      time: DateTime.now(),
    );

    final screenPos =
        _skyToScreen(coords['azimuth']!, coords['altitude']!, size, fov);
    if (screenPos != null) {
      // Draw planet symbol
      final textPainter = TextPainter(
        text: TextSpan(
            text: planet.symbol,
            style: const TextStyle(color: Colors.orange, fontSize: 32)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          screenPos - Offset(textPainter.width / 2, textPainter.height / 2));

      // Draw name
      final namePainter = TextPainter(
        text: TextSpan(
            text: planet.name,
            style: const TextStyle(color: Colors.white, fontSize: 10)),
        textDirection: TextDirection.ltr,
      );
      namePainter.layout();
      namePainter.paint(canvas, screenPos + const Offset(-15, 20));
    }
  }

  void _drawStar(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 3, paint);
  }

  Offset? _skyToScreen(double azimuth, double altitude, Size size, double fov) {
    // Calculate angular distance from device center
    final azDiff = ((azimuth - deviceAzimuth + 180) % 360) - 180;
    final altDiff = altitude - devicePitch;

    // Check if object is in view
    if (azDiff.abs() > fov / 2 || altDiff.abs() > fov / 2) {
      return null;
    }

    // Convert to screen coordinates
    final x = size.width / 2 + (azDiff / (fov / 2)) * (size.width / 2);
    final y = size.height / 2 - (altDiff / (fov / 2)) * (size.height / 2);

    return Offset(x, y);
  }
}
