import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../social/presentation/alumni_network_screen.dart';
import 'presentation/classroom/doubts_screen.dart';
import 'presentation/classroom/study_groups_screen.dart';
import 'presentation/codedex/codedex_menu_screen.dart';
import 'presentation/marketplace/course_marketplace_screen.dart';
import 'presentation/marketplace/decks_screen.dart';
import 'presentation/marketplace/resource_library_screen.dart';
import 'presentation/simulations/astronomy/astronomy_menu_screen.dart';
import 'presentation/simulations/biology/biology_menu_screen.dart';
import 'presentation/simulations/chemistry/chemistry_menu_screen.dart';
import 'presentation/simulations/finance/finance_menu_screen.dart';
import 'presentation/simulations/geography/geography_menu_screen.dart';
import 'presentation/simulations/history/history_menu_screen.dart';
import 'presentation/simulations/pharmacy/pharmacy_menu_screen.dart';
import 'presentation/simulations/physics/physics_menu_screen.dart';
import 'presentation/widgets/continue_learning_section.dart';
import 'presentation/widgets/daily_challenge_card.dart';
import 'presentation/widgets/module_card.dart';
import 'presentation/widgets/upcoming_events_carousel.dart';

/// The main dashboard for the Learning feature.
///
/// Provides access to study groups, resource libraries, digital courses,
/// daily challenges, and interactive simulations across various subjects.
class LearningDashboard extends ConsumerWidget {
  const LearningDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
          children: [
            Text(
              AppLocalizations.of(context)!.learningHub,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const UpcomingEventsCarousel(),

            // In-progress courses
            const ContinueLearningSection(),

            // Daily challenge
            const DailyChallengeCard(),

            // ─── Module Cards ───
            ModuleCard(
              title: 'Study Groups',
              subtitle: 'Collaborative subject hubs',
              icon: LucideIcons.users,
              color: Colors.blueAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StudyGroupsScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'Resource Library',
              subtitle: 'Shared notes & study guides',
              icon: LucideIcons.library,
              color: Colors.indigo,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ResourceLibraryScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ModuleCard(
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
            ModuleCard(
              title: 'Mentors',
              subtitle: 'Find industry professionals',
              icon: LucideIcons.graduationCap,
              color: Colors.purpleAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlumniNetworkScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'My Mentorships',
              subtitle: 'Track your growth sessions',
              icon: LucideIcons.calendarCheck,
              color: Colors.blueAccent,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mentorships — coming soon!')),
                );
              },
            ),
            ModuleCard(
              title: 'Doubts',
              subtitle: 'Ask & answer questions',
              icon: LucideIcons.helpCircle,
              color: Colors.orange,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DoubtsScreen())),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'Study Tools',
              subtitle: 'Flashcards, Planner, Notes',
              icon: LucideIcons.library,
              color: Colors.blue,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DecksScreen())),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'Physics Labs',
              subtitle: '12 Interactive Simulations',
              icon: LucideIcons.atom,
              color: Colors.purple,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PhysicsMenuScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'Chemistry Labs',
              subtitle: '4 Interactive Simulations',
              icon: LucideIcons.flaskConical,
              color: Colors.green,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChemistryMenuScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'Biology Labs',
              subtitle: '3 Interactive Simulations',
              icon: LucideIcons.microscope,
              color: Colors.lightGreen,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BiologyMenuScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'Astronomy',
              subtitle: 'AR Stargazing & Celestial Objects',
              icon: LucideIcons.moon,
              color: Colors.deepPurple,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AstronomyMenuScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'Business & Finance',
              subtitle: 'ROI, Economics, Accounting & More',
              icon: LucideIcons.trendingUp,
              color: Colors.amber,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FinanceMenuScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'Pharmacy Hub',
              subtitle: 'AR Drug Interactions & Lab Sims',
              icon: LucideIcons.pill,
              color: Colors.redAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PharmacyMenuScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'Geography Labs',
              subtitle: 'Interactive 3D Globe & Climate',
              icon: LucideIcons.globe,
              color: Colors.blueAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GeographyMenuScreen()),
              ),
            ),
            ModuleCard(
              title: 'History Labs',
              subtitle: 'AR Archaeological Reconstructions',
              icon: LucideIcons.landmark,
              color: Colors.amber,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryMenuScreen()),
              ),
            ),
            ModuleCard(
              title: 'CS & Boardroom',
              subtitle: 'Governance & Meeting Sims',
              icon: LucideIcons.users,
              color: Colors.indigoAccent,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CS Labs — coming soon!')),
                );
              },
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'CodeDex',
              subtitle: 'Learn Python with Sandbox',
              icon: LucideIcons.terminal,
              color: Colors.lightBlueAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CodedexMenuScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ModuleCard(
              title: 'Find a Tutor',
              subtitle: 'Connect with student mentors',
              icon: LucideIcons.graduationCap,
              color: Colors.redAccent,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tutors — coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
