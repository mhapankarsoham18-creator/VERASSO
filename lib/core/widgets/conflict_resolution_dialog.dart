import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// A dialog for resolving synchronization conflicts.
class ConflictResolutionDialog extends StatelessWidget {
  /// The name of the table where the conflict occurred.
  final String table;

  /// The identifier of the entity with the conflict.
  final String entityId;

  /// The local version of the data.
  final Map<String, dynamic> localData;

  /// The remote version of the data.
  final Map<String, dynamic> remoteData;

  /// Callback function called when the conflict is resolved.
  final Function(Map<String, dynamic> resolution) onResolved;

  /// Creates a [ConflictResolutionDialog] instance.
  const ConflictResolutionDialog({
    super.key,
    required this.table,
    required this.entityId,
    required this.localData,
    required this.remoteData,
    required this.onResolved,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(LucideIcons.alertTriangle, color: Colors.orange),
          SizedBox(width: 8),
          Text('Sync Conflict'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Conflict detected in $table ($entityId).'),
          const SizedBox(height: 16),
          const Text('Which version would you like to keep?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => onResolved(remoteData),
          child: const Text('Keep Remote'),
        ),
        TextButton(
          onPressed: () => onResolved(localData),
          child: const Text('Keep Mine'),
        ),
        ElevatedButton(
          onPressed: () {
            // Simple merge logic: remote takes precedence for everything but what we changed
            final merged = {...remoteData, ...localData};
            onResolved(merged);
          },
          child: const Text('Merge'),
        ),
      ],
    );
  }
}
