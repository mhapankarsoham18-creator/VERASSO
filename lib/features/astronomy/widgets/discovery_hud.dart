import 'package:flutter/material.dart';
import '../rendering/pixel_palette.dart';

/// Small corner HUD showing discovery progress.
class DiscoveryHud extends StatelessWidget {
  final int discoveredCount;
  final int totalCount;

  const DiscoveryHud({
    super.key,
    required this.discoveredCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PixelPalette.skyBlack.withOpacity(0.7),
        border: Border.all(color: PixelPalette.hudDim, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔭', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            '$discoveredCount/$totalCount',
            style: const TextStyle(
              color: PixelPalette.hudText,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
