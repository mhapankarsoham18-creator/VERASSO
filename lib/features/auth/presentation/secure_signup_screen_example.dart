import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../../core/security/security_initializer.dart';

/// Example signup screen demonstrating secure password hashing with bcrypt.
class SecureSignupScreen extends ConsumerStatefulWidget {
  /// Creates a [SecureSignupScreen].
  const SecureSignupScreen({super.key});

  @override
  ConsumerState<SecureSignupScreen> createState() => _SecureSignupScreenState();
}

class _SecureSignupScreenState extends ConsumerState<SecureSignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  int _passwordStrength = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Title
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your password will be secured with bcrypt',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 40),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(LucideIcons.mail),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Username
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(LucideIcons.user),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Full Name
              TextField(
                controller: _fullNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(LucideIcons.userCircle),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: _onPasswordChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(LucideIcons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Password strength indicator
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _passwordStrength / 5,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(
                    _passwordStrength < 2
                        ? Colors.red
                        : _passwordStrength < 4
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _passwordStrength < 2
                      ? 'Weak'
                      : _passwordStrength < 4
                          ? 'Good'
                          : 'Strong',
                  style: TextStyle(
                    color: _passwordStrength < 2
                        ? Colors.red
                        : _passwordStrength < 4
                            ? Colors.orange
                            : Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.all(12),
                  color: Colors.red.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertCircle,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Signup button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blueAccent,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('Create Account',
                        style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 16),

              // Login link
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
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

  Future<void> _handleSignup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get secure auth service
      final authService = SecurityInitializer.authService;

      // Sign up with bcrypt password hashing
      final response = await authService.signUpWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );

      if (response.user != null) {
        if (mounted) {
          // Success! Navigate to home or email verification
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(LucideIcons.checkCircle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('✅ Account created successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home or verification screen
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.message.contains('Password')) {
          _errorMessage = 'Password must:\n'
              '• Be at least 8 characters\n'
              '• Contain uppercase and lowercase\n'
              '• Contain numbers and special chars';
        } else if (e.message.contains('Rate limit')) {
          _errorMessage = 'Too many signup attempts. Please try again later.';
        } else if (e.message.contains('already registered')) {
          _errorMessage = 'Email already registered. Try logging in.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onPasswordChanged(String password) {
    setState(() {
      _passwordStrength = _calculateStrength(password);
    });
  }
}
