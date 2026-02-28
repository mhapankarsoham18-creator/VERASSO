import 'package:flutter/material.dart';

/// A standard widget for displaying empty states across the application.
class EmptyStateWidget extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The title of the empty state.
  final String title;

  /// The message providing more details about the empty state.
  final String message;

  /// The callback for the action button, if any.
  final VoidCallback? onAction;

  /// The label for the action button, if any.
  final String? actionLabel;

  /// Creates an [EmptyStateWidget] instance.
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
