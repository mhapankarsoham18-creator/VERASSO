import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../../core/ui/password_input_dialog.dart';
import '../../learning/data/ar_security_repository.dart';
import 'security_audit_log_screen.dart';

/// Security settings widget for AR projects
/// Widget for managing security settings of an AR project.
class ProjectSecuritySettings extends ConsumerStatefulWidget {
  /// The unique identifier of the project.
  final String projectId;

  /// Whether the project is currently password protected.
  final bool isPasswordProtected;

  /// Whether the project data is encrypted.
  final bool isEncrypted;

  /// A list of fields that are currently encrypted.
  final List<String> encryptedFields;

  /// Creates a [ProjectSecuritySettings] widget.
  const ProjectSecuritySettings({
    super.key,
    required this.projectId,
    required this.isPasswordProtected,
    required this.isEncrypted,
    required this.encryptedFields,
  });

  @override
  ConsumerState<ProjectSecuritySettings> createState() =>
      _ProjectSecuritySettingsState();
}

class _ProjectSecuritySettingsState
    extends ConsumerState<ProjectSecuritySettings> {
  late bool _passwordEnabled;
  late bool _encryptionEnabled;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(LucideIcons.shield, color: Colors.blueAccent, size: 24),
              SizedBox(width: 12),
              Text(
                'Security Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Password Protection Toggle
          _buildSecurityOption(
            icon: LucideIcons.lock,
            title: 'Password Protection',
            subtitle: 'Require password to open this project',
            value: _passwordEnabled,
            onChanged: _isLoading ? null : _togglePasswordProtection,
            color: Colors.orangeAccent,
          ),

          const SizedBox(height: 16),

          // Encryption Toggle
          _buildSecurityOption(
            icon: LucideIcons.shieldCheck,
            title: 'Field Encryption',
            subtitle: 'Encrypt sensitive project data',
            value: _encryptionEnabled,
            onChanged: _isLoading ? null : _toggleEncryption,
            color: Colors.greenAccent,
          ),

          if (widget.encryptedFields.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                'Encrypted: ${widget.encryptedFields.join(", ")}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Encrypted Backups
          _buildActionButton(
            icon: LucideIcons.database,
            title: 'Create Encrypted Backup',
            subtitle: 'Backup with password protection',
            onTap: _createBackup,
            color: Colors.purpleAccent,
          ),

          const SizedBox(height: 12),

          // Security Audit Log
          _buildActionButton(
            icon: LucideIcons.fileText,
            title: 'View Audit Log',
            subtitle: 'See access history',
            onTap: _viewAuditLog,
            color: Colors.cyanAccent,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _passwordEnabled = widget.isPasswordProtected;
    _encryptionEnabled = widget.isEncrypted;
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.5) : Colors.white10,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final securityRepo = ref.read(arSecurityRepositoryProvider);
      final password = await showPasswordInputDialog(
        context,
        title: 'Encryption Password for Backup',
      );

      if (password != null) {
        await securityRepo.createEncryptedBackup(
          projectId: widget.projectId,
          password: password,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleEncryption(bool enabled) async {
    setState(() => _isLoading = true);

    try {
      final securityRepo = ref.read(arSecurityRepositoryProvider);

      if (enabled) {
        // Encrypt description and notes fields
        await securityRepo.encryptProjectFields(
          projectId: widget.projectId,
          fieldsToEncrypt: ['description', 'notes'],
        );
      } else {
        // To be implemented: decrypt fields?
        // securityRepo doesn't have a clear decryptProjectFields right now,
        // but it's usually one-way until read.
      }

      setState(() => _encryptionEnabled = enabled);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(enabled ? 'Encryption enabled' : 'Encryption disabled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePasswordProtection(bool enabled) async {
    setState(() => _isLoading = true);

    try {
      final securityRepo = ref.read(arSecurityRepositoryProvider);

      if (enabled) {
        // Show password input dialog
        final password = await showPasswordInputDialog(
          context,
          title: 'Set Project Password',
          requireConfirmation: true,
        );
        if (password != null) {
          await securityRepo.setProjectPassword(
            projectId: widget.projectId,
            password: password,
          );
          if (!mounted) return;
          setState(() => _passwordEnabled = true);
        }
      } else {
        // Remove password
        await securityRepo.removeProjectPassword(widget.projectId);
        if (!mounted) return;
        setState(() => _passwordEnabled = false);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_passwordEnabled
                ? 'Password protection enabled'
                : 'Password protection disabled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewAuditLog() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecurityAuditLogScreen(projectId: widget.projectId),
      ),
    );
  }
}
