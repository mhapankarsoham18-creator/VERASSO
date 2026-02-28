import 'package:flutter/material.dart';

/// Menu screen for selecting physics-related simulations and educational content.
class PhysicsMenuScreen extends StatelessWidget {
  /// Creates a [PhysicsMenuScreen] instance.
  const PhysicsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Physics')),
      body: const Center(child: Text('Physics Menu Coming Soon')),
    );
  }
}
