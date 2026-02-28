import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../data/project_model.dart';
import '../../data/project_repository.dart';

/// A collaborative workspace screen for a specific project, featuring a Kanban board for tasks.
class ProjectWorkspaceScreen extends ConsumerStatefulWidget {
  /// The unique identifier of the project.
  final String projectId;

  /// The title of the project.
  final String projectTitle;

  /// Creates a [ProjectWorkspaceScreen] instance.
  const ProjectWorkspaceScreen(
      {super.key, required this.projectId, required this.projectTitle});

  @override
  ConsumerState<ProjectWorkspaceScreen> createState() =>
      _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState
    extends ConsumerState<ProjectWorkspaceScreen> {
  // Simplified Kanban state for demo
  // In a real app, this would be managed by a more complex provider syncing with Supabase realtime

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.projectTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquare),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project Chat coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<ProjectTask>>(
                  future: ref
                      .read(projectRepositoryProvider)
                      .getTasks(widget.projectId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final tasks = snapshot.data!;
                    final todo =
                        tasks.where((t) => t.status == 'Todo').toList();
                    final doing =
                        tasks.where((t) => t.status == 'Doing').toList();
                    final done =
                        tasks.where((t) => t.status == 'Done').toList();

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildKanbanColumn('To Do', Colors.redAccent, todo),
                        const SizedBox(width: 16),
                        _buildKanbanColumn('In Progress', Colors.amber, doing),
                        const SizedBox(width: 16),
                        _buildKanbanColumn('Done', Colors.greenAccent, done),
                      ],
                    );
                  },
                ),
              ),
              _buildQuickAdd(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(
      String title, Color color, List<ProjectTask> tasks) {
    return SizedBox(
      width: 280,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        color: Colors.white.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.circle, size: 12, color: color),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${tasks.length}',
                    style: const TextStyle(color: Colors.white54)),
              ],
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (task.assigneeAvatar != null)
                              CircleAvatar(
                                  radius: 8,
                                  backgroundImage:
                                      NetworkImage(task.assigneeAvatar!))
                            else
                              const CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Colors.white24,
                                  child: Icon(LucideIcons.user, size: 10)),
                          ],
                        ),
                        if (task.status != 'Done')
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final newStatus = task.status == 'Todo'
                                        ? 'Doing'
                                        : 'Done';
                                    await ref
                                        .read(projectRepositoryProvider)
                                        .updateTaskStatus(task.id, newStatus);
                                    setState(() {}); // Refresh UI
                                  },
                                  icon: const Icon(LucideIcons.arrowRight,
                                      size: 14),
                                  label: Text(
                                      task.status == 'Todo'
                                          ? 'Start Task'
                                          : 'Complete',
                                      style: const TextStyle(fontSize: 11)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: task.status == 'Todo'
                                        ? Colors.blueAccent
                                        : Colors.greenAccent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.05),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn().scale();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAdd() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black45,
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            hintText: '+ Add a task to this project...',
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white10,
            suffixIcon: IconButton(
              icon: const Icon(LucideIcons.plus, color: Colors.blueAccent),
              onPressed: () {
                // Quick add logic
              },
            )),
        onSubmitted: (value) async {
          if (value.isNotEmpty) {
            await ref
                .read(projectRepositoryProvider)
                .createTask(widget.projectId, value);
            setState(() {});
          }
        },
      ),
    );
  }
}
