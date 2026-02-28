import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/course_skeleton.dart';

import '../../../auth/presentation/auth_controller.dart';
import '../../data/project_model.dart';
import '../../data/project_repository.dart';
import 'create_project_screen.dart';
import 'project_workspace_screen.dart';

/// A central hub for managing and discovering collaborative projects.
class ProjectHubScreen extends ConsumerStatefulWidget {
  /// Creates a [ProjectHubScreen] instance.
  const ProjectHubScreen({super.key});

  @override
  ConsumerState<ProjectHubScreen> createState() => _ProjectHubScreenState();
}

class _ProjectHubScreenState extends ConsumerState<ProjectHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Project Hub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepOrangeAccent,
          tabs: const [
            Tab(text: 'My Projects'),
            Tab(text: 'Team Finder'),
            Tab(text: 'Showcase'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateProjectScreen())),
        label: const Text('New Project'),
        icon: const Icon(LucideIcons.rocket),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: LiquidBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildMyProjectsList(),
            _buildTeamFinder(), // Placeholder for now or reusing showcase logic for open teams
            _buildShowcaseList(),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Widget _buildMyProjectsList() {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const Center(child: Text('Please log in.'));

    return FutureBuilder<List<Project>>(
      future: ref.read(projectRepositoryProvider).getMyProjects(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CourseSkeleton();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('You are not part of any active team.',
                  style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(top: 100, bottom: 80, left: 16, right: 16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildProjectCard(snapshot.data![index], isMyProject: true);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(Project project, {required bool isMyProject}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: project.leaderAvatar != null
                      ? NetworkImage(project.leaderAvatar!)
                      : null,
                  radius: 12,
                  child: project.leaderAvatar == null
                      ? const Icon(LucideIcons.user, size: 12)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(project.leaderName ?? 'Lead',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70)),
                const Spacer(),
                if (project.status == 'Shipped')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('Shipped',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(project.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(project.description,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isMyProject) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProjectWorkspaceScreen(
                                projectId: project.id,
                                projectTitle: project.title)));
                  } else {
                    // View Details logic
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isMyProject ? Colors.blueAccent : Colors.white10),
                child: Text(isMyProject ? 'Enter Workspace' : 'View Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowcaseList() {
    return FutureBuilder<List<Project>>(
      future: ref.read(projectRepositoryProvider).getShippedProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CourseSkeleton();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No shipped projects yet.',
                  style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(top: 100, bottom: 80, left: 16, right: 16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildProjectCard(snapshot.data![index], isMyProject: false);
          },
        );
      },
    );
  }

  Widget _buildTeamFinder() {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return const Center(child: Text('Please log in.'));

    return FutureBuilder<List<Project>>(
      future: ref.read(projectRepositoryProvider).getOpenProjects(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CourseSkeleton();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.search, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text('No Open Teams',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('All teams are full right now.',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(top: 100, bottom: 80, left: 16, right: 16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final project = snapshot.data![index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: project.leaderAvatar != null
                              ? NetworkImage(project.leaderAvatar!)
                              : null,
                          radius: 16,
                          child: project.leaderAvatar == null
                              ? const Icon(LucideIcons.user, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(project.leaderName ?? 'Team Lead',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white70)),
                              Text(project.title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(project.status,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showJoinDialog(project, userId),
                        icon: const Icon(LucideIcons.userPlus, size: 16),
                        label: const Text('Request to Join'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showJoinDialog(Project project, String userId) {
    String selectedRole = 'Developer';
    final roles = ['Developer', 'Designer', 'Researcher', 'Tester', 'Writer'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text('Join "${project.title}"',
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select your role:',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ...roles.map((role) => ListTile(
                    title:
                        Text(role, style: const TextStyle(color: Colors.white)),
                    leading: Radio<String>(
                      value: role,
                      // ignore: deprecated_member_use
                      groupValue: selectedRole,
                      activeColor: Colors.deepOrangeAccent,
                      // ignore: deprecated_member_use
                      onChanged: (val) =>
                          setDialogState(() => selectedRole = val!),
                    ),
                    onTap: () => setDialogState(() => selectedRole = role),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref
                    .read(projectRepositoryProvider)
                    .joinProject(project.id, userId, selectedRole);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Joined "${project.title}" as $selectedRole! 🚀'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {}); // Refresh
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent),
              child: const Text('Join Team'),
            ),
          ],
        ),
      ),
    );
  }
}
