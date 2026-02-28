import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../notifications/data/notification_service.dart';
import '../../notifications/models/notification_model.dart';
import '../data/job_model.dart';
import '../data/job_repository.dart';

/// Provider that fetches job requests created by the current user.
final myJobsProvider = FutureProvider<List<JobRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(jobRepositoryProvider).getMyJobRequests(user.id);
});

/// Widget to display and manage applications for a specific job.
class JobApplicationsView extends ConsumerWidget {
  /// The job for which applications are being viewed.
  final JobRequest job;

  /// Creates a [JobApplicationsView].
  const JobApplicationsView({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(FutureProvider((ref) =>
        ref.watch(jobRepositoryProvider).getApplicationsForJob(job.id)));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Applications for ${job.title}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: appsAsync.when(
                data: (apps) {
                  if (apps.isEmpty) {
                    return const Center(child: Text('No applications yet.'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return _buildApplicationItem(context, ref, app);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AppErrorView(
                  message: e.toString(),
                  onRetry: () => ref.refresh(FutureProvider((ref) => ref
                      .read(jobRepositoryProvider)
                      .getApplicationsForJob(job.id))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptApp(WidgetRef ref, JobApplication app) async {
    await ref
        .read(jobRepositoryProvider)
        .updateApplicationStatus(app.id, 'accepted');
    await ref
        .read(jobRepositoryProvider)
        .updateJobStatus(job.id, 'in_progress');

    // Trigger notification
    await ref.read(notificationServiceProvider).createNotification(
      targetUserId: app.talentId,
      title: 'Application Accepted!',
      body:
          'Pack your bags! Your application for "${job.title}" has been accepted.',
      type: NotificationType.job,
      data: {'jobId': job.id},
    );

    ref.invalidate(myJobsProvider);
  }

  Widget _buildApplicationItem(
      BuildContext context, WidgetRef ref, JobApplication app) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: 'Applicant avatar',
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: app.talentAvatar != null
                      ? NetworkImage(app.talentAvatar!)
                      : null,
                  child: app.talentAvatar == null
                      ? const Icon(LucideIcons.user, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(app.talentName ?? 'Talent',
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              _buildStatusBadge(app.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(app.message ?? 'No message provided.',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (app.status == 'pending' && job.status == 'open') ...[
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _updateApp(ref, app.id, 'rejected'),
                  child: const Text('Reject',
                      style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _acceptApp(ref, app),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  child: Text(AppLocalizations.of(context)!.confirm),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'accepted'
        ? Colors.green
        : (status == 'rejected' ? Colors.red : Colors.orange);
    return Text(status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold));
  }

  Future<void> _updateApp(WidgetRef ref, String appId, String status) async {
    await ref
        .read(jobRepositoryProvider)
        .updateApplicationStatus(appId, status);

    // Trigger notification
    if (status == 'rejected') {
      final apps =
          await ref.read(jobRepositoryProvider).getApplicationsForJob(job.id);
      final app = apps.firstWhere((a) => a.id == appId);
      await ref.read(notificationServiceProvider).createNotification(
        targetUserId: app.talentId,
        title: 'Application Update',
        body: 'Your application for "${job.title}" was not selected.',
        type: NotificationType.job,
        data: {'jobId': job.id},
      );
    }

    ref.invalidate(myJobsProvider); // Refresh
  }
}

/// Screen displaying the list of jobs posted by the current user.
class MyJobsScreen extends ConsumerWidget {
  /// Creates a [MyJobsScreen].
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myJobsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Job Postings'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: jobsAsync.when(
          data: (jobs) {
            if (jobs.isEmpty) {
              return const Center(
                  child: Text('You haven\'t posted any jobs yet.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _buildJobItem(context, ref, job);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(myJobsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildJobItem(BuildContext context, WidgetRef ref, JobRequest job) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(job.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              _buildStatusBadge(job.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(job.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70)),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${job.budget} ${job.currency}',
                  style: const TextStyle(
                      color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  if (job.status == 'in_progress')
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: () => _completeJob(context, ref, job),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.greenAccent.withValues(alpha: 0.2),
                            foregroundColor: Colors.greenAccent),
                        child: const Text('Complete'),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () => _showApplications(context, job),
                    icon: const Icon(LucideIcons.users, size: 16),
                    label: const Text('Applications'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'open':
        color = Colors.green;
        break;
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _completeJob(
      BuildContext context, WidgetRef ref, JobRequest job) async {
    // 1. Get the accepted application to find the talent
    final apps =
        await ref.read(jobRepositoryProvider).getApplicationsForJob(job.id);
    final acceptedApp = apps.firstWhere((a) => a.status == 'accepted');

    // 3. Trigger Notification to talent
    await ref.read(notificationServiceProvider).createNotification(
      targetUserId: acceptedApp.talentId,
      title: 'Job Completed!',
      body:
          'Your job "${job.title}" has been marked as complete by the client.',
      type: NotificationType.job,
      data: {'jobId': job.id},
    );

    // 4. Show review dialog
    if (context.mounted) {
      _showReviewDialog(context, ref, job, acceptedApp.talentId);
    }

    ref.invalidate(myJobsProvider);
  }

  void _showApplications(BuildContext context, JobRequest job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => JobApplicationsView(job: job),
    );
  }

  void _showReviewDialog(
      BuildContext context, WidgetRef ref, JobRequest job, String talentId) {
    int rating = 5;
    final commentC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
              const Text('Rate Talent', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    5,
                    (i) => IconButton(
                          icon: Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber),
                          tooltip: 'Rate ${i + 1} stars',
                          onPressed: () => setState(() => rating = i + 1),
                        )),
              ),
              TextField(
                controller: commentC,
                maxLines: 3,
                decoration:
                    const InputDecoration(hintText: 'Leave a comment...'),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(jobRepositoryProvider).submitReview(JobReview(
                      id: '', // Will be generated
                      jobId: job.id,
                      reviewerId: ref.read(userProfileProvider).value!.id,
                      revieweeId: talentId,
                      rating: rating,
                      comment: commentC.text,
                      createdAt: DateTime.now(),
                    ));

                // Trigger Notification to talent
                await ref.read(notificationServiceProvider).createNotification(
                  targetUserId: talentId,
                  title: 'New Review Received',
                  body:
                      'You received a $rating-star review for "${job.title}".',
                  type: NotificationType.job,
                  data: {'jobId': job.id},
                );

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
