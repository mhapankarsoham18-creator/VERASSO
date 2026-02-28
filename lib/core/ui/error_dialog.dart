import 'package:flutter/material.dart';

/// Displays an error dialog with customizable title, message, and action buttons
/// Displays an error dialog with customizable title, message, and action buttons.
class ErrorDialog extends StatelessWidget {
  /// The title of the error dialog.
  final String title;

  /// The main error message to display.
  final String message;

  /// Callback executed when the "Retry" button is pressed.
  final VoidCallback? onRetry;

  /// Callback executed when the dialog is dismissed.
  final VoidCallback? onDismiss;

  /// Whether to show the technical [details] block.
  final bool showDetails;

  /// Optional technical details or stack trace info.
  final String? details;

  /// Creates an [ErrorDialog].
  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (showDetails && details != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  details!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                        fontFamily: 'monospace',
                      ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('Dismiss'),
        ),
        if (onRetry != null)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!.call();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
      ],
    );
  }

  /// Shows this error dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    String? details,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
        onDismiss: onDismiss,
        showDetails: details != null,
        details: details,
      ),
    );
  }
}
