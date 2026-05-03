import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../theme/colors.dart';
import 'package:verasso/core/utils/logger.dart';

/// Catches uncaught errors in the widget tree and displays a styled error screen
/// instead of the "Red Screen of Death".
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _setupErrorHandlers();
  }

  void _setupErrorHandlers() {
    // Handle framework errors (build/layout/paint phase)
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return _buildInlineErrorWidget(details.exceptionAsString());
    };

    // Catch Flutter framework errors and report to Sentry
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      Sentry.captureException(details.exception, stackTrace: details.stack);
      appLogger.d('Flutter error caught: ${details.exceptionAsString()}');
      if (mounted) {
        setState(() => _error = details.exception);
      }
    };

    // Catch async/platform errors not caught by Flutter framework
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      Sentry.captureException(error, stackTrace: stack);
      appLogger.d('Platform error caught: $error');
      if (mounted) {
        setState(() => _error = error);
      }
      return true; // Prevent the error from propagating further
    };
  }

  Widget _buildInlineErrorWidget(String message) {
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
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.classic.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.colors.neutralBg,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: context.colors.error, size: 64),
                SizedBox(height: 24),
                Text(
                  'CRITICAL SIGNAL LOSS',
                  style: TextStyle(color: context.colors.error, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                SizedBox(height: 12),
                Text(
                  'An unexpected error occurred: $_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() => _error = null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.neutralBg,
                  ),
                  child: Text('RETRY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
