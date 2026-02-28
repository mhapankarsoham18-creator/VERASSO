// Premium Empty State Widget
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

/// A premium empty state widget used to indicate when no data is available.
///
/// Encapsulated in a [GlassContainer] with a placeholder icon and optional action button.
class EmptyStateWidget extends StatelessWidget {
  /// The title for the empty state.
  final String title;

  /// The message explaining why the state is empty (or how to populate it).
  final String message;

  /// The icon to display (defaults to [LucideIcons.ghost]).
  final IconData icon;

  /// Optional callback for a primary action button.
  final VoidCallback? onAction;

  /// The label for the optional action button.
  final String? actionLabel;

  /// Creates an [EmptyStateWidget].
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = LucideIcons.ghost,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: GlassContainer(
          opacity: 0.1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: Colors.white24),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                    ),
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
