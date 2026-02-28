import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/debugger_model.dart';

/// A visualizer that displays variable states as floating augmented reality nodes.
class ArVariableVisualizer extends StatelessWidget {
  /// The list of variables to visualize.
  final List<VariableState> variables;

  /// Creates an [ArVariableVisualizer] widget.
  const ArVariableVisualizer({super.key, required this.variables});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
        ),
      ),
      child: Stack(
        children: [
          const Center(
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.view_in_ar,
                size: 100,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
          // Render variables as floating 3D cubes/spheres
          ...variables.asMap().entries.map((entry) {
            final index = entry.key;
            final variable = entry.value;

            // Calculate a semi-random but stable position in "3D" space
            final x = (math.sin(index * 1.5) * 80) + 100;
            final y = (math.cos(index * 0.8) * 50) + 80;
            final z = math.sin(index * 2.1) * 20;

            return Positioned(
              left: x,
              top: y,
              child: _ArVariableNode(variable: variable, z: z)
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .moveY(
                    begin: -5,
                    end: 5,
                    duration: 2.seconds,
                    curve: Curves.easeInOut,
                  )
                  .shimmer(duration: 3.seconds),
            );
          }),
        ],
      ),
    );
  }
}

class _ArVariableNode extends StatelessWidget {
  final VariableState variable;
  final double z;

  const _ArVariableNode({required this.variable, required this.z});

  @override
  Widget build(BuildContext context) {
    // scale based on "z" depth
    final scale = 1.0 + (z / 100);

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(0.1)
      ..rotateY(0.1);
    transform.multiply(
      Matrix4.diagonal3Values(scale.toDouble(), scale.toDouble(), 1.0),
    );
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              variable.name,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            Text(
              variable.value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
