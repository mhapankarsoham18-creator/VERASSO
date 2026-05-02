import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ira_theme_service.dart';
import '../services/stt_service.dart';

class IraCharacterWidget extends ConsumerStatefulWidget {
  final String expression;
  final bool isTalking;

  const IraCharacterWidget({
    super.key,
    this.expression = 'Smile',
    this.isTalking = false,
  });

  @override
  ConsumerState<IraCharacterWidget> createState() => _IraCharacterWidgetState();
}

class _IraCharacterWidgetState extends ConsumerState<IraCharacterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    // Subtle breathing animation using scale
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.015).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(iraThemeServiceProvider);
    final spritePath = themeState.getSpritePath(widget.expression);
    
    // Watch amplitude to react to user speaking
    final sttState = ref.watch(sttServiceProvider);
    final double amplitudeScale = 1.0 + (sttState.amplitude * 0.1); // Lean in up to 10%
    
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        // Combine breathing scale and amplitude scale for the lean effect
        final double finalScale = _breathingAnimation.value * amplitudeScale;
        
        return Transform.scale(
          scale: finalScale,
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            spritePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
               return const Center(child: Text('Ira Sprite Missing', style: TextStyle(color: Colors.red)));
            },
          ),
        );
      },
    );
  }
}
