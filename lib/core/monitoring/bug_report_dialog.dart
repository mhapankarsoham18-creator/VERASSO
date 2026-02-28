import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../features/gamification/services/gamification_event_bus.dart';
import '../../main.dart'; // To access routerProvider
import '../ui/glass_container.dart';
import 'bug_catcher_service.dart';

/// A dialog widget that allows users to submit bug reports and earn rewards.
class BugReportDialog extends ConsumerStatefulWidget {
  /// Creates a [BugReportDialog].
  const BugReportDialog({super.key});

  @override
  ConsumerState<BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends ConsumerState<BugReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'UI/UX';
  bool _isSending = false;

  final List<String> _categories = [
    'UI/UX',
    'Functionality',
    'Crash',
    'Performance',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.shieldAlert, color: Colors.orangeAccent),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.bugReportTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.bugReportHelpText,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: 'General Bug',
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.bugCategory),
                dropdownColor: Colors.grey.shade900,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.bugTitle,
                  hintText: 'e.g., Feed fails to load',
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.reproductionSteps,
                  hintText: '1. Open Home\n2. Scroll down...',
                ),
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _submitReport,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.send),
                  label: Text(_isSending
                      ? AppLocalizations.of(context)!.transmitting
                      : AppLocalizations.of(context)!.logAnomaly),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog(String message, bool success) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success
            ? AppLocalizations.of(context)!.anomalyNeutralized
            : AppLocalizations.of(context)!.dataLogged),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.dismiss),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final bugCatcher = ref.read(bugCatcherServiceProvider);
      final eventBus = ref.read(gamificationEventBusProvider);

      final router = ref.read(routerProvider);
      final currentRoute =
          router.routerDelegate.currentConfiguration.last.matchedLocation;

      final result = await bugCatcher.submitReport(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
        metadata: {
          'device_os': 'Android',
          'os_version': '13.0',
          'app_version': '1.1.0',
          'current_route': currentRoute,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        if (result['success']) {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (result['status'] == 'valid' && userId != null) {
            eventBus.track(GamificationAction.bugReported, userId, metadata: {
              'category': _category,
              'status': 'valid',
            });
          }

          if (mounted) {
            Navigator.pop(context);
            _showResultDialog(result['message'], result['status'] == 'valid');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to report: ${result['error']}')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
