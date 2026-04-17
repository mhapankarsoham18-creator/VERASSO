import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Catches uncaught errors in the widget tree and displays a styled error screen
/// instead of the "Red Screen of Death".
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  static void setupErrorHandlers() {
    // Handle framework errors (build phase)
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        backgroundColor: AppColors.classic.error.withValues(alpha: 0.1),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.classic.error, size: 64),
                SizedBox(height: 24),
                Text(
                  'CRITICAL SIGNAL LOSS',
                  style: TextStyle(color: AppColors.classic.error, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                SizedBox(height: 12),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.classic.textPrimary),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    ErrorBoundary.setupErrorHandlers();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.colors.neutralBg,
        body: Center(
          child: Text('An unexpected error occurred: \$_error', style: TextStyle(color: context.colors.error)),
        ),
      );
    }
    return widget.child;
  }
}
