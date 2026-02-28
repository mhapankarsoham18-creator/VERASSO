import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../../../features/social/presentation/user_profile_screen.dart';
import '../../../data/astronomy_repository.dart';
import '../../../data/stargazing_model.dart';
import 'create_stargazing_log_screen.dart';

/// A screen that displays a community feed of stargazing logs.
class StargazingFeedScreen extends ConsumerStatefulWidget {
  /// Creates a [StargazingFeedScreen] instance.
  const StargazingFeedScreen({super.key});

  @override
  ConsumerState<StargazingFeedScreen> createState() =>
      _StargazingFeedScreenState();
}

class _StargazingFeedScreenState extends ConsumerState<StargazingFeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Community Logs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CreateStargazingLogScreen()));
          if (result == true) {
            setState(() {}); // Refresh feed
          }
        },
        label: const Text('Log Sighting'),
        icon: const Icon(LucideIcons.eye),
        backgroundColor: Colors.purpleAccent,
      ),
      body: LiquidBackground(
        child: FutureBuilder<List<StargazingLog>>(
          future: ref.read(astronomyRepositoryProvider).getCommunityLogs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final logs = snapshot.data ?? [];

            if (logs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.sparkle, size: 64, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                        'No one has looked up yet.\nBe the first to log a sighting!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                  top: 100, bottom: 80, left: 16, right: 16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return _buildLogCard(logs[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogCard(StargazingLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(userId: log.userId))),
                  child: CircleAvatar(
                    backgroundImage: log.creatorAvatar != null
                        ? NetworkImage(log.creatorAvatar!)
                        : null,
                    radius: 16,
                    child: log.creatorAvatar == null
                        ? const Icon(LucideIcons.user, size: 16)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(log.creatorName ?? 'Astronomer',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(LucideIcons.calendar,
                    size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  "${log.createdAt.day}/${log.createdAt.month}",
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            Row(
              children: [
                const Icon(LucideIcons.scanLine,
                    color: Colors.purpleAccent, size: 20),
                const SizedBox(width: 8),
                Text(log.celestialObject,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purpleAccent)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTag(LucideIcons.eye, log.equipmentType),
                const SizedBox(width: 8),
                _buildTag(LucideIcons.star, '${log.skyRating}/5 visibility'),
              ],
            ),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(log.notes!,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic)),
            ],
            if (log.locationName != null && log.locationName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.mapPin,
                      size: 12, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(log.locationName!,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }
}
