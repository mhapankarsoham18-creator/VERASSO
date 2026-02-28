import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/list_skeleton.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/learning/data/learning_models.dart';
import 'package:verasso/features/learning/data/study_repository.dart';
import 'package:verasso/features/learning/presentation/classroom/study_room_screen.dart';

/// Provider for the list of available study groups.
final studyGroupsProvider = FutureProvider<List<StudyGroup>>((ref) {
  return ref.watch(studyRepositoryProvider).getStudyGroups();
});

/// A screen for browsing and joining peer study groups.
class StudyGroupsScreen extends ConsumerWidget {
  /// Creates a [StudyGroupsScreen] instance.
  const StudyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(studyGroupsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Study Groups'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showCreateGroupDialog(context, ref),
          ),
        ],
      ),
      body: LiquidBackground(
        child: groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return const Center(
                  child: Text('No study groups found. Create one!'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _buildGroupCard(context, ref, group);
              },
            );
          },
          loading: () => const ListSkeleton(),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildGroupCard(
      BuildContext context, WidgetRef ref, StudyGroup group) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                group.avatarUrl != null ? NetworkImage(group.avatarUrl!) : null,
            child: group.avatarUrl == null
                ? const Icon(LucideIcons.users, size: 24)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(group.subject,
                    style: TextStyle(
                        color: Colors.blueAccent.withValues(alpha: 0.8),
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text(group.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              ElevatedButton(
                onPressed: () => _joinGroup(context, ref, group),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.blueAccent,
                ),
                child: const Text('Join'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => StudyRoomScreen(
                        groupId: group.id, groupName: group.name),
                  ));
                },
                child: const Text('Enter Room', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _joinGroup(BuildContext context, WidgetRef ref, StudyGroup group) async {
    await ref.read(studyRepositoryProvider).joinGroup(group.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${group.name}!')),
      );
    }
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameC = TextEditingController();
    final subjectC = TextEditingController();
    final descC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Create Study Group',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameC,
                decoration: const InputDecoration(hintText: 'Group Name'),
                style: const TextStyle(color: Colors.white)),
            TextField(
                controller: subjectC,
                decoration: const InputDecoration(hintText: 'Subject'),
                style: const TextStyle(color: Colors.white)),
            TextField(
                controller: descC,
                decoration: const InputDecoration(hintText: 'Description'),
                style: const TextStyle(color: Colors.white),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user == null) return;

              final newGroup = StudyGroup(
                id: '',
                name: nameC.text,
                subject: subjectC.text,
                description: descC.text,
                creatorId: user.id,
                createdAt: DateTime.now(),
              );

              await ref
                  .read(studyRepositoryProvider)
                  .createStudyGroup(newGroup);
              ref.invalidate(studyGroupsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
