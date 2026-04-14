import 'dart:math';
import 'package:flutter/material.dart';
import '../models/celestial_object.dart';
import '../engine/sky_engine.dart';
import 'pixel_palette.dart';

/// CustomPainter that renders the pixel-art sky.
class SkyPainter extends CustomPainter {
  final SkyEngine engine;
  final CelestialObject? selectedObject;
  final int flickerSeed; // Changes every ~125ms for CRT flicker
  final bool isTransparentBg;

  SkyPainter({
    required this.engine,
    this.selectedObject,
    this.flickerSeed = 0,
    this.isTransparentBg = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    if (!isTransparentBg) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = PixelPalette.skyBlack,
      );
    }

    if (!engine.isLoaded) return;

    final visibleObjects = engine.visibleObjects;
    final rng = Random(flickerSeed);

    // Draw constellation lines first (below stars)
    _drawConstellationLines(canvas, size);

    // Draw stars, planets, etc.
    for (final obj in visibleObjects) {
      _drawCelestialObject(canvas, obj, rng);
    }

    // Draw selection ring if an object is selected
    if (selectedObject != null && selectedObject!.isVisible) {
      _drawSelectionIndicator(canvas, selectedObject!);
    }

    // Draw horizon line
    _drawHorizonLine(canvas, size);

    // Draw cardinal direction labels
    _drawCardinalLabels(canvas, size);
  }

  void _drawCelestialObject(Canvas canvas, CelestialObject obj, Random rng) {
    final double x = obj.screenX;
    final double y = obj.screenY;
    final int pxSize = obj.pixelSize;

    // Flicker: randomly adjust opacity slightly for stars
    double opacity = 1.0;
    if (obj.type == 'star') {
      opacity = 0.7 + rng.nextDouble() * 0.3;
    }

    Color color;
    switch (obj.type) {
      case 'sun':
        color = PixelPalette.sunGlow;
        break;
      case 'moon':
        color = PixelPalette.moonBright;
        break;
      case 'planet':
        color = PixelPalette.planetColor(obj.name);
        break;
      default:
        color = PixelPalette.starColorFromCI(obj.colorIndex);
    }

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Draw as square pixel block (NOT circle — pixel aesthetic)
    final rect = Rect.fromCenter(
      center: Offset(x, y),
      width: pxSize.toDouble(),
      height: pxSize.toDouble(),
    );
    canvas.drawRect(rect, paint);

    // Bright stars get a subtle glow pixel
    if (obj.magnitude < 1.0 && obj.type == 'star') {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      final glowRect = Rect.fromCenter(
        center: Offset(x, y),
        width: (pxSize + 4).toDouble(),
        height: (pxSize + 4).toDouble(),
      );
      canvas.drawRect(glowRect, glowPaint);
    }

    // Planets get a label beneath them
    if (obj.type == 'planet' || obj.type == 'moon' || obj.type == 'sun') {
      _drawPixelLabel(canvas, obj.name.toUpperCase(), x, y + pxSize + 6);
    }
  }

  void _drawSelectionIndicator(Canvas canvas, CelestialObject obj) {
    final paint = Paint()
      ..color = PixelPalette.bubbleBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final double size = obj.pixelSize + 12.0;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(obj.screenX, obj.screenY),
        width: size,
        height: size,
      ),
      paint,
    );

    // Corner ticks (pixel selector style)
    final tickPaint = Paint()
      ..color = PixelPalette.hudText
      ..strokeWidth = 2;

    const double tickLen = 6;
    final double half = size / 2;
    final double cx = obj.screenX;
    final double cy = obj.screenY;

    // Top-left
    canvas.drawLine(Offset(cx - half, cy - half), Offset(cx - half + tickLen, cy - half), tickPaint);
    canvas.drawLine(Offset(cx - half, cy - half), Offset(cx - half, cy - half + tickLen), tickPaint);
    // Top-right
    canvas.drawLine(Offset(cx + half, cy - half), Offset(cx + half - tickLen, cy - half), tickPaint);
    canvas.drawLine(Offset(cx + half, cy - half), Offset(cx + half, cy - half + tickLen), tickPaint);
    // Bottom-left
    canvas.drawLine(Offset(cx - half, cy + half), Offset(cx - half + tickLen, cy + half), tickPaint);
    canvas.drawLine(Offset(cx - half, cy + half), Offset(cx - half, cy + half - tickLen), tickPaint);
    // Bottom-right
    canvas.drawLine(Offset(cx + half, cy + half), Offset(cx + half - tickLen, cy + half), tickPaint);
    canvas.drawLine(Offset(cx + half, cy + half), Offset(cx + half, cy + half - tickLen), tickPaint);
  }

  void _drawConstellationLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PixelPalette.constellationLine
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final line in engine.constellationLines) {
      final star1 = engine.findById(line[0]);
      final star2 = engine.findById(line[1]);
      if (star1 == null || star2 == null) continue;
      if (!star1.isVisible || !star2.isVisible) continue;

      // Draw dashed line for pixel feel
      _drawDashedLine(
        canvas,
        Offset(star1.screenX, star1.screenY),
        Offset(star2.screenX, star2.screenY),
        paint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = sqrt(dx * dx + dy * dy);
    const dashLen = 4.0;
    const gapLen = 4.0;

    double traveled = 0;
    while (traveled < dist) {
      final start = traveled / dist;
      final end = min((traveled + dashLen) / dist, 1.0);
      canvas.drawLine(
        Offset(p1.dx + dx * start, p1.dy + dy * start),
        Offset(p1.dx + dx * end, p1.dy + dy * end),
        paint,
      );
      traveled += dashLen + gapLen;
    }
  }

  void _drawHorizonLine(Canvas canvas, Size size) {
    // Calculate where altitude=0 maps to screen Y
    final pixelsPerDegV = size.height / engine.fovVertical;
    final horizonY = size.height / 2 + engine.devicePitch * pixelsPerDegV;

    if (horizonY > 0 && horizonY < size.height) {
      final paint = Paint()
        ..color = PixelPalette.hudDim
        ..strokeWidth = 1;

      _drawDashedLine(
        canvas,
        Offset(0, horizonY),
        Offset(size.width, horizonY),
        paint,
      );

      // Label
      _drawPixelLabel(canvas, 'HORIZON', size.width / 2, horizonY + 12);
    }
  }

  void _drawCardinalLabels(Canvas canvas, Size size) {
    final directions = {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0};
    final pixelsPerDegH = size.width / engine.fovHorizontal;
    final centerY = size.height - 30;

    for (final entry in directions.entries) {
      double deltaAz = entry.value - engine.compassHeading;
      if (deltaAz > 180) deltaAz -= 360;
      if (deltaAz < -180) deltaAz += 360;

      final x = size.width / 2 + deltaAz * pixelsPerDegH;
      if (x > 0 && x < size.width) {
        _drawPixelLabel(canvas, entry.key, x, centerY);
      }
    }
  }

  void _drawPixelLabel(Canvas canvas, String text, double x, double y) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: PixelPalette.labelColor,
          fontSize: 8,
          fontFamily: 'PressStart2P', // Hardcode standard fallback or assume app level theme
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y),
    );
  }

  @override
  bool shouldRepaint(covariant SkyPainter oldDelegate) => true;
}
