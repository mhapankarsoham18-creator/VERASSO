import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/services/clipboard_service.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/services/backup_codes_service.dart';

/// Screen displayed after MFA enrollment to show the user their backup recovery codes.
class MFABackupCodesScreen extends StatefulWidget {
  /// Creates a [MFABackupCodesScreen].
  const MFABackupCodesScreen({super.key});

  @override
  State<MFABackupCodesScreen> createState() => _MFABackupCodesScreenState();
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _MFABackupCodesScreenState extends State<MFABackupCodesScreen> {
  final _service = BackupCodesService();
  List<String> _codes = [];
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Recovery Codes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.shieldAlert,
                  size: 48, color: Colors.orangeAccent),
              const SizedBox(height: 24),
              const Text(
                'Save your backup codes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'If you lose your phone or can\'t access your authentication app, these codes are the ONLY way to log into your account.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_codes.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const Text('No codes available to display.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _regenerate,
                        child: const Text('Generate New Codes'),
                      ),
                    ],
                  ),
                )
              else
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _codes.length,
                        itemBuilder: (context, index) {
                          return Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _codes[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Colors.white10, height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ActionButton(
                            icon: LucideIcons.copy,
                            label: 'Copy',
                            onTap: () {
                              ClipboardService.copyToClipboard(
                                  _codes.join('\n'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Codes copied to clipboard')),
                              );
                            },
                          ),
                          _ActionButton(
                            icon: LucideIcons.rotateCcw,
                            label: 'Regenerate',
                            onTap: _regenerate,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              const Text(
                'Important Security Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const _TipItem(
                  text:
                      'Store these codes in a secure digital vault or print them out.'),
              const _TipItem(text: 'Each code can only be used once.'),
              const _TipItem(
                  text: 'Generating new codes will invalidate the old ones.'),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('I HAVE SAVED THESE CODES',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    try {
      final existing = await _service.getBackupCodes();
      if (existing.isEmpty) {
        final newCodes = await _service.generateBackupCodes();
        if (mounted) setState(() => _codes = newCodes);
      } else {
        // Since we can't see the full codes again, we encourage regeneration if lost
        // For UI demo, if we have them but can't see, we'll just show 'REGENERATE' button
        // but for now let's assume if they open this, they might want to see new ones
        if (mounted) setState(() => _codes = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load codes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _regenerate() async {
    setState(() => _isLoading = true);
    try {
      final newCodes = await _service.regenerateBackupCodes();
      if (mounted) setState(() => _codes = newCodes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to regenerate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.orangeAccent)),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 14, color: Colors.white54))),
        ],
      ),
    );
  }
}
