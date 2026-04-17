import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PixelPalette.skyBlack.withValues(alpha: 0.7),
        border: Border.all(color: PixelPalette.hudDim, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔭', style: TextStyle(fontSize: 10)),
          SizedBox(width: 6),
          Text(
            '$discoveredCount/$totalCount',
            style: GoogleFonts.pressStart2p(
              textStyle: TextStyle(
                color: PixelPalette.hudText,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              )
            ),
          ),
        ],
      ),
    );
  }
}
