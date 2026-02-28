import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/services/mastery_signature_service.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../core/exceptions/user_friendly_error_handler.dart';
import '../../../core/ui/error_view.dart';
import '../../../core/ui/secrecy_filter.dart';
import '../../../core/ui/shimmers/profile_skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../learning/data/assessment_models.dart';
import '../../learning/data/assessment_repository.dart';
import '../../settings/presentation/privacy_settings_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/profile_repository.dart';
import 'edit_profile_screen.dart';
import 'profile_controller.dart';

/// Future provider that fetches profile statistics (e.g., friend count) for a given [userId].
final profileStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfileStats(userId);
});

/// The user's main profile screen displaying their information, stats, and interests.
class ProfileScreen extends ConsumerWidget {
  /// Creates a [ProfileScreen].
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userProfileProvider);
    final privacySettings = ref.watch(privacySettingsProvider);
    // Safe way to get basic stats if profile loaded
    final statsAsync = profileAsync.value != null
        ? ref.watch(profileStatsProvider(profileAsync.value!.id))
        : const AsyncValue.data({'friends_count': 0});

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.myProfile),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          )
        ],
      ),
      body: LiquidBackground(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return Center(child: Text(l10n.profileNotFound));
            }
            return ListView(
              padding: const EdgeInsets.only(
                  top: 100, left: 16, right: 16, bottom: 20),
              children: [
                // Header Card
                GlassContainer(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? const Icon(LucideIcons.user,
                                size: 50, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SecrecyFilter(
                        isContentVisible: !privacySettings.maskFullName,
                        maskText: l10n.student,
                        child: Text(
                          profile.fullName ?? l10n.student,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '@${profile.username ?? l10n.defaultUsername}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                              l10n.trustScore, '${profile.trustScore}'),
                          // Show Friend Count dynamically
                          statsAsync.when(
                            data: (stats) => _buildStatItem(
                                l10n.friends, '${stats['friends_count'] ?? 0}'),
                            loading: () => _buildStatItem(l10n.friends, '...'),
                            error: (_, __) => _buildStatItem(l10n.friends, '0'),
                          ),
                          _buildStatItem(
                              l10n.following, '${profile.followingCount}'),
                          _buildStatItem(
                              l10n.followers, '${profile.followersCount}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (profile.role != 'student')
                        Chip(
                          label: Text(profile.role.toUpperCase()),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.8),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bio & Details
                GlassContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.about,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        profile.bio?.isNotEmpty == true
                            ? profile.bio!
                            : l10n.noBioYet,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.interests,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: profile.interests
                            .map((interest) => Chip(
                                  label: Text(interest),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.1),
                                ))
                            .toList(),
                      ),
                      if (profile.interests.isEmpty)
                        Text(l10n.noInterestsYet,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showEditProfileDialog(context, ref, profile),
                  icon: const Icon(LucideIcons.edit3),
                  label: Text(l10n.editProfile),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    final certificates =
                        ref.read(userCertificatesProvider(profile.id)).value ??
                            [];
                    _exportTranscript(
                        context, ref, profile, certificates, l10n);
                  },
                  icon: const Icon(LucideIcons.fileSignature),
                  label: Text(l10n.exportTranscript),
                ),
              ],
            );
          },
          loading: () => const ProfileSkeleton(),
          error: (err, stack) => ErrorView(
            message: UserFriendlyErrorHandler.getDisplayMessage(err),
            onRetry: () {
              ref.invalidate(userProfileProvider);
              ref.invalidate(profileStatsProvider);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Future<void> _exportTranscript(
      BuildContext context,
      WidgetRef ref,
      dynamic profile,
      List<Certificate> certificates,
      AppLocalizations l10n) async {
    if (certificates.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.noVerifiedSkills),
          content: Text(l10n.noVerifiedSkillsBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.gotIt),
            ),
          ],
        ),
      );
      return;
    }

    // Map certificates to skill levels (1.0 for earned certificates)
    final Map<String, double> realSkills = {
      for (var cert in certificates) cert.courseTitle ?? 'Unlabeled Skill': 1.0,
    };

    // Mastery transcript signing requires a persistent secure key.
    final signingKey =
        await ref.read(masterySignatureServiceProvider).getGlobalSigningKey();
    if (!context.mounted) return;
    if (signingKey == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Unavailable'),
          content: const Text(
              'Cryptographic signing service is currently offline. Please try again later.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.gotIt)),
          ],
        ),
      );
      return;
    }

    final transcript =
        ref.read(masterySignatureServiceProvider).generateSignedTranscript(
              userId: profile.id,
              skills: realSkills,
              signingKey: signingKey,
            );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.verifiedTranscript),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.verifiedTranscriptBody),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${transcript.substring(0, 50)}...',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          ElevatedButton(
            onPressed: () async {
              // Real copy to clipboard
              await Clipboard.setData(ClipboardData(text: transcript));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.transcriptCopied)),
                );
              }
            },
            child: Text(l10n.share),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, WidgetRef ref, dynamic profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(profile: profile),
        fullscreenDialog: true,
      ),
    );
  }
}
