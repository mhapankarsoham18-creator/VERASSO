import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import '../engine/sky_engine.dart';
import '../interaction/tap_detector.dart';
import '../models/celestial_object.dart';
import '../rendering/crt_overlay.dart';
import '../rendering/pixel_palette.dart';
import '../rendering/sky_painter.dart';
import '../widgets/object_info_panel.dart';
import '../widgets/sky_chat_bubble.dart';
import '../data/discovery_log.dart';
import '../widgets/discovery_hud.dart';

/// Main Astro Hub screen — the pixel sky RPG.
class AstroHubScreen extends StatefulWidget {
  const AstroHubScreen({super.key});

  @override
  State<AstroHubScreen> createState() => _AstroHubScreenState();
}

class _AstroHubScreenState extends State<AstroHubScreen>
    with SingleTickerProviderStateMixin {
  final SkyEngine _engine = SkyEngine();
  final DiscoveryLog _discoveryLog = DiscoveryLog();

  CelestialObject? _selectedObject;
  bool _showInfoPanel = false;
  bool _isLoading = true;
  String? _errorMsg;

  // Animation
  late Ticker _ticker;
  int _flickerSeed = 0;
  int _crtFrame = 0;

  // AR Camera
  CameraController? _cameraController;
  bool _isArMode = false;
  bool _hasCameraPermission = false;

  // Sensor subscriptions
  StreamSubscription? _compassSub;
  StreamSubscription? _accelSub;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _initSensors();
    _loadEngine();
  }

  void _onTick(Duration elapsed) {
    // Update positions at ~30fps
    if (elapsed.inMilliseconds % 33 < 17) {
      _engine.updatePositions();
    }

    // Flicker at ~8fps (125ms steps) for CRT feel
    final newFlicker = elapsed.inMilliseconds ~/ 125;
    final newCrtFrame = elapsed.inMilliseconds ~/ 80;

    if (newFlicker != _flickerSeed || newCrtFrame != _crtFrame) {
      setState(() {
        _flickerSeed = newFlicker;
        _crtFrame = newCrtFrame;
      });
    }
  }

  Future<void> _loadEngine() async {
    try {
      await _engine.loadCatalog();
      await _discoveryLog.init();
      
      // Get location
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
        _engine.latitude = pos.latitude;
        _engine.longitude = pos.longitude;
      } catch (_) {
        // Default to a reasonable latitude if GPS fails
        _engine.latitude = 20.0; // India approximate
        _engine.longitude = 78.0;
      }

      // Initialize camera for AR mode later
      try {
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          _cameraController = CameraController(
            cameras.first,
            ResolutionPreset.max,
            enableAudio: false,
          );
        }
      } catch (e) {
        debugPrint('Camera error: $e');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString();
      });
    }
  }

  void _initSensors() {
    // Compass heading
    _compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        _engine.compassHeading = event.heading!;
      }
    });

    // Accelerometer for device pitch
    _accelSub = accelerometerEventStream().listen((event) {
      // Rough pitch estimate from accelerometer
      // When phone is pointed at horizon: y ≈ 9.8, z ≈ 0
      // When phone is pointed at zenith: y ≈ 0, z ≈ 9.8
      final pitch = event.z.clamp(-9.8, 9.8) / 9.8 * 90;
      _engine.devicePitch = pitch.clamp(0, 90);
    });
  }

  void _onTapDown(TapDownDetails details) {
    final tapped = TapDetector.findNearestObject(
      details.localPosition,
      _engine.visibleObjects,
    );

    setState(() {
      if (tapped != null && tapped.id == _selectedObject?.id) {
        // Tapping same object again = deselect
        _selectedObject = null;
      } else {
        _selectedObject = tapped;
        if (tapped != null) {
          _discoveryLog.discover(tapped.name);
        }
      }
      _showInfoPanel = false;
    });
  }

  void _openInfoPanel() {
    setState(() => _showInfoPanel = true);
  }

  void _closeInfoPanel() {
    setState(() => _showInfoPanel = false);
  }

  Future<void> _toggleArMode() async {
    if (_isArMode) {
      setState(() => _isArMode = false);
      // Wait a moment then stop camera to save battery
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isArMode && mounted) {
           // We keep it initialized but paused?
           // CameraController doesn't have pause, so we either dispose or just keep drawing.
           // Leaving it initialized is faster to toggle back.
        }
      });
    } else {
      if (_cameraController != null) {
        if (!_cameraController!.value.isInitialized) {
          await _cameraController!.initialize();
        }
        setState(() => _isArMode = true);
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _compassSub?.cancel();
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _engine.screenWidth = size.width;
    _engine.screenHeight = size.height;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: PixelPalette.skyBlack,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LOADING STAR MAP...',
                style: GoogleFonts.pressStart2p(
                  textStyle: const TextStyle(
                    color: PixelPalette.hudText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  )
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  backgroundColor: PixelPalette.hudDim,
                  color: PixelPalette.hudText,
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMsg != null) {
      return Scaffold(
        backgroundColor: PixelPalette.skyBlack,
        body: Center(
          child: Text(
            'ERROR: $_errorMsg',
            style: const TextStyle(color: PixelPalette.hudText),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: PixelPalette.skyBlack,
      body: Stack(
        children: [
          // AR Camera Background Layer
          if (_isArMode && _cameraController != null && _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? size.width,
                  height: _cameraController!.value.previewSize?.width ?? size.height,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),

          // Sky renderer (full screen) - Transparent if AR mode is ON
          GestureDetector(
            onTapDown: _onTapDown,
            child: CustomPaint(
              painter: SkyPainter(
                engine: _engine,
                selectedObject: _selectedObject,
                flickerSeed: _flickerSeed,
                isTransparentBg: _isArMode,
              ),
              size: Size.infinite,
            ),
          ),

          // CRT scan-line overlay
          IgnorePointer(
            child: CustomPaint(
              painter: CrtOverlay(frame: _crtFrame, isTransparentBg: _isArMode),
              size: Size.infinite,
            ),
          ),

          // Chat bubble (if an object is selected and panel not open)
          if (_selectedObject != null && !_showInfoPanel)
            SkyChatBubble(
              object: _selectedObject!,
              screenWidth: size.width,
              onTap: () => setState(() => _selectedObject = null),
              onAskMore: _openInfoPanel,
            ),

          // HUD overlay
          _buildHUD(size),

          // Discovery HUD
          Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            right: 12,
            child: DiscoveryHud(
              discoveredCount: _discoveryLog.discoveredCount,
              totalCount: _engine.catalog
                  .where((o) => o.type == 'star')
                  .length,
            ),
          ),

          // Info panel (bottom sheet)
          if (_showInfoPanel && _selectedObject != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ObjectInfoPanel(
                object: _selectedObject!,
                onClose: _closeInfoPanel,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHUD(Size size) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compass heading
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PixelPalette.skyBlack.withOpacity(0.7),
              border: Border.all(color: PixelPalette.hudDim, width: 1),
            ),
            child: Text(
              '${_engine.compassHeading.toStringAsFixed(0)}° ${_compassLabel(_engine.compassHeading)}',
              style: GoogleFonts.pressStart2p(
                textStyle: const TextStyle(
                  color: PixelPalette.hudText,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                )
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Visible objects count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: PixelPalette.skyBlack.withOpacity(0.7),
              border: Border.all(color: PixelPalette.hudDim, width: 1),
            ),
            child: Text(
              '${_engine.visibleObjects.length} OBJECTS IN VIEW',
              style: GoogleFonts.pressStart2p(
                textStyle: const TextStyle(
                  color: PixelPalette.hudDim,
                  fontSize: 6,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                )
              ),
            ),
          ),
          const SizedBox(height: 12),
          // AR Mode Toggle
          GestureDetector(
            onTap: _toggleArMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isArMode ? PixelPalette.hudText.withOpacity(0.2) : PixelPalette.skyBlack.withOpacity(0.7),
                border: Border.all(color: _isArMode ? PixelPalette.hudText : PixelPalette.hudDim, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isArMode ? Icons.camera_alt : Icons.camera_alt_outlined, 
                    size: 14, 
                    color: _isArMode ? PixelPalette.hudText : PixelPalette.hudDim
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isArMode ? 'AR ON' : 'AR OFF',
                    style: GoogleFonts.pressStart2p(
                      textStyle: TextStyle(
                        color: _isArMode ? PixelPalette.hudText : PixelPalette.hudDim,
                        fontSize: 8,
                      )
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _compassLabel(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading < 67.5) return 'NE';
    if (heading < 112.5) return 'E';
    if (heading < 157.5) return 'SE';
    if (heading < 202.5) return 'S';
    if (heading < 247.5) return 'SW';
    if (heading < 292.5) return 'W';
    return 'NW';
  }
}
