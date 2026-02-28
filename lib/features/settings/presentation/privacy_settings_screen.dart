import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/profile/services/data_deletion_service.dart';
import 'package:verasso/features/settings/presentation/privacy_settings_controller.dart';

/// Screen for managing application-wide privacy and security settings.
class PrivacySettingsScreen extends ConsumerStatefulWidget {
  /// Creates a [PrivacySettingsScreen].
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(privacySettingsProvider);
    final notifier = ref.read(privacySettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- PROFILE PRIVACY ---
            _buildSectionHeader('Profile Visibility'),
            GlassContainer(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildToggleTile(
                    title: 'Private Profile',
                    subtitle: 'Only approved connections can see your profile.',
                    value: settings.privateProfile,
                    onChanged: (val) => notifier.setPrivateProfile(val),
                    icon: LucideIcons.shield,
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  _buildToggleTile(
                    title: 'Mask Email',
                    subtitle:
                        'Hide your real email address from public search.',
                    value: settings.maskEmail,
                    onChanged: (val) => notifier.setMaskEmail(val),
                    icon: LucideIcons.mail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- ACTIVITY & STATUS ---
            _buildSectionHeader('Activity & Presence'),
            GlassContainer(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildToggleTile(
                    title: 'Show Online Status',
                    subtitle: 'Let others see when you &apos;re active.',
                    value: settings.showOnlineStatus,
                    onChanged: (val) => notifier.setShowOnlineStatus(val),
                    icon: LucideIcons.activity,
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  _buildToggleTile(
                    title: 'Show Last Seen',
                    subtitle: 'Display your last neural uplink time.',
                    value: settings.showLastSeen,
                    onChanged: (val) => notifier.setShowLastSeen(val),
                    icon: LucideIcons.eye,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- INTERACTION ---
            _buildSectionHeader('Interactions'),
            GlassContainer(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildToggleTile(
                    title: 'Open Friend Requests',
                    subtitle: 'Allow anyone to send you friend requests.',
                    value: settings.allowFriendRequestsFromAnyone,
                    onChanged: (val) =>
                        notifier.setAllowFriendRequestsFromAnyone(val),
                    icon: LucideIcons.userPlus,
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  _buildToggleTile(
                    title: 'Allow Tagging',
                    subtitle: 'Others can tag you in their learning logs.',
                    value: settings.allowTagging,
                    onChanged: (val) => notifier.setAllowTagging(val),
                    icon: LucideIcons.tag,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- CHAT & DATA ---
            _buildSectionHeader('Chat & Data'),
            GlassContainer(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildToggleTile(
                    title: 'Auto Shield Chats',
                    subtitle: 'Automatically enable masking for new chats.',
                    value: settings.autoShieldChats,
                    onChanged: (val) => notifier.setAutoShieldChats(val),
                    icon: LucideIcons.messageSquare,
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  _buildToggleTile(
                    title: 'Auto Blur in Background',
                    subtitle: 'Blur app content when switching tasks.',
                    value: settings.autoBlurInBackground,
                    onChanged: (val) => notifier.setAutoBlurInBackground(val),
                    icon: LucideIcons.layers,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- SECURITY (Phase 2.1) ---
            _buildSectionHeader('Advanced Security'),
            GlassContainer(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildToggleTile(
                    title: 'Biometric Lock',
                    subtitle: 'Require biometric scan to open Verasso.',
                    value: settings.requireBiometric,
                    onChanged: (val) => notifier.setRequireBiometric(val),
                    icon: LucideIcons.fingerprint,
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    onTap: () {
                      // Show timeout picker dialog
                    },
                    leading:
                        const Icon(LucideIcons.clock, color: Colors.white70),
                    title: const Text('Session Timeout',
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                        '${settings.sessionTimeout.inMinutes} minutes',
                        style: const TextStyle(color: Colors.white70)),
                    trailing: const Icon(LucideIcons.chevronRight,
                        color: Colors.white24, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- ACCOUNT ---
            _buildSectionHeader('Account Management'),
            GlassContainer(
              child: ListTile(
                onTap: () {
                  // Trigger data export
                },
                leading:
                    const Icon(LucideIcons.download, color: Colors.white70),
                title: const Text('Export My Data',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                    'Receive a decentralized archive of your profile.',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              child: ListTile(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account?'),
                      content: const Text(
                        'This action is IRREVERSIBLE. All your data will be permanently erased.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Confirm Deletion'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      final service = ref.read(dataDeletionServiceProvider);
                      await service.deleteAccount();
                      // Redirect logic is usually handled by auth listener
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Deletion failed: $e')),
                        );
                      }
                    }
                  }
                },
                leading:
                    const Icon(LucideIcons.trash2, color: Colors.redAccent),
                title: const Text('Delete Account',
                    style: TextStyle(color: Colors.redAccent)),
                subtitle: const Text('Permanently erase your identity.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      activeThumbColor: Theme.of(context).primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
