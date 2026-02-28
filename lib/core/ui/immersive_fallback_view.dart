import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

/// A fallback view used when high-performance immersive features are unavailable.
///
/// Displays a 2.5D perspective grid simulation and informative text as a
/// secondary visual experience.
class ImmersiveFallbackView extends StatelessWidget {
  /// The secondary content/simulation to display.
  final Widget child;

  /// The title for the fallback state.
  final String title;

  /// Descriptive explanation for why the fallback is being shown.
  final String description;

  /// Creates an [ImmersiveFallbackView].
  const ImmersiveFallbackView({
    super.key,
    required this.child,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 2.5D Perspective Background
        Positioned.fill(
          child: CustomPaint(
            painter: _PerspectiveGridPainter(),
          ),
        ),

        // Content Area
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(LucideIcons.cameraOff,
                        size: 48, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // The actual interactive simulation content but in 2D
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerspectiveGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;

    // Draw perspective lines
    const int count = 20;
    final double centerX = size.width / 2;
    final double centerY = size.height * 0.3;

    for (int i = 0; i < count; i++) {
      final double x = (size.width / count) * i;
      canvas.drawLine(Offset(centerX, centerY), Offset(x, size.height), paint);
    }

    // Draw horizontal lines with increasing spacing
    double h = centerY;
    double gap = 5.0;
    while (h < size.height) {
      canvas.drawLine(Offset(0, h), Offset(size.width, h), paint);
      gap *= 1.2;
      h += gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
