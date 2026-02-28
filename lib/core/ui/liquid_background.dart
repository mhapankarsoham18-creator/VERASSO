import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/theme_controller.dart';

/// A dynamic, animated background that creates a "liquid" or "blob" effect using blurring and motion.
///
/// Adapts its colors and intensity based on the current [ThemeStyle] and power-saving settings.
class LiquidBackground extends ConsumerWidget {
  /// The widget to be displayed over the liquid background.
  final Widget child;

  /// Creates a [LiquidBackground].
  const LiquidBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Style Definitions - High Viscosity & Neon
    final Map<ThemeStyle, List<Color>> styleColors = {
      ThemeStyle.liquid: [
        themeState.primaryColor,
        themeState.accentColor,
        isDark ? Colors.white10 : Colors.white70
      ],
      ThemeStyle.midnight: [
        const Color(0xFF001F3F),
        const Color(0xFF001122),
        themeState.primaryColor
      ],
      ThemeStyle.tron: [
        const Color(0xFF000000), // Deep Black
        themeState.primaryColor, // Neon Cyan
        const Color(0xFF0055FF), // Electric Blue
      ],
      ThemeStyle.bladeRunner: [
        const Color(0xFF333333), // Smoke
        themeState.primaryColor, // Amber
        const Color(0xFFFF4500), // Orange
      ],
      ThemeStyle.enchanted: [
        const Color(0xFF2A0D2E), // Midnight Purple
        themeState.primaryColor, // Burgundy
        themeState.accentColor, // Gold
      ],
      ThemeStyle.nature: [
        const Color(0xFF00FF41),
        const Color(0xFF008F11),
        Colors.black
      ],
      ThemeStyle.sunset: [
        const Color(0xFFFF4500),
        const Color(0xFFFF8C00),
        const Color(0xFF1A1A1A)
      ],
    };

    final colors =
        styleColors[themeState.style] ?? styleColors[ThemeStyle.liquid]!;

    return Stack(
      children: [
        // Base Background
        Container(
            color: themeState.style == ThemeStyle.tron ||
                    themeState.style == ThemeStyle.bladeRunner
                ? Colors.black
                : Theme.of(context).scaffoldBackgroundColor),

        // Animated Blobs with RepaintBoundary for performance
        RepaintBoundary(
          child: Stack(
            children: [
              // Blob 1
              _buildBlob(
                top: -100,
                left: -50,
                size: 300,
                color: colors[0].withValues(alpha: 0.5),
                animate: !themeState.isPowerSaveMode,
                scaleDuration: 15,
                moveDuration: 20,
                scaleEnd: const Offset(2.0, 2.0),
                moveEnd: const Offset(80, 80),
              ),

              // Blob 2
              _buildBlob(
                top: -100,
                left: -400,
                size: 400,
                color: colors[1].withValues(alpha: 0.4),
                animate: !themeState.isPowerSaveMode,
                scaleDuration: 18,
                moveDuration: 25,
                scaleEnd: const Offset(1.5, 1.5),
                moveEnd: const Offset(-100, -60),
              ),

              // Blob 3
              if (themeState.style == ThemeStyle.enchanted)
                ...List.generate(
                    10,
                    (i) => Positioned(
                          top: (i * 100).toDouble() % 800,
                          left: (i * 70).toDouble() % 400,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white),
                          )
                              .animate(
                                  onPlay: (c) => themeState.isPowerSaveMode
                                      ? null
                                      : c.repeat(reverse: true))
                              .fadeIn(delay: (i * 200).ms, duration: 1.seconds)
                              .scale(
                                  begin: const Offset(0, 0),
                                  end: const Offset(1.5, 1.5)),
                        ))
              else
                _buildBlob(
                  top: MediaQuery.of(context).size.height * 0.3,
                  left: MediaQuery.of(context).size.width * 0.2,
                  size: 250,
                  color: colors[2].withValues(alpha: 0.3),
                  animate: !themeState.isPowerSaveMode,
                  scaleDuration: 12,
                  moveDuration: 10,
                ),
            ],
          ),
        ),

        // Blur overlay (Liquid effect)
        if (!themeState.isPowerSaveMode)
          BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: 80, sigmaY: 80), // Reduced from 100 for better perf
            child: Container(color: Colors.transparent),
          ),

        Positioned.fill(
            child: Container(
          color: themeState.style == ThemeStyle.tron
              ? Colors.black.withValues(alpha: 0.6)
              : Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: themeState.isPowerSaveMode ? 0.9 : 0.4),
        )),

        // Content
        SafeArea(child: child),
      ],
    );
  }

  Widget _buildBlob(
      {required double top,
      required double left,
      required double size,
      required Color color,
      required bool animate,
      required int scaleDuration,
      required int moveDuration,
      Offset? scaleEnd,
      Offset? moveEnd}) {
    final blob = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );

    if (!animate) return Positioned(top: top, left: left, child: blob);

    return Positioned(
      top: top,
      left: left,
      child: blob
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
              duration: scaleDuration.seconds,
              begin: const Offset(1, 1),
              end: scaleEnd ?? const Offset(1.5, 1.5),
              curve: Curves.easeInOut)
          .move(
              duration: moveDuration.seconds,
              begin: const Offset(0, 0),
              end: moveEnd ?? const Offset(50, 50),
              curve: Curves.easeInOut),
    );
  }
}
