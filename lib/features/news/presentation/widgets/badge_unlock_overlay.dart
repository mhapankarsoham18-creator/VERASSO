import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

/// Overlay widget displayed when a user unlocks a new journalism badge level.
class BadgeUnlockOverlay extends StatefulWidget {
  /// The new level reached (e.g., 'Junior', 'Senior').
  final String level;

  /// Callback when the overlay is dismissed.
  final VoidCallback onDismiss;

  /// Creates a [BadgeUnlockOverlay].
  const BadgeUnlockOverlay({
    super.key,
    required this.level,
    required this.onDismiss,
  });

  @override
  State<BadgeUnlockOverlay> createState() => _BadgeUnlockOverlayState();
}

class _BadgeUnlockOverlayState extends State<BadgeUnlockOverlay> {
  bool _canDismiss = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: InkWell(
        onTap: () {
          if (_canDismiss) {
            widget.onDismiss();
          }
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBadgeIcon(),
              const SizedBox(height: 32),
              Text(
                'LEVEL UP!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: _getAccentColor().withValues(alpha: 0.7),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
              const SizedBox(height: 8),
              Text(
                widget.level.toUpperCase(),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 16),
              Text(
                _getCongratulationText(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 48),
              const GlassContainer(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text('TAP TO DISMISS'),
              ).animate().fadeIn(delay: 1500.ms).shimmer(duration: 2.seconds),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Prevent accidental dismissal for the first 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _canDismiss = true);
      }
    });
  }

  Widget _buildBadgeIcon() {
    final color = _getAccentColor();

    switch (widget.level.toLowerCase()) {
      case 'editor':
        return Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 10),
            ],
          ),
          child: const Icon(LucideIcons.crown, size: 80, color: Colors.white),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2.seconds, color: Colors.white24)
            .scale(duration: 1.seconds, curve: Curves.elasticOut)
            .shake(hz: 2);

      case 'senior':
        return const Icon(LucideIcons.award,
                size: 80, color: Colors.purpleAccent)
            .animate()
            .scale(duration: 800.ms, curve: Curves.easeOutBack)
            .rotate(begin: -0.1, end: 0)
            .boxShadow(
                begin: const BoxShadow(blurRadius: 0),
                end: const BoxShadow(color: Colors.purple, blurRadius: 30));

      case 'staff':
        return const Icon(LucideIcons.shieldCheck,
                size: 80, color: Colors.blueAccent)
            .animate()
            .slideY(
                begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOutBack)
            .fadeIn();

      case 'junior':
      default:
        return const Icon(LucideIcons.medal,
                size: 80, color: Colors.greenAccent)
            .animate()
            .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut)
            .tint(color: Colors.green);
    }
  }

  Color _getAccentColor() {
    switch (widget.level.toLowerCase()) {
      case 'editor':
        return Colors.amber;
      case 'senior':
        return Colors.purpleAccent;
      case 'staff':
        return Colors.blueAccent;
      case 'junior':
        return Colors.greenAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  String _getCongratulationText() {
    switch (widget.level.toLowerCase()) {
      case 'editor':
        return 'You have reached the pinnacle of student journalism.\nYour word is now law.';
      case 'senior':
        return 'Your expertise is recognized across the platform.';
      case 'staff':
        return 'You are now a key contributor to the Verasso community.';
      case 'junior':
        return 'Your first step into a larger world.\nKeep publishing!';
      default:
        return 'Congratulations on your achievement!';
    }
  }
}
