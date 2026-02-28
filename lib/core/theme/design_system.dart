import 'package:flutter/material.dart';

/// Defines the core design tokens and constants for the Verasso UI.
///
/// Includes spatial units (radius), timing (duration), and motion (curves)
/// to ensure a consistent premium feel across all components.
class DesignSystem {
  // Border Radius Constants
  /// Small border radius (8.0), used for minor elements and buttons.
  static const double radiusSmall = 8.0;

  /// Medium border radius (12.0), used for standard cards and containers.
  static const double radiusMedium = 12.0;

  /// Large border radius (16.0), used for main sections and prominent overlays.
  static const double radiusLarge = 16.0;

  // Animation Constants
  /// Fast transition timing (200ms) for micro-interactions.
  static const Duration durationFast = Duration(milliseconds: 200);

  /// Medium transition timing (400ms) for modal entries and page changes.
  static const Duration durationMedium = Duration(milliseconds: 400);

  /// Slow transition timing (600ms) for atmospheric animations.
  static const Duration durationSlow = Duration(milliseconds: 600);

  // Standard cubic-bezier easing
  /// Standard ease-in-out curve for predictable motion.
  static const Curve easingStandard = Cubic(0.4, 0.0, 0.2, 1.0);

  /// Deceleration curve for entering elements.
  static const Curve easingDecelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Acceleration curve for exiting elements.
  static const Curve easingAccelerate = Cubic(0.4, 0.0, 1.0, 1.0);

  // Hover Lift Constants
  /// The vertical lift offset (-4.0) applied to elements on hover.
  static const double hoverLift = -4.0;

  /// Small icon size (16.0) for captions and metadata.
  static const double iconSizeSmall = 16.0;

  /// Standard icon size (20.0) for body text and navigation items.
  static const double iconSizeMedium = 20.0;

  /// Large icon size (24.0) for headings and dominant actions.
  static const double iconSizeLarge = 24.0;

  /// Large boundary radius for layout-wide components.
  static BorderRadius get borderLarge => BorderRadius.circular(radiusLarge);

  /// Standard medium boundary radius for cards.
  static BorderRadius get borderMedium => BorderRadius.circular(radiusMedium);

  /// Tight boundary radius for small buttons or tags.
  static BorderRadius get borderSmall => BorderRadius.circular(radiusSmall);
}
