import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../../core/security/password_hashing_service.dart';
import '../../l10n/app_localizations.dart';

/// Show password input dialog
Future<String?> showPasswordInputDialog(
  BuildContext context, {
  required String title,
  String? hint,
  bool showStrengthIndicator = true,
  bool requireConfirmation = false,
}) async {
  String? password;

  await showDialog(
    context: context,
    builder: (context) => PasswordInputDialog(
      title: title,
      hint: hint,
      showStrengthIndicator: showStrengthIndicator,
      requireConfirmation: requireConfirmation,
      onSubmit: (p) => password = p,
    ),
  );

  return password;
}

/// Password input dialog with strength indicator
/// A specialized dialog for secure password entry with real-time strength validation.
///
/// Features a visual strength indicator, optional password hints, and a
/// double-entry confirmation mode.
class PasswordInputDialog extends StatefulWidget {
  /// The header title for the dialog.
  final String title;

  /// Optional hint text to display to the user.
  final String? hint;

  /// Whether to display the real-time password strength meter.
  final bool showStrengthIndicator;

  /// Whether to require the user to enter the password twice.
  final bool requireConfirmation;

  /// Callback executed when the user submits a valid password.
  final Function(String password) onSubmit;

  /// Creates a [PasswordInputDialog].
  const PasswordInputDialog({
    super.key,
    required this.title,
    this.hint,
    this.showStrengthIndicator = true,
    this.requireConfirmation = false,
    required this.onSubmit,
  });

  @override
  State<PasswordInputDialog> createState() => _PasswordInputDialogState();
}

class _PasswordInputDialogState extends State<PasswordInputDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  int _strengthScore = 0;
  Color _strengthColor = Colors.grey;
  String _strengthText = 'Weak';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(LucideIcons.lock, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Hint
            if (widget.hint != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.lightbulb,
                        color: Colors.yellowAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.hintPrefix(widget.hint!),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: _onPasswordChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.password,
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: Colors.white70,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),

            // Strength indicator
            if (widget.showStrengthIndicator &&
                _passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _strengthScore / 5,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation(_strengthColor),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _strengthText,
                        style: TextStyle(
                          color: _strengthColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.passwordRequirements,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],

            // Confirm password field
            if (widget.requireConfirmation) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: l10n.confirmPassword,
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                      color: Colors.white70,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle,
                        color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel,
                      style: const TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.submit),
                ),
              ],
            ),
          ],
        ),
      ).animate().scale(duration: 200.ms),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  int _calculateStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  void _onPasswordChanged(String password) {
    setState(() {
      _errorMessage = null;
      _strengthScore = _calculateStrength(password);

      final l10n = AppLocalizations.of(context)!;
      if (_strengthScore == 0) {
        _strengthColor = Colors.grey;
        _strengthText = l10n.strengthWeak;
      } else if (_strengthScore == 1) {
        _strengthColor = Colors.red;
        _strengthText = l10n.strengthWeak;
      } else if (_strengthScore == 2) {
        _strengthColor = Colors.orange;
        _strengthText = l10n.strengthFair;
      } else if (_strengthScore == 3) {
        _strengthColor = Colors.yellow;
        _strengthText = l10n.strengthGood;
      } else if (_strengthScore == 4) {
        _strengthColor = Colors.green;
        _strengthText = l10n.strengthStrong;
      } else {
        _strengthColor = Colors.greenAccent;
        _strengthText = l10n.strengthVeryStrong;
      }
    });
  }

  void _onSubmit() {
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;

    // Validate password strength
    final (isValid, errorMessage) =
        PasswordHashingService.validatePasswordStrength(password);

    if (!isValid) {
      setState(() => _errorMessage = errorMessage);
      return;
    }

    // Check confirmation if required
    if (widget.requireConfirmation) {
      if (password != _confirmController.text) {
        setState(() => _errorMessage = l10n.passwordsDoNotMatch);
        return;
      }
    }

    widget.onSubmit(password);
    Navigator.pop(context);
  }
}
