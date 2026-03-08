import 'package:flutter/material.dart';

/// Stubbed ArLabScreen (multiplayer removed).
class ArLabScreen extends StatelessWidget {
  const ArLabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AR Lab")),
      body: const Center(
        child: Text("AR Lab is currently unavailable in single-player mode."),
      ),
    );
  }
}
