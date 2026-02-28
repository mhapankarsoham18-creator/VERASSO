import 'package:flutter/material.dart';

/// Menu screen for selecting biology-related simulations and educational content.
class BiologyMenuScreen extends StatelessWidget {
  /// Creates a [BiologyMenuScreen] instance.
  const BiologyMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biology')),
      body: const Center(child: Text('Biology Menu Coming Soon')),
    );
  }
}
