import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/empty_state_widget.dart';
import 'package:verasso/core/ui/error_state_widget.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/course_skeleton.dart';

import '../../../auth/presentation/auth_controller.dart';
import '../../data/challenge_model.dart';
import '../../data/challenge_repository.dart';
import 'challenge_submissions_review_screen.dart';
import 'create_challenge_screen.dart';

/// A hub for community-driven learning challenges (Battle Arena).
class CommunityChallengesScreen extends ConsumerStatefulWidget {
  /// Creates a [CommunityChallengesScreen] instance.
  const CommunityChallengesScreen({super.key});

  @override
  ConsumerState<CommunityChallengesScreen> createState() =>
      _CommunityChallengesScreenState();
}

class _CommunityChallengesScreenState
    extends ConsumerState<CommunityChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Battle Arena'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          tabs: const [
            Tab(text: 'Active Challenges'),
            Tab(text: 'My Challenges'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateChallengeScreen())),
        label: const Text('Create Challenge'),
        icon: const Icon(
            LucideIcons.swords), // If swords fails, I'll try LucideIcons.sword
        backgroundColor: Colors.purpleAccent,
      ),
      body: LiquidBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveChallengesList(),
            _buildMyChallengesList(),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Widget _buildActiveChallengesList() {
    return FutureBuilder<List<CommunityChallenge>>(
      future: ref.read(challengeRepositoryProvider).getActiveChallenges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CourseSkeleton();
        }

        if (snapshot.hasError) {
          return ErrorStateWidget(
            title: 'Error Loading Challenges',
            message: 'Failed to load challenges. Please try again.',
            onRetry: () {
              setState(() {});
            },
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyStateWidget(
            title: 'No Active Challenges',
            message: 'Be the first to create a battle and challenge others!',
            icon: LucideIcons.swords,
            actionLabel: 'Create Challenge',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateChallengeScreen()),
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(top: 100, bottom: 80, left: 16, right: 16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildChallengeCard(snapshot.data![index], isCreator: false);
          },
        );
      },
    );
  }

  Widget _buildChallengeCard(CommunityChallenge challenge,
      {required bool isCreator}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: challenge.creatorAvatar != null
                      ? NetworkImage(challenge.creatorAvatar!)
                      : null,
                  radius: 12,
                  child: challenge.creatorAvatar == null
                      ? const Icon(LucideIcons.user, size: 12)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(challenge.creatorName ?? 'User',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('${challenge.karmaReward} Karma',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.purpleAccent,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(challenge.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(challenge.description,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTag(LucideIcons.tag, challenge.category),
                const SizedBox(width: 8),
                _buildTag(LucideIcons.barChart, challenge.difficulty),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isCreator) {
                    // Navigate to Review Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChallengeSubmissionsReviewScreen(
                          challengeId: challenge.id,
                          challengeTitle: challenge.title,
                        ),
                      ),
                    );
                  } else {
                    _showSubmissionDialog(challenge.id);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isCreator ? Colors.blueAccent : Colors.white10),
                child:
                    Text(isCreator ? 'Manage Submissions' : 'Accept Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyChallengesList() {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) {
      return ErrorStateWidget(
        title: 'Not Logged In',
        message: 'Please log in to view your challenges.',
        onRetry: () => setState(() {}),
      );
    }

    return FutureBuilder<List<CommunityChallenge>>(
      future: ref.read(challengeRepositoryProvider).getMyChallenges(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CourseSkeleton();
        }

        if (snapshot.hasError) {
          return ErrorStateWidget(
            title: 'Error Loading Your Challenges',
            message: 'Failed to load your challenges. Please try again.',
            onRetry: () {
              setState(() {});
            },
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyStateWidget(
            title: 'No Challenges Created Yet',
            message: 'Challenge your community by creating your first battle!',
            icon: LucideIcons.swords,
            actionLabel: 'Create Challenge',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateChallengeScreen()),
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.only(top: 100, bottom: 80, left: 16, right: 16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildChallengeCard(snapshot.data![index], isCreator: true);
          },
        );
      },
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }

  void _showSubmissionDialog(String challengeId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('Submit Challenge',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Paste link to your work (Github/Figma)...',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final userId = ref.read(currentUserProvider)?.id;
              if (userId != null && controller.text.isNotEmpty) {
                await ref.read(challengeRepositoryProvider).submitEntry(
                      challengeId: challengeId,
                      userId: userId,
                      contentUrl: controller.text,
                    );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Submission sent! Waiting for review.')));
              }
            },
            child: const Text('Submit',
                style: TextStyle(color: Colors.purpleAccent)),
          ),
        ],
      ),
    );
  }
}
