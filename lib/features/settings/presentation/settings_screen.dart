import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../../core/security/biometric_auth_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/mfa_backup_codes_screen.dart';
import '../../auth/presentation/mfa_enrollment_screen.dart';
import '../../profile/presentation/profile_controller.dart';
import 'data_management_screen.dart';
import 'mesh_network_screen.dart';
import 'privacy_policy_screen.dart';
import 'privacy_settings_controller.dart';
import 'terms_service_screen.dart';
import 'theme_controller.dart';
import 'theme_customization_screen.dart';

/// The main settings screen of the application.
class SettingsScreen extends ConsumerWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(AppLocalizations.of(context)!.appearance),
            GlassContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.palette),
                    title: Text(AppLocalizations.of(context)!.themeForge),
                    subtitle: Text(
                        '${themeState.style.name.toUpperCase()} • ${themeState.mode.name.toUpperCase()}'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ThemeCustomizationScreen()),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24),
                  SwitchListTile(
                    secondary: const Icon(LucideIcons.battery),
                    title: Text(AppLocalizations.of(context)!.powerSaveMode),
                    subtitle: const Text(
                        'Disable background animations to save energy'),
                    value: themeState.isPowerSaveMode,
                    onChanged: (val) {
                      ref
                          .read(themeControllerProvider.notifier)
                          .togglePowerSaveMode(val);
                    },
                    activeThumbColor: Colors.greenAccent,
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(LucideIcons.languages),
                    title: Text(AppLocalizations.of(context)!.language),
                    subtitle:
                        Text(_getLanguageName(themeState.locale.languageCode)),
                    trailing: DropdownButton<Locale>(
                      value: themeState.locale,
                      underline: const SizedBox(),
                      dropdownColor: Colors.black,
                      items: const [
                        DropdownMenuItem(
                            value: Locale('en'), child: Text('English')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(themeControllerProvider.notifier)
                              .setLocale(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.connectivity),
            GlassContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.radio),
                    title: Text(AppLocalizations.of(context)!.meshNetwork),
                    subtitle: const Text('Offline Peer-to-Peer Settings'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MeshNetworkScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.account),
            GlassContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.user),
                    title: Text(AppLocalizations.of(context)!.editProfile),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      // Add navigation
                    },
                  ),
                  const Divider(color: Colors.white24),
                  profileAsync.when(
                    data: (profile) => SwitchListTile(
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      title: Text(AppLocalizations.of(context)!.privateAccount),
                      subtitle: Text(
                          AppLocalizations.of(context)!.privateAccountSubtitle),
                      value: profile?.isPrivate ?? false,
                      onChanged: (val) {
                        ref
                            .read(profileControllerProvider.notifier)
                            .togglePrivacy(val);
                      },
                      secondary: const Icon(LucideIcons.lock),
                    ),
                    loading: () => ListTile(
                      title: Text(AppLocalizations.of(context)!.loading),
                      leading: const Icon(LucideIcons.lock),
                      subtitle:
                          Text(AppLocalizations.of(context)!.checkingPrivacy),
                    ),
                    error: (error, stack) => ListTile(
                      leading: const Icon(LucideIcons.lock),
                      title: Text(AppLocalizations.of(context)!.privateAccount),
                      subtitle: Text(
                          AppLocalizations.of(context)!.failedLoadSettings),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.refreshCw),
                        onPressed: () {
                          ref.invalidate(userProfileProvider);
                        },
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  // Global Default Privacy setting
                  profileAsync.when(
                    data: (profile) => SwitchListTile(
                      activeThumbColor: Colors.orange,
                      title: Text(
                          AppLocalizations.of(context)!.allowPersonalPosts),
                      subtitle: Text(
                          AppLocalizations.of(context)!.personalPostsSubtitle),
                      value: profile?.defaultPersonalVisibility ?? false,
                      onChanged: (val) {
                        ref
                            .read(profileControllerProvider.notifier)
                            .updateDefaultPersonalVisibility(val);
                      },
                      secondary:
                          const Icon(LucideIcons.eye, color: Colors.orange),
                    ),
                    loading: () => ListTile(
                      leading:
                          const Icon(LucideIcons.eye, color: Colors.orange),
                      title: Text(
                          AppLocalizations.of(context)!.allowPersonalPosts),
                      subtitle: Text(AppLocalizations.of(context)!.loading),
                    ),
                    error: (error, stack) => ListTile(
                      leading:
                          const Icon(LucideIcons.eye, color: Colors.orange),
                      title: Text(
                          AppLocalizations.of(context)!.allowPersonalPosts),
                      subtitle: Text(
                          AppLocalizations.of(context)!.failedLoadSettings),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.refreshCw),
                        onPressed: () {
                          ref.invalidate(userProfileProvider);
                        },
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(LucideIcons.shield),
                    title: Text(AppLocalizations.of(context)!.security),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MFAEnrollmentScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.security),
            GlassContainer(
              child: Column(
                children: [
                  // Biometric Authentication Toggle
                  const _BiometricAuthTile(),
                  const Divider(color: Colors.white24),
                  // Backup Codes Management
                  ListTile(
                    leading: const Icon(LucideIcons.key),
                    title: const Text('Backup Codes'),
                    subtitle: const Text('Manage 2FA backup codes'),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MFABackupCodesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Privacy Display'),
            GlassContainer(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(LucideIcons.bell),
                    title:
                        Text(AppLocalizations.of(context)!.pushNotifications),
                    subtitle: Text(AppLocalizations.of(context)!
                        .pushNotificationsSubtitle),
                    value: ref.watch(privacySettingsProvider).notifyEnabled,
                    onChanged: (val) => ref
                        .read(privacySettingsProvider.notifier)
                        .setNotifyEnabled(val),
                    activeThumbColor: themeState.mode == ThemeMode.dark
                        ? Colors.blueAccent
                        : Colors.blue,
                  ),
                  const Divider(color: Colors.white24),
                  SwitchListTile(
                    secondary: const Icon(LucideIcons.eyeOff),
                    title: Text(AppLocalizations.of(context)!.snapshotPrivacy),
                    subtitle: Text(
                        AppLocalizations.of(context)!.snapshotPrivacySubtitle),
                    value:
                        ref.watch(privacySettingsProvider).autoBlurInBackground,
                    onChanged: (val) => ref
                        .read(privacySettingsProvider.notifier)
                        .setAutoBlurInBackground(val),
                    activeThumbColor: themeState.mode == ThemeMode.dark
                        ? Colors.blueAccent
                        : Colors.blue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.privacyLegal),
            GlassContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.hardDrive),
                    title: Text(AppLocalizations.of(context)!.dataManagement),
                    subtitle: Text(
                        AppLocalizations.of(context)!.dataManagementSubtitle),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DataManagementScreen()));
                    },
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(LucideIcons.scrollText),
                    title: Text(AppLocalizations.of(context)!.privacyPolicy),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen()));
                    },
                  ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(LucideIcons.fileText),
                    title: Text(AppLocalizations.of(context)!.termsOfService),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TermsOfServiceScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(AppLocalizations.of(context)!.support),
            GlassContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(LucideIcons.helpCircle),
                    title: Text(AppLocalizations.of(context)!.helpCenter),
                    trailing: Icon(LucideIcons.chevronRight),
                  ),
                  Divider(color: Colors.white24),
                  ListTile(
                    leading: Icon(LucideIcons.info),
                    title: Text(AppLocalizations.of(context)!.aboutVerasso),
                    trailing: Text('v1.1.0'), // Updated version
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Sign out
                  ref.read(authControllerProvider.notifier).signOut();
                  // GoRouter should handle redirect based on auth state stream
                },
                icon: const Icon(LucideIcons.logOut, color: Colors.red),
                label: Text(AppLocalizations.of(context)!.signOut,
                    style: const TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  String _getLanguageName(String code) {
    return 'English';
  }
}

/// Biometric Authentication Toggle Widget
class _BiometricAuthTile extends StatefulWidget {
  const _BiometricAuthTile();

  @override
  State<_BiometricAuthTile> createState() => _BiometricAuthTileState();
}

class _BiometricAuthTileState extends State<_BiometricAuthTile> {
  final _biometricService = BiometricAuthService();
  bool _isEnabled = false;
  bool _isAvailable = false;
  String _biometricType = 'Biometric';
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ListTile(
        leading: Icon(LucideIcons.fingerprint),
        title: Text('Biometric Authentication'),
        subtitle: Text('Loading...'),
      );
    }

    if (!_isAvailable) {
      return const ListTile(
        leading: Icon(LucideIcons.fingerprint),
        title: Text('Biometric Authentication'),
        subtitle: Text('Not available on this device'),
        enabled: false,
      );
    }

    return SwitchListTile(
      secondary: const Icon(LucideIcons.fingerprint),
      title: const Text('Biometric Authentication'),
      subtitle: Text('Use $_biometricType for login'),
      value: _isEnabled,
      onChanged: _toggleBiometric,
      activeThumbColor: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final available = await _biometricService.isBiometricAvailable();
      final enabled = await _biometricService.isBiometricEnabled();
      final type = await _biometricService.getBiometricTypeString();

      if (mounted) {
        setState(() {
          _isAvailable = available;
          _isEnabled = enabled;
          _biometricType = type;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final success = await _biometricService.enableBiometric();
      if (success) {
        setState(() => _isEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType authentication enabled'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to enable biometric')),
          );
        }
      }
    } else {
      await _biometricService.disableBiometric();
      setState(() => _isEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_biometricType authentication disabled')),
        );
      }
    }
  }
}
