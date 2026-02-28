import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

/// A network image widget with local caching and shimmer loading effects.
///
/// Uses [CachedNetworkImage] for performance and [Shimmer] during the placeholder state.
class CachedImage extends StatelessWidget {
  /// The URL of the network image to load.
  final String imageUrl;

  /// Optional width for the image.
  final double? width;

  /// Optional height for the image.
  final double? height;

  /// How the image should be inscribed into the box.
  final BoxFit fit;

  /// The border radius applied to the image corners.
  final double borderRadius;

  /// Optional custom widget to display if the image fails to load.
  final Widget? errorWidget;

  /// Creates a [CachedImage].
  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade800,
          highlightColor: Colors.grey.shade700,
          child: Container(
            width: width,
            height: height,
            color: Colors.black,
          ),
        ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey.shade900,
              alignment: Alignment.center,
              child: const Icon(LucideIcons.imageOff, color: Colors.white54),
            ),
      ),
    );
  }
}
