import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic/presentation/academic_fusion_screen.dart';
import '../../avatar/presentation/avatar_screen.dart';
import '../../challenge/presentation/challenge_list_screen.dart';
import '../../collaboration/presentation/collaboration_screen.dart';
import '../../enterprise/presentation/enterprise_sync_screen.dart';
import '../../global/presentation/global_community_screen.dart';
import '../../multiplayer/presentation/code_duel_widget.dart';
import '../../multiplayer/presentation/collaboration_overlay.dart';
import '../../quest/presentation/quest_list_widget.dart';
import '../data/realm_repository.dart';
import 'widgets/realm_node.dart';

/// The main screen for the Odyssey Map, showing various realm nodes and navigational actions.
class OdysseyMapScreen extends ConsumerWidget {
  /// Optional background image for the map.
  final ImageProvider? backgroundImage;

  /// Creates an [OdysseyMapScreen] widget.
  const OdysseyMapScreen({super.key, this.backgroundImage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realms = ref.watch(realmRepositoryProvider).getRealms();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E), // Deep space/fantasy background
      body: Stack(
        children: [
          // Background - Placeholder for a rich map image
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image(
                image:
                    backgroundImage ??
                    const NetworkImage(
                      'https://placehold.co/1080x1920/1a1a2e/FFF.png?text=Map+Background', // Placeholder
                    ),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: Color(0xFF1E1E2E)),
              ),
            ),
          ),

          // Map Title
          Positioned(
            top: 60,
            left: 20,
            child: Text(
              'ODYSSEY MAP',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.5),
          ),

          // Top Buttons
          Positioned(
            top: 120,
            left: 20,
            right: 20,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MapActionButton(
                    icon: Icons.person,
                    label: 'AVATAR',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AvatarScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _MapActionButton(
                    icon: Icons.school,
                    label: 'ACADEMIC',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AcademicFusionScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  const CodeDuelWidget(),
                  const SizedBox(width: 16),
                  _MapActionButton(
                    icon: Icons.group,
                    label: 'COLLABORATE',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CollaborationScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _MapActionButton(
                    icon: Icons.business,
                    label: 'ENTERPRISE',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EnterpriseSyncScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _MapActionButton(
                    icon: Icons.public,
                    label: 'GLOBAL',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GlobalCommunityScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _MapActionButton(
                    icon: Icons.library_books,
                    label: 'CHALLENGES',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChallengeListScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Quest Button & Realm Nodes
          // Simplified layout: A vertical path for now
          Center(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                vertical: 180, // Increased to avoid top buttons
                horizontal: 40,
              ),
              itemCount: realms.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 60), // Path connector space
              itemBuilder: (context, index) {
                final realm = realms[index];
                return RealmNode(
                  realm: realm,
                  index: index,
                  onTap: () {
                    // Navigate to realm details
                    debugPrint('Tapped on ${realm.name}');
                  },
                );
              },
            ),
          ),

          // Side FABs
          Positioned(
            bottom: 30,
            left: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'quests',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => const QuestListWidget(),
                    );
                  },
                  child: const Icon(Icons.assignment),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'challenges',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChallengeListScreen(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.library_books,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ),

          // MESH Multiplayer Overlay
          const CollaborationOverlay(),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MapActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D44),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
