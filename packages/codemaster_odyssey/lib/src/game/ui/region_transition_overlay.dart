import 'package:flutter/material.dart';

import '../odyssey_game.dart';

/// Region name mapping for Python Arc (Regions 1-5).
const _regionNames = <int, String>{
  1: 'Garden of Scripts',
  2: 'Variable Valley',
  3: 'Loop Labyrinth',
  4: 'Recursive Ruins',
  5: 'Class Citadel',
};

/// A full-screen fade overlay shown between region transitions.
class RegionTransitionOverlay extends StatefulWidget {
  /// The game instance, used to read region info.
  final OdysseyGame game;

  /// Creates a [RegionTransitionOverlay].
  const RegionTransitionOverlay({super.key, required this.game});

  @override
  State<RegionTransitionOverlay> createState() =>
      _RegionTransitionOverlayState();
}

class _RegionTransitionOverlayState extends State<RegionTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;

  @override
  Widget build(BuildContext context) {
    final region = widget.game.transitionRegion;
    final regionName = _regionNames[region] ?? 'Region $region';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = _controller.value < 0.5
            ? _fadeIn.value
            : _fadeOut.value;
        return Opacity(
          opacity: opacity,
          child: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'REGION $region',
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    regionName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getSubtitle(region),
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      duration: const Duration(seconds: 2),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  String _getSubtitle(int region) {
    switch (region) {
      case 1:
        return 'Python Arc — Basic Syntax';
      case 2:
        return 'Python Arc — Variables & Types';
      case 3:
        return 'Python Arc — Loops & Iteration';
      case 4:
        return 'Python Arc — Recursion';
      case 5:
        return 'Python Arc — Classes & OOP';
      default:
        return 'The journey continues...';
    }
  }
}
