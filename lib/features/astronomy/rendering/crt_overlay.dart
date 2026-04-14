import 'package:flutter/material.dart';
import 'pixel_palette.dart';

/// Overlay painter that draws horizontal scan lines for CRT effect.
class CrtOverlay extends CustomPainter {
  final int frame; // Animate very slowly for retro feel
  final bool isTransparentBg;

  CrtOverlay({this.frame = 0, this.isTransparentBg = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (isTransparentBg) return; // Disable scanlines in AR for better clarity
    
    final paint = Paint()
      ..color = PixelPalette.scanLineOverlay
      ..style = PaintingStyle.fill;

    // Draw horizontal scan lines every 3 pixels
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 1),
        paint,
      );
    }

    // Subtle moving bright band (old CRT scan)
    final bandY = (frame * 4.0) % size.height;
    final bandPaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, bandY, size.width, 8),
      bandPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CrtOverlay oldDelegate) =>
      oldDelegate.frame != frame;
}
