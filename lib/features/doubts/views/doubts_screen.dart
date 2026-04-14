import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';

class DoubtsScreen extends ConsumerWidget {
  const DoubtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: const Text('DOUBTS NETWORK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Center(
        child: NeoPixelBox(
          padding: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.help_center, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Doubts Frequency is currently empty.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Submit a doubt to bounce signals\noff available Mentors.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
      floatingActionButton: NeoPixelBox(
        padding: 16,
        isButton: true,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doubt protocol initializing...')));
        },
        child: const Icon(Icons.radar, color: AppColors.primary),
      ),
    );
  }
}
