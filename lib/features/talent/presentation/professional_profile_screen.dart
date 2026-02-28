import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/ui/error_view.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/core/ui/shimmers/profile_skeleton.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../finance/presentation/earnings_wallet_screen.dart';
import '../../learning/data/assessment_models.dart';
import '../../learning/data/assessment_repository.dart';
import '../../learning/data/collaboration_models.dart';
import '../../profile/presentation/profile_controller.dart';
import '../data/job_model.dart';
import '../data/job_repository.dart';
import '../data/talent_profile_model.dart';
import '../data/talent_profile_repository.dart';
import 'analytics_dashboard_screen.dart';
import 'verification_gate_dialog.dart';
import 'widgets/talent_bio_section.dart';
import 'widgets/talent_education_list.dart';
import 'widgets/talent_experience_list.dart';
import 'widgets/talent_portfolio_list.dart';
import 'widgets/talent_profile_header.dart';
import 'widgets/talent_skills_chips.dart';

/// Provider that fetches certificates for a given user.
final certificatesProvider =
    FutureProvider.family<List<Certificate>, String>((ref, userId) {
  return AssessmentRepository().getStudentCertificates(userId);
});

/// Provider that fetches student karma score.
final karmaProvider =
    FutureProvider.family<StudentScore?, String>((ref, userId) async {
  final response = await Supabase.instance.client
      .from('student_scores')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();
  if (response == null) return null;
  return StudentScore.fromJson(response);
});

/// Provider that fetches reviews for a user.
final reviewsProvider =
    FutureProvider.family<List<JobReview>, String>((ref, userId) {
  return ref.watch(jobRepositoryProvider).getReviewsForUser(userId);
});

/// Provider that fetches the detailed talent profile for a user.
final talentProfileProvider =
    FutureProvider.family<TalentProfile?, String>((ref, userId) {
  return ref.watch(talentProfileRepositoryProvider).getTalentProfile(userId);
});

/// Screen that displays a user's professional profile (Talent view).
class ProfessionalProfileScreen extends ConsumerStatefulWidget {
  /// The ID of the user whose profile is to be displayed.
  final String userId;

  /// Creates a [ProfessionalProfileScreen].
  const ProfessionalProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfessionalProfileScreen> createState() =>
      _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState
    extends ConsumerState<ProfessionalProfileScreen> {
  bool _isEditing = false;

  // Controllers for editing
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  List<ExperienceEntry> _tempExperience = [];
  List<EducationEntry> _tempEducation = [];
  List<String> _tempPortfolio = [];

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(talentProfileProvider(widget.userId));
    final myProfile = ref.watch(userProfileProvider).value;
    final isMe = myProfile?.id == widget.userId;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.professionalProfile),
        backgroundColor: Colors.transparent,
        actions: [
          if (isMe)
            IconButton(
              icon: Icon(_isEditing ? LucideIcons.save : LucideIcons.edit),
              onPressed: () {
                final profile = ref.read(userProfileProvider).value;
                if (_isEditing) {
                  profileAsync.whenData((p) => _saveProfile(p!));
                } else {
                  if (profile?.isAgeVerified == true) {
                    profileAsync.whenData((p) {
                      _headlineController.text = p?.headline ?? '';
                      _bioController.text = p?.bio ?? '';
                      _skillsController.text = p?.skills.join(', ') ?? '';
                      _tempExperience = List.from(p?.experience ?? []);
                      _tempEducation = List.from(p?.education ?? []);
                      _tempPortfolio = List.from(p?.portfolioUrls ?? []);
                      setState(() => _isEditing = true);
                    });
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => const VerificationGateDialog(),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: LiquidBackground(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null && isMe) {
              return _buildCareerSetupCard();
            }
            if (profile == null) {
              return const Center(child: Text('Profile not found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TalentProfileHeader(
                    profile: profile,
                    isEditing: _isEditing,
                    headlineController: _headlineController,
                    karmaBadge: _buildKarmaBadge(profile.id),
                    ratingRow: _buildRatingRow(profile.id),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                      'About',
                      TalentBioSection(
                        bio: profile.bio,
                        isEditing: _isEditing,
                        bioController: _bioController,
                      )),
                  const SizedBox(height: 16),
                  _buildSection(
                      'Skills',
                      TalentSkillsChips(
                        skills: profile.skills,
                        isEditing: _isEditing,
                        skillsController: _skillsController,
                      )),
                  const SizedBox(height: 16),
                  _buildSection(
                      'Portfolio',
                      TalentPortfolioList(
                        portfolioUrls: profile.portfolioUrls,
                        isEditing: _isEditing,
                        onRemove: (idx) => _removePortfolio(idx),
                      ),
                      onAdd: isMe && _isEditing
                          ? () => _showPortfolioDialog()
                          : null),
                  const SizedBox(height: 16),
                  _buildSection(
                      'Experience',
                      TalentExperienceList(
                        experience: profile.experience,
                        isEditing: _isEditing,
                        onRemove: (idx) => _removeExperience(idx),
                      ),
                      onAdd: isMe && _isEditing
                          ? () => _showExperienceDialog()
                          : null),
                  const SizedBox(height: 16),
                  _buildSection(
                      'Education',
                      TalentEducationList(
                        education: profile.education,
                        isEditing: _isEditing,
                        onRemove: (idx) => _removeEducation(idx),
                      ),
                      onAdd: isMe && _isEditing
                          ? () => _showEducationDialog()
                          : null),
                  const SizedBox(height: 16),
                  if (isMe) ...[
                    _buildSection('Business & Finance', _buildFinanceSection()),
                    const SizedBox(height: 16),
                  ],
                  _buildSection('Verified Expertise', _buildCertificates()),
                  const SizedBox(height: 16),
                  _buildSection('Client Reviews', _buildReviews()),
                ],
              ),
            );
          },
          loading: () => const ProfileSkeleton(),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(talentProfileProvider(widget.userId)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Widget _buildCareerSetupCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.rocket,
                    size: 40, color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              const Text('Scale Your Professional Impact',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                'Create a professional profile to get discovered by recruiters and mentors in the Verasso ecosystem.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Profile Strength',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text(
                          '${(_calculateProfileStrength(null) * 100).toInt()}%',
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _calculateProfileStrength(null),
                      backgroundColor: Colors.white10,
                      color: Colors.blueAccent,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _setupInitialProfile(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Initialize Talent Profile',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificates() {
    final certificatesAsync = ref.watch(certificatesProvider(widget.userId));
    return certificatesAsync.when(
      data: (certs) {
        if (certs.isEmpty) {
          return const Text('No verified credentials yet.',
              style: TextStyle(color: Colors.white38));
        }
        return Column(
          children: certs
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.award,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.courseTitle ?? 'Professional Certificate',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text(
                                  'Issued: ${c.issuedAt.day}/${c.issuedAt.month}/${c.issuedAt.year}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(c.verificationCode,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: Colors.blueAccent)),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading certificates: $e'),
    );
  }

  Widget _buildFinanceItem(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blueAccent, size: 18),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.white54)),
      trailing:
          const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildFinanceSection() {
    return Column(
      children: [
        _buildFinanceItem(
            LucideIcons.wallet,
            'Earnings & Wallet',
            'Track your revenue and invoices',
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const EarningsWalletScreen()))),
        const SizedBox(height: 12),
        _buildFinanceItem(
            LucideIcons.lineChart,
            'Detailed Analytics',
            'Deep dive into your performance data',
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AnalyticsDashboardScreen()))),
      ],
    );
  }

  Widget _buildKarmaBadge(String userId) {
    final karmaAsync = ref.watch(karmaProvider(userId));
    return karmaAsync.when(
      data: (score) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.star, color: Colors.amber, size: 12),
            const SizedBox(width: 6),
            Text(
              '${score?.karmaPoints ?? 0} KARMA',
              style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 10),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 20),
      error: (_, __) => const SizedBox(height: 20),
    );
  }

  Widget _buildRatingRow(String userId) {
    return ref.watch(reviewsProvider(userId)).when(
          data: (reviews) {
            if (reviews.isEmpty) return const SizedBox.shrink();
            final avg = reviews.fold<double>(0, (sum, r) => sum + r.rating) /
                reviews.length;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(avg.toStringAsFixed(1),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 4),
                Text('(${reviews.length})',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
  }

  Widget _buildReviews() {
    final reviewsAsync = ref.watch(reviewsProvider(widget.userId));
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Text('No reviews yet.',
              style: TextStyle(color: Colors.white38));
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (_, __) =>
              const Divider(color: Colors.white10, height: 24),
          itemBuilder: (context, index) {
            final r = reviews[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < r.rating
                                    ? LucideIcons.star
                                    : LucideIcons.starHalf,
                                color: Colors.amber,
                                size: 14,
                              )),
                    ),
                    Text(
                      '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (r.comment != null)
                  Text(r.comment!,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading reviews: $e'),
    );
  }

  Widget _buildSection(String title, Widget content, {VoidCallback? onAdd}) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70)),
              if (onAdd != null)
                IconButton(
                  icon: const Icon(LucideIcons.plusCircle,
                      size: 20, color: Colors.blueAccent),
                  onPressed: onAdd,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          content,
        ],
      ),
    );
  }

  double _calculateProfileStrength(TalentProfile? profile) {
    if (profile == null) return 0.0;
    double strength = 0.0;
    if (profile.headline != null && profile.headline!.isNotEmpty) {
      strength += 0.2;
    }
    if (profile.bio != null && profile.bio!.isNotEmpty) {
      strength += 0.2;
    }
    if (profile.skills.isNotEmpty) {
      strength += 0.2;
    }
    if (profile.experience.isNotEmpty) {
      strength += 0.2;
    }
    if (profile.education.isNotEmpty) {
      strength += 0.1;
    }
    if (profile.portfolioUrls.isNotEmpty) {
      strength += 0.1;
    }
    return strength;
  }

  void _removeEducation(int index) {
    setState(() {
      _tempEducation.removeAt(index);
    });
  }

  void _removeExperience(int index) {
    setState(() {
      _tempExperience.removeAt(index);
    });
  }

  void _removePortfolio(int index) {
    setState(() {
      _tempPortfolio.removeAt(index);
    });
  }

  Future<void> _saveProfile(TalentProfile current) async {
    final updated = current.copyWith(
      headline: _headlineController.text,
      bio: _bioController.text,
      skills: _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      experience: _tempExperience,
      education: _tempEducation,
      portfolioUrls: _tempPortfolio,
    );

    await ref
        .read(talentProfileRepositoryProvider)
        .upsertTalentProfile(updated);
    ref.invalidate(talentProfileProvider(widget.userId));
    setState(() => _isEditing = false);
  }

  Future<void> _setupInitialProfile() async {
    final myId = ref.read(userProfileProvider).value?.id;
    if (myId == null) return;

    await ref
        .read(talentProfileRepositoryProvider)
        .upsertTalentProfile(TalentProfile(id: myId));
    ref.invalidate(talentProfileProvider(widget.userId));
  }

  void _showEducationDialog() {
    final schoolC = TextEditingController();
    final degreeC = TextEditingController();
    final startC = TextEditingController();
    final endC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Add Education', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: schoolC,
                decoration: const InputDecoration(labelText: 'School'),
                style: const TextStyle(color: Colors.white)),
            TextField(
                controller: degreeC,
                decoration: const InputDecoration(labelText: 'Degree'),
                style: const TextStyle(color: Colors.white)),
            TextField(
                controller: startC,
                decoration: const InputDecoration(labelText: 'Start Date'),
                style: const TextStyle(color: Colors.white)),
            TextField(
                controller: endC,
                decoration: const InputDecoration(labelText: 'End Date'),
                style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tempEducation.add(EducationEntry(
                  school: schoolC.text,
                  degree: degreeC.text,
                  startDate: startC.text,
                  endDate: endC.text,
                ));
              });
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
  }

  void _showExperienceDialog() {
    final titleC = TextEditingController();
    final companyC = TextEditingController();
    final startC = TextEditingController();
    final endC = TextEditingController();
    final descC = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title:
            const Text('Add Experience', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: 'Job Title'),
                  style: const TextStyle(color: Colors.white)),
              TextField(
                  controller: companyC,
                  decoration: const InputDecoration(labelText: 'Company'),
                  style: const TextStyle(color: Colors.white)),
              TextField(
                  controller: startC,
                  decoration: const InputDecoration(
                      labelText: 'Start Date (e.g. Jan 2023)'),
                  style: const TextStyle(color: Colors.white)),
              TextField(
                  controller: endC,
                  decoration:
                      const InputDecoration(labelText: 'End Date (or Present)'),
                  style: const TextStyle(color: Colors.white)),
              TextField(
                  controller: descC,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tempExperience.add(ExperienceEntry(
                  title: titleC.text,
                  company: companyC.text,
                  startDate: startC.text,
                  endDate: endC.text,
                  description: descC.text,
                ));
              });
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
  }

  void _showPortfolioDialog() {
    final urlC = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Portfolio Link',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: urlC,
          decoration:
              const InputDecoration(hintText: 'https://github.com/yourstack'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () {
              if (urlC.text.isNotEmpty) {
                setState(() => _tempPortfolio.add(urlC.text));
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
