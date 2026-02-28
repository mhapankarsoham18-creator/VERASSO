import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mentorship_repository.dart';
import '../domain/mentorship_model.dart';

/// Dashboard widget that manages and displays mentorship requests.
class MentorshipDashboard extends ConsumerWidget {
  /// Creates a [MentorshipDashboard] widget.
  const MentorshipDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(mentorshipProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'MENTORSHIP HUB',
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          if (requests.isEmpty)
            const Text(
              'No pending help requests.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          else
            ...requests.map((req) => _MentorshipRequestTile(request: req)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showRequestHelpDialog(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('REQUEST HELP'),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestHelpDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Describe your struggle',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g., Recursion in Python Plains',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(mentorshipProvider.notifier)
                  .requestHelp(controller.text);
              Navigator.pop(context);
            },
            child: const Text('SEND REQUEST'),
          ),
        ],
      ),
    );
  }
}

class _MentorshipRequestTile extends ConsumerWidget {
  final MentorshipRequest request;

  const _MentorshipRequestTile({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, size: 16, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.apprenticeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  request.topic,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          if (request.status == MentorshipStatus.pending &&
              request.apprenticeId != 'me')
            TextButton(
              onPressed: () => ref
                  .read(mentorshipProvider.notifier)
                  .acceptRequest(request.id),
              child: const Text(
                'HELP',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              request.status == MentorshipStatus.active ? 'ACTIVE' : 'SENT',
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
        ],
      ),
    );
  }
}
