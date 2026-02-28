import 'package:flutter/material.dart';

/// Tutorial overlay widget that displays guided tours
/// Tutorial overlay widget that displays guided tours with step-by-step navigation.
class TutorialOverlay extends StatefulWidget {
  /// The ordered list of [TutorialStep]s to display.
  final List<TutorialStep> steps;

  /// Callback executed when all tutorial steps are completed.
  final VoidCallback onComplete;

  /// Callback executed if the user chooses to skip the tutorial.
  final VoidCallback? onSkip;

  /// Creates a [TutorialOverlay].
  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

/// Model for a single tutorial step
/// Model representing a single step within a guided application tour.
class TutorialStep {
  /// The header title for this tutorial step.
  final String title;

  /// Detailed explanation for the feature being highlighted.
  final String description;

  /// Optional icon to represent the feature.
  final IconData? icon;

  /// The [GlobalKey] of the widget to be highlighted (if any).
  final GlobalKey? targetKey;

  /// Preferred alignment for the tooltip relative to the target.
  final Alignment? tooltipAlignment;

  /// Creates a [TutorialStep].
  const TutorialStep({
    required this.title,
    required this.description,
    this.icon,
    this.targetKey,
    this.tooltipAlignment,
  });
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];

    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        children: [
          // Skip button (top right)
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _skip,
              child: const Text('Skip',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    if (step.icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step.icon,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Title
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Progress indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.steps.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentStep ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _currentStep
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Navigation buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: _previousStep,
                            child: const Text('Back',
                                style: TextStyle(fontSize: 16)),
                          )
                        else
                          const SizedBox(width: 80),

                        // Next/Done button
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentStep == widget.steps.length - 1
                                ? 'Done'
                                : 'Next',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
  }

  void _complete() {
    Navigator.of(context).pop();
    widget.onComplete();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      _complete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _skip() {
    Navigator.of(context).pop();
    if (widget.onSkip != null) {
      widget.onSkip!();
    }
  }
}
