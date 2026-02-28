import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:verasso/core/monitoring/app_logger.dart';

/// Unique animations for level milestones (every 10 levels)
/// Each milestone has a unique theme and celebration
class LevelMilestoneAnimation extends StatefulWidget {
  /// The level reached (e.g., 10, 20).
  final int level;

  /// Callback when the animation completes.
  final VoidCallback onComplete;

  /// Creates a [LevelMilestoneAnimation].
  const LevelMilestoneAnimation({
    super.key,
    required this.level,
    required this.onComplete,
  });

  @override
  State<LevelMilestoneAnimation> createState() =>
      _LevelMilestoneAnimationState();
}

class _LevelMilestoneAnimationState extends State<LevelMilestoneAnimation>
    with TickerProviderStateMixin {
  late AnimationController _shieldController;
  late AnimationController _textController;
  late ConfettiController _confetti1;
  late ConfettiController _confetti2;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Stack(
        children: [
          // Left confetti
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _confetti1,
              blastDirection: 0,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
            ),
          ),
          // Right confetti
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _confetti2,
              blastDirection: math.pi,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
            ),
          ),
          Center(
            child: _buildLevelContent(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shieldController.dispose();
    _textController.dispose();
    _confetti1.dispose();
    _confetti2.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _shieldController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _confetti1 = ConfettiController(
      duration: const Duration(seconds: 4),
    );

    _confetti2 = ConfettiController(
      duration: const Duration(seconds: 4),
    );

    _playAnimation();
  }

  Widget _buildBronzeShield() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _shieldController,
          builder: (context, child) {
            return Transform.scale(
              scale: _shieldController.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFFCD7F32), // Bronze
                      Color(0xFF8B4513),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCD7F32).withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🛡️',
                    style: TextStyle(fontSize: 100),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        FadeTransition(
          opacity: _textController,
          child: const Text(
            'Level 10 Reached!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFFCD7F32),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiamondShield() {
    return Stack(
      children: [
        // Galaxy background effect
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Color(0xFF1a1a2e),
                Color(0xFF0f3460),
                Color(0xFF16213e),
              ],
            ),
          ),
        ),
        // Stars
        ...List.generate(30, (index) {
          return Positioned(
            left: (index * 37) % MediaQuery.of(context).size.width,
            top: (index * 41) % MediaQuery.of(context).size.height,
            child: AnimatedBuilder(
              animation: _shieldController,
              builder: (context, child) {
                return Opacity(
                  opacity:
                      (math.sin(_shieldController.value * 3 * math.pi + index) +
                              1) /
                          2,
                  child: const Text('⭐', style: TextStyle(fontSize: 20)),
                );
              },
            ),
          );
        }),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _shieldController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _shieldController.value,
                  child: Transform.rotate(
                    angle: _shieldController.value * 2 * math.pi,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            Color(0xFFB9F2FF),
                            Color(0xFF4FACFE),
                            Color(0xFF00F2FE),
                            Color(0xFFB9F2FF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF4FACFE).withValues(alpha: 0.8),
                            blurRadius: 80,
                            spreadRadius: 30,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '💎',
                          style: TextStyle(fontSize: 130),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _textController,
              child: const Text(
                'Level 50 LEGEND!',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB9F2FF),
                  shadows: [
                    Shadow(
                      color: Color(0xFF4FACFE),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _textController,
              child: const Text(
                '🎆 LEGENDARY STATUS ACHIEVED! 🎆',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoldShield() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _shieldController,
          builder: (context, child) {
            return Transform.scale(
              scale: _shieldController.value,
              child: Transform.rotate(
                angle: math.sin(_shieldController.value * 2 * math.pi) * 0.1,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFD700), // Gold
                        Color(0xFFFFA500),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🛡️',
                      style: TextStyle(fontSize: 110),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        FadeTransition(
          opacity: _textController,
          child: const Text(
            'Level 30 Mastered!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelContent() {
    switch (widget.level) {
      case 10:
        return _buildBronzeShield();
      case 20:
        return _buildSilverShield();
      case 30:
        return _buildGoldShield();
      case 40:
        return _buildPlatinumShield();
      case 50:
        return _buildDiamondShield();
      default:
        if (widget.level >= 60) {
          return _buildMasterShield();
        }
        return _buildGoldShield();
    }
  }

  Widget _buildMasterShield() {
    // For levels 60, 70, 80, 90, 100+
    final levelTier = (widget.level / 10).floor();
    final colors = _getMasterTierColors(levelTier);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _shieldController,
          builder: (context, child) {
            return Transform.scale(
              scale: _shieldController.value,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: colors),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.8),
                      blurRadius: 70,
                      spreadRadius: 25,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('👑', style: TextStyle(fontSize: 130)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        FadeTransition(
          opacity: _textController,
          child: Text(
            'Level ${widget.level} MASTER!',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: colors.first,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatinumShield() {
    return Stack(
      children: [
        // Lightning effect
        ...List.generate(6, (index) {
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + (index - 3) * 80,
            top: 100,
            child: AnimatedBuilder(
              animation: _shieldController,
              builder: (context, child) {
                return Opacity(
                  opacity:
                      (math.sin(_shieldController.value * 4 * math.pi + index) +
                              1) /
                          2,
                  child: const Text('⚡', style: TextStyle(fontSize: 60)),
                );
              },
            ),
          );
        }),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _shieldController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _shieldController.value,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFE5E4E2), // Platinum
                          Color(0xFFD3D3D3),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.9),
                          blurRadius: 60,
                          spreadRadius: 25,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🛡️',
                        style: TextStyle(fontSize: 120),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _textController,
              child: const Text(
                'Level 40 Champion!',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE5E4E2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSilverShield() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _shieldController,
          builder: (context, child) {
            return Transform.scale(
              scale: _shieldController.value,
              child: AnimatedBuilder(
                animation: _shieldController,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFC0C0C0), // Silver
                          Color(0xFF808080),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC0C0C0).withValues(alpha: 0.7),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Text(
                            '🛡️',
                            style: TextStyle(fontSize: 100),
                          ),
                        ),
                        ...List.generate(8, (index) {
                          final angle = (index / 8) * 2 * math.pi;
                          return Positioned(
                            left: 100 +
                                60 *
                                    math.cos(angle +
                                        _shieldController.value * 2 * math.pi),
                            top: 100 +
                                60 *
                                    math.sin(angle +
                                        _shieldController.value * 2 * math.pi),
                            child:
                                const Text('✨', style: TextStyle(fontSize: 20)),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        FadeTransition(
          opacity: _textController,
          child: const Text(
            'Level 20 Achieved!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC0C0C0),
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _getMasterTierColors(int tier) {
    switch (tier) {
      case 6: // 60
        return const [Color(0xFFFF6B6B), Color(0xFFEE5A6F)];
      case 7: // 70
        return const [Color(0xFF4ECDC4), Color(0xFF44A08D)];
      case 8: // 80
        return const [Color(0xFFF7971E), Color(0xFFFFD200)];
      case 9: // 90
        return const [Color(0xFF667EEA), Color(0xFF764BA2)];
      default: // 100+
        return const [Color(0xFFFA709A), Color(0xFFFEE140)];
    }
  }

  void _playAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _shieldController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _textController.forward();
    _confetti1.play();
    _confetti2.play();

    // Play sound effect based on level
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/level_up_${widget.level}.mp3'));
    } catch (e) {
      AppLogger.warning('Audio playback failed', error: e);
    }

    await Future.delayed(const Duration(milliseconds: 4000));
    widget.onComplete();
  }
}
