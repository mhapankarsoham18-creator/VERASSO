import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Show session timeout warning dialog
void showSessionTimeoutWarning(
  BuildContext context, {
  required VoidCallback onStayLogged,
  required VoidCallback onLogout,
  required int secondsRemaining,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => SessionTimeoutWarningDialog(
      onStayLogged: onStayLogged,
      onLogout: onLogout,
      secondsRemaining: secondsRemaining,
    ),
  );
}

/// Dialog shown when session is about to expire
/// A warning dialog displayed when the user's session is nearing expiration.
///
/// Shows a countdown timer and provides options to stay logged in or logout.
class SessionTimeoutWarningDialog extends StatefulWidget {
  /// Callback executed if the user chooses to extend the session.
  final VoidCallback onStayLogged;

  /// Callback executed if the user chooses to logout immediately.
  final VoidCallback onLogout;

  /// The number of seconds remaining before automatic logout.
  final int secondsRemaining;

  /// Creates a [SessionTimeoutWarningDialog].
  const SessionTimeoutWarningDialog({
    super.key,
    required this.onStayLogged,
    required this.onLogout,
    required this.secondsRemaining,
  });

  @override
  State<SessionTimeoutWarningDialog> createState() =>
      _SessionTimeoutWarningDialogState();
}

class _SessionTimeoutWarningDialogState
    extends State<SessionTimeoutWarningDialog> {
  late int _secondsLeft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.sessionExpiringSoon),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.sessionExpireIn,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            _formatTime(_secondsLeft),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.stayLoggedIn,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onLogout,
          child: Text(
            l10n.logout,
            style: const TextStyle(color: Colors.red),
          ),
        ),
        ElevatedButton(
          onPressed: widget.onStayLogged,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: Text(
            l10n.stayLoggedIn,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.secondsRemaining;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
