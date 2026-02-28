import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';

/// A styled text input field optimized for authentication flows.
///
/// Uses a [GlassContainer] for a "Liquid Glass" aesthetic and integrates
/// with the application theme.
class AuthTextField extends StatelessWidget {
  /// The controller for the text being edited.
  final TextEditingController controller;

  /// The label text to display as a hint.
  final String label;

  /// The icon to display at the start of the field.
  final IconData icon;

  /// Whether to obscure the text (e.g., for passwords).
  final bool isPassword;

  /// The key for the internal TextField.
  final Key? textFieldKey;

  /// Creates an [AuthTextField].
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.textFieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      opacity: 0.1,
      child: TextField(
        key: textFieldKey,
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(icon, color: Theme.of(context).colorScheme.primary),
          hintText: label,
          hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}
