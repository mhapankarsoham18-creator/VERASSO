import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/exceptions/user_friendly_error_handler.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

import '../data/job_model.dart';
import '../data/job_repository.dart';

/// Provider that fetches job applications submitted by the current user.
final myApplicationsProvider = FutureProvider<List<JobApplication>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(jobRepositoryProvider).getSentApplications(user.id);
});

/// Screen displaying the status of job applications sent by the user.
class MyApplicationsScreen extends ConsumerWidget {
  /// Creates a [MyApplicationsScreen].
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Applications'),
        backgroundColor: Colors.transparent,
      ),
      body: LiquidBackground(
        child: appsAsync.when(
          data: (apps) {
            if (apps.isEmpty) {
              return const Center(
                  child: Text('You haven\'t applied for any jobs yet.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return _buildApplicationItem(context, app);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorView(
            message: UserFriendlyErrorHandler.getDisplayMessage(e),
            onRetry: () => ref.invalidate(myApplicationsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationItem(BuildContext context, JobApplication app) {
    Color statusColor;
    switch (app.status) {
      case 'accepted':
        statusColor = Colors.greenAccent;
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.orangeAccent;
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.jobTitle ?? 'Job Request',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Applied on ${_formatDate(app.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  app.status.toUpperCase(),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'My Message:',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            app.message ?? 'No message provided.',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          if (app.status == 'accepted') ...[
            const Divider(color: Colors.white10, height: 24),
            const Row(
              children: [
                Icon(LucideIcons.checkCircle2,
                    size: 16, color: Colors.greenAccent),
                SizedBox(width: 8),
                Text('You have been selected! Check your chat.',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
