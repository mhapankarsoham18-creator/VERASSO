# Sky Map — Verasso Integration Guide

Drop this entire folder into `lib/features/sky_map/`.

```
lib/features/sky_map/
├── models/        sky_object.dart
├── engine/        sensor_service.dart  •  tap_detector.dart
├── painters/      sky_painter.dart
├── widgets/       sky_chat_bubble.dart
├── theme/         pixel_theme.dart
├── data/          sky_database.dart
└── screens/       sky_screen.dart
```

Add to `pubspec.yaml`:
```yaml
dependencies:
  sensors_plus: ^4.0.2
  flutter_compass: ^0.8.0
  google_fonts: ^6.2.1
  permission_handler: ^11.3.0
```

---

## models/sky_object.dart

```dart
import 'package:flutter/material.dart';

enum SkyObjectType { star, planet, galaxy, nebula }

class SkyObject {
  final String id;
  final String name;
  final SkyObjectType type;
  final double magnitude;   // lower = brighter
  final String distance;
  final String funFact;

  // Horizontal coords — updated each frame by astronomy logic
  double azimuth  = 0; // 0-360, degrees from North
  double altitude = 0; // -90 to +90, degrees above horizon

  // Computed each paint frame by SkyPainter
  Offset screenPos = Offset.zero;
  bool   isVisible = false;

  SkyObject({
    required this.id,
    required this.name,
    required this.type,
    required this.magnitude,
    required this.distance,
    required this.funFact,
  });

  // Pixel block size driven by magnitude
  int get pixelSize {
    if (magnitude < 1.0) return 7;
    if (magnitude < 2.0) return 5;
    if (magnitude < 3.5) return 3;
    return 2;
  }

  Color get pixelColor {
    switch (type) {
      case SkyObjectType.planet:
        return const Color(0xFF44FF88);
      case SkyObjectType.galaxy:
        return const Color(0xFFAA88FF);
      case SkyObjectType.nebula:
        return const Color(0xFF88CCFF);
      case SkyObjectType.star:
        if (magnitude < 1.0) return const Color(0xFFF0F0FF);
        if (magnitude < 2.5) return const Color(0xFFFFE566);
        return const Color(0xFFFF9944);
    }
  }

  String get typeLabel {
    switch (type) {
      case SkyObjectType.planet:       return 'PLANET';
      case SkyObjectType.galaxy:       return 'GALAXY';
      case SkyObjectType.nebula:       return 'NEBULA';
      case SkyObjectType.star:         return 'STAR';
    }
  }
}
```

---

## engine/sensor_service.dart

```dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DeviceOrientation {
  final double azimuth;   // 0-360 degrees, compass heading
  final double altitude;  // -90 to +90 degrees, tilt above horizon
  const DeviceOrientation(this.azimuth, this.altitude);
}

class SensorService {
  final _controller = StreamController<DeviceOrientation>.broadcast();
  Stream<DeviceOrientation> get stream => _controller.stream;

  StreamSubscription? _compassSub;
  StreamSubscription? _accelSub;

  double _azimuth  = 0;
  double _altitude = 0;

  void start() {
    // Compass → azimuth
    _compassSub = FlutterCompass.events?.listen((event) {
      _azimuth = event.heading ?? 0;
      _emit();
    });

    // Accelerometer → altitude (pitch)
    // When phone lies flat face-up:  az ≈ 0, ay ≈ 0, az ≈ +9.8
    // When phone held upright:       ax ≈ 0, ay ≈ -9.8, az ≈ 0
    _accelSub = accelerometerEventStream().listen((event) {
      // pitch = angle above horizontal plane
      final pitch = math.atan2(
        -event.y,
        math.sqrt(event.x * event.x + event.z * event.z),
      ) * 180 / math.pi;

      _altitude = pitch.clamp(-90.0, 90.0);
      _emit();
    });
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(DeviceOrientation(_azimuth, _altitude));
    }
  }

  void dispose() {
    _compassSub?.cancel();
    _accelSub?.cancel();
    _controller.close();
  }
}
```

---

## engine/tap_detector.dart

```dart
import 'dart:ui';
import '../models/sky_object.dart';

class SkyTapDetector {
  // 44px = minimum comfortable tap target on mobile
  static const double kThreshold = 44.0;

  /// Returns nearest visible object within threshold, or null.
  static SkyObject? nearest(Offset tap, List<SkyObject> objects) {
    SkyObject? best;
    double bestDist = kThreshold;

    for (final obj in objects) {
      if (!obj.isVisible) continue;
      final d = (tap - obj.screenPos).distance;
      if (d < bestDist) {
        bestDist = d;
        best = obj;
      }
    }
    return best;
  }
}
```

---

## painters/sky_painter.dart

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sky_object.dart';
import '../theme/pixel_theme.dart';

class SkyPainter extends CustomPainter {
  final List<SkyObject> objects;
  final double deviceAzimuth;
  final double deviceAltitude;
  final double fovH; // horizontal FOV degrees
  final int    frame; // drives flicker animation

  SkyPainter({
    required this.objects,
    required this.deviceAzimuth,
    required this.deviceAltitude,
    this.fovH = 90.0,
    this.frame = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBg(canvas, size);
    _drawGrid(canvas, size);

    final fovV = fovH * size.height / size.width;

    for (final obj in objects) {
      final pos = _project(obj, size, fovH, fovV);
      if (pos == null) { obj.isVisible = false; continue; }
      obj.screenPos = pos;
      obj.isVisible = true;
      _drawObject(canvas, obj, pos);
    }

    _drawScanlines(canvas, size);
    _drawHUD(canvas, size);
  }

  // ── Projection ────────────────────────────────────────────────────────

  Offset? _project(SkyObject obj, Size size, double fovH, double fovV) {
    double dAz  = _wrap(obj.azimuth  - deviceAzimuth);
    double dAlt = obj.altitude - deviceAltitude;

    if (dAz.abs()  > fovH / 2) return null;
    if (dAlt.abs() > fovV / 2) return null;

    final x = (dAz  / (fovH / 2) + 1) * 0.5 * size.width;
    final y = (-dAlt / (fovV / 2) + 1) * 0.5 * size.height;
    return Offset(x, y);
  }

  double _wrap(double deg) {
    while (deg >  180) deg -= 360;
    while (deg < -180) deg += 360;
    return deg;
  }

  // ── Drawing ───────────────────────────────────────────────────────────

  void _drawBg(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = PixelTheme.bgDeep);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = PixelTheme.gridLine
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width;  x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  void _drawObject(Canvas canvas, SkyObject obj, Offset pos) {
    final s = obj.pixelSize.toDouble();

    // Snap to 2px grid — the retro effect
    final snapped = Offset(
      (pos.dx / 2).roundToDouble() * 2,
      (pos.dy / 2).roundToDouble() * 2,
    );

    // Outer glow for bright objects
    if (obj.magnitude < 2.5) {
      canvas.drawRect(
        Rect.fromCenter(center: snapped, width: s + 6, height: s + 6),
        Paint()..color = obj.pixelColor.withOpacity(0.15),
      );
    }

    // Core pixel block
    canvas.drawRect(
      Rect.fromCenter(center: snapped, width: s, height: s),
      Paint()..color = obj.pixelColor,
    );

    // Planet cross marker
    if (obj.type == SkyObjectType.planet) {
      final cp = Paint()
        ..color = obj.pixelColor.withOpacity(0.5)
        ..strokeWidth = 1;
      canvas.drawLine(snapped.translate(-10, 0), snapped.translate(10, 0), cp);
      canvas.drawLine(snapped.translate(0, -10), snapped.translate(0, 10), cp);
    }

    // CRT flicker — every ~20 frames dim a star slightly
    if (obj.type == SkyObjectType.star && (obj.id.hashCode + frame) % 23 == 0) {
      canvas.drawRect(
        Rect.fromCenter(center: snapped, width: s, height: s),
        Paint()..color = PixelTheme.bgDeep.withOpacity(0.4),
      );
    }
  }

  void _drawScanlines(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withOpacity(0.05);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), p);
    }
  }

  void _drawHUD(Canvas canvas, Size size) {
    // Crosshair in center
    final p = Paint()
      ..color = PixelTheme.uiGreen.withOpacity(0.3)
      ..strokeWidth = 1;
    final cx = size.width  / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx + 12, cy), p);
    canvas.drawLine(Offset(cx, cy - 12), Offset(cx, cy + 12), p);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: 4, height: 4),
      Paint()..color = PixelTheme.uiGreen.withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(SkyPainter old) =>
      old.deviceAzimuth != deviceAzimuth ||
      old.deviceAltitude != deviceAltitude ||
      old.frame != frame;
}
```

---

## widgets/sky_chat_bubble.dart

```dart
import 'package:flutter/material.dart';
import '../models/sky_object.dart';
import '../theme/pixel_theme.dart';

class SkyChatBubble extends StatefulWidget {
  final SkyObject  object;
  final Offset     starPos;    // current screen position of star
  final Size       screenSize;
  final VoidCallback onClose;

  const SkyChatBubble({
    super.key,
    required this.object,
    required this.starPos,
    required this.screenSize,
    required this.onClose,
  });

  @override
  State<SkyChatBubble> createState() => _SkyChatBubbleState();
}

class _SkyChatBubbleState extends State<SkyChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  )..forward();

  static const double kW = 196.0;
  static const double kH = 128.0;

  bool get _goLeft => widget.starPos.dx > widget.screenSize.width / 2;

  Offset get _pos {
    double x = _goLeft
        ? widget.starPos.dx - kW - 14
        : widget.starPos.dx + 14;
    double y = widget.starPos.dy - kH / 2;
    return Offset(
      x.clamp(6.0, widget.screenSize.width  - kW - 6),
      y.clamp(6.0, widget.screenSize.height - kH - 6),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = _pos;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 80), // follows star smoothly
      left: p.dx,
      top:  p.dy,
      child: FadeTransition(
        opacity: _ctrl,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack)
              .drive(Tween(begin: 0.75, end: 1.0)),
          alignment: _goLeft
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: _BubbleBody(
            object:  widget.object,
            onClose: widget.onClose,
            goLeft:  _goLeft,
          ),
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────

class _BubbleBody extends StatelessWidget {
  final SkyObject object;
  final VoidCallback onClose;
  final bool goLeft;

  const _BubbleBody({
    required this.object,
    required this.onClose,
    required this.goLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 196,
      height: 128,
      child: CustomPaint(
        painter: _BorderPainter(color: object.pixelColor, goLeft: goLeft),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header
              Row(
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    color: object.pixelColor,
                    child: Text(object.typeLabel,
                        style: PixelTheme.micro
                            .copyWith(color: PixelTheme.bgDeep)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text('×',
                          style: PixelTheme.label
                              .copyWith(color: PixelTheme.uiGreen)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Name
              Text(
                object.name.toUpperCase(),
                style: PixelTheme.label.copyWith(color: object.pixelColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // ── Distance
              Text(
                '⬡ ${object.distance}',
                style: PixelTheme.micro.copyWith(color: PixelTheme.textDim),
              ),
              const SizedBox(height: 4),

              // ── Fun fact
              Expanded(
                child: Text(
                  object.funFact,
                  style: PixelTheme.micro.copyWith(color: PixelTheme.textMid),
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  final Color color;
  final bool  goLeft;
  _BorderPainter({required this.color, required this.goLeft});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = PixelTheme.bubbleBg,
    );

    // Pixel border
    canvas.drawRect(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Corner accent squares (retro box style)
    final cp = Paint()..color = color;
    const c = 4.0;
    for (final o in [
      Offset(0, 0), Offset(size.width - c, 0),
      Offset(0, size.height - c), Offset(size.width - c, size.height - c),
    ]) canvas.drawRect(o & const Size(c, c), cp);

    // Top accent bar
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 2),
      Paint()..color = color.withOpacity(0.5),
    );

    // Tail triangle toward star
    final tailX = goLeft
        ? size.width          // points right
        : 0.0;                // points left
    final cy = size.height / 2;
    final tailDir = goLeft ? 8.0 : -8.0;
    final path = Path()
      ..moveTo(tailX, cy - 6)
      ..lineTo(tailX + tailDir, cy)
      ..lineTo(tailX, cy + 6)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BorderPainter old) => old.color != color;
}
```

---

## theme/pixel_theme.dart

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PixelTheme {
  // ── Color Palette ─────────────────────────────────────────────────────
  static const bgDeep    = Color(0xFF050510);  // deep space black
  static const bgMid     = Color(0xFF0A0A1E);
  static const gridLine  = Color(0xFF0E0E28);  // barely-visible grid
  static const bubbleBg  = Color(0xFF060D1C);  // bubble fill

  static const uiGreen   = Color(0xFF00FF41);  // phosphor green (primary UI)
  static const uiAmber   = Color(0xFFFFB000);  // amber (warnings)
  static const uiCyan    = Color(0xFF00FFEE);  // cyan (secondary)

  static const textBright = Color(0xFFDDE8FF);
  static const textMid    = Color(0xFF7788AA);
  static const textDim    = Color(0xFF334455);

  // ── Typography ────────────────────────────────────────────────────────
  // Press Start 2P — canonical pixel font
  static TextStyle get heading => GoogleFonts.pressStart2p(
    fontSize: 10, color: uiGreen, letterSpacing: 1.2,
  );

  static TextStyle get label => GoogleFonts.pressStart2p(
    fontSize: 7.5, color: textBright, letterSpacing: 0.5,
  );

  static TextStyle get micro => GoogleFonts.pressStart2p(
    fontSize: 5.5, color: textMid, height: 1.9,
  );

  // ── Rules (enforce everywhere) ────────────────────────────────────────
  // 1. No border-radius — everything sharp corners
  // 2. No gradients — flat colors only
  // 3. Snap all positions to 2px grid
  // 4. Use uiGreen as primary accent, pixelColor per object as secondary
  // 5. Animations: short duration (150-200ms), easeOut curves
}
```

---

## data/sky_database.dart

```dart
import '../models/sky_object.dart';

/// Seed data. Replace azimuth/altitude each frame using astronomy-engine.
/// These static values are just for wiring up the pipeline first.
class SkyDatabase {
  static List<SkyObject> get objects => [
    SkyObject(
      id: 'sirius',
      name: 'Sirius',
      type: SkyObjectType.star,
      magnitude: -1.46,
      distance: '8.6 light-years',
      funFact: 'Brightest star in Earth\'s night sky. Part of Canis Major.',
    ),
    SkyObject(
      id: 'canopus',
      name: 'Canopus',
      type: SkyObjectType.star,
      magnitude: -0.74,
      distance: '310 light-years',
      funFact: 'Used as a navigation reference by spacecraft.',
    ),
    SkyObject(
      id: 'arcturus',
      name: 'Arcturus',
      type: SkyObjectType.star,
      magnitude: -0.05,
      distance: '36.7 light-years',
      funFact: 'A red giant 25× wider than the Sun.',
    ),
    SkyObject(
      id: 'venus',
      name: 'Venus',
      type: SkyObjectType.planet,
      magnitude: -4.5,
      distance: '~41M km (varies)',
      funFact: 'Hottest planet at 465°C. A day on Venus is longer than its year.',
    ),
    SkyObject(
      id: 'mars',
      name: 'Mars',
      type: SkyObjectType.planet,
      magnitude: -2.9,
      distance: '~78M km (varies)',
      funFact: 'Has the tallest volcano in the solar system — Olympus Mons.',
    ),
    SkyObject(
      id: 'jupiter',
      name: 'Jupiter',
      type: SkyObjectType.planet,
      magnitude: -2.7,
      distance: '~628M km (varies)',
      funFact: 'The Great Red Spot is a storm older than 400 years.',
    ),
    SkyObject(
      id: 'andromeda',
      name: 'Andromeda',
      type: SkyObjectType.galaxy,
      magnitude: 3.44,
      distance: '2.537M light-years',
      funFact: 'On a collision course with the Milky Way in ~4.5B years.',
    ),
    SkyObject(
      id: 'orion_nebula',
      name: 'Orion Nebula',
      type: SkyObjectType.nebula,
      magnitude: 4.0,
      distance: '1,344 light-years',
      funFact: 'A stellar nursery — new stars are forming inside it right now.',
    ),
  ];
}
```

---

## screens/sky_screen.dart

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/sky_database.dart';
import '../engine/sensor_service.dart';
import '../engine/tap_detector.dart';
import '../models/sky_object.dart';
import '../painters/sky_painter.dart';
import '../theme/pixel_theme.dart';
import '../widgets/sky_chat_bubble.dart';

class SkyScreen extends StatefulWidget {
  const SkyScreen({super.key});

  @override
  State<SkyScreen> createState() => _SkyScreenState();
}

class _SkyScreenState extends State<SkyScreen>
    with SingleTickerProviderStateMixin {
  final _sensorService = SensorService();
  final _objects       = SkyDatabase.objects;

  double _azimuth  = 0;
  double _altitude = 30; // default looking slightly up
  int    _frame    = 0;

  SkyObject? _selected;
  StreamSubscription? _sensorSub;
  late final Timer _flickerTimer;

  // ── Permissions ───────────────────────────────────────────────────────
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _requestPermsAndStart();

    // Drive flicker at ~6fps (retro feel)
    _flickerTimer = Timer.periodic(
      const Duration(milliseconds: 160),
      (_) => setState(() => _frame++),
    );
  }

  Future<void> _requestPermsAndStart() async {
    final status = await Permission.sensors.request();
    // Location needed by flutter_compass on some devices
    await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      _sensorService.start();
      _sensorSub = _sensorService.stream.listen((o) {
        setState(() {
          _azimuth  = o.azimuth;
          _altitude = o.altitude;

          // TODO: replace with real astronomy-engine call:
          // _updateObjectPositions(o.azimuth, o.altitude, DateTime.now());
          _mockUpdatePositions(); // uses static spread for now
        });
      });
    }
    setState(() => _ready = true);
  }

  /// Temporary: scatter objects across visible sky for UI testing.
  /// Replace with astronomy-engine coordinate conversion.
  void _mockUpdatePositions() {
    final offsets = [
      const Offset(-20, 10), const Offset(30, 5),
      const Offset(-10, 25), const Offset(5, -5),
      const Offset(40, 15),  const Offset(-35, 20),
      const Offset(15, -10), const Offset(-5, 30),
    ];
    for (int i = 0; i < _objects.length; i++) {
      _objects[i].azimuth  = _azimuth  + offsets[i % offsets.length].dx;
      _objects[i].altitude = _altitude + offsets[i % offsets.length].dy;
    }
  }

  // ── Tap Handling ──────────────────────────────────────────────────────

  void _onTap(TapUpDetails details) {
    final hit = SkyTapDetector.nearest(
      details.localPosition,
      _objects,
    );
    setState(() => _selected = hit);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    _sensorSub?.cancel();
    _sensorService.dispose();
    _flickerTimer.cancel();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: PixelTheme.bgDeep,
      body: Stack(
        children: [
          // ── Sky canvas
          GestureDetector(
            onTapUp: _onTap,
            child: SizedBox.expand(
              child: CustomPaint(
                painter: SkyPainter(
                  objects:         _objects,
                  deviceAzimuth:   _azimuth,
                  deviceAltitude:  _altitude,
                  frame:           _frame,
                ),
              ),
            ),
          ),

          // ── Chat bubble (follows selected star)
          if (_selected != null && _selected!.isVisible)
            SkyChatBubble(
              key:        ValueKey(_selected!.id),
              object:     _selected!,
              starPos:    _selected!.screenPos,
              screenSize: size,
              onClose:    () => setState(() => _selected = null),
            ),

          // ── Top HUD bar
          _buildHUD(size),

          // ── Permission/loading state
          if (!_ready)
            const Center(
              child: CircularProgressIndicator(color: PixelTheme.uiGreen),
            ),
        ],
      ),
    );
  }

  Widget _buildHUD(Size size) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: PixelTheme.bubbleBg,
                    border: Border.all(color: PixelTheme.uiGreen, width: 1),
                  ),
                  child: Text('◀',
                      style: PixelTheme.micro
                          .copyWith(color: PixelTheme.uiGreen)),
                ),
              ),
              const SizedBox(width: 10),
              Text('SKY MAP',
                  style: PixelTheme.heading),
              const Spacer(),
              // Compass readout
              Text(
                '${_azimuth.toStringAsFixed(0)}°',
                style: PixelTheme.micro.copyWith(color: PixelTheme.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Integration: add route to your router

```dart
// In your GoRouter / Navigator routes:
GoRoute(
  path: '/sky-map',
  builder: (_, __) => const SkyScreen(),
),
```

## Integration: add entry point in Verasso nav

```dart
// Wherever you open tools/screens — add a sky map button:
IconButton(
  icon: const Icon(Icons.star_outlined),
  tooltip: 'Sky Map',
  onPressed: () => context.go('/sky-map'),
  // or: Navigator.of(context).push(
  //       MaterialPageRoute(builder: (_) => const SkyScreen()))
),
```

---

## Next milestone: real star positions

Replace `_mockUpdatePositions()` with astronomy-engine:

```dart
// pubspec.yaml: astronomy_engine: ^2.1.0
import 'package:astronomy_engine/astronomy_engine.dart';

void _updateObjectPositions(double lat, double lon, DateTime time) {
  final observer = Observer(lat, lon, 0);
  for (final obj in _objects) {
    // example for a planet:
    if (obj.id == 'mars') {
      final eq = GeoVector(Body.Mars, time, false);
      final hor = Horizon(time, observer, eq.ra, eq.dec, Refraction.Normal);
      obj.azimuth  = hor.azimuth;
      obj.altitude = hor.altitude;
    }
  }
}
```
