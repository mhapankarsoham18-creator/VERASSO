import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_system.dart';

/// A specialized container that implements the "Liquid Glass 2.0" aesthetic.
///
/// Features adaptive blurring, semi-transparent backgrounds, and reactive
/// borders based on [meshStress] and theme brightness.
class GlassContainer extends StatelessWidget {
  /// The content to be displayed inside the glass container.
  final Widget child;

  /// The intensity of the backdrop blur effect (default: 10.0).
  final double blur;

  /// The base opacity of the glass surface (default: 0.2).
  final double opacity;

  /// A value from 0.0 to 1.0 representing physical stress on the "glass" mesh.
  /// Increases blur and border thickness as the value approaches 1.0.
  final double meshStress;

  /// Internal padding for the glass container.
  final EdgeInsetsGeometry padding;

  /// External margin around the glass container.
  final EdgeInsetsGeometry? margin;

  /// Explicit width for the container.
  final double? width;

  /// Explicit height for the container.
  final double? height;

  /// Optional custom border radius. Defaults to [DesignSystem.borderMedium].
  final BorderRadius? borderRadius;

  /// Optional custom border configuration.
  final BoxBorder? border;

  /// Optional background color override.
  final Color? color;

  /// Creates a [GlassContainer].
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 12.0, // Standardized
    this.opacity = 0.15, // Standardized for better contrast
    this.meshStress = 0.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.border,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Liquid Glass 2.0 Physics: Mesh stress increases blur and slightly decreases opacity
    final effectiveBlur = blur + (meshStress * 15.0);
    final effectiveOpacity = (opacity - (meshStress * 0.1)).clamp(0.05, 1.0);

    final glassWidget = RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius ?? DesignSystem.borderMedium,
        child: BackdropFilter(
          filter:
              ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
          child: Semantics(
            container: true,
            child: Container(
              width: width,
              height: height,
              padding: padding,
              decoration: BoxDecoration(
                color: color?.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? (effectiveOpacity - 0.05).clamp(0.0, 1.0)
                          : effectiveOpacity,
                    ) ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withValues(
                            alpha: (effectiveOpacity - 0.05).clamp(0.0, 1.0))
                        : Colors.white.withValues(alpha: effectiveOpacity)),
                borderRadius: borderRadius ?? DesignSystem.borderMedium,
                border: border ??
                    Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.primary.withValues(
                              alpha: (0.3 + (meshStress * 0.2)).clamp(0.0, 1.0))
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1.5 + (meshStress * 1.5),
                    ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          AppColors.primary
                              .withValues(alpha: 0.1 + (meshStress * 0.1)),
                          AppColors.deepSpace
                              .withValues(alpha: 0.8 + (meshStress * 0.1)),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                ),
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                              alpha:
                                  (0.05 + (meshStress * 0.1)).clamp(0.0, 1.0)),
                          blurRadius: 20 + (meshStress * 20),
                          spreadRadius: -5,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          spreadRadius: -2,
                        )
                      ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: glassWidget,
      );
    }

    return glassWidget;
  }
}
