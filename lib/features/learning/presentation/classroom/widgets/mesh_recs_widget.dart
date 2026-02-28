import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../services/mesh_recommendation_service.dart';

/// A widget that displays smart recommendations for learning resources based on the current subject,
/// fetched from the surrounding mesh network.
class MeshRecsWidget extends ConsumerWidget {
  /// The subject for which to fetch recommendations.
  final String currentSubject;

  /// Creates a [MeshRecsWidget] instance.
  const MeshRecsWidget({super.key, required this.currentSubject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref
        .read(meshRecommendationServiceProvider.notifier)
        .getRecommendations(currentSubject);

    if (recommendations.isEmpty) {
      return Container(); // Hide if no recs
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.sparkles, color: Colors.amberAccent, size: 20),
            SizedBox(width: 8),
            Text(
              "Smart Mesh Suggestions",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              return GlassContainer(
                margin: const EdgeInsets.only(right: 12),
                width: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.bookOpen, color: Colors.blueAccent),
                    const SizedBox(height: 8),
                    Text(
                      recommendations[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Request via Mesh",
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: (index * 100).ms)
                  .slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }
}
