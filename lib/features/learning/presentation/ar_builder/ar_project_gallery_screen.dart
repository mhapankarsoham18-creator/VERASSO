import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/empty_state_widget.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/learning/data/ar_project_repository.dart';

import '../../data/ar_project_model.dart';
import 'ar_circuit_builder_screen.dart';
import 'ar_project_viewer_screen.dart';

/// Project gallery showing saved and shared AR projects
class ArProjectGalleryScreen extends ConsumerStatefulWidget {
  /// Creates an [ArProjectGalleryScreen] instance.
  const ArProjectGalleryScreen({super.key});

  @override
  ConsumerState<ArProjectGalleryScreen> createState() =>
      _ArProjectGalleryScreenState();
}

class _ArProjectGalleryScreenState extends ConsumerState<ArProjectGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ArProject> _myProjects = [];
  List<SharedArProject> _sharedProjects = [];
  List<ArProject> _publicProjects = [];
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AR Project Gallery'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: _loadProjects,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'My Projects'),
            Tab(text: 'Shared'),
            Tab(text: 'Public'),
          ],
        ),
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyProjectsTab(),
                    _buildSharedProjectsTab(),
                    _buildPublicProjectsTab(),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ArCircuitBuilderScreen(),
            ),
          );
        },
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Project'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProjects();
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildMyProjectsTab() {
    if (_myProjects.isEmpty) {
      return const EmptyStateWidget(
        title: 'No projects yet',
        message: 'Create your first AR circuit and share it!',
        icon: LucideIcons.layers,
      );
    }

    return _buildProjectGrid(_myProjects
        .map((p) => _ProjectGridItem(
              project: p,
              onTap: () => _openProject(p),
              onDelete: () => _deleteProject(p),
            ))
        .toList());
  }

  Widget _buildProjectGrid(List<Widget> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          items[index].animate().fadeIn(delay: (index * 50).ms),
    );
  }

  Widget _buildPublicProjectsTab() {
    if (_publicProjects.isEmpty) {
      return _buildEmptyState(
        'No public projects',
        'Public projects from the community will appear here',
        LucideIcons.globe,
      );
    }

    return _buildProjectGrid(_publicProjects
        .map((p) => _ProjectGridItem(
              project: p,
              onTap: () => _viewPublicProject(p),
              showRemix: true,
              onRemix: () => _remixProject(p),
            ))
        .toList());
  }

  Widget _buildSharedProjectsTab() {
    if (_sharedProjects.isEmpty) {
      return const EmptyStateWidget(
        title: 'No shared projects',
        message: 'Projects shared by friends will appear here.',
        icon: LucideIcons.users,
      );
    }

    return _buildProjectGrid(_sharedProjects
        .map((sp) => _ProjectGridItem(
              project: sp.project,
              sharedBy: sp.sharedByUsername,
              onTap: () => _viewSharedProject(sp),
              showRemix: sp.canRemix,
              onRemix: () => _remixProject(sp.project),
            ))
        .toList());
  }

  Future<void> _deleteProject(ArProject project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to delete "${project.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(arProjectRepositoryProvider).deleteProject(project.id);
        _loadProjects();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting project: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(arProjectRepositoryProvider);

      final results = await Future.wait<dynamic>([
        repo.getUserProjects(),
        repo.getSharedProjects(),
        repo.getPublicProjects(),
      ]);

      if (mounted) {
        setState(() {
          _myProjects = results[0] as List<ArProject>;
          _sharedProjects = results[1] as List<SharedArProject>;
          _publicProjects = results[2] as List<ArProject>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load projects: $e')),
        );
      }
    }
  }

  void _openProject(ArProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArCircuitBuilderScreen(existingProject: project),
      ),
    );
  }

  Future<void> _remixProject(ArProject project) async {
    try {
      final remixed =
          await ref.read(arProjectRepositoryProvider).remixProject(project.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project remixed: ${remixed.title}')),
        );
        _loadProjects();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remix: $e')),
        );
      }
    }
  }

  void _viewPublicProject(ArProject project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArProjectViewerScreen(project: project),
      ),
    );
  }

  void _viewSharedProject(SharedArProject sharedProject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArProjectViewerScreen(project: sharedProject.project),
      ),
    );
  }
}

class _ProjectGridItem extends StatelessWidget {
  final ArProject project;
  final String? sharedBy;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool showRemix;
  final VoidCallback? onRemix;

  const _ProjectGridItem({
    required this.project,
    this.sharedBy,
    required this.onTap,
    this.onDelete,
    this.showRemix = false,
    this.onRemix,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: project.thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          project.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        ),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            const SizedBox(height: 8),

            // Title
            Text(
              project.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Info
            if (sharedBy != null)
              Text(
                'by $sharedBy',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),

            // Component count
            Text(
              '${project.components.length} components',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),

            const SizedBox(height: 8),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showRemix)
                  IconButton(
                    icon: const Icon(LucideIcons.copy, size: 16),
                    color: Colors.blueAccent,
                    onPressed: onRemix,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    color: Colors.redAccent,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        LucideIcons.box,
        size: 48,
        color: Colors.white24,
      ),
    );
  }
}
