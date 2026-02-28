import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/empty_state_widget.dart';
import 'package:verasso/core/ui/error_state_widget.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../data/challenge_model.dart';
import '../../data/challenge_repository.dart';

/// A screen for reviewing and approving/rejecting submissions for a specific challenge.
class ChallengeSubmissionsReviewScreen extends ConsumerWidget {
  /// Unique identifier of the challenge being reviewed.
  final String challengeId;

  /// Display title of the challenge.
  final String challengeTitle;

  /// Creates a [ChallengeSubmissionsReviewScreen] instance.
  const ChallengeSubmissionsReviewScreen({
    super.key,
    required this.challengeId,
    required this.challengeTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Review Submissions - $challengeTitle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: FutureBuilder<List<ChallengeSubmission>>(
          future: ref
              .read(challengeRepositoryProvider)
              .getSubmissionsForChallenge(challengeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ErrorStateWidget(
                title: 'Error Loading Submissions',
                message: 'Failed to load submissions. Please try again.',
                onRetry: () {
                  // Trigger rebuild by invalidating the future
                },
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const EmptyStateWidget(
                title: 'No Submissions Yet',
                message: 'Submissions will appear here as participants join.',
                icon: LucideIcons.inbox,
              );
            }

            final submissions = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.only(
                  top: 100, bottom: 80, left: 16, right: 16),
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                return _buildSubmissionCard(
                  context,
                  ref,
                  submissions[index],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _approveSubmission(
      WidgetRef ref, ChallengeSubmission submission) async {
    try {
      await ref.read(challengeRepositoryProvider).reviewSubmission(
          submission.id, 'Approved',
          feedback: 'Great work! Your submission has been approved.');

      // Show success message
    } catch (e) {
      // Show error message
    }
  }

  Widget _buildStatusBadge(String status) {
    late Color badgeColor;
    late IconData badgeIcon;

    switch (status) {
      case 'Approved':
        badgeColor = Colors.greenAccent;
        badgeIcon = LucideIcons.check;
        break;
      case 'Rejected':
        badgeColor = Colors.redAccent;
        badgeIcon = LucideIcons.x;
        break;
      case 'Pending':
      default:
        badgeColor = Colors.orangeAccent;
        badgeIcon = LucideIcons.clock;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    WidgetRef ref,
    ChallengeSubmission submission,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Submitter Info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: submission.userAvatar != null
                      ? NetworkImage(submission.userAvatar!)
                      : null,
                  radius: 16,
                  child: submission.userAvatar == null
                      ? const Icon(LucideIcons.user, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.userName ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        submission.submittedAt.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(submission.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),

            // Submission Content URL
            if (submission.contentUrl != null) ...[
              const Text(
                'Submission Link',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  // In a real app, you'd open the URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Opening: ${submission.contentUrl}')),
                  );
                },
                child: Text(
                  submission.contentUrl!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Feedback
            if (submission.feedback != null &&
                submission.feedback!.isNotEmpty) ...[
              const Text(
                'Feedback',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 4),
              Text(
                submission.feedback!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (submission.isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showRejectDialog(context, ref, submission),
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveSubmission(ref, submission),
                      icon: const Icon(LucideIcons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  'Status: ${submission.status}',
                  style: TextStyle(
                    fontSize: 13,
                    color: submission.isApproved
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    ChallengeSubmission submission,
  ) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Reject Submission',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add feedback for the user (optional):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Explain why this was rejected...',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(challengeRepositoryProvider).reviewSubmission(
                    submission.id,
                    'Rejected',
                    feedback: feedbackController.text.isNotEmpty
                        ? feedbackController.text
                        : null,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Submission rejected.')),
                );
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
