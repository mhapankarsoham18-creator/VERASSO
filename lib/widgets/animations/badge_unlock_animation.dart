import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Unique animation widget for each badge unlock
/// Each badge gets its own custom animation based on rarity and category
class BadgeUnlockAnimation extends StatefulWidget {
  /// The name of the badge being unlocked.
  final String badgeName;

  /// The description of the badge.
  final String badgeDescription;

  /// The rarity of the badge (e.g., 'common', 'legendary').
  final String rarity;

  /// The category of the badge (e.g., 'learning').
  final String category;

  /// The points rewarded for unlocking the badge.
  final int pointsReward;

  /// Callback when the animation completes.
  final VoidCallback onComplete;

  /// Creates a [BadgeUnlockAnimation].
  const BadgeUnlockAnimation({
    super.key,
    required this.badgeName,
    required this.badgeDescription,
    required this.rarity,
    required this.category,
    required this.pointsReward,
    required this.onComplete,
  });

  @override
  State<BadgeUnlockAnimation> createState() => _BadgeUnlockAnimationState();
}

/// Specific badge-specific animations.
class SpecificBadgeAnimations {
  /// Graduation cap toss animation for the "Expert" badge.
  static Widget expert(VoidCallback onComplete) {
    return _CodeBasedAnimation(
      duration: const Duration(milliseconds: 2500),
      onComplete: onComplete,
      builder: (context, controller) {
        // Parabola logic: y = -4x^2 + 4x (0 to 1 mapping)
        final t = controller.value;
        final yOffset = -300 * (4 * t * (1 - t)); // Up and down
        final rotate = t * 4 * 3.14;

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, -yOffset + 100), // Start lower, go up
                child: Transform.rotate(
                  angle: rotate,
                  child: const Icon(LucideIcons.graduationCap,
                      size: 100, color: Colors.yellowAccent),
                ),
              ),
              if (t > 0.8)
                FadeTransition(
                  opacity: AlwaysStoppedAnimation((t - 0.8) * 5),
                  child: const Text('Expert!',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                )
            ],
          ),
        );
      },
    );
  }

  /// Walking footsteps animation for the "First Steps" badge.
  static Widget firstSteps(VoidCallback onComplete) {
    return _CodeBasedAnimation(
      duration: const Duration(seconds: 3),
      onComplete: onComplete,
      builder: (context, controller) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Left foot
            Positioned(
              left: 100,
              top: 200 - (controller.value * 200),
              child: Opacity(
                opacity:
                    (math.sin(controller.value * 3.14 * 4) > 0) ? 1.0 : 0.0,
                child: const Icon(LucideIcons.ban,
                    size: 50,
                    color:
                        Colors.white), // Using standard icon as footprint proxy
              ),
            ),
            // Right foot
            Positioned(
              right: 100,
              top: 150 - (controller.value * 200),
              child: Opacity(
                opacity: (math.sin(controller.value * 3.14 * 4 + 3.14) > 0)
                    ? 1.0
                    : 0.0,
                child: const Icon(LucideIcons.ban,
                    size: 50, color: Colors.white12),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: controller,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.footprints,
                        size: 100, color: Colors.orangeAccent),
                    SizedBox(height: 10),
                    Text('First Steps!',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Hammer swing animation for the "Master Builder" badge.
  static Widget masterBuilder(VoidCallback onComplete) {
    return _CodeBasedAnimation(
      duration: const Duration(seconds: 2),
      onComplete: onComplete,
      builder: (context, controller) {
        // Swing logic
        final swing = math.sin(controller.value * 3.14 * 3); // 3 swings
        final angle = -0.5 + (swing * 1.0); // -0.5 to 0.5 rad

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: angle,
                alignment: Alignment.bottomRight,
                child: const Icon(LucideIcons.wrench,
                    size: 120, color: Colors.brown),
              ),
              const SizedBox(height: 20),
              if (swing.abs() > 0.8)
                const Text('BAM!',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
            ],
          ),
        );
      },
    );
  }

  /// Book page-flip animation for the "Scholar" badge.
  static Widget scholar(VoidCallback onComplete) {
    return _CodeBasedAnimation(
      duration: const Duration(seconds: 3),
      onComplete: onComplete,
      builder: (context, controller) {
        final angle = controller.value * 2 * 3.14159;
        return Center(
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.bookOpen, size: 120, color: Colors.blueAccent),
                SizedBox(height: 20),
                Text('Scholar!',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pulsing flame animation for the "Week Warrior" badge.
  static Widget weekWarrior(VoidCallback onComplete) {
    return _CodeBasedAnimation(
      duration: const Duration(milliseconds: 3000),
      onComplete: onComplete,
      builder: (context, controller) {
        final scale = 1.0 + math.sin(controller.value * 20) * 0.1;
        return Center(
          child: ScaleTransition(
            scale: AlwaysStoppedAnimation(scale),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.flame, size: 120, color: Colors.deepOrange),
                SizedBox(height: 10),
                Text('Week Warrior!',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orangeAccent)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BadgeUnlockAnimationState extends State<BadgeUnlockAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late ConfettiController _confettiController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  String get _categoryIcon {
    switch (widget.category) {
      case 'learning':
        return '📚';
      case 'building':
        return '🏗️';
      case 'social':
        return '👥';
      case 'engagement':
        return '🔥';
      default:
        return '🏆';
    }
  }

  Color get _rarityColor {
    switch (widget.rarity) {
      case 'legendary':
        return const Color(0xFFFFD700); // Gold
      case 'epic':
        return const Color(0xFF9C27B0); // Purple
      case 'rare':
        return const Color(0xFF2196F3); // Blue
      case 'uncommon':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnimation),
      child: Material(
        color: Colors.black87,
        child: Stack(
          children: [
            _buildParticles(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _rotateAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: widget.rarity == 'legendary'
                              ? _rotateAnimation.value
                              : 0,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _rarityColor,
                              _rarityColor.withValues(alpha: 0.3),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _rarityColor.withValues(alpha: 0.6),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _categoryIcon,
                            style: const TextStyle(fontSize: 80),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      widget.badgeName,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      widget.badgeDescription,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _rarityColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${widget.pointsReward} Points',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _rotateAnimation =
        Tween<double>(begin: 0, end: 2 * 3.14159).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _playAnimation();
  }

  Widget _buildCommonParticles() {
    // Simple fade-in sparkles
    return ConfettiWidget(
      confettiController: _confettiController,
      blastDirection: 3.14 / 2,
      emissionFrequency: 0.25,
      numberOfParticles: 8,
      colors: const [Colors.grey, Colors.blueGrey],
    );
  }

  Widget _buildEpicParticles() {
    // Purple glow with lightning
    return ConfettiWidget(
      confettiController: _confettiController,
      blastDirectionality: BlastDirectionality.explosive,
      emissionFrequency: 0.1,
      numberOfParticles: 20,
      colors: const [Colors.purple, Colors.deepPurple, Colors.purpleAccent],
    );
  }

  Widget _buildLegendaryParticles() {
    // Diamond explosion with rainbow confetti
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14 / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.3,
            colors: const [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.purple,
            ],
          ),
        ),
        // Animated sparkles
        ...List.generate(20, (index) {
          return AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              final angle = (index / 20) * 2 * 3.14159 + _rotateAnimation.value;
              const radius = 150.0;
              return Positioned(
                left: MediaQuery.of(context).size.width / 2 +
                    radius * math.cos(angle),
                top: MediaQuery.of(context).size.height / 2 +
                    radius * math.sin(angle),
                child: Opacity(
                  opacity:
                      (math.sin(_rotateAnimation.value * 4 + index) + 1) / 2,
                  child: const Text('💎', style: TextStyle(fontSize: 20)),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildParticles() {
    switch (widget.rarity) {
      case 'legendary':
        return _buildLegendaryParticles();
      case 'epic':
        return _buildEpicParticles();
      case 'rare':
        return _buildRareParticles();
      case 'uncommon':
        return _buildUncommonParticles();
      default:
        return _buildCommonParticles();
    }
  }

  Widget _buildRareParticles() {
    // Star burst
    return ConfettiWidget(
      confettiController: _confettiController,
      blastDirectionality: BlastDirectionality.explosive,
      emissionFrequency: 0.15,
      numberOfParticles: 15,
      colors: const [Colors.blue, Colors.lightBlue, Colors.cyan],
    );
  }

  Widget _buildUncommonParticles() {
    // Green sparkles
    return ConfettiWidget(
      confettiController: _confettiController,
      blastDirection: 3.14 / 2,
      emissionFrequency: 0.2,
      numberOfParticles: 10,
      colors: const [Colors.green, Colors.lightGreen],
    );
  }

  void _playAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _rotateController.forward();
    _confettiController.play();

    await Future.delayed(const Duration(milliseconds: 3000));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    widget.onComplete();
  }
}

class _CodeBasedAnimation extends StatefulWidget {
  final Duration duration;
  final VoidCallback onComplete;
  final Widget Function(BuildContext, AnimationController) builder;

  const _CodeBasedAnimation({
    required this.duration,
    required this.onComplete,
    required this.builder,
  });

  @override
  State<_CodeBasedAnimation> createState() => _CodeBasedAnimationState();
}

class _CodeBasedAnimationState extends State<_CodeBasedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(context, _controller),
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
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }
}
