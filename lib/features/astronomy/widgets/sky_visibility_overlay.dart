import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../engine/sky_visibility.dart';
import '../rendering/pixel_palette.dart';

class SkyVisibilityOverlay extends StatelessWidget {
  final SkyVisibilityReport report;

  const SkyVisibilityOverlay({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    if (report.state == SkyViewState.skyVisible) {
      return SizedBox.shrink();
    }

    return IgnorePointer(
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 320),
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PixelPalette.skyBlack.withValues(alpha: 0.9),
            border: Border.all(color: PixelPalette.bubbleBorder, width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: PixelPalette.hudDim,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                report.title,
                style: GoogleFonts.pressStart2p(
                  textStyle: TextStyle(
                    color: PixelPalette.hudText,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                report.detail,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  border: Border.all(color: PixelPalette.hudDim),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: report.confidence.clamp(0.0, 1.0),
                  child: Container(color: PixelPalette.hudText),
                ),
              ),
              SizedBox(height: 8),
              Text(
                report.isEstimated ? 'MODE: ESTIMATED' : 'MODE: VERIFIED',
                style: TextStyle(
                  color: PixelPalette.hudDim,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
