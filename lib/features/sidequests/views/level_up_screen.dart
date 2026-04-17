import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

import '../title_system.dart';

class LevelUpScreen extends StatefulWidget {
  final TitleTier oldTier;
  final TitleTier newTier;

  const LevelUpScreen({
    super.key,
    required this.oldTier,
    required this.newTier,
  });

  /// Helper to trigger this screen as a dialog overlay
  static Future<void> show(BuildContext context, TitleTier oldTier, TitleTier newTier) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, anim1, anim2) {
        return LevelUpScreen(oldTier: oldTier, newTier: newTier);
      },
      transitionBuilder: (context, a1, a2, child) {
        return FadeTransition(opacity: a1, child: child);
      },
      transitionDuration: Duration(milliseconds: 500),
    );
  }

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  
  bool _canDismiss = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 3));
    
    _animController = AnimationController(
       vsync: this,
       duration: Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut)
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(Duration(milliseconds: 300));
    _confettiController.play();
    _animController.forward();
    
    await Future.delayed(Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _canDismiss = true;
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Uses barrier color
      body: Stack(
        children: [
          // Left Confetti
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 0, // right
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.2,
            ),
          ),
          
          // Right Confetti
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi, // left
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.2,
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'RANK UP!',
                  style: TextStyle(
                    fontFamily: 'Pixel', // Assuming a pixel font or coarse sans exists
                    fontSize: 24,
                    color: Colors.amber,
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: 40),
                
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      Text(
                        widget.newTier.emoji,
                        style: TextStyle(fontSize: 80),
                      ),
                      SizedBox(height: 16),
                      Text(
                        widget.newTier.title.toUpperCase(),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 40),
                
                Text(
                  'Farewell, ${widget.oldTier.title}...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white60,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                SizedBox(height: 60),
                
                AnimatedOpacity(
                  opacity: _canDismiss ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: GestureDetector(
                    onTap: () {
                      if (_canDismiss) Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white38, width: 2),
                        color: Colors.white10,
                      ),
                      child: Text(
                        'TAP TO CONTINUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
