import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/celestial_object.dart';
import '../rendering/pixel_palette.dart';

/// Pixel-art speech bubble anchored to a celestial object.
class SkyChatBubble extends StatelessWidget {
  final CelestialObject object;
  final double screenWidth;
  final VoidCallback onTap;
  final VoidCallback onAskMore;

  const SkyChatBubble({
    super.key,
    required this.object,
    required this.screenWidth,
    required this.onTap,
    required this.onAskMore,
  });

  @override
  Widget build(BuildContext context) {
    // Determine bubble position: left or right of object
    final bool showLeft = object.screenX > screenWidth / 2;
    final double bubbleWidth = 220;

    final double left = showLeft
        ? object.screenX - bubbleWidth - 20
        : object.screenX + 20;

    return Positioned(
      left: left.clamp(8, screenWidth - bubbleWidth - 8),
      top: (object.screenY - 60).clamp(8, double.infinity),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: bubbleWidth,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PixelPalette.bubbleBg,
            border: Border.all(color: PixelPalette.bubbleBorder, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: emoji + name
              Row(
                children: [
                  Text(
                    object.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      object.name.toUpperCase(),
                      style: const TextStyle(
                        color: PixelPalette.hudText,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 2),

              // Type label
              Text(
                object.typeLabel,
                style: TextStyle(
                  color: PixelPalette.hudText.withOpacity(0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 8),

              // Description (1-2 lines)
              Text(
                object.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 8),

              // Stats row
              Row(
                children: [
                  if (object.distanceLy > 0)
                    _statChip('${_formatDistance(object.distanceLy)} LY'),
                  if (object.constellation.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _statChip(object.constellation),
                  ],
                  const SizedBox(width: 6),
                  _statChip('mag ${object.magnitude.toStringAsFixed(1)}'),
                ],
              ),

              const SizedBox(height: 8),

              // "Ask more..." button
              GestureDetector(
                onTap: onAskMore,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: PixelPalette.hudText.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 12, color: PixelPalette.hudText),
                      const SizedBox(width: 6),
                      Text(
                        'ASK MORE...',
                        style: TextStyle(
                          color: PixelPalette.hudText,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: PixelPalette.hudDim, width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: PixelPalette.hudDim,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatDistance(double ly) {
    if (ly < 0.01) return '${(ly * 63241).toStringAsFixed(0)} AU';
    if (ly < 1) return '${(ly * 63241).toStringAsFixed(0)} AU';
    if (ly >= 1000) return '${(ly / 1000).toStringAsFixed(1)}K';
    return ly.toStringAsFixed(1);
  }
}
