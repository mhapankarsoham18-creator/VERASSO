import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/dashboard_skeleton.dart';
import 'package:verasso/features/astronomy/presentation/astronomy_menu_screen.dart';
import 'package:verasso/features/finance/presentation/finance_hub.dart';
import 'package:verasso/features/learning/data/collaboration_models.dart';
import 'package:verasso/features/learning/data/collaboration_repository.dart';
import 'package:verasso/features/learning/data/course_models.dart';
import 'package:verasso/features/learning/data/course_repository.dart';
import 'package:verasso/features/talent/presentation/mentor_directory_screen.dart';
import 'package:verasso/features/talent/presentation/mentorship_management_screen.dart';
import 'package:verasso/features/talent/presentation/talent_dashboard.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../core/config/feature_flags.dart';
import 'presentation/classroom/doubts_screen.dart';
import 'presentation/classroom/mesh_labs_screen.dart';
import 'presentation/classroom/study_groups_screen.dart';
import 'presentation/codedex/codedex_menu_screen.dart';
import 'presentation/marketplace/course_marketplace_screen.dart';
import 'presentation/marketplace/decks_screen.dart';
import 'presentation/marketplace/resource_library_screen.dart';
import 'presentation/simulations/biology/biology_menu_screen.dart';
import 'presentation/simulations/chemistry/chemistry_menu_screen.dart';
import 'presentation/simulations/cs/cs_menu_screen.dart';
import 'presentation/simulations/geography/geography_menu_screen.dart';
import 'presentation/simulations/history/history_menu_screen.dart';
import 'presentation/simulations/pharmacy/pharmacy_menu_screen.dart';
import 'presentation/simulations/physics/physics_menu_screen.dart';
import 'presentation/widgets/upcoming_events_carousel.dart';

/// Provider that fetches active daily challenges from the [CollaborationRepository].
final activeChallengesProvider = FutureProvider<List<DailyChallenge>>((ref) {
  final repo = ref.watch(collaborationRepositoryProvider);
  return repo.getActiveChallenges();
});

/// Fetches the current user's enrollments.
final myEnrollmentsProvider = FutureProvider<List<Enrollment>>((ref) {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getMyEnrollments();
});

/// The main dashboard for the Learning feature.
///
/// Provides access to study groups, resource libraries, digital courses,
/// daily challenges, and a wide array of interactive simulations across
/// various subjects like Physics, Biology, and Chemistry.
class LearningDashboard extends ConsumerWidget {
  /// Creates a [LearningDashboard] instance.
  const LearningDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          children: [
            Text(AppLocalizations.of(context)!.learningHub,
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            const UpcomingEventsCarousel(),

            // Progress Section
            ref.watch(myEnrollmentsProvider).when(
                  data: (enrollments) {
                    if (enrollments.isEmpty) return const SizedBox.shrink();
                    final inProgress = enrollments
                        .where((e) => e.progressPercent < 100)
                        .toList();
                    if (inProgress.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                              AppLocalizations.of(context)!.continueLearning,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: inProgress.length,
                            itemBuilder: (context, index) {
                              final enroll = inProgress[index];
                              return Semantics(
                                label:
                                    'Continue course: ${enroll.courseTitle}, ${enroll.progressPercent} percent complete',
                                child: Container(
                                  width: 180,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: GlassContainer(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(enroll.courseTitle ?? 'Course',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: enroll.progressPercent / 100,
                                          backgroundColor: Colors.white10,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        Text('${enroll.progressPercent}%',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white54)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

            // Daily Challenge Widget
            ref.watch(activeChallengesProvider).when(
                  data: (challenges) {
                    if (challenges.isEmpty) return const SizedBox.shrink();
                    final challenge = challenges.first;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Semantics(
                        label:
                            'Daily Challenge: ${challenge.subject}. ${challenge.title}. ${challenge.content}',
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          color: Colors.amber.withValues(alpha: 0.1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.zap,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 8),
                                  Text('DAILY CHALLENGE - ${challenge.subject}',
                                      style: const TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(challenge.title,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(challenge.content,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    // Mark as complete and award karma
                                    await ref
                                        .read(collaborationRepositoryProvider)
                                        .completeChallenge(challenge.id,
                                            challenge.rewardPoints);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Challenge Complete! +${challenge.rewardPoints} Karma')));
                                      // Refresh challenges
                                      ref.invalidate(activeChallengesProvider);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black),
                                  child: const Text('Complete & Earn 20 Karma'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const DashboardSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

            _ModuleCard(
              title: 'Study Groups',
              subtitle: 'Collaborative subject hubs',
              icon: LucideIcons.users,
              color: Colors.blueAccent,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StudyGroupsScreen())),
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Resource Library',
              subtitle: 'Shared notes & study guides',
              icon: LucideIcons.library,
              color: Colors.indigo,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ResourceLibraryScreen())),
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Digital Courses',
              subtitle: 'Self-paced learning modules',
              icon: LucideIcons.bookOpen,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CourseMarketplaceScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (FeatureFlags.enableMeshLabs)
              _ModuleCard(
                title: 'Mesh Labs (Offline)',
                subtitle: 'Collaborative mesh experiments',
                icon: LucideIcons.wifiOff,
                color: Colors.cyanAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MeshLabsScreen(),
                  ),
                ),
              ),

            _ModuleCard(
              title: 'Mentors',
              subtitle: 'Find industry professionals',
              icon: LucideIcons.graduationCap,
              color: Colors.purpleAccent,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MentorDirectoryScreen())),
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'My Mentorships',
              subtitle: 'Track your growth sessions',
              icon: LucideIcons.calendarCheck,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MentorshipManagementScreen())),
            ),

            _ModuleCard(
              title: 'Doubts',
              subtitle: 'Ask & answer questions',
              icon: LucideIcons.helpCircle,
              color: Colors.orange,
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DoubtsScreen())),
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Study Tools',
              subtitle: 'Flashcards, Planner, Notes',
              icon: LucideIcons.library,
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DecksScreen()));
              },
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Physics Labs',
              subtitle: '12 Interactive Simulations',
              icon: LucideIcons.atom,
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PhysicsMenuScreen()));
              },
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Chemistry Labs',
              subtitle: '6 Interactive Simulations',
              icon: LucideIcons.flaskConical,
              color: Colors.green,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ChemistryMenuScreen()));
              },
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Biology Labs',
              subtitle: '11 Interactive Simulations',
              icon: LucideIcons.microscope,
              color: Colors.lightGreen,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BiologyMenuScreen()));
              },
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Astronomy',
              subtitle: 'AR Stargazing & Celestial Objects',
              icon: LucideIcons.moon,
              color: Colors.deepPurple,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AstronomyMenuScreen()));
              },
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Business & Finance',
              subtitle: 'ROI, Economics, Accounting & More',
              icon: LucideIcons.trendingUp,
              color: Colors.amber,
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FinanceHub()));
              },
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Pharmacy Hub',
              subtitle: 'AR Drug Interactions & Lab Sims',
              icon: LucideIcons.pill,
              color: Colors.redAccent,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PharmacyMenuScreen()));
              },
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Geography Labs',
              subtitle: 'Interactive 3D Globe & Climate',
              icon: LucideIcons.globe,
              color: Colors.blueAccent,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const GeographyMenuScreen()));
              },
            ),
            _ModuleCard(
              title: 'History Labs',
              subtitle: 'AR Archaeological Reconstructions',
              icon: LucideIcons.landmark,
              color: Colors.amber,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const HistoryMenuScreen()));
              },
            ),
            _ModuleCard(
              title: 'CS & Boardroom',
              subtitle: 'Governance & Meeting Sims',
              icon: LucideIcons.users,
              color: Colors.indigoAccent,
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CSMenuScreen()));
              },
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'CodeDex',
              subtitle: 'Learn Python with Sandbox',
              icon: LucideIcons.terminal,
              color: Colors.lightBlueAccent,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CodedexMenuScreen()));
              },
            ),
            const SizedBox(height: 16),
            _ModuleCard(
              title: 'Find a Tutor',
              subtitle: 'Connect with student mentors',
              icon: LucideIcons.graduationCap,
              color: Colors.redAccent,
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TalentDashboard()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open $title: $subtitle',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const Spacer(),
              const Icon(LucideIcons.chevronRight, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
