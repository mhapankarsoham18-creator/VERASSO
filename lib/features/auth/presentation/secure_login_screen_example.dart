import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/ui/glass_container.dart';

import '../../../core/security/security_initializer.dart';

/// Example login screen demonstrating dual-layer verification (Supabase + bcrypt).
class SecureLoginScreen extends ConsumerStatefulWidget {
  /// Creates a [SecureLoginScreen].
  const SecureLoginScreen({super.key});

  @override
  ConsumerState<SecureLoginScreen> createState() => _SecureLoginScreenState();
}

class _SecureLoginScreenState extends ConsumerState<SecureLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Title
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Login with dual-layer verification',
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

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
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
                onSubmitted: (_) => _handleLogin(),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.all(12),
                  color: Colors.red.withValues(alpha: 0.2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

              const SizedBox(height: 8),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navigate to password reset flow
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text('Forgot Password?'),
                ),
              ),

              const SizedBox(height: 24),

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 16),

              // Signup link
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text('Don\'t have an account? Sign up'),
              ),

              const SizedBox(height: 32),

              // Security info
              GlassContainer(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withValues(alpha: 0.1),
                child: const Column(
                  children: [
                    Icon(LucideIcons.shield,
                        color: Colors.blueAccent, size: 32),
                    SizedBox(height: 12),
                    Text(
                      'Protected by',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bcrypt + Dual Verification',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text('Rate Limited',
                              style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.green,
                        ),
                        Chip(
                          label: Text('Bcrypt Hashed',
                              style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.blue,
                        ),
                        Chip(
                          label:
                              Text('Auto-Lock', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
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
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get secure auth service
      final authService = SecurityInitializer.authService;

      // Sign in with dual verification:
      // 1. Supabase auth
      // 2. Our bcrypt password table
      final response = await authService.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.session != null) {
        if (mounted) {
          // Success! Navigate to home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(LucideIcons.checkCircle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('✅ Login successful!'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (e) {
      setState(() {
        if (e.message.contains('locked')) {
          _errorMessage = '🔒 Account locked due to multiple failed attempts.\n'
              'Please try again in 15 minutes.';
        } else if (e.message.contains('Rate limit')) {
          // Extract retry time
          final match = RegExp(r'(\d+) seconds').firstMatch(e.message);
          final seconds = match?.group(1) ?? '300';
          final minutes = (int.parse(seconds) / 60).ceil();
          _errorMessage = '⏱️ Too many login attempts.\n'
              'Please wait $minutes minute(s) before trying again.';
        } else if (e.message.contains('Invalid')) {
          _errorMessage = '❌ Invalid email or password.\n'
              'Please check your credentials.';
        } else if (e.message.contains('Authentication failed')) {
          _errorMessage = '🚨 Security verification failed.\n'
              'Your password may need to be reset.';
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
}
