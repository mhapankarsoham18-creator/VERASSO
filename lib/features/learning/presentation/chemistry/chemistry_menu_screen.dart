import 'package:flutter/material.dart';

/// Menu screen for selecting chemistry-related simulations and educational content.
class ChemistryMenuScreen extends StatelessWidget {
  /// Creates a [ChemistryMenuScreen] instance.
  const ChemistryMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chemistry')),
      body: const Center(child: Text('Chemistry Menu Coming Soon')),
    );
  }
}
