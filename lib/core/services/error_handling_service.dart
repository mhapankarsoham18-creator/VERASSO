import 'package:flutter/material.dart';

import '../exceptions/app_exceptions.dart';

/// Service providing standardized error dialogs.
class ErrorDialogService {
  /// Displays an error dialog for the given [error] in the provided [context].
  static Future<void> showError(BuildContext context, dynamic error) async {
    String title = 'Error';
    String message = 'An unexpected error occurred.';

    if (error is AppException) {
      // Handle known app exceptions
      message = error.message;
      if (error is NetworkException) {
        title = 'Connection Error';
        message = 'Please check your internet connection.';
      } else if (error is AppAuthException) {
        title = 'Authentication Failed';
      } else if (error is ValidationException) {
        title = 'Invalid Input';
      }
    } else if (error is String) {
      message = error;
    } else {
      message = error.toString();
    }

    if (context.mounted) {
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
