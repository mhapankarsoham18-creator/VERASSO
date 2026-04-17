import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';

class DoubtsScreen extends ConsumerWidget {
  const DoubtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('DOUBTS NETWORK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
      ),
      body: Center(
        child: NeoPixelBox(
          padding: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_center, size: 64, color: context.colors.primary),
              SizedBox(height: 16),
              Text('Doubts Frequency is currently empty.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 8),
              Text('Submit a doubt to bounce signals\noff available Mentors.', textAlign: TextAlign.center, style: TextStyle(color: context.colors.textSecondary)),
            ],
          ),
        ),
      ),
      floatingActionButton: NeoPixelBox(
        padding: 16,
        isButton: true,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Doubt protocol initializing...')));
        },
        child: Icon(Icons.radar, color: context.colors.primary),
      ),
    );
  }
}
