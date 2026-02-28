import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/data/user_profile_model.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';
import 'package:verasso/features/social/data/alumni_repository.dart';

/// Provider that fetches the list of alumni mentors.
final alumniMentorsProvider = FutureProvider<List<UserProfile>>((ref) {
  return ref.watch(alumniRepositoryProvider).getAlumniMentors();
});

/// Screen displaying the directory of alumni mentors.
class AlumniNetworkScreen extends ConsumerStatefulWidget {
  /// Creates an [AlumniNetworkScreen] instance.
  const AlumniNetworkScreen({super.key});

  @override
  ConsumerState<AlumniNetworkScreen> createState() =>
      _AlumniNetworkScreenState();
}

class _AlumniNetworkScreenState extends ConsumerState<AlumniNetworkScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Alumni Network'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildVolunteerToggle(),
              Expanded(
                child: ref.watch(alumniMentorsProvider).when(
                      data: (alumni) {
                        if (alumni.isEmpty) {
                          return const Center(
                              child: Text(
                                  'No alumni mentors yet. Be the first!',
                                  style: TextStyle(color: Colors.white70)));
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: alumni.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _buildAlumniCard(alumni[index]);
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => AppErrorView(
                        message: e.toString(),
                        onRetry: () => ref.invalidate(alumniMentorsProvider),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlumniCard(UserProfile mentor) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
              backgroundImage: mentor.avatarUrl != null
                  ? NetworkImage(mentor.avatarUrl!)
                  : null,
              radius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mentor.fullName ?? 'Anonymous',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(mentor.mentorTitle ?? mentor.role,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('ALUMNI MENTOR',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon:
                const Icon(LucideIcons.messageCircle, color: Colors.cyanAccent),
            onPressed: () {}, // Navigate to chat
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerToggle() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        color: Colors.amber.withValues(alpha: 0.1),
        child: Row(
          children: [
            const Icon(LucideIcons.heartHandshake,
                color: Colors.amber, size: 32),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Give Back',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                      'Toggle this to appear in the directory as available for quick questions.',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: ref.watch(userProfileProvider).value?.isMentor ?? false,
              activeThumbColor: Colors.amber,
              onChanged: (val) async {
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  await ref
                      .read(alumniRepositoryProvider)
                      .toggleAlumniMentorStatus(val);
                  ref.invalidate(userProfileProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Status Updated!')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
