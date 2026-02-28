import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../auth/presentation/auth_controller.dart';
import '../../../learning/data/project_repository.dart'; // To select which team to apply with
import '../../data/internship_repository.dart';
import '../../data/job_model.dart';
import 'contract_screen.dart'; // Will create next

/// Screen allowing users to browse and search for internship opportunities.
class InternshipFinderScreen extends ConsumerWidget {
  /// Creates an [InternshipFinderScreen].
  const InternshipFinderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Virtual Internships'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: LiquidBackground(
        child: SafeArea(
          child: FutureBuilder<List<JobRequest>>(
            future:
                ref.read(internshipRepositoryProvider).getInternshipListings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No active internship offers.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final job = snapshot.data![index];
                  return _buildInternshipCard(context, job);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInternshipCard(BuildContext context, JobRequest job) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                  backgroundImage: job.clientAvatar != null
                      ? NetworkImage(job.clientAvatar!)
                      : null,
                  radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(job.clientName ?? 'Unknown Company',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('INTERNSHIP',
                    style: TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(job.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(LucideIcons.banknote,
                  size: 16, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Text('${job.currency} ${job.budget} / project',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _showTeamSelectionDialog(context, job),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black),
                child: const Text('Apply as Team'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTeamSelectionDialog(BuildContext context, JobRequest job) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          return AlertDialog(
            title: const Text('Select Your Team'),
            content: SizedBox(
              width: double.maxFinite,
              child: FutureBuilder(
                future: () async {
                  final userId = ref.read(currentUserProvider)?.id;
                  if (userId == null) return [];
                  return ref
                      .read(projectRepositoryProvider)
                      .getMyProjects(userId);
                }(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final projects = snapshot.data as List;
                  if (projects.isEmpty) {
                    return const Text(
                        'You need to create a project team first!');
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      return ListTile(
                        title: Text(project.title),
                        subtitle: Text('${project.memberCount} members'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ContractScreen(
                                      job: job,
                                      projectId: project.id,
                                      projectName: project.title)));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
