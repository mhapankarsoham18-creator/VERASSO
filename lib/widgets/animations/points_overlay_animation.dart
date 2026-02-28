import 'package:flutter/material.dart';

/// Animated overlay that shows points earned, sliding upward and fading out.
class PointsOverlayAnimation extends StatefulWidget {
  /// The number of points to display.
  final int points;

  /// Callback when the animation completes.
  final VoidCallback onComplete;

  /// Creates a [PointsOverlayAnimation].
  const PointsOverlayAnimation({
    super.key,
    required this.points,
    required this.onComplete,
  });

  @override
  State<PointsOverlayAnimation> createState() => _PointsOverlayAnimationState();
}

class _PointsOverlayAnimationState extends State<PointsOverlayAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // Assuming this will be used in a Stack
      top: MediaQuery.of(context).size.height / 2,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Center(
            child: Text(
              '+${widget.points} XP',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                shadows: [
                  Shadow(
                      blurRadius: 10,
                      color: Colors.black45,
                      offset: Offset(2, 2)),
                ],
              ),
            ),
          ),
        ),
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
      duration: const Duration(seconds: 2),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _slide =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -2.0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) => widget.onComplete());
  }
}
