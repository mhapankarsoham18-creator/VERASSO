import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/list_skeleton.dart';

import '../data/mentor_model.dart';
import '../data/mentor_repository.dart';
import 'mentor_detail_screen.dart';
import 'mentor_onboarding_screen.dart';

/// Provider that fetches the list of verified mentors.
final verifiedMentorsProvider = FutureProvider<List<MentorProfile>>((ref) {
  return ref.watch(mentorRepositoryProvider).getVerifiedMentors();
});

/// Screen displaying a directory of verified mentors.
class MentorDirectoryScreen extends ConsumerWidget {
  /// Creates a [MentorDirectoryScreen].
  const MentorDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentorsAsync = ref.watch(verifiedMentorsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Premium Mentors'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MentorOnboardingScreen())),
            icon: const Icon(LucideIcons.graduationCap, size: 16),
            label: const Text('Become a Mentor'),
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
          ),
        ],
      ),
      body: LiquidBackground(
        child: mentorsAsync.when(
          data: (mentors) {
            if (mentors.isEmpty) {
              return const Center(
                  child: Text(
                      'No premium mentors verified yet. Check back soon!'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
              itemCount: mentors.length,
              itemBuilder: (context, index) =>
                  _buildMentorCard(context, mentors[index]),
            );
          },
          loading: () => const ListSkeleton(),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(verifiedMentorsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildMentorCard(BuildContext context, MentorProfile mentor) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: mentor.userId.isNotEmpty
                    ? NetworkImage(
                        'https://api.dicebear.com/7.x/avataaars/png?seed=${mentor.userId}')
                    : null,
                child:
                    mentor.userId.isEmpty ? const Icon(LucideIcons.user) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(mentor.headline ?? 'Expert Mentor',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.badgeCheck,
                            color: Colors.blueAccent, size: 18),
                      ],
                    ),
                    Text('${mentor.experienceYears} Years Experience',
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(mentor.specializations.join(' • '),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          const Text('Top Educational Qualifications',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70)),
          const SizedBox(height: 8),
          Column(
            children: mentor.degrees
                .take(2)
                .map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.bookOpen,
                              size: 12, color: Colors.white38),
                          const SizedBox(width: 8),
                          Text('${d['title']} @ ${d['institution']}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white54)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetric(
                  LucideIcons.users, '${mentor.totalMentees}', 'Mentees'),
              const SizedBox(width: 24),
              _buildMetric(LucideIcons.star,
                  mentor.averageRating.toStringAsFixed(1), 'Rating'),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MentorDetailScreen(mentor: mentor))),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent),
                child: const Text('View Profile'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white38)),
      ],
    );
  }
}
