import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Dialog widget celebrating a daily streak milestone with flame animation.
class StreakCelebrationAnimation extends StatefulWidget {
  /// The number of days in the streak.
  final int days;

  /// Callback when the dialog is dismissed.
  final VoidCallback onDismiss;

  /// Creates a [StreakCelebrationAnimation].
  const StreakCelebrationAnimation({
    super.key,
    required this.days,
    required this.onDismiss,
  });

  @override
  State<StreakCelebrationAnimation> createState() =>
      _StreakCelebrationAnimationState();
}

class _StreakCelebrationAnimationState extends State<StreakCelebrationAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Animated background glow
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.4, 1.0],
                    radius: 0.5 + (_controller.value * 0.2),
                  ),
                ),
              );
            },
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flame visual
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 800),
                builder: (context, val, child) {
                  return Transform.scale(
                    scale: val,
                    child: const Icon(LucideIcons.flame,
                        size: 120, color: Colors.deepOrange),
                  );
                },
                onEnd: () {},
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.days} Day Streak!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep it up!',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Awesome'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }
}
