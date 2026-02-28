import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/monitoring/app_logger.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../data/privacy_repository.dart';

/// Screen for managing personal data and privacy consents.
class DataManagementScreen extends StatefulWidget {
  /// Creates a [DataManagementScreen].
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final _privacyRepo = PrivacyRepository();
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data & Privacy')),
      body: LiquidBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                'Personal Data Management',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            GlassContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.download),
                    title: const Text('Export My Data'),
                    subtitle:
                        const Text('Get a copy of your activity and profile'),
                    trailing: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.chevronRight),
                    onTap: _isExporting ? null : _handleExport,
                  ),
                  const Divider(color: Colors.white24),
                  const ListTile(
                    leading: Icon(LucideIcons.shieldCheck),
                    title: Text('Consent Preferences'),
                    subtitle: Text('Manage how your data is used'),
                    trailing: Icon(LucideIcons.chevronRight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 16),
              child: Text(
                'Danger Zone',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
            GlassContainer(
              child: ListTile(
                leading:
                    const Icon(LucideIcons.trash2, color: Colors.redAccent),
                title: const Text('Delete Account',
                    style: TextStyle(color: Colors.redAccent)),
                subtitle:
                    const Text('Permanently remove your data from Verasso'),
                onTap: _isDeleting ? null : _handleDeleteAccount,
              ),
            ),
            if (_isDeleting)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is IRREVERSIBLE. All your posts, profile data, and social connections will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await _privacyRepo.deleteAccount();
        // Auth state will trigger logout automatically via router redirect
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deletion failed: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final jsonData = await _privacyRepo.exportUserData();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data Export Ready'),
            content: const Text(
                'Your data has been compiled into a JSON format. In a production app, this would be sent to your email or downloaded.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  // In a real app, share or save file
                  AppLogger.info(jsonData.toString());
                  Navigator.pop(context);
                },
                child: const Text('View Raw Data'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
