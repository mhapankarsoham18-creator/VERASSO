import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../features/settings/presentation/help_support_screen.dart';
import '../../l10n/app_localizations.dart';

/// Standard app-wide error view with retry and optional support link.
///
/// This version includes a "Help & Support" link that pushes [HelpSupportScreen].
class AppErrorView extends StatelessWidget {
  /// Short error title (e.g. 'Could not load').
  final String? title;

  /// User-facing error message.
  final String message;

  /// Retry action; if null, no retry button is shown.
  final VoidCallback? onRetry;

  /// Optional custom support action; if null and [showSupportLink] is true,
  /// navigates to [HelpSupportScreen].
  final VoidCallback? onSupportTap;

  /// Whether to show a "Help & Support" link (defaults to true).
  final bool showSupportLink;

  /// Icon for the error state.
  final IconData icon;

  /// Creates an [AppErrorView].
  const AppErrorView({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.onSupportTap,
    this.showSupportLink = true,
    this.icon = LucideIcons.alertTriangle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.redAccent.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? l10n.somethingWentWrong,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: Text(l10n.tryAgain),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                if (showSupportLink)
                  OutlinedButton.icon(
                    onPressed: () {
                      if (onSupportTap != null) {
                        onSupportTap!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(LucideIcons.helpCircle, size: 18),
                    label: Text(l10n.helpAndSupport),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A generic error view widget for displaying full-screen or centered error states.
class ErrorView extends StatelessWidget {
  /// The title of the error view (defaults to 'Something went wrong').
  final String? title;

  /// The main message describing the error.
  final String message;

  /// Optional callback for a retry action.
  final VoidCallback? onRetry;

  /// The icon to display alongside the error (defaults to [LucideIcons.alertTriangle]).
  final IconData icon;

  /// Creates an [ErrorView].
  const ErrorView({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.icon = LucideIcons.alertTriangle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.redAccent.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title ?? l10n.somethingWentWrong,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(l10n.tryAgain),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
