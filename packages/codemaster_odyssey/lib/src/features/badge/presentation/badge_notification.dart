import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_animate/flutter_animate.dart';

import '../../badge/domain/badge_model.dart';

/// A decorative notification widget that celebrates a newly unlocked [badge].
class BadgeNotification extends StatelessWidget {
  /// The badge that was just unlocked.
  final Badge badge;

  /// Callback triggered when the 'AWESOME!' button is pressed.
  final VoidCallback onDismiss;

  /// Creates a [BadgeNotification] instance.
  const BadgeNotification({
    super.key,
    required this.badge,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with glow
              Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E1E2E),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      badge.iconData,
                      size: 60,
                      color: const Color(0xFFFFD700),
                    ),
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .then(delay: 200.ms)
                  .shimmer(duration: 1000.ms),

              const SizedBox(height: 24),

              Text(
                'BADGE UNLOCKED!',
                style: TextStyle(
                  color: const Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn().slideY(begin: 0.5),

              const SizedBox(height: 8),

              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),

              const SizedBox(height: 8),

              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('AWESOME!'),
              ).animate().scale(delay: 600.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }
}
