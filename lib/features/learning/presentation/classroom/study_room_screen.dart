import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/learning/data/collaboration_models.dart';
import 'package:verasso/features/learning/data/collaboration_repository.dart';

/// Provider for the [CollaborationRepository].
final collaborationRepositoryProvider =
    Provider((ref) => CollaborationRepository());

/// Provider for real-time live sessions within a specific study group.
final liveSessionsProvider =
    StreamProvider.family<List<StudyRoomSession>, String>((ref, groupId) {
  return ref.watch(collaborationRepositoryProvider).watchLiveSessions(groupId);
});

/// A screen representing a physical or virtual study room for a group.
class StudyRoomScreen extends ConsumerWidget {
  /// Unique identifier of the study group.
  final String groupId;

  /// Display name of the study group.
  final String groupName;

  /// Creates a [StudyRoomScreen] instance.
  const StudyRoomScreen(
      {super.key, required this.groupId, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(liveSessionsProvider(groupId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('$groupName Room'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.sparkles),
            tooltip: 'Start Live Session',
            onPressed: () => _startSession(context, ref),
          ),
        ],
      ),
      body: LiquidBackground(
        child: sessionsAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.volumeX,
                        size: 64, color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text('No live study rooms yet.',
                        style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _startSession(context, ref),
                      child: const Text('Initiate Study Session'),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildSessionCard(context, ref, session);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildPinnedChip(dynamic res) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.fileText, size: 12, color: Colors.blueAccent),
          const SizedBox(width: 6),
          Text(res.toString(),
              style: const TextStyle(fontSize: 11, color: Colors.blueAccent)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
      BuildContext context, WidgetRef ref, StudyRoomSession session) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(session.title ?? 'Interactive Study',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4)),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Colors.redAccent),
                    SizedBox(width: 6),
                    Text('LIVE',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${session.activeUsers.length} students currently collaborating',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Divider(color: Colors.white10, height: 32),
          const Text('Pinned Resources',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent)),
          const SizedBox(height: 12),
          if (session.pinnedResources.isEmpty)
            const Text('No resources pinned yet.',
                style: TextStyle(color: Colors.white24, fontSize: 12))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.pinnedResources
                  .map((res) => _buildPinnedChip(res))
                  .toList(),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pinAResource(context, ref, session.id),
                  icon: const Icon(LucideIcons.pin, size: 16),
                  label: const Text('Pin Knowledge'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {}, // Enter interactive mode
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  child: const Text('Join Room'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _pinAResource(
      BuildContext context, WidgetRef ref, String sessionId) async {
    // For demo, we just pin a random text
    await ref
        .read(collaborationRepositoryProvider)
        .pinResource(sessionId, "Formula Sheet V1");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource pinned to room!')));
    }
  }

  void _startSession(BuildContext context, WidgetRef ref) {
    final titleC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Start Study Session'),
        content: TextField(
            controller: titleC,
            decoration: const InputDecoration(
                hintText: 'e.g., Quantum Physics Exam Prep'),
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(collaborationRepositoryProvider)
                  .createSession(groupId, titleC.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Launch'),
          ),
        ],
      ),
    );
  }
}
