import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/list_skeleton.dart';

import '../../../auth/presentation/auth_controller.dart';
import '../../data/learning_models.dart';
import '../../data/study_repository.dart';

/// Future provider for fetching all shared learning resources.
final resourcesProvider = FutureProvider<List<LearningResource>>((ref) {
  return ref.watch(studyRepositoryProvider).getResources();
});

/// A screen that displays a library of shared learning resources.
class ResourceLibraryScreen extends ConsumerWidget {
  /// Creates a [ResourceLibraryScreen] instance.
  const ResourceLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourcesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Resource Library'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.upload),
            onPressed: () => _showUploadDialog(context, ref),
          ),
        ],
      ),
      body: LiquidBackground(
        child: resourcesAsync.when(
          data: (resources) {
            if (resources.isEmpty) {
              return const Center(
                  child: Text('No resources shared yet. Be the first!'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
              itemCount: resources.length,
              itemBuilder: (context, index) {
                final resource = resources[index];
                return _buildResourceCard(context, ref, resource);
              },
            );
          },
          loading: () => const ListSkeleton(),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildResourceCard(
      BuildContext context, WidgetRef ref, LearningResource resource) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.fileText, color: Colors.blueAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(resource.subject,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                if (resource.description != null)
                  Text(resource.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.externalLink,
                size: 18, color: Colors.white54),
            onPressed: () {
              if (resource.fileUrl != null) {
                launchUrl(Uri.parse(resource.fileUrl!));
              }
            },
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context, WidgetRef ref) {
    final titleC = TextEditingController();
    final subjectC = TextEditingController();
    final urlC = TextEditingController();
    final descC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Share Resource', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleC,
                decoration: const InputDecoration(
                    hintText: 'Title (e.g., Physics Summary)'),
                style: const TextStyle(color: Colors.white)),
            TextField(
                controller: subjectC,
                decoration: const InputDecoration(hintText: 'Subject'),
                style: const TextStyle(color: Colors.white)),
            TextField(
                controller: urlC,
                decoration:
                    const InputDecoration(hintText: 'Link (PDF or Drive)'),
                style: const TextStyle(color: Colors.white)),
            TextField(
                controller: descC,
                decoration:
                    const InputDecoration(hintText: 'Optional description'),
                style: const TextStyle(color: Colors.white),
                maxLines: 2),
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

              final newRes = LearningResource(
                id: '',
                userId: user.id,
                title: titleC.text,
                subject: subjectC.text,
                fileUrl: urlC.text,
                description: descC.text,
                createdAt: DateTime.now(),
              );

              await ref.read(studyRepositoryProvider).uploadResource(newRes);
              ref.invalidate(resourcesProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
