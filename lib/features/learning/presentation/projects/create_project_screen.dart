import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/progress/services/progress_tracking_service.dart';

import '../../data/project_repository.dart';

/// A screen that allows users to create a new collaborative project.
class CreateProjectScreen extends ConsumerStatefulWidget {
  /// Creates a [CreateProjectScreen] instance.
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Start New Project'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: LiquidBackground(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 100),
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'Project Name (e.g. Weather App)',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Describe the goal of your team...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(LucideIcons.rocket),
                        label: const Text('Launch Team Workspace'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrangeAccent,
                            foregroundColor: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    if (_titleController.text.isEmpty) return;

    await ref.read(projectRepositoryProvider).createProject(
          leaderId: userId,
          title: _titleController.text,
          description: _descController.text,
        );

    // Hook: Log Activity
    try {
      await ProgressTrackingService().logActivity(
        userId: userId,
        activityType: 'created_project',
        activityCategory: 'building',
        metadata: {'title': _titleController.text},
      );
    } catch (e) {
      AppLogger.info('Error logging project creation: $e');
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
