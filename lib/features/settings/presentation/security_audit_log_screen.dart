import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../learning/data/ar_security_repository.dart';

/// Security audit log viewer
/// Screen for viewing security audit logs for a project or the user.
class SecurityAuditLogScreen extends ConsumerStatefulWidget {
  /// The project ID to view logs for, or null for global user logs.
  final String? projectId;

  /// Creates a [SecurityAuditLogScreen].
  const SecurityAuditLogScreen({super.key, this.projectId});

  @override
  ConsumerState<SecurityAuditLogScreen> createState() =>
      _SecurityAuditLogScreenState();
}

class _SecurityAuditLogScreenState
    extends ConsumerState<SecurityAuditLogScreen> {
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Security Audit Log'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _auditLogs.isEmpty
                  ? _buildEmptyState()
                  : _buildAuditList(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Widget _buildAuditList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _auditLogs.length,
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        return _buildAuditLogCard(log)
            .animate(delay: (index * 50).ms)
            .fadeIn()
            .slideY(begin: 0.2);
      },
    );
  }

  Widget _buildAuditLogCard(Map<String, dynamic> log) {
    final action = log['action'] as String;
    final result = log['action_result'] as String;
    final timestamp = DateTime.parse(log['created_at'] as String);

    final (icon, color) = _getActionIconAndColor(action, result);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatAction(action),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),

          // Result badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: result == 'success'
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              result.toUpperCase(),
              style: TextStyle(
                color:
                    result == 'success' ? Colors.greenAccent : Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileText, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'No audit logs yet',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  String _formatAction(String action) {
    return action
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  (IconData, Color) _getActionIconAndColor(String action, String result) {
    final isSuccess = result == 'success';

    switch (action) {
      case 'view':
        return (LucideIcons.eye, isSuccess ? Colors.blue : Colors.grey);
      case 'edit':
        return (LucideIcons.edit, isSuccess ? Colors.orange : Colors.grey);
      case 'share':
        return (LucideIcons.share2, isSuccess ? Colors.purple : Colors.grey);
      case 'delete':
        return (LucideIcons.trash2, isSuccess ? Colors.red : Colors.grey);
      case 'password_attempt':
        return (LucideIcons.lock, isSuccess ? Colors.green : Colors.red);
      case 'password_set':
        return (LucideIcons.shieldCheck, Colors.green);
      case 'backup_created':
        return (LucideIcons.database, Colors.cyan);
      default:
        return (LucideIcons.activity, Colors.white);
    }
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);

    try {
      final securityRepo = ref.read(arSecurityRepositoryProvider);
      if (widget.projectId != null) {
        _auditLogs =
            await securityRepo.getAuditLog(projectId: widget.projectId!);
      } else {
        _auditLogs = await securityRepo.getUserAuditLog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load audit log: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
