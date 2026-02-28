import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/ui/glass_container.dart';
import '../../../core/ui/liquid_background.dart';
import '../data/group_service.dart';
import '../models/group_models.dart';
import 'group_chat_screen.dart';

/// Screen showcasing the list of available collaborative study [Group]s.
class GroupsScreen extends ConsumerStatefulWidget {
  /// Creates a [GroupsScreen] instance.
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupCard extends ConsumerWidget {
  final Group group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupService = ref.watch(groupServiceProvider);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupChatScreen(group: group),
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: group.avatarUrl != null
                  ? NetworkImage(group.avatarUrl!)
                  : null,
              child: group.avatarUrl == null
                  ? const Icon(LucideIcons.users)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (group.isPrivate) ...[
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.lock,
                            size: 14, color: Colors.white70),
                      ],
                    ],
                  ),
                  if (group.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      group.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${group.memberCount} members',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<GroupMember?>(
              future: groupService.getUserMembership(group.id),
              builder: (context, snapshot) {
                final isMember = snapshot.data != null;

                return ElevatedButton(
                  onPressed: () async {
                    try {
                      if (isMember) {
                        await groupService.leaveGroup(group.id);
                      } else {
                        await groupService.joinGroup(group.id);
                      }
                      // Trigger rebuild
                      (context as Element).markNeedsBuild();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMember ? Colors.red : Colors.green,
                  ),
                  child: Text(isMember ? 'Leave' : 'Join'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final groupService = ref.watch(groupServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: _showCreateGroupDialog,
          ),
        ],
      ),
      body: LiquidBackground(
        child: FutureBuilder<List<Group>>(
          future: groupService.getGroups(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final groups = snapshot.data!;

            if (groups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.users,
                        size: 64, color: Colors.white38),
                    const SizedBox(height: 16),
                    const Text(
                      'No groups yet',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showCreateGroupDialog,
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Create Group'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                  top: 100, left: 16, right: 16, bottom: 20),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return _GroupCard(group: groups[index]);
              },
            );
          },
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter description (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Private Group'),
                value: isPrivate,
                onChanged: (value) =>
                    setState(() => isPrivate = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                try {
                  final service = ref.read(groupServiceProvider);
                  await service.createGroup(
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    isPrivate: isPrivate,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {}); // Refresh list
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
