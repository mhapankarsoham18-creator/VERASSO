import 'package:flutter/material.dart';
import 'package:verasso/core/widgets/verasso_snackbar.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../../core/services/privacy_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _privacyService = PrivacyService();
  bool _isLoading = false;

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      await _privacyService.exportUserData();
      if (mounted) {
        VerassoSnackbar.show(context, message: 'Data export generated and ready for sharing.');
      }
    } catch (e) {
      if (mounted) {
        VerassoSnackbar.show(context, message: 'Export failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.neutralBg,
        title: Text('DELETE IDENTITY?', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
        content: Text(
            'This action is irreversible. All your data, transmissions, and mesh interactions will be permanently scrubbed. You will be logged out immediately.',
            style: TextStyle(color: context.colors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: context.colors.textSecondary)),
          ),
          NeoPixelBox(
            padding: 8,
            isButton: true,
            backgroundColor: context.colors.error.withValues(alpha: 0.1),
            onTap: () => Navigator.pop(context, true),
            child: Text('PURGE', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Account deletion initiated. This might take a few seconds...'))
            );
        }
        await _privacyService.deleteAccount();
        if (mounted) {
           Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          String err = e.toString();
          if (err.contains('requires-recent-login')) {
            err = "For security reasons, please log out and log back in to verify ownership before deleting your account.";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deletion interrupted: $err', style: TextStyle(fontWeight: FontWeight.bold))),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('PRIVACY & SECURITY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: _isLoading 
        ? Center(child: VerassoLoading())
        : ListView(
        padding: EdgeInsets.all(24.0),
        children: [
          NeoPixelBox(
            padding: 24,
            enableTilt: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, color: context.colors.primary, size: 28),
                    SizedBox(width: 12),
                    Expanded(child: Text('DATA COMPLIANCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: context.colors.textPrimary))),
                  ],
                ),
                SizedBox(height: 16),
                Text('Verasso complies with the DPDP Act 2023. Your mesh interactions are E2E encrypted and your personal data belongs to you.', style: TextStyle(color: context.colors.textSecondary, height: 1.5)),
                SizedBox(height: 24),
                
                // Export Data
                NeoPixelBox(
                  padding: 16,
                  isButton: true,
                  onTap: _exportData,
                  child: Row(
                    children: [
                      Icon(Icons.download, color: context.colors.primary),
                      SizedBox(width: 12),
                      Text('REQUEST DATA EXPORT', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary)),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Delete Account
                NeoPixelBox(
                  padding: 16,
                  isButton: true,
                  backgroundColor: context.colors.error.withValues(alpha: 0.1),
                  onTap: _deleteAccount,
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: context.colors.error),
                      SizedBox(width: 12),
                      Text('DELETE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
