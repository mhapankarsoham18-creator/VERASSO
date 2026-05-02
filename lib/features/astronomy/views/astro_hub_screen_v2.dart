import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/discovery_log.dart';
import '../engine/sky_engine.dart';
import '../engine/sky_visibility.dart';
import '../interaction/tap_detector.dart';
import '../models/celestial_object.dart';
import '../rendering/crt_overlay.dart';
import '../rendering/pixel_palette.dart';
import '../rendering/sky_painter.dart';
import '../widgets/discovery_hud.dart';
import '../widgets/object_info_panel.dart';
import '../widgets/sky_visibility_overlay.dart';
import '../../../core/theme/colors.dart';
import 'package:verasso/core/utils/logger.dart';

/// Main Astro Hub screen with offline sky visibility gating.
class AstroHubScreen extends StatefulWidget {
  const AstroHubScreen({super.key});

  @override
  State<AstroHubScreen> createState() => _AstroHubScreenState();
}

class _AstroHubScreenState extends State<AstroHubScreen>
    with SingleTickerProviderStateMixin {
  final SkyEngine _engine = SkyEngine();
  final DiscoveryLog _discoveryLog = DiscoveryLog();
  final SkyVisibilityEstimator _visibilityEstimator = SkyVisibilityEstimator();

  CelestialObject? _selectedObject;
  bool _isLoading = true;
  String? _errorMsg;
  SkyVisibilityReport _visibilityReport = SkyVisibilityReport(
    state: SkyViewState.calibrating,
    title: 'CALIBRATING SKY SCAN',
    detail: 'Hold steady for a moment while Astro locks your viewing angle.',
    confidence: 0.1,
    shouldRenderSky: false,
    canDiscover: false,
  );

  late Ticker _ticker;
  int _flickerSeed = 0;
  int _crtFrame = 0;

  CameraController? _cameraController;
  bool _isArMode = false;
  bool _hasCameraPermission = false;
  bool _hasCameraAnalysis = false;
  bool _isProcessingFrame = false;
  DateTime _lastCameraSampleAt = DateTime.fromMillisecondsSinceEpoch(0);

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _hasCompassData = false;
  bool _hasMotionData = false;
  bool _hasLocationLock = false;

  double _smoothedHeading = 0.0;
  double _smoothedPitch = 45.0;
  bool _isFirstHeading = true;
  bool _isFirstPitch = true;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _initSensors();
    _loadEngine();
  }

  void _onTick(Duration elapsed) {
    if (elapsed.inMilliseconds % 33 < 17) {
      _engine.updatePositions();
    }

    final int newFlicker = elapsed.inMilliseconds ~/ 125;
    final int newCrtFrame = elapsed.inMilliseconds ~/ 80;

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

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      _hasLocationLock = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      try {
        final Position pos = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
        _engine.latitude = pos.latitude;
        _engine.longitude = pos.longitude;
        _hasLocationLock = true;
      } catch (_) {
        _engine.latitude = 20.0;
        _engine.longitude = 78.0;
      }

      await _prepareCameraAnalysis();

      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      _refreshVisibilityReport();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString();
      });
    }
  }

  void _initSensors() {
    _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
      final double? heading = event.heading;
      if (heading != null) {
        if (_isFirstHeading) {
          _smoothedHeading = heading;
          _isFirstHeading = false;
        } else {
          double diff = heading - _smoothedHeading;
          if (diff > 180) diff -= 360;
          if (diff < -180) diff += 360;
          _smoothedHeading += diff * 0.15; // Smooth factor
          if (_smoothedHeading < 0) _smoothedHeading += 360;
          if (_smoothedHeading >= 360) _smoothedHeading -= 360;
        }

        _engine.compassHeading = _smoothedHeading;
        _hasCompassData = true;
        _visibilityEstimator.updateHeading(_smoothedHeading);
        _refreshVisibilityReport();
      }
    });

    _accelSub = accelerometerEventStream().listen((AccelerometerEvent event) {
      // Standard pitch calculation for portrait device
      // Positive Z = screen facing up. Positive Y = top of device pointing up.
      final double pitch = -math.atan2(event.z, event.y) * 180 / math.pi;
      final double clampedPitch = pitch.clamp(-90.0, 90.0);

      if (_isFirstPitch) {
        _smoothedPitch = clampedPitch;
        _isFirstPitch = false;
      } else {
        _smoothedPitch += (clampedPitch - _smoothedPitch) * 0.15;
      }

      _engine.devicePitch = _smoothedPitch;
      _hasMotionData = true;
      _visibilityEstimator.updatePitch(_smoothedPitch);
      _refreshVisibilityReport();
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (!_visibilityReport.canDiscover) {
      return;
    }

    final CelestialObject? tapped = TapDetector.findNearestObject(
      details.localPosition,
      _engine.visibleObjects,
    );

    setState(() {
      if (tapped != null && tapped.id == _selectedObject?.id) {
        _selectedObject = null;
      } else {
        _selectedObject = tapped;
        if (tapped != null) {
          _discoveryLog.discover(tapped.name);
        }
      }
    });
  }

  void _closeInfoPanel() {
    setState(() => _selectedObject = null);
  }

  Future<void> _toggleArMode() async {
    if (_cameraController == null) {
      return;
    }

    if (_isArMode) {
      setState(() => _isArMode = false);
      return;
    }

    if (!_cameraController!.value.isInitialized) {
      await _cameraController!.initialize();
      await _startCameraAnalysis();
    }

    if (!mounted) {
      return;
    }
    setState(() => _isArMode = true);
  }

  Future<void> _prepareCameraAnalysis() async {
    try {
      final PermissionStatus cameraPermission = await Permission.camera.request();
      _hasCameraPermission = cameraPermission.isGranted;
      if (!_hasCameraPermission) {
        _refreshVisibilityReport();
        return;
      }

      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        _refreshVisibilityReport();
        return;
      }

      final CameraDescription backCamera = cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();
      await _startCameraAnalysis();
    } catch (e) {
      appLogger.d('Camera error: $e');
      _hasCameraAnalysis = false;
    } finally {
      _refreshVisibilityReport();
    }
  }

  Future<void> _startCameraAnalysis() async {
    final CameraController? controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }

    try {
      await controller.startImageStream((CameraImage image) {
        _handleCameraFrame(image);
      });
      _hasCameraAnalysis = true;
    } catch (e) {
      appLogger.d('Camera analysis error: $e');
      _hasCameraAnalysis = false;
    }
  }

  void _handleCameraFrame(CameraImage image) {
    final DateTime now = DateTime.now();
    if (_isProcessingFrame ||
        now.difference(_lastCameraSampleAt) < Duration(milliseconds: 900)) {
      return;
    }

    _isProcessingFrame = true;
    _lastCameraSampleAt = now;

    try {
      final SkyCameraMetrics metrics = _sampleCameraMetrics(image);
      _visibilityEstimator.updateCameraMetrics(metrics);
      _refreshVisibilityReport();
    } catch (e) {
      appLogger.d('Camera frame parse error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  SkyCameraMetrics _sampleCameraMetrics(CameraImage image) {
    if (image.planes.isEmpty) {
      return SkyCameraMetrics(
        brightness: 0,
        contrast: 1,
        roughness: 1,
      );
    }

    if (image.format.group == ImageFormatGroup.bgra8888) {
      return _sampleBgraMetrics(image);
    }

    return _sampleLumaMetrics(image);
  }

  SkyCameraMetrics _sampleLumaMetrics(CameraImage image) {
    if (image.planes.isEmpty) {
      return SkyCameraMetrics(brightness: 0, contrast: 1, roughness: 1);
    }

    final Plane yPlane = image.planes[0];
    final bool hasColor = image.planes.length >= 3;
    final Plane? uPlane = hasColor ? image.planes[1] : null;
    final Plane? vPlane = hasColor ? image.planes[2] : null;

    final Uint8List yBytes = yPlane.bytes;
    final int width = image.width;
    final int height = image.height;
    final int yBytesPerRow = yPlane.bytesPerRow;
    
    final int stepX = math.max(6, width ~/ 36);
    final int stepY = math.max(6, height ~/ 36);

    double sum = 0;
    double sumSquares = 0;
    double roughness = 0;
    int count = 0;
    int roughCount = 0;

    double blueScoreSum = 0;
    int colorCount = 0;

    for (int y = 0; y < height; y += stepY) {
      int? previous;
      for (int x = 0; x < width; x += stepX) {
        final int luminance = yBytes[(y * yBytesPerRow) + x];
        final double value = luminance.toDouble();
        sum += value;
        sumSquares += value * value;
        count++;

        if (previous != null) {
          roughness += (luminance - previous).abs();
          roughCount++;
        }
        previous = luminance;

        // Sample color planes if available (they are half resolution)
        if (hasColor && uPlane != null && vPlane != null) {
          final int uvX = x ~/ 2;
          final int uvY = y ~/ 2;
          
          final int uIndex = (uvY * uPlane.bytesPerRow) + (uvX * (uPlane.bytesPerPixel ?? 1));
          final int vIndex = (uvY * vPlane.bytesPerRow) + (uvX * (vPlane.bytesPerPixel ?? 1));
          
          if (uIndex < uPlane.bytes.length && vIndex < vPlane.bytes.length) {
            final int uVal = uPlane.bytes[uIndex]; // 0-255, 128 is neutral
            final int vVal = vPlane.bytes[vIndex];
            
            // Very rough proxy for "blueness":
            // Sky is typically high U, low to moderate V.
            // Convert to a ratio roughly mapping to [0,1].
            double score = 0.3; // base grey score
            if (uVal > 130 && vVal < 125) {
                score = 0.4 + ((uVal - 130) / 125.0 * 0.6).clamp(0.0, 0.6);
            }
            blueScoreSum += score;
            colorCount++;
          }
        }
      }
    }

    final SkyCameraMetrics base = _buildMetrics(
      sum: sum,
      sumSquares: sumSquares,
      roughness: roughness,
      count: count,
      roughCount: roughCount,
    );

    return SkyCameraMetrics(
      brightness: base.brightness,
      contrast: base.contrast,
      roughness: base.roughness,
      blueRatio: colorCount > 0 ? (blueScoreSum / colorCount) : null,
    );
  }

  SkyCameraMetrics _sampleBgraMetrics(CameraImage image) {
    final Plane plane = image.planes.first;
    final Uint8List bytes = plane.bytes;
    final int width = image.width;
    final int height = image.height;
    final int bytesPerRow = plane.bytesPerRow;
    final int pixelStride = plane.bytesPerPixel ?? 4;
    final int stepX = math.max(6, width ~/ 36);
    final int stepY = math.max(6, height ~/ 36);

    double sum = 0;
    double sumSquares = 0;
    double roughness = 0;
    double blueRatioSum = 0;
    int count = 0;
    int roughCount = 0;

    for (int y = 0; y < height; y += stepY) {
      double? previous;
      for (int x = 0; x < width; x += stepX) {
        final int index = (y * bytesPerRow) + (x * pixelStride);
        if (index + 2 >= bytes.length) {
          continue;
        }

        final double blue = bytes[index].toDouble();
        final double green = bytes[index + 1].toDouble();
        final double red = bytes[index + 2].toDouble();
        final double luminance = (0.0722 * blue) + (0.7152 * green) + (0.2126 * red);

        sum += luminance;
        sumSquares += luminance * luminance;
        blueRatioSum += blue / math.max(1.0, red + green + blue);
        count++;

        if (previous != null) {
          roughness += (luminance - previous).abs();
          roughCount++;
        }
        previous = luminance;
      }
    }

    final SkyCameraMetrics base = _buildMetrics(
      sum: sum,
      sumSquares: sumSquares,
      roughness: roughness,
      count: count,
      roughCount: roughCount,
    );

    return SkyCameraMetrics(
      brightness: base.brightness,
      contrast: base.contrast,
      roughness: base.roughness,
      blueRatio: count == 0 ? null : blueRatioSum / count,
    );
  }

  SkyCameraMetrics _buildMetrics({
    required double sum,
    required double sumSquares,
    required double roughness,
    required int count,
    required int roughCount,
  }) {
    if (count == 0) {
      return SkyCameraMetrics(
        brightness: 0,
        contrast: 1,
        roughness: 1,
      );
    }

    final double mean = sum / count;
    final double variance = math.max(0, (sumSquares / count) - (mean * mean));
    final double normalizedBrightness = mean / 255;
    final double normalizedContrast = math.sqrt(variance) / 255;
    final double normalizedRoughness =
        roughCount == 0 ? 0 : (roughness / roughCount) / 255;

    return SkyCameraMetrics(
      brightness: normalizedBrightness.clamp(0.0, 1.0),
      contrast: normalizedContrast.clamp(0.0, 1.0),
      roughness: normalizedRoughness.clamp(0.0, 1.0),
    );
  }

  void _refreshVisibilityReport() {
    final SkyVisibilityReport nextReport = _visibilityEstimator.buildReport(
      hasMotionData: _hasMotionData,
      hasCompassData: _hasCompassData,
      hasCameraPermission: _hasCameraPermission,
      hasCameraAnalysis: _hasCameraAnalysis,
      hasLocationLock: _hasLocationLock,
    );

    if (!mounted) {
      _visibilityReport = nextReport;
      return;
    }

    final bool changed = nextReport.state != _visibilityReport.state ||
        nextReport.title != _visibilityReport.title ||
        nextReport.detail != _visibilityReport.detail ||
        nextReport.shouldRenderSky != _visibilityReport.shouldRenderSky ||
        nextReport.canDiscover != _visibilityReport.canDiscover ||
        nextReport.isEstimated != _visibilityReport.isEstimated;

    if (!changed) {
      _visibilityReport = nextReport;
      return;
    }

    setState(() {
      _visibilityReport = nextReport;
      if (!_visibilityReport.canDiscover) {
        _selectedObject = null;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _compassSub?.cancel();
    _accelSub?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    _engine.screenWidth = size.width;
    // Screen height is constrained to the top half now
    final double screenH = size.height * 0.55;
    _engine.screenHeight = screenH;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: PixelPalette.skyBlack,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'LOADING STAR MAP...',
                style: GoogleFonts.pressStart2p(
                  textStyle: TextStyle(
                    color: PixelPalette.hudText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              SizedBox(height: 16),
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
            style: TextStyle(color: PixelPalette.hudText),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFDCDCDC), // Classic Retro Handheld off-white body
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // â”€â”€ TOP HALF: Retro Screen Bezel â”€â”€
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                height: screenH,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF6B6B6B), // Bezel color
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(48), // Angled classic corner
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.neutralBg.withValues(alpha: 0.15),
                      offset: Offset(2, 4),
                      blurRadius: 8,
                    )
                  ]
                ),
                padding: EdgeInsets.all(16), // Bezel thickness
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: <Widget>[
                      // Black backdrop
                      Container(color: PixelPalette.skyBlack),

                      // AR Camera Feed
                      if (_isArMode &&
                          _cameraController != null &&
                          _cameraController!.value.isInitialized)
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraController!.value.previewSize?.height ?? size.width,
                              height: _cameraController!.value.previewSize?.width ?? screenH,
                              child: CameraPreview(_cameraController!),
                            ),
                          ),
                        ),
                      
                      // Sky Star Overlay
                      GestureDetector(
                        onTapDown: _onTapDown,
                        child: CustomPaint(
                          painter: SkyPainter(
                            engine: _engine,
                            selectedObject: _visibilityReport.shouldRenderSky ? _selectedObject : null,
                            flickerSeed: _flickerSeed,
                            isTransparentBg: _isArMode && _visibilityReport.shouldRenderSky,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                      
                      // CRT Filter lines
                      IgnorePointer(
                        child: Semantics(
                          label: 'Retro CRT monitor scanline effect',
                          child: CustomPaint(
                            painter: CrtOverlay(
                              frame: _crtFrame,
                              isTransparentBg: _isArMode && _visibilityReport.shouldRenderSky,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                      
                      // Hardware Crosshair
                      IgnorePointer(
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CustomPaint(painter: _CrosshairPainter()),
                          ),
                        ),
                      ),
                      
                      SkyVisibilityOverlay(report: _visibilityReport),
                      _buildHUD(),
                      
                      // Top-right corner HUD
                      Positioned(
                        top: 8,
                        right: 8,
                        child: DiscoveryHud(
                          discoveredCount: _discoveryLog.discoveredCount,
                          totalCount: _engine.catalog.where((CelestialObject o) => o.type == 'star').length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // â”€â”€ BOTTOM HALF: Controls & LCD â”€â”€
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Physical buttons decoration row
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildDPad(),
                          Spacer(),
                          _buildSlantedButtons(),
                        ],
                      ),
                    ),
                    
                    // The LCD Info Screen
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: _visibilityReport.shouldRenderSky && _selectedObject != null
                            ? ObjectInfoPanel(
                                object: _selectedObject!,
                                onClose: _closeInfoPanel,
                              )
                            : Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Color(0xFF8BAC0F), // Classic LCD Green
                                  border: Border.all(
                                    color: Color(0xFF0F380F), 
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFE0E0E0),
                                      blurRadius: 10,
                                    )
                                  ]
                                ),
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: Text(
                                    _visibilityReport.canDiscover 
                                        ? 'USE CROSSHAIR OR TAP A STAR\n\nTO IDENTIFY'
                                        : 'AWAITING SENSOR LOCK...\nPOINT AT OPEN SKY',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.pressStart2p(
                                      textStyle: TextStyle(
                                        color: Color(0xFF0F380F),
                                        fontSize: 10,
                                        height: 1.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
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

  Widget _buildDPad() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Color(0xFF1B1B1B),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: context.colors.neutralBg.withValues(alpha: 0.26),
            offset: Offset(0, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(0xFF333333),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildSlantedButtons() {
    return Transform.rotate(
      angle: -0.4,
      child: Row(
        children: [
          _retroButton('B'),
          SizedBox(width: 16),
          _retroButton('A'),
        ],
      ),
    );
  }

  Widget _retroButton(String label) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color(0xFF900020), // Magenta/Maroon red
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.colors.neutralBg.withValues(alpha: 0.26),
                offset: Offset(1, 2),
                blurRadius: 2,
              )
            ],
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.pressStart2p(
            textStyle: TextStyle(
              color: Color(0xFF6B6B6B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildHUD() {
    final int visibleCount =
        _visibilityReport.shouldRenderSky ? _engine.visibleObjects.length : 0;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _hudTile(
            '${_engine.compassHeading.toStringAsFixed(0)} deg ${_compassLabel(_engine.compassHeading)}',
            PixelPalette.hudText,
            8,
          ),
          SizedBox(height: 4),
          _hudTile(
            '$visibleCount OBJECTS IN VIEW',
            PixelPalette.hudDim,
            6,
          ),
          SizedBox(height: 4),
          _hudTile(
            _visibilityReport.state == SkyViewState.skyVisible
                ? (_visibilityReport.isEstimated ? 'ESTIMATED LOCK' : 'OPEN SKY VERIFIED')
                : _visibilityReport.title,
            PixelPalette.hudDim,
            6,
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: _toggleArMode,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isArMode
                    ? PixelPalette.hudText.withValues(alpha: 0.2)
                    : PixelPalette.skyBlack.withValues(alpha: 0.7),
                border: Border.all(
                  color: _isArMode ? PixelPalette.hudText : PixelPalette.hudDim,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _isArMode ? Icons.camera_alt : Icons.camera_alt_outlined,
                    size: 14,
                    color: _isArMode ? PixelPalette.hudText : PixelPalette.hudDim,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _isArMode ? 'AR ON' : 'AR OFF',
                    style: GoogleFonts.pressStart2p(
                      textStyle: TextStyle(
                        color: _isArMode ? PixelPalette.hudText : PixelPalette.hudDim,
                        fontSize: 8,
                      ),
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

  Widget _hudTile(String label, Color color, double fontSize) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PixelPalette.skyBlack.withValues(alpha: 0.7),
        border: Border.all(color: PixelPalette.hudDim, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.pressStart2p(
          textStyle: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  String _compassLabel(double heading) {
    if (heading >= 337.5 || heading < 22.5) {
      return 'N';
    }
    if (heading < 67.5) {
      return 'NE';
    }
    if (heading < 112.5) {
      return 'E';
    }
    if (heading < 157.5) {
      return 'SE';
    }
    if (heading < 202.5) {
      return 'S';
    }
    if (heading < 247.5) {
      return 'SW';
    }
    if (heading < 292.5) {
      return 'W';
    }
    return 'NW';
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final cx = size.width / 2;
    final cy = size.height / 2;
    
    canvas.drawLine(Offset(0, cy), Offset(10, cy), p);
    canvas.drawLine(Offset(size.width - 10, cy), Offset(size.width, cy), p);
    canvas.drawLine(Offset(cx, 0), Offset(cx, 10), p);
    canvas.drawLine(Offset(cx, size.height - 10), Offset(cx, size.height), p);
    
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: 4, height: 4),
      Paint()..color = Colors.greenAccent.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => false;
}

