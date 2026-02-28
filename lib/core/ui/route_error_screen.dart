import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'empty_state_widget.dart';
import 'liquid_background.dart';

/// Fallback screen for unknown or failing routes.
///
/// This ensures that bad deep links or navigation errors result in a
/// graceful, branded experience instead of a raw exception or blank screen.
class RouteErrorScreen extends StatelessWidget {
  /// The router state associated with the failure.
  final GoRouterState state;

  /// Creates a [RouteErrorScreen].
  const RouteErrorScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final errorMessage = state.error?.toString() ??
        'The page you requested could not be found or is no longer available.';

    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          child: EmptyStateWidget(
            title: 'Navigation Error',
            message: errorMessage,
            icon: LucideIcons.alertTriangle,
            actionLabel: 'Back to Home',
            onAction: () => context.go('/'),
          ),
        ),
      ),
    );
  }
}

